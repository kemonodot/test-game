class_name MimicCombat
extends RefCounted
const CENTER := Vector2(640, 360)
const MAX_ENEMIES := 120
const MAX_PROJECTILES := 256
const MAX_EFFECTS := 64
const RUN_SECONDS := 300.0
const STAGE_ROSTERS := [["swordsman","shield","archer","thief","fanatic"],["shield","archer","mage","priest","thief","fanatic","lancer"]]
const FAMILIES := ["devour","blade","hex","poison","summon","defense","arcane"]
var rng := RandomNumberGenerator.new()
var enemies: Array = []
var projectiles: Array = []
var effects: Array = []
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

func _init(seed_value: int = 1) -> void:
 rng.seed = seed_value
 enemy_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))
 balance = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json"))
 for i in MAX_ENEMIES:
  enemies.append({"index":i, "active": false, "pos": Vector2.ZERO, "hp": 0.0, "max_hp": 0.0, "cooldown": 0.0, "speed": 0.0, "damage": 0.0, "kind": "swordsman", "boss": false, "poison": 0.0, "mark": 0, "dot_tick": 0.0, "phase": 0, "timer": 0.0})
 for i in MAX_PROJECTILES:
  projectiles.append({"active": false, "pos": Vector2.ZERO, "vel": Vector2.ZERO, "ttl": 0.0, "damage": 0.0, "enemy": false, "family": "", "pierce": 0})
 for i in MAX_EFFECTS:
  effects.append({"active": false, "from": Vector2.ZERO, "to": Vector2.ZERO, "ttl": 0.0, "family": "", "radius": 0.0})
 for i in 12:minions.append({"active":false,"pos":Vector2.ZERO,"ttl":0.0,"timer":0.0,"power":0.0,"side":0.0})
 for i in 192:sparks.append({"active":false,"pos":Vector2.ZERO,"vel":Vector2.ZERO,"ttl":0.0,"family":""})
 for i in MAX_ENEMIES:loot_events.append({"active":false,"kind":"","boss":false,"position":Vector2.ZERO})
 for i in 40:popups.append({"active":false,"pos":Vector2.ZERO,"value":0,"ttl":0.0})
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
   e.merge({"active":true,"pos":position,"max_hp":health,"hp":health,"speed":float(def.speed),"damage":float(def.damage)*float(balance.stage_scaling[stage].damage)*(1.0 if boss else scale),"cooldown":1.5,"kind":kind,"boss":boss,"poison":0.0,"mark":0,"dot_tick":0.0,"phase":0,"timer":0.0},true)
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
func target_index(origin: Vector2, direction: Vector2, max_range: float) -> int:
 var best := -1
 var best_dist := INF
 var best_front := -1
 var front_dist := INF
 for i in enemies.size():
  var e: Dictionary = enemies[i]
  if not e.active: continue
  var offset: Vector2 = e.pos - origin
  var d: float = offset.length()
  if d > max_range: continue
  if d < best_dist: best = i; best_dist = d
  if direction.dot(offset.normalized()) >= 0.5 and d < front_dist: best_front = i; front_dist = d
 return best_front if best_front >= 0 else best

func effect(from: Vector2, to: Vector2, family: String, radius: float = 0.0) -> void:
 for fx in effects:
  if not fx.active:
   fx.merge({"active":true,"from":from,"to":to,"ttl":0.18,"family":family,"radius":radius},true)
   return
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
func hit_enemy(index: int, amount: float, push: Vector2 = Vector2.ZERO, family: String = "devour") -> void:
 if index < 0 or index >= enemies.size() or not enemies[index].active: return
 var e: Dictionary = enemies[index]
 var value: float = amount * float(stats.damage) * float(stats.get(family,1.0))
 if e.kind=="shield": value *= 0.55
 if e.pos.distance_to(CENTER)<40 or e.kind in ["archer","mage","priest"]: value *= float(stats.stationary)
 if rng.randf() < stats.crit: value *= stats.crit_damage
 e.hp -= value
 e.pos += push
 damage_events += 1
 hitstop = maxf(hitstop,0.018)
 for pop in popups:
  if not pop.active:
   pop.active=true;pop.pos=e.pos;pop.value=int(value);pop.ttl=0.45
   break
 hp = minf(max_hp, hp + value * stats.lifesteal)
 if e.hp <= 0:
  kill_enemy(e)
  hp = minf(max_hp, hp + stats.heal_kill)
  if "curse_spread" in unique_ids and e.mark>0:
   for other in enemies:
    if other.active and other.pos.distance_to(e.pos)<100: other.mark+=e.mark

func kill_enemy(e: Dictionary) -> void:
 if not e.active:return
 e.active=false
 if family_counts.get("hex",0)>0 and family_counts.get("poison",0)>0 and e.mark>0 and e.poison>0:
  effect(e.pos,e.pos,"poison",52)
  for other in enemies:
   if other.active and other.pos.distance_to(e.pos)<52:other.hp-=8.0*float(stats.damage)
 scatter(e.pos,"blade",6)
 kills+=1
 for event in loot_events:
  if not event.active:
   event.active=true;event.kind=e.kind;event.boss=e.boss;event.position=e.pos
   break
 if e.boss: won=true;ended=true
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
 var index := target_index(CENTER, aim, reach)
 if ability == "heal":
  hp = minf(max_hp,hp + 1.0 + float(a.power)*0.1)
  effect(CENTER,CENTER,"defense",42)
  return true
 if ability in ["hide","armor"]: return false
 if index < 0: return false
 var e: Dictionary = enemies[index]
 var power: float = float(a.power)
 if family=="blade" and "extra_blades" in unique_ids:power*=1.0+family_counts.get("blade",0)*0.2
 if family=="blade" and family_counts.get("devour",0)>0:power*=1.15
 if family=="devour" and "devour_chain" in unique_ids:
  devour_chain=mini(devour_chain+1,5)
  power*=1.0+devour_chain*0.12
 if family == "devour":
  effect(CENTER,e.pos,"devour")
  hit_enemy(index,power, -((e.pos-CENTER).normalized())*10.0,"devour")
  if ability=="pull":
   for other in enemies:
    if other.active and other.pos.distance_to(e.pos)<100:other.pos+=(CENTER-other.pos).normalized()*35
  if ability=="maw" or family_counts.get("devour",0)>=4 or ("devour_chain" in unique_ids and devour_chain>=2):
   for i in enemies.size():
    if i!=index and enemies[i].active and enemies[i].pos.distance_to(e.pos)<65: hit_enemy(i,power*0.5,Vector2.ZERO,"devour")
 elif family == "blade":
  var blade_center:Vector2=CENTER+aim*45
  effect(CENTER,blade_center,"blade",90 if ability=="orbit" else 60)
  for i in enemies.size():
   var other: Dictionary = enemies[i]
   if other.active and ((ability=="orbit" and other.pos.distance_to(blade_center)<105) or (ability!="orbit" and other.pos.distance_to(CENTER)<reach and aim.dot((other.pos-CENTER).normalized())>0.4)):
    hit_enemy(i,power,(other.pos-CENTER).normalized()*9,"blade")
    if ability == "pierce": continue
    if ability != "orbit" and family_counts.get("blade",0)<4 and "cleave" not in unique_ids and "extra_blades" not in unique_ids: break
 elif family == "hex":
  e.mark += 1
  if ability=="mark" and e.mark>=3:
   power*=2.0
   e.mark=1
  if family_counts.get("hex",0)>=4 or "curse_chain" in unique_ids:
   for other in enemies:
    if other.active and other!=e and other.pos.distance_to(e.pos)<90: other.mark+=1
  effect(CENTER,e.pos,"hex",18)
  hit_enemy(index,power,Vector2.ZERO,"hex")
  if stats.chain > 0:
   var chains:int=0
   for i in enemies.size():
    if i!=index and enemies[i].active and enemies[i].pos.distance_to(e.pos)<100:
     effect(e.pos,enemies[i].pos,"hex")
     hit_enemy(i,power*0.5,Vector2.ZERO,"hex")
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
    other.poison = maxf(other.poison,4.0)
    if family_counts.get("poison",0)>=4 or "poison_burst" in unique_ids: other.hp -= power*0.4
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
    if enemies[i].active and enemies[i].pos.distance_to(center)<80*float(stats.area): hit_enemy(i,power*(1.5 if "double_nova" in unique_ids else 1.0),Vector2.ZERO,"arcane")
  else:
   projectile(CENTER,(e.pos-CENTER).normalized(),power,"arcane")
   for extra in mini(4,int(stats.projectiles)): projectile(CENTER,(e.pos-CENTER).normalized().rotated(0.1*(extra+1)),power*0.7,"arcane")
   if family_counts.get("arcane",0)>=4: projectile(CENTER,(e.pos-CENTER).normalized().rotated(0.16),power*0.8,"arcane")
 if family_counts.get(family,0)>=4: effect(CENTER,CENTER+aim*80,family,35)
 shots += 1
 return true

func update(delta: float) -> void:
 if ended: return
 if hitstop>0: hitstop-=delta;return
 elapsed += delta
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
 for a in abilities:
  a.timer -= delta
  if a.timer <= 0.0 and cast(a): a.timer = float(a.cooldown)/float(stats.speed)
 for e in enemies:
  if not e.active: continue
  if e.poison>0:
   e.poison -= delta
   e.dot_tick -= delta
   if e.dot_tick<=0:
    e.hp -= 3.0 * float(stats.dot) * float(stats.poison)
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
 for minion in minions:
  if not minion.active:continue
  minion.ttl-=delta;minion.timer-=delta
  minion.pos=CENTER+aim*75+aim.orthogonal()*float(minion.side)
  if minion.ttl<=0:minion.active=false;continue
  if minion.timer<=0:
   var target:int=target_index(minion.pos,aim,350)
   if target>=0:
    projectile(minion.pos,(enemies[target].pos-minion.pos).normalized(),minion.power,"summon")
    if family_counts.get("arcane",0)>0:projectile(minion.pos,(enemies[target].pos-minion.pos).normalized().rotated(0.12),minion.power*0.5,"arcane")
    minion.timer=1.0
 for p in projectiles:
  if not p.active: continue
  if not p.enemy and p.family=="arcane":
   var target := target_index(p.pos,aim,400.0)
   if target>=0:p.vel=p.vel.lerp((enemies[target].pos-p.pos).normalized()*420.0,minf(1.0,delta*2.0))
  p.pos += p.vel * delta
  p.ttl -= delta
  if p.ttl<=0: p.active=false; continue
  if p.enemy:
   if p.pos.distance_to(CENTER)<30:
    hurt_player(p.damage); p.active=false
  else:
   for i in enemies.size():
    if enemies[i].active and enemies[i].pos.distance_to(p.pos)<16:
     hit_enemy(i,p.damage,p.vel.normalized()*8,p.family)
     if p.pierce>0: p.pierce-=1
     else: p.active=false
     break
 for spark in sparks:
  if spark.active:
   spark.pos+=spark.vel*delta;spark.vel*=0.95;spark.ttl-=delta
   if spark.ttl<=0:spark.active=false
 for pop in popups:
  if pop.active:
   pop.ttl-=delta;pop.pos.y-=delta*30
   if pop.ttl<=0:pop.active=false
 for fx in effects:
  if fx.active:
   if fx.family=="poison" and fx.ttl>0.2:
    for enemy in enemies:
     if enemy.active and enemy.pos.distance_to(fx.to)<fx.radius:enemy.poison=maxf(enemy.poison,1.5)
   fx.ttl-=delta
   if fx.ttl<=0: fx.active=false
 if hp <= 0: hp=0; ended=true
 elif elapsed >= RUN_SECONDS: ended=true
