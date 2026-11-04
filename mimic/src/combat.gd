class_name MimicCombat
extends RefCounted
const CENTER := Vector2(640, 360)
const MAX_ENEMIES := 120
const MAX_PROJECTILES := 256
const MAX_EFFECTS := 64
const MAX_TONGUE_OVERFLOW := 8
const MAX_IMPACT_VISUALS := 12
const RUN_SECONDS := 300.0
const AIM_HALF_WIDTH := 32.0
const DEVOUR_HALF_WIDTH := 68.0
const TONGUE_DURATION := 0.30
# Shields face the mimic. Sources within +/-45 degrees of that facing are blocked.
const SHIELD_FRONT_DOT := 0.7071067811865476
const SUMMON_BURST_RADIUS := 60.0
const SUMMON_BURST_DAMAGE := 0.5
const BOMB_COOLDOWN := 20.0
const BOMB_DAMAGE := 85.0
const BOMB_RADIUS := 135.0
const BOMB_GOLD_MULTIPLIER := 3
const STAGE_ROSTERS := [["swordsman","shield","archer","thief","fanatic"],["shield","archer","mage","priest","thief","fanatic","lancer"]]
const FAMILIES := ["devour","blade","hex","poison","summon","defense","arcane"]
var rng := RandomNumberGenerator.new()
var enemies: Array = []
var projectiles: Array = []
var effects: Array = []
# Reserved visual-only fallback for tongues when the shared effect pool is full.
var tongue_overflow: Array = []
# Bounded cosmetic-only impact pool, independent of the effects used by gameplay.
var impacts: Array = []
var impact_serial := 0
var impact_critical_pending := false
var sparks: Array = []
var minions: Array = []
var abilities: Array = []
var family_counts := {}
var stats := {}
var elapsed := 0.0
var hp := 100.0
var max_hp := 100.0
var kills := 0
var spawn_budget := 0.0
var aim := Vector2.RIGHT
var ended := false
var won := false
var stage := 0
var damage := 15.0
var attack_interval := 0.6
var attack_range := 330.0
var shots := 0
var bomb_remaining := 0.0
var damage_events := 0
var boss_spawned := false
var loot_events: Array = []
var popups: Array = []
var enemy_data: Dictionary = {}
var balance: Dictionary = {}
var unique_ids: Array = []
var devour_chain := 0
var last_stand_used := false
var hitstop := 0.0
var debug_invulnerable := false
# Packed snapshots accelerate frequent projectile targeting. The enemy pool remains authoritative.
var target_cache_active := false
var target_positions := PackedVector2Array()
var target_active := PackedByteArray()

func _init(seed_value: int = 1) -> void:
 rng.seed = seed_value
 target_positions.resize(MAX_ENEMIES)
 target_active.resize(MAX_ENEMIES)
 enemy_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))
 balance = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json"))
 for i in MAX_ENEMIES:
  enemies.append({"index":i, "generation":0, "popup_index":-1, "active": false, "pos": Vector2.ZERO, "hp": 0.0, "max_hp": 0.0, "cooldown": 0.0, "speed": 0.0, "damage": 0.0, "kind": "swordsman", "boss": false, "poison": 0.0, "poison_source": Vector2.INF, "mark": 0, "dot_tick": 0.0, "phase": 0, "timer": 0.0})
 for i in MAX_PROJECTILES:
  projectiles.append({"active": false, "pos": Vector2.ZERO, "vel": Vector2.ZERO, "ttl": 0.0, "damage": 0.0, "enemy": false, "family": "", "pierce": 0})
 for i in MAX_EFFECTS:
  effects.append({"active": false, "from": Vector2.ZERO, "to": Vector2.ZERO, "ttl": 0.0, "family": "", "radius": 0.0})
 for i in MAX_TONGUE_OVERFLOW:
  tongue_overflow.append({"active":false,"from":Vector2.ZERO,"to":Vector2.ZERO,"ttl":0.0,"family":"devour","splash":false,"splash_center":Vector2.ZERO})
 for i in MAX_IMPACT_VISUALS:
  impacts.append({"active":false,"pos":Vector2.ZERO,"angle":0.0,"ttl":0.0,"duration":0.0,"critical":false})
 for i in 12:minions.append({"active":false,"pos":Vector2.ZERO,"ttl":0.0,"timer":0.0,"power":0.0,"side":0.0})
 for i in 192:sparks.append({"active":false,"pos":Vector2.ZERO,"vel":Vector2.ZERO,"ttl":0.0,"family":""})
 for i in MAX_ENEMIES:loot_events.append({"active":false,"kind":"","boss":false,"position":Vector2.ZERO,"bomb":false})
 for i in 16:popups.append({"active":false,"pos":Vector2.ZERO,"value":0,"ttl":0.0,"enemy_index":-1,"generation":-1,"critical":false})
 configure([])

func configure(equipment: Array, upgrades: Dictionary = {}) -> void:
 abilities.clear()
 family_counts.clear()
 unique_ids.clear()
 stats = {"damage":1.0,"speed":1.0,"range":1.0,"area":1.0,"crit":0.05,"crit_damage":1.5,"lifesteal":0.0,"reduction":0.0,"hp":0.0,"drop":0.0,"projectiles":0,"pierce":0,"chain":0,"dot":1.0,"stationary":1.0,"heal_kill":0.0}
 for family in FAMILIES: stats[family] = 1.0
 for item in equipment:
  var family: String = item.family
  if item.has("unique"): unique_ids.append(item.unique)
  family_counts[family] = family_counts.get(family, 0) + 1
  if item.has("item"):
   for affix in item.item.get("affixes", []):
    var key: String = affix.id
    if stats.has(key): stats[key] += float(affix.value)
   for gem in item.item.get("sockets",[]):
    var gem_family: String = gem.family
    if stats.has(gem_family): stats[gem_family] += 0.05 * int(gem.tier)
 for item in equipment:
  var a: Dictionary = item.duplicate(true)
  a.timer = 0.0
  var level: int = int(item.get("item",{}).get("level",0))
  var rarity: int = int(item.get("item",{}).get("rarity",0))
  a.power = float(a.power) * (1.0 + level * 0.12 + rarity * 0.12)
  abilities.append(a)
  if item.slot == "shell":
   stats.reduction += minf(0.30, float(a.power)*0.005)
  if item.slot == "fang":
   damage = a.power * stats.damage
   attack_interval = float(a.cooldown) / stats.speed
   attack_range = float(a.range) * stats.range
 if abilities.is_empty(): abilities.append({"slot":"fang","family":"devour","ability":"bite","power":15.0,"cooldown":0.6,"range":330.0,"timer":0.0})
 max_hp = 100.0 * (1.0 + float(upgrades.get("hp",0)) * 0.1 + float(stats.hp))
 hp = max_hp
 stats.damage *= 1.0 + float(upgrades.get("damage",0))*0.1
 for family in family_counts:
  if family_counts[family] >= 2: stats[family] += 0.20
 for a in abilities:
  if a.slot=="fang":
   damage=float(a.power)*float(stats.damage)*float(stats.get(a.family,1.0))
   attack_interval=float(a.cooldown)/float(stats.speed)
   attack_range=float(a.range)*float(stats.range)

func spawn_enemy(kind: String = "swordsman", position := Vector2.INF) -> bool:
 for e in enemies:
  if not e.active:
   if position == Vector2.INF:
    var angle := rng.randf_range(0.0, TAU)
    var direction := Vector2.from_angle(angle)
    var distance: float = minf(700.0 / maxf(absf(direction.x), 0.001), 420.0 / maxf(absf(direction.y), 0.001))
    position = CENTER + direction * distance
   var def: Dictionary = enemy_data.get(kind,enemy_data.swordsman)
   var scale: float = 1.0
   for step in balance.time_steps:
    if elapsed>=float(step.at): scale=float(step.mult)
   var boss: bool=def.get("boss",false)
   var health: float=float(def.hp)*float(balance.stage_scaling[stage].hp)*(1.0 if boss else scale)
   e.generation=int(e.generation)+1
   e.popup_index=-1
   e.merge({"active":true,"pos":position,"max_hp":health,"hp":health,"speed":float(def.speed),"damage":float(def.damage)*float(balance.stage_scaling[stage].damage)*(1.0 if boss else scale),"cooldown":1.5,"kind":kind,"boss":boss,"poison":0.0,"poison_source":Vector2.INF,"mark":0,"dot_tick":0.0,"phase":0,"timer":0.0},true)
   if target_cache_active:
    target_active[int(e.index)]=1
    target_positions[int(e.index)]=e.pos
   return true
 return false

func dominant_family() -> String:
 var best: String=""
 var count := 0
 for family in FAMILIES:
  if int(family_counts.get(family,0))>count:
   best=family
   count=int(family_counts[family])
 return best
func sync_target_cache() -> void:
 for i in enemies.size():
  var e:Dictionary=enemies[i]
  target_active[i]=1 if e.active else 0
  if e.active:target_positions[i]=e.pos
func target_index(origin:Vector2,direction:Vector2,max_range:float,half_width:float=AIM_HALF_WIDTH)->int:
 if max_range<0.0 or direction.length_squared()<0.0001:return -1
 var aim_dir:Vector2=direction.normalized()
 var best: int=-1
 var best_forward:float=INF
 for i in enemies.size():
  var pos:Vector2
  if target_cache_active:
   if target_active[i]==0:continue
   pos=target_positions[i]
  else:
   var e:Dictionary=enemies[i]
   if not e.active:continue
   pos=e.pos
  var offset:Vector2=pos-origin
  var forward:float=aim_dir.dot(offset)
  var lateral:float=absf(aim_dir.cross(offset))
  if forward>0.0 and forward<=max_range and lateral<=half_width and forward<best_forward:
   best=i;best_forward=forward
 return best

func effect(from: Vector2, to: Vector2, family: String, radius: float = 0.0, duration: float = 0.18) -> Dictionary:
 for fx in effects:
  if not fx.active:
   fx.merge({"active":true,"from":from,"to":to,"ttl":duration,"family":family,"radius":radius},true)
   return fx
 return {}
func tongue_effect(tip: Vector2) -> Dictionary:
 var fx:Dictionary=effect(CENTER,tip,"devour",0.0,TONGUE_DURATION)
 if fx.is_empty():
  var chosen:Dictionary=tongue_overflow[0]
  for candidate in tongue_overflow:
   if not candidate.active:chosen=candidate;break
   if float(candidate.ttl)<float(chosen.ttl):chosen=candidate
  chosen.merge({"active":true,"from":CENTER,"to":tip,"ttl":TONGUE_DURATION,"family":"devour"},true)
  fx=chosen
 fx["splash"]=false
 fx["splash_center"]=tip
 return fx
func scatter(origin: Vector2, family: String, count: int = 6) -> void:
 var remaining:int=count
 for spark in sparks:
  if not spark.active:
   var angle:float=rng.randf_range(0.0,TAU)
   spark.active=true;spark.pos=origin;spark.vel=Vector2.from_angle(angle)*rng.randf_range(30,100);spark.ttl=rng.randf_range(0.25,0.6);spark.family=family
   remaining-=1
   if remaining<=0:return
func projectile(origin: Vector2, direction: Vector2, amount: float, family: String, enemy: bool = false) -> void:
 for p in projectiles:
  if not p.active:
   p.merge({"active":true,"pos":origin,"vel":direction.normalized() * (210.0 if enemy else 420.0),"ttl":2.0,"damage":amount,"enemy":enemy,"family":family,"pierce":int(stats.pierce)},true)
   return
func shield_multiplier(enemy: Dictionary, source_position: Vector2) -> float:
 if enemy.kind!="shield" or not source_position.is_finite():return 1.0
 var facing:Vector2=CENTER-enemy.pos
 var source:Vector2=source_position-enemy.pos
 if facing.length_squared()<0.0001 or source.length_squared()<0.0001:return 1.0
 return 0.55 if facing.normalized().dot(source.normalized())>=SHIELD_FRONT_DOT-0.000001 else 1.0
func apply_poison(enemy: Dictionary, duration: float, source_position: Vector2) -> void:
 if duration>float(enemy.poison):
  enemy.poison=duration
  enemy.poison_source=source_position
func impact_visual(position: Vector2, source_position: Vector2, critical: bool) -> void:
 impact_serial+=1
 impact_critical_pending=impact_critical_pending or critical
 var slot:Dictionary=impacts[0]
 for candidate in impacts:
  if not candidate.active:slot=candidate;break
  if float(candidate.ttl)<float(slot.ttl):slot=candidate
 var direction:Vector2=position-source_position if source_position.is_finite() else Vector2.RIGHT
 var angle:float=direction.angle() if direction.length_squared()>0.01 else 0.0
 var duration:float=0.40 if critical else 0.24
 slot.active=true;slot.pos=position;slot.angle=angle
 slot.ttl=duration;slot.duration=duration;slot.critical=critical
func hit_enemy(index: int, amount: float, push: Vector2 = Vector2.ZERO, family: String = "devour", bomb_kill: bool = false, source_position: Vector2 = CENTER) -> void:
 if index < 0 or index >= enemies.size() or not enemies[index].active: return
 var e: Dictionary = enemies[index]
 var value: float = amount * float(stats.damage) * float(stats.get(family,1.0))
 value *= shield_multiplier(e,source_position)
 if e.pos.distance_to(CENTER)<40 or e.kind in ["archer","mage","priest"]: value *= float(stats.stationary)
 var critical:bool=rng.randf() < stats.crit
 if critical:value *= stats.crit_damage
 impact_visual(e.pos,source_position,critical)
 e.hp -= value
 e.pos += push
 if target_cache_active:target_positions[index]=e.pos
 damage_events += 1
 hitstop = maxf(hitstop,0.018)
 # Combine rapid hits on the same living enemy into one readable number.
 var popup_index:int=int(e.popup_index)
 var existing_hit:=false
 if popup_index>=0:
  var existing:Dictionary=popups[popup_index]
  if not existing.active or int(existing.enemy_index)!=index or int(existing.generation)!=int(e.generation):popup_index=-1
  else:existing_hit=true
 if popup_index<0:
  for i in popups.size():
   if not popups[i].active:
    popup_index=i
    e.popup_index=i
    popups[i].value=0
    popups[i].enemy_index=index
    popups[i].generation=e.generation
    popups[i].critical=false
    break
 if popup_index>=0:
  var pop:Dictionary=popups[popup_index]
  if not existing_hit:pop.active=true;pop.pos=e.pos;pop.ttl=0.45
  pop.value+=int(value)
  pop.critical=bool(pop.critical) or critical
 hp = minf(max_hp, hp + value * stats.lifesteal)
 if e.hp <= 0:
  kill_enemy(e,bomb_kill)
  hp = minf(max_hp, hp + stats.heal_kill)
  if "curse_spread" in unique_ids and e.mark>0:
   for other in enemies:
    if other.active and other.pos.distance_to(e.pos)<100: other.mark+=e.mark

func kill_enemy(e: Dictionary, bomb_kill: bool = false) -> void:
 if not e.active:return
 e.active=false
 if target_cache_active:target_active[int(e.index)]=0
 if family_counts.get("hex",0)>0 and family_counts.get("poison",0)>0 and e.mark>0 and e.poison>0:
  effect(e.pos,e.pos,"poison",52)
  for other in enemies:
   if other.active and other.pos.distance_to(e.pos)<52:other.hp-=8.0*float(stats.damage)*shield_multiplier(other,e.pos)
 scatter(e.pos,"blade",6)
 kills+=1
 for event in loot_events:
  if not event.active:
   event.active=true;event.kind=e.kind;event.boss=e.boss;event.position=e.pos;event.bomb=bomb_kill
   break
 if e.boss: won=true;ended=true
func use_bomb() -> bool:
 if ended or bomb_remaining>0.0:return false
 bomb_remaining=BOMB_COOLDOWN
 var center:Vector2=CENTER+aim.normalized()*160.0
 effect(center,center,"bomb",BOMB_RADIUS,0.55)
 scatter(center,"bomb",24)
 for i in enemies.size():
  var enemy:Dictionary=enemies[i]
  if enemy.active and enemy.pos.distance_squared_to(center)<=BOMB_RADIUS*BOMB_RADIUS:
   var impulse:Vector2=(enemy.pos-center).normalized()*45.0
   hit_enemy(i,BOMB_DAMAGE,impulse,"bomb",true,center)
 return true
func hurt_player(amount: float) -> void:
 if debug_invulnerable:return
 hp -= amount*(1.0-clampf(stats.reduction,0.0,0.75))
 if hp<=0 and "last_stand" in unique_ids and not last_stand_used:
  hp=max_hp*0.3
  last_stand_used=true
  effect(CENTER,CENTER,"defense",100)
func cast(a: Dictionary) -> bool:
 var family: String = a.family
 var ability: String = a.ability
 var reach: float = float(a.get("range",300)) * float(stats.range)
 var index := target_index(CENTER, aim, reach, DEVOUR_HALF_WIDTH if family=="devour" else AIM_HALF_WIDTH)
 if ability == "heal":
  hp = minf(max_hp,hp + 1.0 + float(a.power)*0.1)
  effect(CENTER,CENTER,"defense",42)
  return true
 if ability in ["hide","armor"]: return false
 var e:Dictionary=enemies[index] if index>=0 else {}
 var power: float = float(a.power)
 if family=="blade" and "extra_blades" in unique_ids:power*=1.0+family_counts.get("blade",0)*0.2
 if family=="blade" and family_counts.get("devour",0)>0:power*=1.15
 if family=="devour" and "devour_chain" in unique_ids:
  if index>=0:devour_chain=mini(devour_chain+1,5)
  else:devour_chain=0
  power*=1.0+devour_chain*0.12
 if family == "devour":
  # The tip bends toward a target inside the player's aimed strike corridor.
  var tongue_tip:Vector2=CENTER+aim*reach if index<0 else e.pos
  var tongue_fx:Dictionary=tongue_effect(tongue_tip)
  if index>=0:hit_enemy(index,power, -((e.pos-CENTER).normalized())*10.0,"devour")
  if index>=0 and ability=="pull":
   for other in enemies:
    if other.active and other.pos.distance_to(e.pos)<100:
     other.pos+=(CENTER-other.pos).normalized()*35
     if target_cache_active:target_positions[int(other.index)]=other.pos
  if index>=0 and (ability=="maw" or family_counts.get("devour",0)>=4 or ("devour_chain" in unique_ids and devour_chain>=2)):
   for i in enemies.size():
    if i!=index and enemies[i].active and enemies[i].pos.distance_to(e.pos)<65:
     tongue_fx.splash=true;tongue_fx.splash_center=e.pos
     hit_enemy(i,power*0.5,Vector2.ZERO,"devour",false,e.pos)
 elif family == "blade":
  var blade_center:Vector2=CENTER+aim*45
  effect(CENTER,blade_center,"blade",90 if ability=="orbit" else 60)
  for i in enemies.size():
   var other: Dictionary = enemies[i]
   if other.active and ((ability=="orbit" and other.pos.distance_to(blade_center)<105) or (ability!="orbit" and aim.dot(other.pos-CENTER)>0 and aim.dot(other.pos-CENTER)<=reach and absf(aim.cross(other.pos-CENTER))<=AIM_HALF_WIDTH)):
    hit_enemy(i,power,(other.pos-CENTER).normalized()*9,"blade",false,blade_center if ability=="orbit" else CENTER)
    if ability == "pierce": continue
    if ability != "orbit" and family_counts.get("blade",0)<4 and "cleave" not in unique_ids and "extra_blades" not in unique_ids: break
 elif family == "hex":
  if index<0:
   effect(CENTER,CENTER+aim*reach,"hex",18)
  else:
   e.mark += 1
   if ability=="mark" and e.mark>=3:
    power*=2.0
    e.mark=1
   if family_counts.get("hex",0)>=4 or "curse_chain" in unique_ids:
    for other in enemies:
     if other.active and other!=e and other.pos.distance_to(e.pos)<90: other.mark+=1
   effect(CENTER,CENTER+aim*minf(reach,e.pos.distance_to(CENTER)),"hex",18)
   hit_enemy(index,power,Vector2.ZERO,"hex")
   if stats.chain > 0:
    var chains:int=0
    for i in enemies.size():
     if i!=index and enemies[i].active and enemies[i].pos.distance_to(e.pos)<100:
      effect(e.pos,enemies[i].pos,"hex")
      hit_enemy(i,power*0.5,Vector2.ZERO,"hex",false,e.pos)
      chains+=1
      if chains>=int(stats.chain):break
 elif family == "poison":
  var center: Vector2 = CENTER + aim * minf(160,reach*0.6)
  effect(CENTER,center,"poison",65)
  if ability=="pool":
   for fx in effects:
    if fx.active and fx.family=="poison" and fx.to==center:fx.ttl=3.0;break
  for other in enemies:
   if other.active and other.pos.distance_to(center)<=90*float(stats.area):
    apply_poison(other,4.0,center)
    if family_counts.get("poison",0)>=4 or "poison_burst" in unique_ids: other.hp -= power*0.4*shield_multiplier(other,center)
 elif family == "summon":
  var origin: Vector2 = CENTER + aim * 75
  effect(CENTER,origin,"summon",12)
  var limit:int=mini(10,2+int(family_counts.get("summon",0))+(2 if "extra_minions" in unique_ids else 0))
  var active_minions:int=0
  for minion in minions:
   if minion.active:active_minions+=1
  if active_minions<limit:
   for minion in minions:
    if not minion.active:
     minion.active=true;minion.ttl=8.0;minion.timer=0.0;minion.power=power;minion.side=(active_minions-limit*0.5)*24;break
  else:
   for minion in minions:
    if minion.active:minion.ttl=maxf(minion.ttl,5.0)
 elif family == "defense":
  effect(CENTER,CENTER+aim*70,"defense",70)
  if family_counts.get("defense",0)>=4: hp=minf(max_hp,hp+2.0)
  for i in enemies.size():
   var other: Dictionary = enemies[i]
   if other.active and other.pos.distance_to(CENTER)<(210 if "wide_counter" in unique_ids else 140) and aim.dot((other.pos-CENTER).normalized())>0.0:
    hit_enemy(i,power,(other.pos-CENTER).normalized()*20,"defense")
 elif family == "arcane":
  if ability == "nova" or "double_nova" in unique_ids:
   var center: Vector2 = CENTER + aim*100
   effect(CENTER,center,"arcane",65)
   for i in enemies.size():
    if enemies[i].active and enemies[i].pos.distance_to(center)<80*float(stats.area): hit_enemy(i,power*(1.5 if "double_nova" in unique_ids else 1.0),Vector2.ZERO,"arcane",false,center)
  else:
   projectile(CENTER,aim,power,"arcane")
   for extra in mini(4,int(stats.projectiles)): projectile(CENTER,aim.rotated(0.1*(extra+1)),power*0.7,"arcane")
   if family_counts.get("arcane",0)>=4: projectile(CENTER,aim.rotated(0.16),power*0.8,"arcane")
 if family!="devour" and family_counts.get(family,0)>=4: effect(CENTER,CENTER+aim*80,family,35)
 shots += 1
 return true

func update(delta: float) -> void:
 if ended: return
 if hitstop>0: hitstop-=delta;return
 elapsed += delta
 bomb_remaining=maxf(0.0,bomb_remaining-delta)
 if elapsed>=240 and not boss_spawned:
  boss_spawned=spawn_enemy("hero" if stage==0 else "captain")
  if not boss_spawned:
   for candidate in enemies:
    if candidate.active and not candidate.boss:
     candidate.active=false
     break
   boss_spawned=spawn_enemy("hero" if stage==0 else "captain")
 spawn_budget += delta * (0.7 + elapsed / 100.0 + stage*0.2)
 var roster: Array = STAGE_ROSTERS[stage]
 while spawn_budget >= 1.0:
  var start:int=rng.randi_range(0,roster.size()-1)
  var kind:String=""
  for n in roster.size():
   var candidate:String=roster[(start+n)%roster.size()]
   if float(enemy_data[candidate].cost)<=spawn_budget:kind=candidate;break
  if kind.is_empty() or not spawn_enemy(kind):break
  spawn_budget -= float(enemy_data[kind].cost)
 # Abilities run directly against the pool; most frames have only a few casts.
 for a in abilities:
  a.timer -= delta
  if a.timer <= 0.0 and cast(a): a.timer = float(a.cooldown)/float(stats.speed)
 for e in enemies:
  if not e.active: continue
  if e.poison>0:
   e.poison -= delta
   e.dot_tick -= delta
   if e.dot_tick<=0:
    e.hp -= 3.0 * float(stats.dot) * float(stats.poison) * shield_multiplier(e,e.poison_source)
    e.dot_tick = 0.5
    if e.hp<=0: kill_enemy(e);continue
  e.timer += delta
  e.cooldown -= delta
  var dir: Vector2 = CENTER - e.pos
  var distance := dir.length()
  var ranged: bool=e.kind in ["archer","mage","priest"]
  var stop_range: float=230 if ranged else 44+14*(int(e.index)%4)
  if e.kind=="lancer" and distance<260 and e.cooldown<=0: e.phase=1;e.cooldown=4.0
  if e.kind=="captain" and distance<350 and e.cooldown<=0: e.phase=1;e.cooldown=3.0
  var speed: float=float(e.speed)*(3.0 if e.phase==1 else 1.0)
  if e.kind=="thief" and e.timer>9:
   e.pos -= dir.normalized()*speed*delta
   if e.pos.x < -60 or e.pos.x > 1340 or e.pos.y < -60 or e.pos.y > 780:e.active=false
   continue
  if distance>stop_range: e.pos += dir.normalized()*speed*delta
  elif e.kind=="fanatic": hurt_player(e.damage);e.active=false;effect(e.pos,e.pos,"poison",50)
  elif e.phase==1: hurt_player(e.damage*1.5);e.phase=0;e.cooldown=2.5
  elif not ranged and e.cooldown<=0: hurt_player(e.damage);e.cooldown=1.2;e.phase=0
  if ranged and distance<=stop_range and e.cooldown<=0:
   if e.kind=="priest":
    for ally in enemies:
     if ally.active and ally.pos.distance_to(e.pos)<110: ally.hp=minf(ally.max_hp,ally.hp+6.0)
    effect(e.pos,e.pos,"defense",65)
   else:
    projectile(e.pos,dir,e.damage,"enemy",true)
    if e.kind=="mage":projectile(e.pos,dir.rotated(0.22),e.damage,"enemy",true);projectile(e.pos,dir.rotated(-0.22),e.damage,"enemy",true)
   e.cooldown=2.4
  if e.boss and e.timer>=5.0:
   e.timer=0
   if e.kind=="hero":
    projectile(e.pos,dir,e.damage,"enemy",true)
    if e.hp<e.max_hp*0.65:projectile(e.pos,dir.rotated(0.25),e.damage,"enemy",true);spawn_enemy("swordsman")
    if e.hp<e.max_hp*0.3:spawn_enemy("archer")
   else:
    for ally in enemies:
     if ally.active and ally.pos.distance_to(e.pos)<120:ally.hp=minf(ally.max_hp,ally.hp+15)
    for angle in [-0.35,0.0,0.35]:projectile(e.pos,dir.rotated(angle),e.damage,"enemy",true)
    var blast:Vector2=e.pos+dir.normalized()*minf(distance,130.0)
    effect(e.pos,blast,"enemy",85)
    if blast.distance_to(CENTER)<85:hurt_player(e.damage)
    effect(e.pos,e.pos,"defense",100)
 # Build the packed view only when friendly projectiles or minions need repeated searches.
 var query_count:=0
 for minion in minions:
  if minion.active:query_count+=1
 if query_count<4:
  for candidate in projectiles:
   if candidate.active and not candidate.enemy:
    query_count+=1
    if query_count>=4:break
 if query_count>=4:
  sync_target_cache()
  target_cache_active=true
 for minion in minions:
  if not minion.active:continue
  minion.ttl-=delta;minion.timer-=delta
  minion.pos=CENTER+aim*75+aim.orthogonal()*float(minion.side)
  if minion.ttl<=0:minion.active=false;continue
  if minion.timer<=0:
   projectile(minion.pos,aim,minion.power,"summon")
   if family_counts.get("arcane",0)>0:projectile(minion.pos,aim.rotated(0.12),minion.power*0.5,"arcane")
   minion.timer=1.0
 for p in projectiles:
  if not p.active: continue
  var previous_pos:Vector2=p.pos
  p.pos += p.vel * delta
  p.ttl -= delta
  if p.ttl<=0: p.active=false; continue
  if p.enemy:
   if p.pos.distance_to(CENTER)<30:
    hurt_player(p.damage); p.active=false
  else:
   var hit_index: int=-1
   if target_cache_active:
    for i in enemies.size():
     if target_active[i]!=0 and target_positions[i].distance_squared_to(p.pos)<256.0:hit_index=i;break
   else:
    for i in enemies.size():
     if enemies[i].active and enemies[i].pos.distance_squared_to(p.pos)<256.0:hit_index=i;break
   if hit_index>=0:
    var impact:Vector2=enemies[hit_index].pos
    hit_enemy(hit_index,p.damage,p.vel.normalized()*8,p.family,false,previous_pos)
    if p.family=="summon" and int(family_counts.get("summon",0))>=4:
     var radius:float=SUMMON_BURST_RADIUS*float(stats.area)
     effect(impact,impact,"summon",radius)
     for i in enemies.size():
      if i!=hit_index and enemies[i].active and enemies[i].pos.distance_squared_to(impact)<=radius*radius:
       hit_enemy(i,p.damage*SUMMON_BURST_DAMAGE,Vector2.ZERO,"summon",false,impact)
    if p.pierce>0: p.pierce-=1
    else: p.active=false
 for spark in sparks:
  if spark.active:
   spark.pos+=spark.vel*delta;spark.vel*=0.95;spark.ttl-=delta
   if spark.ttl<=0:spark.active=false
 for pop in popups:
  if pop.active:
   pop.ttl-=delta;pop.pos.y-=delta*30
   if pop.ttl<=0:pop.active=false
 for impact in impacts:
  if impact.active:
   impact.ttl-=delta
   if impact.ttl<=0:impact.active=false
 for tongue in tongue_overflow:
  if tongue.active:
   tongue.ttl-=delta
   if tongue.ttl<=0:tongue.active=false
 for fx in effects:
  if fx.active:
   if fx.family=="poison" and fx.ttl>0.2:
    for enemy in enemies:
     if enemy.active and enemy.pos.distance_to(fx.to)<fx.radius:apply_poison(enemy,1.5,fx.to)
   fx.ttl-=delta
   if fx.ttl<=0: fx.active=false
 target_cache_active=false
 if hp <= 0: hp=0; ended=true
 elif elapsed >= RUN_SECONDS: ended=true
