extends SceneTree
# Reproducible, headless progression trials. Never saves or changes gameplay values.
const Combat=preload("res://src/combat.gd")
const Profile=preload("res://src/profile.gd")
const STEP:=1.0/60.0
const MAX_STEPS:=180000
var output_path:="/tmp/mimic-early-trials.json"
var samples:=10
var max_runs:=50

func _initialize()->void:
 call_deferred("run_all")

func aim_at_closest_group(b) -> void:
 var closest:Dictionary={};var best:=INF
 for e in b.enemies:
  if not e.active:continue
  var distance:float=e.pos.distance_squared_to(Combat.CENTER)
  if distance<best:best=distance;closest=e
 if closest.is_empty():return
 var sum:=Vector2.ZERO;var count:=0
 for e in b.enemies:
  if e.active and e.pos.distance_squared_to(closest.pos)<=10000.0:
   sum+=e.pos;count+=1
 var target:Vector2=(sum/count if count>0 else closest.pos)-Combat.CENTER
 if target.length_squared()>4.0:b.aim=target.normalized()

func use_bomb_if_useful(b) -> void:
 if b.bomb_remaining>0:return
 var center:Vector2=Combat.CENTER+b.aim*160.0
 for e in b.enemies:
  if e.active and e.pos.distance_squared_to(center)<=Combat.BOMB_RADIUS*Combat.BOMB_RADIUS:
   b.use_bomb();return

func item_score(p,item:Dictionary) -> float:
 var t:Dictionary=p.get_template(item.template)
 var power:float=float(t.power)*(1.0+0.12*int(item.level)+0.12*int(item.rarity))
 if t.slot=="shell":return power
 return power/maxf(0.2,float(t.cooldown))

func prepare_equipment(p) -> Array:
 var changed:=[]
 for slot in ["fang","shell","organ1","organ2","organ3","organ4","core"]:
  if slot=="organ4" and not p.data.upgrades.get("organ_slot",false):continue
  var kind:String="organ" if slot.begins_with("organ") else slot
  var current:Dictionary=p.get_item(int(p.data.equipped.get(slot,-1)))
  var score:float=item_score(p,current) if not current.is_empty() else -1.0
  var best:int=int(current.uid) if not current.is_empty() else -1
  for item in p.data.inventory:
   if p.get_template(item.template).slot!=kind:continue
   if item.uid in p.data.equipped.values() and (current.is_empty() or item.uid!=current.uid):continue
   var candidate:float=item_score(p,item)
   if candidate>score+0.001:best=int(item.uid);score=candidate
  if best>=0 and (current.is_empty() or int(current.uid)!=best):
   if p.equip(best,slot):changed.append({"slot":slot,"item":p.get_template(p.get_item(best).template).name})
 return changed

func spend_points(p,run_number:int) -> Array:
 var bought:=[]
 for key in ["awakening","damage","family_hex"]:
  if int(p.data.upgrades.get(key,0))==0:
   if p.upgrade(key):bought.append(key)
   else:return bought
 while true:
  var hp:int=int(p.data.upgrades.get("hp",0));var damage:int=int(p.data.upgrades.get("damage",0))
  if hp>=10 and damage>=10:break
  var key:String="hp" if hp<=damage and hp<10 else "damage"
  if not p.upgrade(key):break
  bought.append(key)
 return bought

func spend_gold(p) -> Array:
 var changes:=[]
 while true:
  var lowest_uid:=-1;var lowest_cost:=2147483647
  for slot in ["fang","shell"]:
   var item:Dictionary=p.get_item(int(p.data.equipped.get(slot,-1)))
   if not item.is_empty():
    var cost:int=25*(int(item.level)+1)
    if cost<lowest_cost:lowest_cost=cost;lowest_uid=int(item.uid)
  if lowest_uid<0 or int(p.data.gold)<lowest_cost:break
  if not p.upgrade_item(lowest_uid):break
  changes.append({"uid":lowest_uid,"level":int(p.get_item(lowest_uid).level),"cost":lowest_cost})
 return changes

func play_one(p,stage:int,seed_value:int,stage_two_limit:float=60.0) -> Dictionary:
 var b=Combat.new(seed_value);b.stage=stage;b.configure(p.equipped_templates(),p.data.upgrades)
 var chance:float=float(p.balance.drop_chance[stage])+float(p.data.upgrades.get("drop",0))*0.02+float(b.stats.drop)
 var starting:int=int(p.data.upgrades.get("starting_gold",0))*10
 p.data.gold+=starting
 var gold_gained:=starting;var gear_gained:=0;var gems_gained:=0;var bombs:=0;var steps:=0
 var stage_two_partial:=false
 while not b.ended and steps<MAX_STEPS:
  if steps%12==0:aim_at_closest_group(b)
  var bombs_before:float=b.bomb_remaining
  use_bomb_if_useful(b)
  if bombs_before<=0 and b.bomb_remaining>0:bombs+=1
  b.update(STEP)
  for event in b.loot_events:
   if not event.active:continue
   event.active=false
   var amount:int=(5+stage*3)*(Combat.BOMB_GOLD_MULTIPLIER if event.get("bomb",false) else 1)
   p.data.gold+=amount;gold_gained+=amount
   if event.boss or b.rng.randf()<float(p.balance.drop_chance[stage])+float(p.data.upgrades.get("drop",0))*0.02+float(b.stats.drop):
    var item:Dictionary=p.drop(stage,event.boss)
    if not item.is_empty():gear_gained+=1;b.scatter(event.position,"arcane",5)
   if b.rng.randf()<0.12:
    p.add_gem(Profile.FAMILIES[b.rng.randi_range(0,6)]);gems_gained+=1
  steps+=1
  if stage==1 and b.elapsed>=stage_two_limit and not b.ended:
   stage_two_partial=true;break
 var points:=0
 if b.ended:
  points=int(b.kills/5)+int(b.elapsed/30)+(20 if b.won else 0)
  p.data.points+=points
  if b.won:p.data.unlocked_stage=maxi(int(p.data.unlocked_stage),mini(1,stage+1))
 return {"stage":stage+1,"elapsed":snappedf(b.elapsed,0.01),"simulated_wall":snappedf(steps*STEP,0.01),"kills":b.kills,"won":b.won,"boss_spawned":b.boss_spawned,"hp":snappedf(b.hp,0.01),"gold_gained":gold_gained,"items":gear_gained,"gems":gems_gained,"points":points,"bombs":bombs,"drop_chance":chance,"max_hp":b.max_hp,"primary_damage":b.damage,"attack_interval":b.attack_interval,"partial":stage_two_partial,"step_cap":steps>=MAX_STEPS,"equipped":p.data.equipped.duplicate(true),"upgrades_at_start":p.data.upgrades.duplicate(true)}

func run_all()->void:
 var path:=OS.get_environment("MIMIC_TRIAL_OUTPUT")
 if not path.is_empty():output_path=path
 var count_arg:=OS.get_environment("MIMIC_TRIAL_SAMPLES")
 if count_arg.is_valid_int():samples=int(count_arg)
 var max_arg:=OS.get_environment("MIMIC_TRIAL_MAX_RUNS")
 if max_arg.is_valid_int():max_runs=int(max_arg)
 var summary:Dictionary={"samples":samples,"max_first_stage_runs":max_runs,"step_seconds":STEP,"stage_two_cutoff":60,"trials":[]}
 for sample_index in range(1,samples+1):
  var p=Profile.new(false);p.rng.seed=120000+sample_index
  var trial:Dictionary={"trial":sample_index,"runs":[],"family_unlock_run":0,"first_clear_run":0,"first_awaken_affordable":false,"first_both_affordable":false,"first_equipped_changes":[]}
  for run_number in range(1,max_runs+1):
   var run_result:Dictionary=play_one(p,0,1000000+sample_index*10000+run_number)
   run_result["run"]=run_number
   if run_number==1:
    trial.first_awaken_affordable=int(p.data.points)>=3
    trial.first_both_affordable=int(p.data.points)>=11
   var equip_changes:=prepare_equipment(p)
   if run_number==1:trial.first_equipped_changes=equip_changes.duplicate(true)
   var bought:=spend_points(p,run_number)
   if "family_hex" in bought and int(trial.family_unlock_run)==0:trial.family_unlock_run=run_number
   var upgrades:=spend_gold(p)
   run_result["equipment_changes"]=equip_changes
   run_result["purchases"]=bought
   run_result["item_upgrades"]=upgrades
   run_result["points_balance_after"]=int(p.data.points)
   run_result["gold_balance_after"]=int(p.data.gold)
   trial.runs.append(run_result)
   print("trial=%d run=%d stage=1 time=%.1f kills=%d won=%s pts=%d gold=%d gear=%d gems=%d" % [sample_index,run_number,run_result.elapsed,run_result.kills,run_result.won,run_result.points,run_result.gold_gained,run_result.items,run_result.gems])
   if run_result.step_cap:break
   if run_result.won:
    trial.first_clear_run=run_number
    var second:Dictionary=play_one(p,1,2000000+sample_index*10000+run_number)
    second["run"]=run_number+1;second["points_balance_after"]=int(p.data.points);second["gold_balance_after"]=int(p.data.gold)
    trial.runs.append(second)
    print("trial=%d run=%d stage=2 time=%.1f kills=%d partial=%s" % [sample_index,run_number+1,second.elapsed,second.kills,second.partial])
    break
  summary.trials.append(trial)
  var out:=FileAccess.open(output_path,FileAccess.WRITE)
  if out:out.store_string(JSON.stringify(summary,"  "));out.close()
  print("DONE trial=%d clear=%d family=%d" % [sample_index,trial.first_clear_run,trial.family_unlock_run])
 print("TRIALS COMPLETE: "+output_path)
 quit(0)
