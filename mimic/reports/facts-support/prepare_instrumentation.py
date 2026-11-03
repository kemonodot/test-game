from pathlib import Path
root=Path('/tmp/mimic-facts-copy')
p=root/'src/combat.gd';s=p.read_text()
s=s.replace('var debug_invulnerable := false','''var debug_invulnerable := false
# Measurement-only fields: never change target selection, RNG, damage or progression.
var metric_clock := 0.0
var metric_incoming: Array = []
var metric_damage := 0.0
var metric_raw_damage := 0.0
var metric_set_damage := {"devour":0.0,"blade":0.0,"hex":0.0,"poison":0.0,"summon":0.0,"defense":0.0,"arcane":0.0}
func metric_record_damage(enemy: Dictionary, amount: float, set_tag: String = "") -> void:
 var actual:float=minf(maxf(0.0,float(enemy.hp)),maxf(0.0,amount))
 metric_damage += actual
 metric_raw_damage += maxf(0.0,amount)
 if set_tag=="hex_half":
  metric_set_damage.hex += maxf(0.0,actual-minf(maxf(0.0,float(enemy.hp)),maxf(0.0,amount*0.5)))
 elif metric_set_damage.has(set_tag):
  metric_set_damage[set_tag] += actual''')
s=s.replace('"poison_source": Vector2.INF, "mark": 0','"poison_source": Vector2.INF, "metric_set_marks": 0, "mark": 0')
s=s.replace('"poison_source":Vector2.INF,"mark":0','"poison_source":Vector2.INF,"metric_set_marks":0,"mark":0')
s=s.replace('func projectile(origin: Vector2, direction: Vector2, amount: float, family: String, enemy: bool = false) -> void:', 'func projectile(origin: Vector2, direction: Vector2, amount: float, family: String, enemy: bool = false, metric_enemy_kind: String = "", metric_set_tag: String = "") -> void:')
s=s.replace('"family":family,"pierce":int(stats.pierce)},true)', '"family":family,"pierce":int(stats.pierce),"metric_enemy_kind":metric_enemy_kind,"metric_set_tag":metric_set_tag},true)')
s=s.replace('bomb_kill: bool = false, source_position: Vector2 = CENTER) -> void:', 'bomb_kill: bool = false, source_position: Vector2 = CENTER, metric_set_tag: String = "") -> void:',1)
s=s.replace(' if rng.randf() < stats.crit: value *= stats.crit_damage\n e.hp -= value',' if rng.randf() < stats.crit: value *= stats.crit_damage\n metric_record_damage(e,value,metric_set_tag)\n e.hp -= value')
s=s.replace('''   if other.active and other.pos.distance_to(e.pos)<52:other.hp-=8.0*float(stats.damage)*shield_multiplier(other,e.pos)''','''   if other.active and other.pos.distance_to(e.pos)<52:
    var metric_hybrid:float=8.0*float(stats.damage)*shield_multiplier(other,e.pos)
    metric_record_damage(other,metric_hybrid)
    other.hp-=metric_hybrid''')
s=s.replace('''func hurt_player(amount: float) -> void:
 if debug_invulnerable:return
 hp -= amount*(1.0-clampf(stats.reduction,0.0,0.75))''','''func hurt_player(amount: float, metric_kind: String = "unknown") -> void:
 if debug_invulnerable:return
 var metric_before:float=hp
 var metric_amount:float=amount*(1.0-clampf(stats.reduction,0.0,0.75))
 metric_incoming.append({"time":metric_clock,"kind":metric_kind,"amount":metric_amount,"hp_loss":minf(maxf(0.0,metric_before),metric_amount),"hp_before":metric_before})
 hp -= metric_amount''')
s=s.replace('''if i!=index and enemies[i].active and enemies[i].pos.distance_to(e.pos)<65: hit_enemy(i,power*0.5,Vector2.ZERO,"devour",false,e.pos)''','''if i!=index and enemies[i].active and enemies[i].pos.distance_to(e.pos)<65:
     var metric_devour_set:bool=int(family_counts.get("devour",0))>=4 and ability!="maw" and not ("devour_chain" in unique_ids and devour_chain>=2)
     hit_enemy(i,power*0.5,Vector2.ZERO,"devour",false,e.pos,"devour" if metric_devour_set else "")''')
s=s.replace('''  effect(CENTER,blade_center,"blade",90 if ability=="orbit" else 60)
  for i in enemies.size():''','''  effect(CENTER,blade_center,"blade",90 if ability=="orbit" else 60)
  var metric_blade_hits:=0
  for i in enemies.size():''')
s=s.replace('''    hit_enemy(i,power,(other.pos-CENTER).normalized()*9,"blade",false,blade_center if ability=="orbit" else CENTER)
    if ability == "pierce": continue''','''    var metric_blade_set:bool=metric_blade_hits>0 and ability not in ["pierce","orbit"] and int(family_counts.get("blade",0))>=4 and "cleave" not in unique_ids and "extra_blades" not in unique_ids
    hit_enemy(i,power,(other.pos-CENTER).normalized()*9,"blade",false,blade_center if ability=="orbit" else CENTER,"blade" if metric_blade_set else "")
    metric_blade_hits+=1
    if ability == "pierce": continue''')
s=s.replace(''' elif family == "hex":
  if index<0:''',''' elif family == "hex":
  var metric_hex_tag:=""
  if index<0:''')
s=s.replace('''   if ability=="mark" and e.mark>=3:
    power*=2.0
    e.mark=1''','''   if ability=="mark" and e.mark>=3:
    if int(family_counts.get("hex",0))>=4 and int(e.metric_set_marks)>0 and int(e.mark)-int(e.metric_set_marks)<3:metric_hex_tag="hex_half"
    power*=2.0
    e.mark=1;e.metric_set_marks=0''')
s=s.replace('''     if other.active and other!=e and other.pos.distance_to(e.pos)<90: other.mark+=1''','''     if other.active and other!=e and other.pos.distance_to(e.pos)<90:
      other.mark+=1
      if int(family_counts.get("hex",0))>=4 and "curse_chain" not in unique_ids:other.metric_set_marks+=1''')
s=s.replace('''   hit_enemy(index,power,Vector2.ZERO,"hex")''','''   hit_enemy(index,power,Vector2.ZERO,"hex",false,CENTER,metric_hex_tag)''')
s=s.replace('''    if family_counts.get("poison",0)>=4 or "poison_burst" in unique_ids: other.hp -= power*0.4*shield_multiplier(other,center)''','''    if family_counts.get("poison",0)>=4 or "poison_burst" in unique_ids:
     var metric_poison_hit:float=power*0.4*shield_multiplier(other,center)
     metric_record_damage(other,metric_poison_hit,"poison" if int(family_counts.get("poison",0))>=4 and "poison_burst" not in unique_ids else "")
     other.hp-=metric_poison_hit''')
s=s.replace('''if family_counts.get("arcane",0)>=4: projectile(CENTER,aim.rotated(0.16),power*0.8,"arcane")''','''if family_counts.get("arcane",0)>=4: projectile(CENTER,aim.rotated(0.16),power*0.8,"arcane",false,"","arcane")''')
s=s.replace('''    e.hp -= 3.0 * float(stats.dot) * float(stats.poison) * shield_multiplier(e,e.poison_source)''','''    var metric_dot:float=3.0*float(stats.dot)*float(stats.poison)*shield_multiplier(e,e.poison_source)
    metric_record_damage(e,metric_dot)
    e.hp -= metric_dot''')
s=s.replace('''elif e.kind=="fanatic": hurt_player(e.damage);''','''elif e.kind=="fanatic": hurt_player(e.damage,e.kind);''')
s=s.replace('''elif e.phase==1: hurt_player(e.damage*1.5);''','''elif e.phase==1: hurt_player(e.damage*1.5,e.kind);''')
s=s.replace('''elif not ranged and e.cooldown<=0: hurt_player(e.damage);''','''elif not ranged and e.cooldown<=0: hurt_player(e.damage,e.kind);''')
s=s.replace('''if blast.distance_to(CENTER)<85:hurt_player(e.damage)''','''if blast.distance_to(CENTER)<85:hurt_player(e.damage,e.kind)''')
s=s.replace('''"enemy",true)''','''"enemy",true,e.kind)''')
s=s.replace('''hurt_player(p.damage); p.active=false''','''hurt_player(p.damage,p.metric_enemy_kind); p.active=false''')
s=s.replace('''hit_enemy(hit_index,p.damage,p.vel.normalized()*8,p.family,false,previous_pos)''','''hit_enemy(hit_index,p.damage,p.vel.normalized()*8,p.family,false,previous_pos,p.metric_set_tag)''')
s=s.replace('''hit_enemy(i,p.damage*SUMMON_BURST_DAMAGE,Vector2.ZERO,"summon",false,impact)''','''hit_enemy(i,p.damage*SUMMON_BURST_DAMAGE,Vector2.ZERO,"summon",false,impact,"summon")''')
p.write_text(s)
p=root/'tests/early_progression_trials.gd';s=p.read_text()
s=s.replace(''' var starting:int=int(p.data.upgrades.get("starting_gold",0))*10''',''' var metric_start_inventory:int=p.data.inventory.size()
 var metric_health:Array=[[0.0,b.hp]]
 var metric_families:Dictionary=b.family_counts.duplicate(true)
 var starting:int=int(p.data.upgrades.get("starting_gold",0))*10''')
s=s.replace(''' while not b.ended and steps<MAX_STEPS:
  if steps%12==0:''',''' while not b.ended and steps<MAX_STEPS:
  b.metric_clock=steps*STEP
  if steps%12==0:''')
s=s.replace('''  steps+=1
  if stage==1''','''  steps+=1
  metric_health.append([steps*STEP,maxf(0.0,b.hp)])
  if stage==1''')
s=s.replace(''' return {"stage":stage+1,''',''' var metric_time:float=steps*STEP
 var metric_dead:bool=b.ended and not b.won and b.hp<=0.0
 var metric_last15:={}
 if metric_dead:
  for event in b.metric_incoming:
   if float(event.time)>=metric_time-15.0 and float(event.time)<=metric_time and float(event.hp_before)>0.0:
    var kind:String=event.kind if not str(event.kind).is_empty() else "unknown"
    metric_last15[kind]=float(metric_last15.get(kind,0.0))+float(event.hp_loss)
 var metric_last30:=[]
 if metric_dead:
  for seconds in [30,25,20,15,10,5,0]:
   var target:float=maxf(0.0,metric_time-seconds)
   var value:float=b.max_hp
   for state in metric_health:
    if float(state[0])>target+0.000001:break
    value=float(state[1])
   metric_last30.append({"before":seconds,"hp":value})
 var metric_peak3:=0.0
 if metric_dead:
  for state in metric_health:
   if float(state[0])>=metric_time-3.0-0.000001:metric_peak3=maxf(metric_peak3,float(state[1]))
 return {"metric_inventory_start":metric_start_inventory,"metric_inventory_end":p.data.inventory.size(),"metric_damage":b.metric_damage,"metric_raw_damage":b.metric_raw_damage,"metric_set_damage":b.metric_set_damage.duplicate(true),"metric_families":metric_families,"metric_incoming_last15":metric_last15,"metric_last30":metric_last30,"metric_peak3":metric_peak3,"metric_sudden":metric_dead and metric_peak3>=b.max_hp*0.5,"metric_dead":metric_dead,"stage":stage+1,''')
p.write_text(s)
print('instrumented copy:',root)
