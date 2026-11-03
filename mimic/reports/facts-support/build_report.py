from pathlib import Path
import json, csv, statistics as stats
R=Path(__file__).resolve().parent.parent
old=json.loads((R/'early-progression-data.json').read_text())
data=json.loads((R/'facts-progress-data.json').read_text())
control=json.loads((R/'facts-set-control.json').read_text())
assert len(data['trials'])==len(old['trials'])==10
for old_trial,trial in zip(old['trials'],data['trials']):
 assert len(old_trial['runs'])==len(trial['runs'])
 for a,b in zip(old_trial['runs'],trial['runs']):
  assert a=={k:v for k,v in b.items() if not k.startswith('metric_')}
  assert b['metric_inventory_end']==b['metric_inventory_start']+b['items']
  assert sum(b['metric_set_damage'].values())<=b['metric_damage']+0.0001
names={'devour':'捕食','blade':'刃物','hex':'呪術','poison':'毒・腐食','summon':'召喚','defense':'防御','arcane':'魔力'}
enemies={'swordsman':'剣士','shield':'盾兵','archer':'弓手','mage':'魔法使い','priest':'僧侶','thief':'盗賊','fanatic':'狂信者','lancer':'槍騎兵','hero':'勇者','paladin':'聖騎士団長','unknown':'不明'}
lines=[]
def w(s=''):lines.append(s)
def table(header,rows):
 w()
 w('| '+' | '.join(header)+' |');w('| '+' | '.join(['---']*len(header))+' |')
 for row in rows:w('| '+' | '.join(map(str,row))+' |')
 w()
def fmt(x):return f'{x:,.1f}'
def damage(d):return '、'.join(f'{enemies.get(k,k)} {fmt(v)}' for k,v in sorted(d.items())) or 'なし'
def outcome(r):return ('急死' if r['metric_sudden'] else '緩やかな死') if r['metric_dead'] else ('クリア' if r['won'] else '死亡なし')
def bonus(r,f):return f"{fmt(r['metric_set_damage'][f])} / {fmt(r['metric_damage'])} ({r['metric_set_damage'][f]/r['metric_damage']*100:.2f}%)" if r['metric_damage'] else '—'
w('# MIMIC 装備の事実確認と序盤の定量計測')
w('実施：2026-11-03 ／ 対象：ソース `9718529` ／ ゲーム本体と仕様数値は変更していません。')
w('\n## 1. 装備の処分と所持数')
w('売却・解体・破棄など、**所持装備を減らす手段はありません**。「装備を外す」は枠から取り外すだけで所持品に残り、資源も得られません。ドロップした装備は所持配列へ追加されます。')
w('所持数にゲーム側の明示的な上限はありません。装備画面では選択した枠に対応する候補全件をスクロール表示し、鍛冶画面では全装備をスクロール表示します。ページ分割や仮想表示はなく、開くたび各候補のボタンを作ります。上限なしは無制限の動作を保証するものではなく、大量所持時の端末負荷や容量限界は未測定です。')
w('セーブ時は所持品を含むデータ全体をJSON化して保存し直します。装備が増えるほど保存対象も増えます。保存ファイルを開けなければ失敗を返しますが、呼び出し側は結果を画面に表示しません。容量不足が起きる所持数や保存時間は測っていません。')
w('下の表は前回の10試行の全ランです。開始・終了には装備中の品も含みます。初期1個からドロップ数を累積した値と、今回の直接記録は全64ランで一致しました。第2層は60ゲーム秒時点で打ち切った途中経過です。')
rows=[]
for t in data['trials']:
 for r in t['runs']:
  rows.append([t['trial'],r['run'],'第2層・途中' if r['partial'] else '第1層',r['metric_inventory_start'],r['items'],r['metric_inventory_end']])
table(['試行','ラン','範囲','開始時','獲得数','終了時'],rows)
w('## 2. 計測の方法と限界')
w('前回と同じ10個の乱数シード、新規セーブ、最寄りの敵集団へ照準を向ける方策、ボム、装備選択・購入順を使用しました。ゲーム本体のコピーに計測だけを加え、前回の全64ランについて追加項目以外の記録が完全一致したことを確認しました。第一層クリア後の第二層は60ゲーム秒までです。')
w('時間には2種類あります。「到達秒」はゲーム内時間で、ヒットストップ中は進みません。「実時間換算」は固定ステップ数×1/60秒で、ヒットストップを含むシミュレーション時間です。DPSは実時間換算で割ります。死亡前の窓とHP推移も実時間換算です。端末の処理速度やFPSの実測ではありません。')
w('総与ダメージは敵の残HPを実際に減らした量の合計です。過剰ダメージを除外し、回復後の再ダメージは含みます。被ダメージは軽減後に実際に失ったHPで、致死分の超過は除外し、回復との相殺はしません。急死は死亡直前3秒のHPの最大値が最大HPの50%以上の場合と定義しました。0HPまでの低下がその時間内に発生した判定です。')
w('## A. ラン1〜3：死亡直前15秒の被ダメージ')
w('敵ごとの値はHPの実減少量です。クリアしたランは死亡していないため判定対象外です。')
rows=[]
for t in data['trials']:
 for r in t['runs'][:3]:
  rows.append([t['trial'],r['run'],outcome(r),damage(r['metric_incoming_last15']) if r['metric_dead'] else '—',fmt(r['metric_peak3']) if r['metric_dead'] else '—',fmt(r['max_hp'])])
table(['試行','ラン','判定','死亡前15秒の敵別被ダメージ','死亡前3秒の最大HP','最大HP'],rows)
w('### ラン1：死亡前30秒のHP（5秒刻み）')
w('各列は死亡時点からの秒数です。回復によってHPが増える可能性があるため、前表の被ダメージの合計とHP差は一致しない場合があります。')
rows=[]
for t in data['trials']:
 r=t['runs'][0];rows.append([t['trial']]+[fmt(x['hp']) for x in r['metric_last30']])
table(['試行','−30秒','−25秒','−20秒','−15秒','−10秒','−5秒','死亡時'],rows)
w('## B. 成長：全ランの生存・撃破・与ダメージ')
w('第1層では死亡またはクリアまで、第2層では60ゲーム秒の途中打ち切りまでの値です。DPS＝実HP減少量 ÷ 実時間換算。各ランの購入・装備変更は次ランに反映されます。')
rows=[]
for t in data['trials']:
 for r in t['runs']:
  rows.append([t['trial'],r['run'],'2途中' if r['partial'] else '1',outcome(r),fmt(r['elapsed']),fmt(r['simulated_wall']),r['kills'],fmt(r['metric_damage']),fmt(r['metric_damage']/r['simulated_wall'])])
table(['試行','ラン','層','結果','到達秒','実時間換算秒','撃破','総与ダメ','DPS'],rows)
w('### ラン1 → 2（初回購入を含む変化）')
w('飢えの目覚めは全10試行で購入、飢えた牙は6試行で購入しました。同時にドロップ装備の付け替えや装備強化も行うため、変化を購入した永続強化だけの効果とみなすことはできません。到達秒はゲーム内時間です。')
rows=[]
for t in data['trials']:
 a,b=t['runs'][:2];rows.append([t['trial'],'あり' if 'damage' in a['purchases'] else 'なし',f"{a['elapsed']:.1f} → {b['elapsed']:.1f} ({b['elapsed']-a['elapsed']:+.1f})",f"{a['kills']} → {b['kills']} ({b['kills']-a['kills']:+d})"])
table(['試行','飢えた牙','到達秒','撃破数'],rows)
w('### 第一層クリアまでの到達秒の推移')
w('同じ試行の連続ランです。到達秒は必ずしも毎回増えません。')
rows=[]
for t in data['trials']:
 rr=[r for r in t['runs'] if r['stage']==1];v=[r['elapsed'] for r in rr]
 rows.append([t['trial'],len(rr),' → '.join(f'{x:.1f}' for x in v),' / '.join(f'{b-a:+.1f}' for a,b in zip(v,v[1:]))])
table(['試行','クリアまでのラン数','各ランの到達秒','前ランとの差'],rows)
w('## C. 4個セットの直接ダメージ')
w('ここでの割合は「4個セットによって追加されたと特定できる直接ダメージ ÷ そのランの総与ダメージ」です。2個セットの効果は含めません。既存能力・伝説効果と重複する攻撃は、4個セットに固有と特定できなければ計上しません。呪術は追加された呪印が閾値到達に必要だった際の直接増加分のみを計上します。追加ダメージが生んだ死亡・連鎖・生存時間・その後の攻撃の間接効果は含めないため、セットを外した場合との差を示す因果推定ではありません。防御4個の回復は直接ダメージに含まれません。')
w('### 通常進行の10試行で4個以上を装備したラン')
rows=[]
for t in data['trials']:
 for r in t['runs']:
  for f,n in r['metric_families'].items():
   if n>=4:rows.append([t['trial'],r['run'],'第2層・途中' if r['partial'] else '第1層',names[f],n,bonus(r,f)])
table(['試行','ラン','範囲','系統','個数','直接追加分 / 総与ダメージ'],rows)
w('通常進行の方策は召喚系を解放しないため、召喚4個セットの自然な発動例はありません。次の比較は不足を補う追加実験であり、新規セーブからの進行結果ではありません。')
w('### 補足：各系統4個を事前装備した比較')
w('第一層で、各系統についてコモン装備4個を実験用にあらかじめ装備し、永続強化なし・同じ照準／ボム方策で各10回実行。各系統は対応する同じ乱数シードを使用していますが、攻撃や生存時間によって乱数の消費と戦況は変わります。割合は10ランの合計で重み付けしています。装備や生存時間が異なるため、この割合だけで系統の強弱は決められません。')
rows=[]
for f in ['devour','blade','hex','poison','summon','defense','arcane']:
 rr=[r for r in control['runs'] if r['family']==f];assert len(rr)==10
 num=sum(r['metric_set_damage'][f] for r in rr);den=sum(r['metric_damage'] for r in rr)
 rows.append([names[f],len(rr),fmt(num),fmt(den),f'{num/den*100:.2f}%','眷属の連鎖' if f=='summon' else ('回復効果は対象外' if f=='defense' else '')])
table(['系統','試行数','4個セット直接分','総与ダメージ','割合','注記'],rows)
w('## 3. 計測から言えること・言えないこと')
w('- この方策では、初回10ラン中2件、2ラン目10件中5件、3ラン目の死亡8件中5件が、指定した条件の急死でした。3ラン目の残り2件はクリアです。')
w('- ラン1から2の到達ゲーム時間は平均60.2秒から157.0秒、撃破数は平均45.9体から221.2体へ増えました。ただし購入・装備変更・強化・乱数が同時に変わるため、個々の要素による効果の大きさは分離できません。')
w('- 装備は上の試行で増加し続けました。ただしスマホやブラウザで何個から操作や保存に支障が出るかは、この計測では分かりません。')
w('- 補足実験の直接ダメージ割合は、間接的な効果、操作感、演出の分かりやすさ、プレイヤーが受ける成長実感を表しません。実プレイで別途確認が必要です。')
w('\n## 4. 調整案')
w('今回は数値やゲーム内容を変更していません。自動試行だけでは手触りの良し悪しを決められないため、具体的なバランス数値の変更は提案しません。装備管理については、処分機能や大量所持時の表示・保存性能を検討する余地がありますが、実装はしていません。')
w('\n生データ：[通常進行 JSON](../reports/facts-progress-data.json) ／ [4個セット比較 JSON](../reports/facts-set-control.json) ／ [集計用 CSV](../reports/facts-run-records.csv)。')
(R/'facts-2026-11.md').write_text('\n'.join(lines)+'\n')
with (R/'facts-run-records.csv').open('w',newline='') as f:
 writer=csv.writer(f);writer.writerow(['trial','run','stage','partial','outcome','game_seconds','simulated_wall_seconds','kills','effective_damage','effective_dps','inventory_start','items_acquired','inventory_end','damage_last15_by_enemy','peak_hp_last3','max_hp'])
 for t in data['trials']:
  for r in t['runs']:
   writer.writerow([t['trial'],r['run'],r['stage'],r['partial'],outcome(r),r['elapsed'],r['simulated_wall'],r['kills'],r['metric_damage'],r['metric_damage']/r['simulated_wall'],r['metric_inventory_start'],r['items'],r['metric_inventory_end'],json.dumps(r['metric_incoming_last15'],ensure_ascii=False),r['metric_peak3'] if r['metric_dead'] else '',r['max_hp']])
print('report created; verified 64 previous runs')
