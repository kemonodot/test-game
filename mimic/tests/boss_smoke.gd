extends SceneTree
const Combat=preload("res://src/combat.gd")
const Profile=preload("res://src/profile.gd")
func _initialize() -> void:
 var p=Profile.new(false)
 for stage in 2:
  var b=Combat.new(17)
  b.stage=stage
  b.elapsed=240
  b.update(0.01)
  assert(b.boss_spawned)
  var boss:Dictionary={}
  for e in b.enemies:
   if e.active and e.boss:boss=e;break
  assert(not boss.is_empty())
  assert(boss.kind==("hero" if stage==0 else "captain"))
  var idx:int=b.enemies.find(boss)
  b.hit_enemy(idx,1000000)
  assert(b.ended and b.won)
  assert(b.loot_events.any(func(x):return x.active and x.boss))
 var c=Combat.new(3)
 c.configure([p.get_template("lastshell")])
 c.hurt_player(99999)
 assert(c.hp>0 and c.last_stand_used)
 c.hurt_player(99999)
 assert(c.hp<=0)
 print("BOSS SMOKE: two stages, boss victory, boss drop, legendary survival passed")
 quit(0)
