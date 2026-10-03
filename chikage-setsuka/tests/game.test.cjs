'use strict';
// Optional developer checks; the browser game itself does not require Node.js.
const test = require('node:test');
const assert = require('node:assert/strict');
const { GameCore, data } = require('../script.js');

function seededRandom(seed) {
  return () => {
    seed = (seed + 0x6D2B79F5) | 0;
    let t = Math.imul(seed ^ seed >>> 15, 1 | seed);
    t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
    return ((t ^ t >>> 14) >>> 0) / 4294967296;
  };
}

function chooseForBuild(game, setsuka, chikage) {
  const s = game.state;
  const score = id => {
    const card = data.upgrades.find(item => item.id === id);
    if (card.type === 'synergy') {
      const link = data.synergies.find(item => item.id === card.link);
      if (link.setsuka === setsuka && link.chikage === chikage) return 100;
      return link.setsuka === setsuka || link.chikage === chikage ? 2 : 0;
    }
    if (card.type === 'setsuka') {
      if (card.axis === setsuka) return 30 + (s.axes.chikage[chikage] - s.axes.setsuka[setsuka]) * 3;
      return card.axis === 'rage' ? -10 : 3;
    }
    if (card.axis === chikage) return 30 + (s.axes.setsuka[setsuka] - s.axes.chikage[chikage]) * 3;
    return card.axis === 'support' ? 6 : 4;
  };
  return [...s.choices].sort((a, b) => score(b) - score(a))[0];
}

function simulate(setsuka, chikage, seed) {
  const game = new GameCore({ random: seededRandom(seed) });
  game.start();
  for (let ticks = 0; ticks < 12000 && game.state.status !== 'result'; ticks++) {
    if (game.state.status === 'choice') {
      assert.equal(new Set(game.state.choices).size, 3);
      assert.ok(game.choose(chooseForBuild(game, setsuka, chikage)));
    } else game.step(0.25);
    assert.ok(Number.isFinite(game.state.danger));
    assert.ok(game.state.danger >= 0 && game.state.danger <= 100);
  }
  assert.equal(game.state.status, 'result', 'A run must terminate, rather than stall.');
  assert.equal(new Set(game.state.records.map(record => record.id)).size, game.state.records.length);
  assert.ok(game.state.artifacts >= 0 && game.state.data >= 0);
  for (const rank of Object.values(game.state.cards)) assert.ok(rank >= 1 && rank <= 3);
  if (game.state.won) {
    assert.equal(game.state.records.length, 10);
    assert.equal(game.state.records.at(-1).id, 'boss');
    assert.equal(game.state.choicesTaken, 20);
  }
  return game;
}

test('Content: 9 normal cases, 1 boss, 27 upgrades, 9 complete pairs, 5 personalities', () => {
  assert.equal(data.cases.filter(c => !c.boss).length, 9);
  assert.equal(data.cases.filter(c => c.boss).length, 1);
  assert.equal(data.upgrades.length, 27);
  for (const type of ['setsuka', 'chikage', 'synergy']) assert.equal(data.upgrades.filter(card => card.type === type).length, 9);
  assert.equal(data.synergies.length, 9);
  assert.equal(new Set(data.synergies.map(link => `${link.setsuka}/${link.chikage}`)).size, 9);
  assert.equal(Object.keys(data.kinds).length, 5);
  assert.equal(new Set(data.upgrades.map(card => card.id)).size, 27);
});

test('Initial choice pauses progression; an unoffered/duplicate selection is rejected', () => {
  const game = new GameCore();
  assert.ok(game.start());
  assert.equal(game.start(), false);
  game.step(100);
  assert.equal(game.state.elapsed, 0);
  assert.equal(game.choose('c-index'), false);
  assert.ok(game.choose('s-cut'));
  assert.equal(game.choose('s-cut'), false);
  game.step(1000);
  assert.equal(game.state.status, 'choice');
  assert.equal(game.state.choiceKind, 'partner');
  const elapsed = game.state.elapsed;
  game.step(1000);
  game.step(Infinity);
  assert.equal(game.state.elapsed, elapsed);
});

test('All 27 upgrades can be selected and have a hard cap of Lv3', () => {
  for (const card of data.upgrades) {
    const game = new GameCore();
    game.start();
    for (let rank = 1; rank <= 3; rank++) {
      game.state.status = 'choice';
      game.state.choices = [card.id];
      assert.ok(game.choose(card.id), card.id);
      assert.equal(game.state.cards[card.id], rank);
    }
    game.state.status = 'choice';
    game.state.choices = [card.id];
    assert.equal(game.choose(card.id), false, card.id);
    const totalLevels = Object.values(game.state.axes.setsuka).concat(Object.values(game.state.axes.chikage)).reduce((sum, n) => sum + n, 0);
    assert.equal(totalLevels, card.type === 'synergy' ? 6 : 3);
  }
});

for (const link of data.synergies) {
  test(`${link.name} activates automatically at both Lv2, then link training strengthens it`, () => {
    const game = new GameCore();
    game.start();
    game.state.axes.setsuka[link.setsuka] = 2;
    game.state.axes.chikage[link.chikage] = 1;
    assert.equal(game.isActive(link.id), false);
    const card = data.upgrades.find(item => item.link === link.id);
    game.state.choices = [card.id];
    assert.ok(game.choose(card.id));
    assert.ok(game.isActive(link.id));
    assert.ok(game.state.activeLinks.includes(link.id));
    assert.equal(game.state.links[link.id], 1);
    assert.ok(game.state.logs.some(log => log.text.includes(link.name)));
  });
}

test('Mimic resistance disappears after analysis; complete analysis also controls danger', () => {
  const game = new GameCore();
  game.enterCase(9);
  const before = game.stats();
  game.state.analysis = game.state.current.depth;
  const after = game.stats();
  assert.ok(after.attack > before.attack * 1.5);
  assert.ok(after.danger < before.danger);
  assert.ok(after.weak);
});

test('Collection becomes a capture after sufficient analysis, improving process speed', () => {
  const game = new GameCore();
  game.start();
  game.state.axes.setsuka.collect = 2;
  game.state.analysis = game.state.current.depth * 0.70;
  assert.equal(game.stats().capturable, false);
  const before = game.stats().attack;
  game.state.analysis = game.state.current.depth * 0.80;
  assert.ok(game.stats().capturable);
  assert.ok(game.stats().attack > before);
});

test('The burst axe produces extra progress only in the danger zone', () => {
  function advance(danger) {
    const game = new GameCore();
    game.enterCase(0);
    game.state.cards['s-burst'] = 1;
    game.state.danger = danger;
    game.state.nextBurst = 0;
    game.step(0.25);
    return game.state.process;
  }
  assert.ok(advance(60) > advance(10) * 3);
});

test('Danger 100 ends the run with a withdrawal result; no further progress is applied', () => {
  const game = new GameCore();
  game.enterCase(0);
  game.state.danger = 99.999;
  game.step(1);
  assert.equal(game.state.status, 'result');
  assert.equal(game.state.won, false);
  const elapsed = game.state.elapsed;
  game.step(60);
  assert.equal(game.state.elapsed, elapsed);
});

test('Shuffled early encounters scale with position; special encounters change risk/rewards', () => {
  const game = new GameCore({ random: seededRandom(1) });
  game.enterCase(1);
  const normal = { ...game.state.current };
  assert.equal(normal.hp, 124);
  assert.equal(normal.depth, 103);
  game.state.specialNext = true;
  game.enterCase(1);
  assert.ok(game.state.current.special);
  assert.ok(game.state.current.hp > normal.hp);
  assert.ok(game.state.current.threat > normal.threat);
});

test('DATA research and research-oriented upgrades cross real thresholds', () => {
  const game = new GameCore();
  game.start();
  game.state.data = 55;
  game.updateResearch();
  assert.equal(game.state.research, 0);
  game.state.choices = ['c-log'];
  assert.ok(game.choose('c-log'));
  assert.equal(game.state.research, 1);
  game.state.data = 300;
  game.updateResearch();
  assert.equal(game.state.research, 3);
});

const outcomes = new Map();
for (const setsuka of ['destroy', 'collect', 'rage']) {
  for (const chikage of ['analyze', 'support', 'explore']) {
    test(`Full run terminates and remains valid: ${setsuka} × ${chikage} (3 seeded runs)`, () => {
      const runs = [1, 2, 3].map(seed => simulate(setsuka, chikage, seed));
      outcomes.set(`${setsuka}/${chikage}`, runs);
      if (['collect/analyze', 'destroy/explore', 'rage/support'].includes(`${setsuka}/${chikage}`)) {
        assert.ok(runs.every(game => game.state.won), 'The three principal build concepts must be able to clear the boss.');
      }
    });
  }
}

test('Builds change the loop: research earns DATA/captures; sweep is faster and finds variants', () => {
  const research = outcomes.get('collect/analyze');
  const sweep = outcomes.get('destroy/explore');
  const sum = (runs, selector) => runs.reduce((total, game) => total + selector(game.state), 0);
  assert.ok(sum(research, s => s.data) > sum(sweep, s => s.data) * 2);
  assert.ok(sum(research, s => s.records.filter(r => r.captured).length) >= 15);
  assert.ok(sum(research, s => s.elapsed) > sum(sweep, s => s.elapsed));
  assert.ok(sum(sweep, s => s.records.filter(r => r.special).length) > sum(research, s => s.records.filter(r => r.special).length));
});

test('Support makes a reckless build sustainable; uncontrolled reckless exploration can withdraw', () => {
  assert.ok(outcomes.get('rage/support').every(game => game.state.won));
  assert.ok(outcomes.get('rage/explore').some(game => !game.state.won));
});

test('Retry resets resources, progress, acquired upgrades and all axes', () => {
  const game = simulate('collect', 'analyze', 1);
  game.reset();
  assert.equal(game.state.status, 'intro');
  assert.equal(game.state.elapsed, 0);
  assert.equal(game.state.artifacts, 0);
  assert.equal(game.state.data, 0);
  assert.deepEqual(game.state.cards, {});
  assert.equal(game.state.activeLinks.length, 0);
  assert.equal(game.state.records.length, 0);
  assert.ok(Object.values(game.state.axes.setsuka).concat(Object.values(game.state.axes.chikage)).every(level => level === 0));
});
