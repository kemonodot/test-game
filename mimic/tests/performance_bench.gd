extends SceneTree
# Repeatable CPU-only workloads. Browser/GPU frame rate is measured separately.
const Profile=preload("res://src/profile.gd")
func _initialize()->void:
 var p=Profile.new(false)
 var battle_path:String=OS.get_environment("MIMIC_BATTLE_PATH")
 if battle_path.is_empty():battle_path="res://src/combat.gd"
 var Battle=load(battle_path)
 var items=[]
 for id in ["sparkfang","orb","seeker","nova","gland","eye"]:items.append(p.get_template(id))
 for projectile_count in [0,24,80]:
  var b=Battle.new(7201)
  b.configure(items);b.debug_invulnerable=true;b.elapsed=120;b.spawn_budget=-10000
  for i in 120:
   var angle:float=TAU*float(i)/120.0
   var r:float=160.0+float((i%5)*45)
   b.spawn_enemy("swordsman",Vector2(640,360)+Vector2.from_angle(angle)*r)
   b.enemies[i].hp=10000000;b.enemies[i].max_hp=10000000
  # Keep the projectile pressure stable to compare identical workloads.
  var elapsed_us:int=0
  for frame in 900:
   for i in projectile_count:
    var q:Dictionary=b.projectiles[i]
    q.active=true;q.pos=Vector2(640,360)+Vector2.from_angle(TAU*float(i)/maxi(1,projectile_count))*120
    q.vel=Vector2.from_angle(TAU*float(i)/maxi(1,projectile_count))*420;q.ttl=2.0;q.damage=1;q.enemy=false;q.family="arcane";q.pierce=100
   b.hitstop=0
   var started:int=Time.get_ticks_usec()
   b.update(1.0/60.0)
   if frame>=120:elapsed_us+=Time.get_ticks_usec()-started
  print("120 enemies, %d homing projectiles: %.3f ms/update"%[projectile_count,float(elapsed_us)/780000.0])
 quit(0)
