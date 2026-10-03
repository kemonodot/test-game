(function (root) {
  'use strict';

  const axes = {
    setsuka: { destroy: '殲滅', collect: '回収', rage: '暴走' },
    chikage: { analyze: '解析', support: '支援', explore: '探索' }
  };

  const kinds = {
    body: { name: '実体', mark: '◉', hint: '実体を持つ怪異。処理と解析の基本形。', event: '剥がれた表皮から微量のDATAを回収。' },
    mimic: { name: '擬態', mark: '◇', hint: '弱点を看破するまでは処理速度が低下。解析が突破口になる。', event: '偽装が揺らぐ。未解析なら危険度が上昇。' },
    echo: { name: '反響', mark: '≋', hint: '一定間隔で危険な反響が発生。支援による制御が有効。', event: '反響波が増幅。解析が進むが、危険度も上昇。' },
    space: { name: '空間', mark: '∞', hint: '処理速度が少し低下。探索傾向が高いほど希少異物を発見しやすい。', event: '空間の継ぎ目が開く。隠された異物を探査。' },
    swarm: { name: '群体', mark: '⠿', hint: '小さな個体の集合。連鎖粉砕と余剰破壊が特に有効。', event: '群体が分裂。セツカがまとめて薙ぎ払う。' }
  };

  const cases = [
    { id: 'c01', name: '笑わない死体', location: '旧市街 / 地下安置室', kind: 'body', hp: 110, depth: 95, threat: 0.24, artifacts: 12, data: 16, note: '誰もいないはずの安置室から、呼吸の音がする。' },
    { id: 'c02', name: '声だけの同居人', location: '第七区 / 無人アパート', kind: 'echo', hp: 126, depth: 105, threat: 0.26, artifacts: 14, data: 19, note: '返事をするたび、隣の部屋がひとつ増える。' },
    { id: 'c03', name: '逆さまの廊下', location: '廃校 / 北棟三階', kind: 'space', hp: 140, depth: 115, threat: 0.25, artifacts: 15, data: 22, note: '出口の先には、入口が裏返しで待っている。' },
    { id: 'c04', name: '顔のない乗客', location: '終点 / 最終電車', kind: 'mimic', hp: 149, depth: 120, threat: 0.28, artifacts: 16, data: 24, note: '乗客は全員、あなたの名前を知っている。' },
    { id: 'c05', name: '百足のチャイム', location: '封鎖団地 / 共用通路', kind: 'swarm', hp: 168, depth: 128, threat: 0.27, artifacts: 18, data: 27, note: '扉の向こうを、小さな足音が埋め尽くす。' },
    { id: 'c06', name: '眠らない標本', location: '閉鎖病棟 / 検体保管庫', kind: 'body', hp: 181, depth: 135, threat: 0.25, artifacts: 20, data: 29, note: '保存液の中で、昨日のあなたが目を開ける。' },
    { id: 'c07', name: '遅れてくる鏡像', location: '地下街 / 鏡張りの店', kind: 'mimic', hp: 194, depth: 144, threat: 0.29, artifacts: 21, data: 32, note: '鏡の中だけ、一秒早く斧が振り下ろされる。' },
    { id: 'c08', name: '零時の留守電', location: '通信局 / 廃回線', kind: 'echo', hp: 210, depth: 150, threat: 0.28, artifacts: 23, data: 35, note: '留守電には、まだ起きていない事故が記録される。' },
    { id: 'c09', name: '開かずの非常口', location: '境界区 / 消失階段', kind: 'space', hp: 224, depth: 158, threat: 0.27, artifacts: 25, data: 38, note: '非常口の向こうには、この街の外側がある。' },
    { id: 'boss', name: '夜を喰う観測者', location: '最深部 / 観測不能領域', kind: 'mimic', hp: 350, depth: 205, threat: 0.27, artifacts: 65, data: 85, boss: true, note: 'すべての事件の視線が、ひとつの影に収束する。' }
  ];

  const upgrades = [
    { id: 's-cut', type: 'setsuka', axis: 'destroy', name: '断頭の一撃', desc: '迷う前に、叩き壊す。巨大斧の一撃を研ぎ澄ます。', impact: '処理火力 +14%', mods: { attack: 0.14 } },
    { id: 's-overkill', type: 'setsuka', axis: 'destroy', name: '余剰破壊', desc: '壊しすぎた破片も、資源になる。', impact: '処理火力 +8% / 高速処理時の異物 +20% / 群体火力 +3%', mods: { attack: 0.08, overkill: 0.20 } },
    { id: 's-chain', type: 'setsuka', axis: 'destroy', name: '連鎖粉砕', desc: 'ひと振りで、群れごと切り裂く。', impact: '処理火力 +7% / 群体への火力 +25%', mods: { attack: 0.07, swarm: 0.25 } },
    { id: 's-hook', type: 'setsuka', axis: 'collect', name: '捕獲用フック', desc: '生きたまま引き寄せる。壊しすぎないための刃。', impact: '捕獲に必要な解析率 −13pt / 異物 +10% / 火力 −2.5%', mods: { capture: 0.13, artifacts: 0.10, attack: -0.025 } },
    { id: 's-sample', type: 'setsuka', axis: 'collect', name: '無傷の標本', desc: 'きれいな回収が、次の研究を支える。', impact: '異物 +18% / 危険上昇を毎秒 0.015 抑制', mods: { artifacts: 0.18, control: 0.015 } },
    { id: 's-bag', type: 'setsuka', axis: 'collect', name: '磁性ポーチ', desc: '小さな欠片も、取りこぼさない。', impact: '異物 +12% / 希少発見率 +2pt', mods: { artifacts: 0.12, rare: 0.02 } },
    { id: 's-limit', type: 'setsuka', axis: 'rage', name: 'リミッター破棄', desc: '「まだいけるでしょ？」安全域を踏み越える。', impact: '処理火力 +24% / 危険上昇 毎秒 +0.12', mods: { attack: 0.24, danger: 0.12 } },
    { id: 's-heat', type: 'setsuka', axis: 'rage', name: '血熱機関', desc: '危険を燃料に変える。限界に近いほど鋭くなる。', impact: '危険度に比例して火力 最大+35% / 危険上昇 毎秒 +0.075', mods: { riskAttack: 0.35, danger: 0.075 } },
    { id: 's-burst', type: 'setsuka', axis: 'rage', name: '破局の斧', desc: '危険域で、爆発的な追撃を叩き込む。', impact: '危険40%以上で12秒ごとに追撃 / 危険上昇 毎秒 +0.08', mods: { burst: 0.50, danger: 0.08 } },
    { id: 'c-weak', type: 'chikage', axis: 'analyze', name: '弱点看破', desc: '「そこ。……外さないで」揺らぎの中心を特定。', impact: '解析速度 +18% / 弱点看破後の火力 +12pt', mods: { analysis: 0.18, weakpoint: 0.12 } },
    { id: 'c-scan', type: 'chikage', axis: 'analyze', name: '多層スキャン', desc: '表層から核まで、同時に読み解く。', impact: '解析速度 +10% / DATA +18%', mods: { analysis: 0.10, data: 0.18 } },
    { id: 'c-log', type: 'chikage', axis: 'analyze', name: '解剖ログ', desc: '観測を記録に、記録を次の看破へ。', impact: 'DATA +25% / 研究到達に使うDATA評価 +15%', mods: { data: 0.25, research: 0.15 } },
    { id: 'c-cool', type: 'chikage', axis: 'support', name: '冷却プロトコル', desc: '熱くなったセツカを、冷たい声で制御する。', impact: '危険上昇を毎秒 0.09 抑制', mods: { control: 0.09 } },
    { id: 'c-boost', type: 'chikage', axis: 'support', name: '遠隔ブースト', desc: '前衛の動きに、後方から出力を重ねる。', impact: '支援による処理火力 +13%（支援傾向で増幅）', mods: { support: 0.13 } },
    { id: 'c-noise', type: 'chikage', axis: 'support', name: 'ノイズ遮断', desc: '余計な音を消す。ふたりの呼吸だけを残す。', impact: '危険上昇を毎秒 0.04 抑制 / 解析 +6% / 突発危険 −15%', mods: { control: 0.04, analysis: 0.06, shield: 0.15 } },
    { id: 'c-radar', type: 'chikage', axis: 'explore', name: '残響レーダー', desc: '事件の外縁から、希少な気配を拾う。', impact: '希少発見率 +5.5pt', mods: { rare: 0.055 } },
    { id: 'c-key', type: 'chikage', axis: 'explore', name: '裏層への鍵', desc: '通常のCASEの奥に、別の位相を見つける。', impact: '特殊CASE発見率 +12pt / 危険上昇 毎秒 +0.015', mods: { special: 0.12, control: -0.015 } },
    { id: 'c-index', type: 'chikage', axis: 'explore', name: '遺失物索引', desc: '珍しいものほど、回収する価値がある。', impact: '希少異物の収量 +45% / DATA +6%', mods: { rareYield: 0.45, data: 0.06 } },
    { id: 'y-dissection', type: 'synergy', link: 'dissection', name: '生体スキャン', desc: '捕獲した怪異を、ふたりで完全に読み解く。', impact: '回収・解析 各Lv+1 / 《完全解剖》の効果を強化' },
    { id: 'y-unshackle', type: 'synergy', link: 'unshackle', name: '制御限界', desc: '止めるための支援を、解き放つための支援へ。', impact: '暴走・支援 各Lv+1 / 《安全装置解除》の効果を強化' },
    { id: 'y-sweep', type: 'synergy', link: 'sweep', name: '跡地索敵', desc: 'セツカが壊したその先を、チカゲが調べる。', impact: '殲滅・探索 各Lv+1 / 《掃討調査》の効果を強化' },
    { id: 'y-fracture', type: 'synergy', link: 'fracture', name: '照準共有', desc: '解析した急所へ、巨大斧を誘導する。', impact: '殲滅・解析 各Lv+1 / 《弱点破砕》の効果を強化' },
    { id: 'y-silent', type: 'synergy', link: 'silent', name: '呼吸同期', desc: '無駄のない破壊と、無駄のない制御。', impact: '殲滅・支援 各Lv+1 / 《無音の制圧》の効果を強化' },
    { id: 'y-seal', type: 'synergy', link: 'seal', name: '封鎖手順', desc: '逃げ道を塞ぎ、無傷のまま確保する。', impact: '回収・支援 各Lv+1 / 《完全封鎖》の効果を強化' },
    { id: 'y-catalog', type: 'synergy', link: 'catalog', name: '標本タグ', desc: '見つけた異物の価値を、ふたりで引き上げる。', impact: '回収・探索 各Lv+1 / 《標本目録》の効果を強化' },
    { id: 'y-predict', type: 'synergy', link: 'predict', name: '破局シミュレーション', desc: 'セツカの暴走を、チカゲの予測へ接続する。', impact: '暴走・解析 各Lv+1 / 《危険予測》の効果を強化' },
    { id: 'y-forbidden', type: 'synergy', link: 'forbidden', name: '境界越え', desc: 'ふたりなら、立入禁止のその先まで。', impact: '暴走・探索 各Lv+1 / 《禁域踏破》の効果を強化' }
  ].map(upgrade => ({ ...upgrade, max: 3 }));

  const synergies = [
    { id: 'dissection', name: '完全解剖', setsuka: 'collect', chikage: 'analyze', effect: '捕獲しやすくなり、DATA +40%、異物 +10%。', flavor: '壊さずに捕らえ、余さずに知る。' },
    { id: 'unshackle', name: '安全装置解除', setsuka: 'rage', chikage: 'support', effect: '危険度に比例して火力 最大+75%。高危険ほど制御も強まる。', flavor: 'ブレーキがあるから、アクセルを踏める。' },
    { id: 'sweep', name: '掃討調査', setsuka: 'destroy', chikage: 'explore', effect: '火力 +12%。高速処理すると次の特殊CASE発見率 +24pt。', flavor: '壊した跡に、次の事件が見える。' },
    { id: 'fracture', name: '弱点破砕', setsuka: 'destroy', chikage: 'analyze', effect: '看破後の火力 +25%、解析速度 +8%。', flavor: '一番脆い場所へ、一番重い一撃を。' },
    { id: 'silent', name: '無音の制圧', setsuka: 'destroy', chikage: 'support', effect: '火力 +13%。危険上昇を毎秒 0.09 抑制。', flavor: '速く、静かに、終わらせる。' },
    { id: 'seal', name: '完全封鎖', setsuka: 'collect', chikage: 'support', effect: '捕獲しやすくなり、異物 +12%。危険上昇を毎秒 0.10 抑制。', flavor: '逃がさない。壊しすぎない。' },
    { id: 'catalog', name: '標本目録', setsuka: 'collect', chikage: 'explore', effect: '希少発見率 +12pt、希少異物の収量 +45%。', flavor: '見たことのないものを、持ち帰る。' },
    { id: 'predict', name: '危険予測', setsuka: 'rage', chikage: 'analyze', effect: '高危険ほど解析が加速（最大+30%）。解析で危険を抑える。', flavor: '暴走の先を、先に知っておく。' },
    { id: 'forbidden', name: '禁域踏破', setsuka: 'rage', chikage: 'explore', effect: '高危険ほど希少発見率上昇（最大+16pt）。特殊CASE率 +20pt、危険 毎秒+0.06。', flavor: '危険な場所ほど、珍しいものがある。' }
  ];

  const data = { axes, kinds, cases, upgrades, synergies, researchThresholds: [60, 150, 300] };
  root.NIGHTSHIFT_DATA = data;
  if (typeof module !== 'undefined' && module.exports) module.exports = data;
})(typeof globalThis !== 'undefined' ? globalThis : window);
