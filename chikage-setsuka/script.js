(function (root) {
  'use strict';
  const DATA = root.NIGHTSHIFT_DATA || (typeof require === 'function' ? require('./data.js') : null);
  const clamp = (value, min, max) => Math.min(max, Math.max(min, value));
  const formatTime = seconds => `${String(Math.floor(seconds / 60)).padStart(2, '0')}:${String(Math.floor(seconds % 60)).padStart(2, '0')}`;

  // The simulation has no DOM, timers, storage or network dependencies.
  class GameCore {
    constructor(options = {}) {
      this.random = options.random || Math.random;
      this.onEvent = options.onEvent || (() => {});
      this.reset();
    }

    reset() {
      const middle = DATA.cases.slice(1, -1);
      for (let i = middle.length - 1; i > 0; i--) {
        const j = Math.floor(this.random() * (i + 1));
        [middle[i], middle[j]] = [middle[j], middle[i]];
      }
      this.state = {
        status: 'intro', queue: [DATA.cases[0], ...middle, DATA.cases.at(-1)], index: 0,
        current: null, elapsed: 0, caseTime: 0, process: 0, analysis: 0, danger: 14,
        artifacts: 0, data: 0, rare: 0, research: 0, cards: {},
        axes: { setsuka: { destroy: 0, collect: 0, rage: 0 }, chikage: { analyze: 0, support: 0, explore: 0 } },
        links: {}, activeLinks: [], choices: [], choicesTaken: 0, choiceKind: '',
        midOffered: false, pendingAdvance: false, nextEvent: 24, nextAction: 6,
        nextBurst: 12, weakpointFound: false, fullyAnalyzed: false,
        specialNext: false, records: [], logs: [], won: false, reason: ''
      };
      this.log('夜間対応班、待機。最初の育成方針を選んで出動。');
    }

    log(text, type = '') {
      this.state.logs.unshift({ text, type, time: this.state.elapsed });
      this.state.logs.length = Math.min(30, this.state.logs.length);
      this.onEvent({ type: 'log', text, tone: type });
    }

    start() {
      if (this.state.status !== 'intro') return false;
      this.enterCase(0);
      this.offerChoice('initial');
      return true;
    }

    enterCase(index) {
      const s = this.state;
      const source = s.queue[index];
      const special = !source.boss && s.specialNext;
      s.specialNext = false;
      // Shuffle encounters, while scaling difficulty with the run's position.
      // A late-game file appearing early must not inherit late-game durability.
      s.current = {
        ...source, special,
        hp: (source.boss ? source.hp : 110 + index * 14) * (special ? 1.15 : 1),
        depth: source.boss ? source.depth : 95 + index * 8,
        threat: source.threat + (source.boss ? 0 : index * 0.007) + (special ? 0.045 : 0)
      };
      s.index = index;
      s.process = 0;
      s.analysis = 0;
      s.caseTime = 0;
      s.midOffered = false;
      s.nextEvent = 24;
      s.nextAction = 6;
      s.nextBurst = 12;
      s.weakpointFound = false;
      s.fullyAnalyzed = false;
      s.pendingAdvance = false;
      s.danger = index === 0 ? 14 : Math.max(10, s.danger * 0.55 + 6);
      s.status = 'running';
      this.log(`${source.boss ? '最終CASE' : `CASE ${String(index + 1).padStart(2, '0')}`}：${source.name}${special ? '〈異相を発見〉' : ''}`);
      this.onEvent({ type: 'case', current: s.current });
    }

    weightedPick(cards, weight) {
      const total = cards.reduce((sum, card) => sum + weight(card), 0);
      let needle = this.random() * total;
      for (const card of cards) {
        needle -= weight(card);
        if (needle <= 0) return card;
      }
      return cards.at(-1);
    }

    offerChoice(kind) {
      const s = this.state;
      s.status = 'choice';
      s.choiceKind = kind;
      if (kind === 'initial') {
        s.choices = ['s-cut', 's-hook', 's-limit'];
      } else if (kind === 'partner') {
        s.choices = ['c-weak', 'c-cool', 'c-radar'];
      } else {
        s.choices = ['setsuka', 'chikage', 'synergy'].map(type => {
          const eligible = DATA.upgrades.filter(card => card.type === type && (s.cards[card.id] || 0) < card.max);
          return this.weightedPick(eligible, card => {
            if (type !== 'synergy') return 1 + s.axes[type][card.axis] * 0.75;
            const link = DATA.synergies.find(item => item.id === card.link);
            return 1 + Math.min(s.axes.setsuka[link.setsuka], s.axes.chikage[link.chikage]) * 1.6;
          }).id;
        });
      }
      this.onEvent({ type: 'choice', kind, choices: s.choices });
    }

    choose(id) {
      const s = this.state;
      const card = DATA.upgrades.find(item => item.id === id);
      if (s.status !== 'choice' || !card || !s.choices.includes(id) || (s.cards[id] || 0) >= card.max) return false;
      s.cards[id] = (s.cards[id] || 0) + 1;
      s.choicesTaken++;
      if (card.type === 'synergy') {
        const link = DATA.synergies.find(item => item.id === card.link);
        s.axes.setsuka[link.setsuka]++;
        s.axes.chikage[link.chikage]++;
        s.links[card.link] = (s.links[card.link] || 0) + 1;
      } else {
        s.axes[card.type][card.axis]++;
      }
      this.log(`${card.name} Lv${s.cards[id]} を取得。`, card.type === 'synergy' ? 'link' : card.type);
      for (const link of DATA.synergies) {
        if (this.isActive(link.id) && !s.activeLinks.includes(link.id)) {
          s.activeLinks.push(link.id);
          this.log(`連携発動：《${link.name}》`, 'link');
          this.onEvent({ type: 'synergy', link });
        }
      }
      s.choices = [];
      this.updateResearch();
      if (s.pendingAdvance) this.enterCase(s.index + 1);
      else s.status = 'running';
      return true;
    }

    isActive(id) {
      const link = DATA.synergies.find(item => item.id === id);
      return Boolean(link && this.state.axes.setsuka[link.setsuka] >= 2 && this.state.axes.chikage[link.chikage] >= 2);
    }

    modifiers() {
      const mods = {};
      for (const card of DATA.upgrades) {
        const rank = this.state.cards[card.id] || 0;
        for (const [key, amount] of Object.entries(card.mods || {})) mods[key] = (mods[key] || 0) + amount * rank;
      }
      return mods;
    }

    stats() {
      const s = this.state;
      const m = this.modifiers();
      const c = s.current || s.queue[0];
      const a = s.axes;
      const analysisRatio = clamp(s.analysis / c.depth, 0, 1);
      const risk = s.danger / 100;
      const threshold = Math.max(0.25, 0.55 - s.research * 0.03);
      const weak = analysisRatio >= threshold;
      const stats = {
        attack: 1.55 * (1 + (m.attack || 0) + a.setsuka.destroy * 0.025)
          * (1 + (m.support || 0) * (1 + a.chikage.support * 0.035))
          * (1 + ((m.riskAttack || 0) + a.setsuka.rage * 0.08) * risk),
        analysis: 1.20 * (1 + (m.analysis || 0) + a.chikage.analyze * 0.035),
        danger: c.threat + (m.danger || 0) - (m.control || 0) - a.chikage.support * 0.012 - analysisRatio * 0.16 - s.research * 0.025,
        artifacts: 1 + (m.artifacts || 0) + a.setsuka.collect * 0.045,
        data: 1 + (m.data || 0) + a.chikage.analyze * 0.04,
        rare: 0.015 + (m.rare || 0) + a.chikage.explore * 0.017,
        special: 0.025 + (m.special || 0) + a.chikage.explore * 0.015,
        rareYield: 1 + (m.rareYield || 0),
        captureThreshold: Math.max(0.30, 0.72 - (m.capture || 0)),
        shield: clamp(m.shield || 0, 0, 0.80), burst: m.burst || 0, overkill: m.overkill || 0,
        weak, threshold, analysisRatio
      };
      for (const link of DATA.synergies) {
        if (!this.isActive(link.id)) continue;
        const power = 1 + (s.links[link.id] || 0) * 0.20;
        switch (link.id) {
          case 'dissection': stats.data *= 1 + 0.40 * power; stats.artifacts += 0.10 * power; stats.captureThreshold -= 0.10 * power; break;
          case 'unshackle': stats.attack *= 1 + risk * 0.75 * power; stats.danger -= 0.10 * power * (0.4 + risk); break;
          case 'sweep': stats.attack *= 1 + 0.12 * power; stats.sweep = 0.24 * power; break;
          case 'fracture': if (weak) stats.attack *= 1 + 0.25 * power; stats.analysis *= 1 + 0.08 * power; break;
          case 'silent': stats.attack *= 1 + 0.13 * power; stats.danger -= 0.09 * power; break;
          case 'seal': stats.captureThreshold -= 0.12 * power; stats.danger -= 0.10 * power; stats.artifacts *= 1 + 0.12 * power; break;
          case 'catalog': stats.rare += 0.12 * power; stats.rareYield *= 1 + 0.45 * power; break;
          case 'predict': stats.analysis *= 1 + 0.30 * power * risk; stats.danger -= 0.12 * power * analysisRatio; stats.data += 0.10 * power; break;
          case 'forbidden': stats.rare += 0.16 * power * risk; stats.special += 0.20 * power; stats.danger += 0.06 * power; break;
        }
      }
      if (weak) stats.attack *= 1.12 + (m.weakpoint || 0);
      if (c.kind === 'mimic' && !weak) stats.attack *= 0.64;
      if (c.kind === 'space') { stats.attack *= 0.88; stats.rare += a.chikage.explore * 0.015; }
      if (c.kind === 'swarm') stats.attack *= 1 + (m.swarm || 0) + (m.overkill || 0) * 0.15;
      if (c.boss) stats.attack *= 0.85;
      stats.capturable = a.setsuka.collect >= 2 && analysisRatio >= Math.max(0.15, stats.captureThreshold);
      if (stats.capturable) stats.attack *= 1.10;
      stats.rare = clamp(stats.rare, 0, 0.80);
      stats.special = clamp(stats.special, 0, 0.85);
      stats.captureThreshold = Math.max(0.15, stats.captureThreshold);
      if (analysisRatio >= 1) stats.danger -= 0.10;
      stats.danger = Math.max(-0.40, stats.danger);
      return stats;
    }

    updateResearch() {
      const s = this.state;
      const researchValue = s.data * (1 + (this.modifiers().research || 0));
      const tier = DATA.researchThresholds.filter(threshold => researchValue >= threshold).length;
      if (tier > s.research) {
        s.research = tier;
        this.log(`研究 ${tier}：弱点看破が早まり、危険制御が向上。`, 'chikage');
      }
    }

    step(delta) {
      if (this.state.status !== 'running' || !Number.isFinite(delta) || delta <= 0) return;
      // Substeps keep events/choices consistent even when a caller supplies a long delta.
      let remaining = delta;
      while (remaining > 0 && this.state.status === 'running') {
        const dt = Math.min(0.25, remaining);
        this.tick(dt);
        remaining -= dt;
      }
    }

    tick(dt) {
      const s = this.state;
      const c = s.current;
      const stats = this.stats();
      s.elapsed += dt;
      s.caseTime += dt;
      s.process += stats.attack * dt;
      s.analysis = Math.min(c.depth, s.analysis + stats.analysis * dt);
      s.danger = clamp(s.danger + stats.danger * dt, 0, 100);
      if (stats.weak && !s.weakpointFound) {
        s.weakpointFound = true;
        this.log('チカゲ：弱点、見えた。……そこを壊して。', 'chikage');
      }
      if (s.analysis >= c.depth && !s.fullyAnalyzed) {
        s.fullyAnalyzed = true;
        this.log('解析完了。DATA価値を最大化、危険上昇を抑制。', 'chikage');
      }
      if (s.caseTime >= s.nextBurst) {
        s.nextBurst += 12;
        if (stats.burst > 0 && s.danger >= 40) {
          s.process += stats.attack * 3 * stats.burst;
          this.log('セツカ：もっと壊せる！《破局の斧》追撃。', 'setsuka');
          this.onEvent({ type: 'hit' });
        }
      }
      if (s.caseTime >= s.nextEvent) {
        s.nextEvent += 24;
        this.caseEvent(stats);
      }
      if (s.caseTime >= s.nextAction) {
        s.nextAction += 8;
        const actor = Math.floor(s.nextAction / 8) % 2 ? 'setsuka' : 'chikage';
        const text = actor === 'setsuka'
          ? (this.dominant('setsuka').key === 'collect' ? 'セツカ：壊さず引き寄せる。標本を確保中。' : s.danger >= 60 ? 'セツカ：いいね、このくらい危なくなくちゃ！' : 'セツカ：邪魔。まとめて叩き割る。')
          : (this.dominant('chikage').key === 'explore' ? 'チカゲ：……別の気配。外縁を調べてる。' : this.dominant('chikage').key === 'support' ? 'チカゲ：出力を調整。まだ、無茶していい。' : 'チカゲ：パターン照合中。もう少しで読める。');
        this.log(text, actor);
      }
      if (s.danger >= 100) {
        this.finish(false, `CASE ${String(s.index + 1).padStart(2, '0')}「${c.name}」で危険度が100%に到達。ふたりは緊急撤退。`);
        return;
      }
      if (!s.midOffered && s.process >= c.hp * 0.50) {
        s.midOffered = true;
        this.offerChoice(s.index === 0 ? 'partner' : 'mid');
        return;
      }
      if (s.process >= c.hp) this.completeCase();
    }

    caseEvent(stats) {
      const s = this.state;
      const kind = s.current.kind;
      let danger = 2;
      if (kind === 'mimic') danger = stats.weak ? 1 : 5;
      if (kind === 'echo') { danger = 4; s.analysis = Math.min(s.current.depth, s.analysis + 5); }
      if (kind === 'swarm') { danger = 3; s.process += stats.attack * 2; this.onEvent({ type: 'hit' }); }
      if (kind === 'body') { s.data += 2; this.updateResearch(); }
      if (kind === 'space') danger = 3;
      s.danger = clamp(s.danger + danger * (1 - stats.shield), 0, 100);
      this.log(DATA.kinds[kind].event);
      if (this.random() < stats.rare * 0.55) this.collectRare(stats);
    }

    collectRare(stats) {
      const s = this.state;
      const amount = Math.round((8 + s.index) * stats.rareYield);
      s.rare++;
      s.artifacts += amount;
      this.log(`希少異物を発見。異物 +${amount}〈残響標本〉`, 'link');
    }

    completeCase() {
      const s = this.state;
      const c = s.current;
      const stats = this.stats();
      const captured = stats.capturable;
      const fast = s.caseTime < c.hp / 1.55 * 0.77;
      const artifacts = Math.round(c.artifacts * stats.artifacts * (captured ? 1.30 : 1) * (c.special ? 1.40 : 1) * (fast ? 1 + stats.overkill : 1));
      const data = Math.round(c.data * (0.15 + 0.85 * stats.analysisRatio) * stats.data * (captured ? 1.20 : 1) * (c.special ? 1.35 : 1));
      s.artifacts += artifacts;
      s.data += data;
      if (this.random() < stats.rare) this.collectRare(stats);
      s.records.push({ id: c.id, name: c.name, time: s.caseTime, artifacts, data, analysis: stats.analysisRatio, danger: s.danger, captured, fast, special: c.special });
      this.log(`${captured ? '捕獲成功' : 'CASE処理完了'}：異物 +${artifacts} / DATA +${data}${fast ? '〈高速処理〉' : ''}`, 'link');
      this.updateResearch();
      if (c.boss) {
        this.finish(true, '最終CASEを処理。ふたりの夜勤は、ここで終わる。');
      } else {
        s.specialNext = this.random() < clamp(stats.special + (fast ? stats.sweep || 0 : 0), 0, 0.90);
        s.pendingAdvance = true;
        this.offerChoice('clear');
      }
    }

    finish(won, reason) {
      const s = this.state;
      s.status = 'result';
      s.won = won;
      s.reason = reason;
      this.log(won ? '夜間対応終了。全CASEの封鎖を確認。' : '危険域を超過。緊急撤退プロトコルを実行。');
      this.onEvent({ type: 'result', won });
    }

    dominant(actor) {
      const ranked = Object.entries(this.state.axes[actor]).sort((a, b) => b[1] - a[1]);
      const first = ranked[0];
      const second = ranked[1];
      return {
        key: first[1] ? first[0] : '', level: first[1],
        label: first[1] === 0 ? '未特化' : first[1] === second[1]
          ? `${DATA.axes[actor][first[0]]}×${DATA.axes[actor][second[0]]}` : `${DATA.axes[actor][first[0]]}型`
      };
    }
  }

  root.Nightshift = { GameCore, data: DATA };
  if (typeof module !== 'undefined' && module.exports) module.exports = { GameCore, data: DATA };
  if (typeof document === 'undefined') return;

  const byId = id => document.getElementById(id);
  const escapeHTML = value => String(value).replace(/[&<>"']/g, char => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[char]));
  const session = { runs: [], seen: new Set() };
  const ui = { panel: null, backPanel: null, paused: false, speed: 1, archiveTab: 'cases', lastFrame: 0, renderClock: 0, renderKey: '', resultRecorded: false };
  const dialog = byId('game-dialog');
  const game = new GameCore({ onEvent: event => {
    if (event.type === 'case') session.seen.add(event.current.id);
    if (event.type === 'hit') {
      byId('game-shell').classList.remove('hit');
      requestAnimationFrame(() => byId('game-shell').classList.add('hit'));
    }
    // Panel transitions happen after the simulation/selection finishes.
  } });
  root.Nightshift.game = game;

  const panelHeader = (eyebrow, title, close = true) => `<header class="modal-header"><div><p class="modal-eyebrow">${eyebrow}</p><h2 id="dialog-title" tabindex="-1">${title}</h2></div>${close ? '<button class="close-button" data-action="close" aria-label="画面を閉じる">×</button>' : ''}</header>`;

  function linkCard(link, catalog = false) {
    const s = game.state;
    const active = game.isActive(link.id);
    const rank = s.links[link.id] || 0;
    return `<article class="link-card ${active ? 'active' : ''}"><h3>${link.name}<span>${active ? `ACTIVE${rank ? ` / +${rank * 20}%` : ''}` : '未発動'}</span></h3><p class="condition">セツカ ${DATA.axes.setsuka[link.setsuka]} ${s.axes.setsuka[link.setsuka]}/2 × チカゲ ${DATA.axes.chikage[link.chikage]} ${s.axes.chikage[link.chikage]}/2</p><p>${link.effect}</p>${catalog ? `<p>${link.flavor}</p>` : ''}</article>`;
  }

  function choicesHTML() {
    const s = game.state;
    const initial = s.choiceKind === 'initial';
    const partner = s.choiceKind === 'partner';
    const title = initial ? 'セツカの育成方針' : partner ? 'チカゲの育成方針' : '次は、どう育てる？';
    const intro = initial ? '斧を振るう理由を選ぶ。最初の強化が、今回のセツカを変える。' : partner ? '後方から、何を届ける？ チカゲの選択がふたりの回り方を変える。' : s.choiceKind === 'clear' ? 'CASE処理完了。次の現場へ向かう前に、ひとつ強化を選ぶ。' : '処理進行50%。現場の観測を、ひとつの強化へ変換する。';
    return `${panelHeader(`UPGRADE / ${String(s.choicesTaken + 1).padStart(2, '0')} · 進行停止中`, title, false)}<div class="modal-body"><p class="modal-intro">${intro}</p>${s.choices.map(id => {
      const card = DATA.upgrades.find(item => item.id === id);
      const rank = s.cards[id] || 0;
      const link = card.link && DATA.synergies.find(item => item.id === card.link);
      const category = card.type === 'setsuka' ? `セツカ / ${DATA.axes.setsuka[card.axis]}` : card.type === 'chikage' ? `チカゲ / ${DATA.axes.chikage[card.axis]}` : 'ふたり / SYNERGY';
      return `<button class="choice-card ${card.type}" data-action="choose" data-id="${id}"><span class="choice-top"><span>${category}</span><span class="mono">Lv ${rank} → ${rank + 1} / ${card.max}</span></span><h3>${card.name}</h3><p>${card.desc}</p><span class="choice-impact">${card.impact}</span>${link ? `<span class="choice-condition">発動条件：${DATA.axes.setsuka[link.setsuka]} ${s.axes.setsuka[link.setsuka]}/2 × ${DATA.axes.chikage[link.chikage]} ${s.axes.chikage[link.chikage]}/2 · 連携強度+20% / 取得</span>` : ''}</button>`;
    }).join('')}<p class="modal-footnote">選んだ強化はラン中ずっと有効。同じ強化は最大Lv3。<br>ふたりの傾向が各Lv2でシナジーが自動発動。連携強化は両方の傾向を育てる。</p></div>`;
  }

  function buildHTML() {
    const s = game.state;
    const stats = game.stats();
    const m = game.modifiers();
    const cards = DATA.upgrades.filter(card => s.cards[card.id]);
    const active = DATA.synergies.filter(link => game.isActive(link.id));
    const relevant = DATA.synergies.filter(link => !game.isActive(link.id) && s.axes.setsuka[link.setsuka] + s.axes.chikage[link.chikage] > 0);
    return `${panelHeader('BUILD / ふたりの現在地', '今回のふたり')}<div class="modal-body"><p class="modal-intro">強化は重ねられる。組み合わせは、処理・回収・危険のバランスを変える。</p>${['setsuka', 'chikage'].map(actor => {
      const highest = Math.max(6, ...Object.values(s.axes[actor]));
      return `<section class="build-character ${actor}"><h3>${actor === 'setsuka' ? 'セツカ' : 'チカゲ'}<span>${game.dominant(actor).label}</span></h3>${Object.entries(DATA.axes[actor]).map(([key, label]) => `<div class="axis-row"><span>${label}</span><div class="axis-track"><span class="axis-fill" style="width:${s.axes[actor][key] / highest * 100}%"></span></div><span class="mono">Lv${s.axes[actor][key]}</span></div>`).join('')}</section>`;
    }).join('')}<div class="build-stats"><div><span>現在の処理 / 秒</span><strong>${stats.attack.toFixed(2)}</strong></div><div><span>解析 / 秒</span><strong>${stats.analysis.toFixed(2)}</strong></div><div><span>危険変化 / 秒</span><strong>${stats.danger > 0 ? '+' : ''}${stats.danger.toFixed(2)}</strong></div><div><span>希少発見率</span><strong>${Math.round(stats.rare * 100)}%</strong></div><div><span>異物 基礎倍率</span><strong>×${stats.artifacts.toFixed(2)}</strong></div><div><span>DATA 基礎倍率</span><strong>×${stats.data.toFixed(2)}</strong></div></div><p class="modal-footnote">現在のCASE・危険度・解析率を反映。捕獲には回収Lv2以上と解析${Math.ceil(stats.captureThreshold * 100)}%以上が必要。${m.burst ? '破局の斧は危険40%以上で追撃。' : ''}</p><h3 class="modal-section-title">発動中シナジー / ${active.length}</h3>${active.length ? active.map(link => linkCard(link)).join('') : '<p class="empty-note">まだ連携は発動していない。<br>セツカとチカゲ、両方の傾向をLv2に育てよう。</p>'}${relevant.length ? `<h3 class="modal-section-title">あと少しでつながる</h3>${relevant.slice(0, 3).map(link => linkCard(link)).join('')}` : ''}<h3 class="modal-section-title">取得した効果 / ${s.choicesTaken} 回</h3>${cards.length ? cards.map(card => `<article class="effect-row"><span class="rank">Lv${s.cards[card.id]}</span><strong>${card.name}</strong><p>${card.impact}${card.type === 'synergy' ? ' / 各Lv2で効果が発動' : ' / 1Lvあたり'}</p></article>`).join('') : '<p class="empty-note">最初の3択から、今回のビルドが始まる。</p>'}</div>`;
  }

  function archiveHTML() {
    const casesTab = ui.archiveTab === 'cases';
    return `${panelHeader('ARCHIVE / 調査記録', '知ったこと、まだ知らないこと')}<div class="modal-body"><div class="tabs" role="tablist" aria-label="記録の種類"><button role="tab" data-action="archive-tab" data-tab="cases" aria-selected="${casesTab}">CASE ${session.seen.size}/10</button><button role="tab" data-action="archive-tab" data-tab="links" aria-selected="${!casesTab}">連携図鑑 9</button></div>${casesTab ? `<p class="modal-intro">出会ったCASEを記録。同じタブでの再挑戦中は記録が残る。<br>再読み込みで記録もリセットされる。</p>${DATA.cases.map(c => {
      const seen = session.seen.has(c.id);
      const record = game.state.records.find(item => item.id === c.id);
      return `<article class="archive-case ${seen ? '' : 'locked'}"><h3>${seen ? c.name : c.boss ? '最終CASE / 未確認' : '未確認のCASE'}<span>${record ? '処理済' : seen ? '観測済' : 'LOCKED'}</span></h3>${seen ? `<p class="mono">${c.location} / ${DATA.kinds[c.kind].name}</p><p>${c.note}</p><p>${DATA.kinds[c.kind].hint}</p>${record ? `<p>今回：${formatTime(record.time)} / 異物 ${record.artifacts} / DATA ${record.data}${record.captured ? ' / 捕獲' : ''}${record.special ? ' / 異相' : ''}</p>` : ''}` : '<p>現場で遭遇すると、記録が開示される。</p>'}</article>`;
    }).join('')}` : `<p class="modal-intro">両方の傾向がLv2になると自動発動。連携強化を取ると、基礎効果を1Lvにつき20%増幅する。条件の異なる連携を同時に発動することもできる。</p>${DATA.synergies.map(link => linkCard(link, true)).join('')}`}</div>`;
  }

  function resultHTML() {
    const s = game.state;
    const active = DATA.synergies.filter(link => game.isActive(link.id));
    const recommendation = DATA.synergies.find(link => !game.isActive(link.id)) || DATA.synergies[0];
    const previous = session.runs.length > 1 ? session.runs.at(-2) : null;
    return `${panelHeader(`RESULT / RUN ${String(session.runs.length).padStart(2, '0')}`, '今回の夜勤報告', false)}<div class="modal-body"><div class="result-mark ${s.won ? '' : 'failed'}"><span>${s.won ? 'ALL CASES RESOLVED' : 'EMERGENCY WITHDRAWAL'}</span><h3>${s.won ? 'NIGHT CLEAR.' : 'WITHDRAW.'}</h3><p>${s.reason}</p></div><div class="result-duo"><div><span>セツカ</span><strong>${game.dominant('setsuka').label}</strong></div><div><span>チカゲ</span><strong>${game.dominant('chikage').label}</strong></div></div><div class="result-grid"><div>処理したCASE<strong>${s.records.length}<small> / 10</small></strong></div><div>稼働時間<strong>${formatTime(s.elapsed)}</strong></div><div>回収異物<strong>${s.artifacts}</strong></div><div>獲得DATA<strong>${s.data}</strong></div><div>希少異物発見<strong>${s.rare}<small> 回</small></strong></div><div>特殊CASE処理<strong>${s.records.filter(record => record.special).length}<small> 件</small></strong></div></div><h3 class="modal-section-title">今回の主な連携</h3>${active.length ? active.map(link => linkCard(link)).join('') : '<p class="empty-note">単独特化の夜だった。次はふたりの傾向を各Lv2にして、連携を試そう。</p>'}${previous ? `<p class="modal-footnote">前回：${previous.setsuka} × ${previous.chikage}<br>CASE ${previous.cases}/10 · 異物 ${previous.artifacts} · DATA ${previous.data} · ${formatTime(previous.time)}</p>` : ''}<div class="retry-note"><strong>次の夜は、《${recommendation.name}》を。</strong>セツカの${DATA.axes.setsuka[recommendation.setsuka]} × チカゲの${DATA.axes.chikage[recommendation.chikage]}。<br>${recommendation.flavor}</div><div class="result-actions"><button class="text-button" data-action="result-build">BUILDを見る</button><button class="primary-button" data-action="retry">別のビルドで再挑戦 <span aria-hidden="true">↗</span></button></div><p class="modal-footnote">再挑戦は育成・資源をリセット。CASEの順序と強化候補は毎回変わる。</p></div>`;
  }

  function helpHTML() {
    return `${panelHeader('FIELD GUIDE / 遊び方', '壊す。知る。組み合わせる。')}<div class="modal-body"><p class="modal-intro">セツカとチカゲは自動で行動する。あなたの仕事は、ふたりの育て方を決めること。</p><div class="guide-step"><span>01</span><div><h3>CASEを処理する</h3><p>処理100%で解決。解析は弱点看破とDATA回収に効く。解析100%は解決の必須条件ではない。</p></div></div><div class="guide-step"><span>02</span><div><h3>3択からひとつ選ぶ</h3><p>各CASEの処理50%時と、通常CASEの解決後に強化を選ぶ。セツカは殲滅・回収・暴走、チカゲは解析・支援・探索。同じ強化は最大Lv3。</p></div></div><div class="guide-step"><span>03</span><div><h3>ふたりの傾向をつなぐ</h3><p>両方の傾向がLv2でシナジー発動。連携カードはふたりの傾向を各Lv1育て、対応するシナジーを20%ずつ増幅。BUILDであと何Lvか確認できる。</p></div></div><div class="guide-step"><span>04</span><div><h3>10件目のボスへ</h3><p>通常CASE9件とボス1件。危険100%で撤退。次のCASEでは危険が55%に下がり、6pt加算される。ボス撃破でクリア。結果を見て、別の組み合わせへ。</p></div></div><p class="guide-warning">DATAの研究評価が60 / 150 / 300に届くと、弱点を早く看破でき、危険も抑えやすくなる。希少異物は追加資源、特殊CASE〈異相〉は難度と報酬が上がる。<br><br>初期速度1×で約10–20分が目安。右上の1× / 2×で変更可能。強化・BUILD・ARCHIVE・このガイド表示中、タブが非表示の間、一時停止中は進行しない。保存・オフライン進行・通信はない。</p></div>`;
  }

  function showPanel(panel, back = null) {
    ui.panel = panel;
    ui.backPanel = back;
    const markup = panel === 'choice' ? choicesHTML() : panel === 'build' ? buildHTML() : panel === 'archive' ? archiveHTML() : panel === 'result' ? resultHTML() : helpHTML();
    byId('dialog-content').innerHTML = markup;
    if (!dialog.open) dialog.showModal();
    byId('dialog-title').focus({ preventScroll: true });
    dialog.scrollTop = 0;
    render();
  }

  function closePanel() {
    if (ui.panel === 'choice' || ui.panel === 'result') return;
    const back = ui.backPanel;
    if (back) { showPanel(back); return; }
    ui.panel = null;
    ui.backPanel = null;
    dialog.close();
    ui.lastFrame = 0;
    syncPanels();
    render();
  }

  function recordResult() {
    if (ui.resultRecorded) return;
    const s = game.state;
    session.runs.push({ setsuka: game.dominant('setsuka').label, chikage: game.dominant('chikage').label, cases: s.records.length, artifacts: s.artifacts, data: s.data, time: s.elapsed });
    if (session.runs.length > 10) session.runs.shift();
    ui.resultRecorded = true;
  }

  function syncPanels() {
    if (game.state.status === 'choice' && ui.panel !== 'choice') showPanel('choice');
    if (game.state.status === 'result' && ui.panel !== 'result' && ui.backPanel !== 'result') { recordResult(); showPanel('result'); }
  }

  function render() {
    const s = game.state;
    const c = s.current || s.queue[0];
    const running = s.status === 'running' && !ui.paused && !ui.panel && !document.hidden;
    const process = clamp(s.process / c.hp * 100, 0, 100);
    const analysis = clamp(s.analysis / c.depth * 100, 0, 100);
    const key = `${s.index}-${s.status}-${c.special}-${s.research}-${s.choicesTaken}`;
    const stats = game.stats();
    if (key !== ui.renderKey) {
      byId('case-number').innerHTML = `${String(s.index + 1).padStart(2, '0')}<span>/10</span>`;
      byId('case-label').textContent = `${c.boss ? 'FINAL CASE' : 'CASE FILE'} / ${String(s.index + 1).padStart(3, '0')}`;
      byId('case-name').textContent = c.name;
      byId('case-location').textContent = c.location;
      byId('case-kind').textContent = c.boss ? 'BOSS / 擬態' : c.special ? `異相 / ${DATA.kinds[c.kind].name}` : DATA.kinds[c.kind].name;
      byId('case-kind').className = `case-kind${c.boss ? ' boss' : c.special ? ' special' : ''}`;
      byId('research-tag').textContent = `研究 ${s.research}`;
      byId('anomaly').dataset.kind = c.kind;
      byId('anomaly-mark').textContent = DATA.kinds[c.kind].mark;
      byId('setsuka-type').textContent = game.dominant('setsuka').label;
      byId('chikage-type').textContent = game.dominant('chikage').label;
      const active = DATA.synergies.filter(link => game.isActive(link.id));
      byId('synergy-strip').classList.toggle('active', active.length > 0);
      byId('synergy-strip').innerHTML = `<span class="link-symbol" aria-hidden="true">⌁</span><span>${active.length ? active.map(link => link.name).join(' / ') : 'ふたりの組み合わせが、夜を変える。'}</span>`;
      ui.renderKey = key;
    }
    byId('artifact-count').textContent = s.artifacts;
    byId('data-count').textContent = s.data;
    byId('run-time').textContent = formatTime(s.elapsed);
    byId('run-status').textContent = s.status === 'intro' ? '待機' : s.status === 'result' ? (s.won ? '完了' : '撤退') : running ? '処理中' : '停止中';
    for (const [name, value] of [['process', process], ['analysis', analysis], ['danger', s.danger]]) {
      byId(`${name}-bar`).value = value;
      byId(`${name}-value`).textContent = `${Math.floor(value)}%`;
    }
    byId('danger-bar').closest('.gauge').classList.toggle('critical', s.danger >= 75);
    byId('process-label').textContent = game.dominant('setsuka').key === 'collect' ? '捕獲処理' : '処理';
    const setsukaStatus = game.dominant('setsuka').key === 'collect' ? (stats.capturable ? '標本確保' : '捕獲準備') : game.dominant('setsuka').key === 'rage' && s.danger >= 40 ? '全開駆動' : '前衛処理';
    const chikageStatus = analysis >= 100 ? (game.dominant('chikage').key === 'explore' ? '残響探索' : '後方支援') : game.dominant('chikage').key === 'support' ? '出力制御' : game.dominant('chikage').key === 'explore' ? '外縁探索' : '弱点解析';
    byId('setsuka-state').textContent = s.status === 'intro' ? '待機中' : s.status === 'result' ? '任務終了' : !running ? '待機中' : setsukaStatus;
    byId('chikage-state').textContent = s.status === 'intro' ? '待機中' : s.status === 'result' ? '記録整理' : !running ? '待機中' : chikageStatus;
    byId('case-hint').textContent = s.danger >= 75 ? '危険域。100%で緊急撤退。支援・解析・連携による制御が重要。' : `${DATA.kinds[c.kind].hint}${stats.weak ? ' 弱点看破済：処理火力が上昇。' : ''}`;
    byId('log-indicator').textContent = s.status === 'intro' ? 'STANDBY' : running ? '● LIVE' : 'PAUSED';
    const logMarkup = s.logs.slice(0, 3).map(log => `<li><time class="mono">${formatTime(log.time)}</time><span class="${log.type ? `log-${log.type}` : ''}">${escapeHTML(log.text)}</span></li>`).join('');
    if (byId('action-log').innerHTML !== logMarkup) byId('action-log').innerHTML = logMarkup;
    byId('main-button').disabled = s.status === 'choice';
    byId('main-button').innerHTML = s.status === 'intro' ? '夜勤を開始する <span aria-hidden="true">↗</span>' : s.status === 'result' ? 'リザルトを見る <span aria-hidden="true">↗</span>' : s.status === 'choice' ? '強化を選択中 <span aria-hidden="true">…</span>' : ui.paused ? '進行を再開する <span aria-hidden="true">▷</span>' : '一時停止 <span aria-hidden="true">Ⅱ</span>';
    byId('footer-hint').textContent = s.status === 'intro' ? '1ラン 約10–20分 · 自動進行 / 強化は3択' : s.status === 'result' ? '今回の育て方を振り返り、次の組み合わせへ。' : ui.panel ? '画面表示中は進行停止 · 落ち着いて選ぼう' : ui.paused ? '一時停止中 · 再開で自動進行' : `自動進行 ${ui.speed}× · 処理50%とCASE解決後に強化`;
    byId('game-shell').classList.toggle('running', running);
    byId('game-shell').classList.toggle('paused', !running);
    byId('game-shell').classList.toggle('dangerous', s.danger >= 75);
  }

  byId('main-button').addEventListener('click', () => {
    if (game.state.status === 'intro') { game.start(); syncPanels(); }
    else if (game.state.status === 'result') showPanel('result');
    else if (game.state.status === 'running') { ui.paused = !ui.paused; ui.lastFrame = 0; }
    render();
  });
  byId('build-button').addEventListener('click', () => showPanel('build'));
  byId('archive-button').addEventListener('click', () => showPanel('archive'));
  byId('help-button').addEventListener('click', () => showPanel('help'));
  byId('speed-button').addEventListener('click', () => {
    ui.speed = ui.speed === 1 ? 2 : 1;
    byId('speed-button').textContent = `${ui.speed}×`;
    byId('speed-button').setAttribute('aria-label', `進行速度 ${ui.speed}倍`);
    render();
  });
  dialog.addEventListener('cancel', event => { event.preventDefault(); closePanel(); });
  dialog.addEventListener('click', event => {
    const button = event.target.closest('button[data-action]');
    if (!button) return;
    const action = button.dataset.action;
    if (action === 'close') closePanel();
    if (action === 'choose') {
      if (!game.choose(button.dataset.id)) return;
      ui.panel = null;
      ui.backPanel = null;
      dialog.close();
      ui.lastFrame = 0;
      syncPanels();
      render();
    }
    if (action === 'archive-tab') { ui.archiveTab = button.dataset.tab; showPanel('archive'); }
    if (action === 'result-build') showPanel('build', 'result');
    if (action === 'retry') {
      ui.panel = null;
      ui.backPanel = null;
      ui.paused = false;
      ui.lastFrame = 0;
      ui.resultRecorded = false;
      ui.renderKey = '';
      dialog.close();
      game.reset();
      game.start();
      syncPanels();
      render();
    }
  });
  document.addEventListener('visibilitychange', () => { ui.lastFrame = 0; render(); });

  function frame(timestamp) {
    const dt = ui.lastFrame ? Math.min((timestamp - ui.lastFrame) / 1000, 0.25) : 0;
    ui.lastFrame = timestamp;
    if (game.state.status === 'running' && !ui.paused && !ui.panel && !document.hidden) game.step(dt * ui.speed);
    syncPanels();
    ui.renderClock += dt;
    if (ui.renderClock >= 0.15) { render(); ui.renderClock = 0; }
    requestAnimationFrame(frame);
  }
  render();
  requestAnimationFrame(frame);
})(typeof globalThis !== 'undefined' ? globalThis : window);
