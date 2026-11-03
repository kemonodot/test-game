extends SceneTree
const Combat=preload("res://src/combat.gd")
const Profile=preload("res://src/profile.gd")
func _initialize()->void:
 var b=Combat.new(21);b.spawn_budget=-1000;b.stats.crit=0
 b.spawn_enemy("swordsman",Vector2(520,360));b.aim=Vector2.RIGHT
 var before:float=b.enemies[0].hp
 b.update(.1)
 assert(b.shots==1 and b.enemies[0].hp==before,"Auto-fire must not aim behind the player")
 assert(b.target_index(Combat.CENTER,Vector2.RIGHT,500)==-1)
 b.aim=Vector2.LEFT;b.hitstop=0;b.update(.7)
 assert(b.enemies[0].hp<before,"Attack must hit when aimed at the enemy")
 var p=Profile.new(false);var magic=Combat.new(10)
 magic.spawn_budget=-1000;magic.configure([p.get_template("sparkfang")]);magic.aim=Vector2.RIGHT
 magic.spawn_enemy("swordsman",Vector2(750,420));magic.update(.01)
 var shot:Dictionary={}
 for projectile in magic.projectiles:
  if projectile.active and not projectile.enemy:shot=projectile;break
 assert(not shot.is_empty() and is_zero_approx(shot.vel.y),"Projectile must fire along aim")
 magic.aim=Vector2.UP;magic.update(.05)
 assert(is_zero_approx(shot.vel.y),"Already-fired projectile must not home on enemies")
 var bomb=Combat.new(2);bomb.spawn_budget=-1000;bomb.stats.crit=0;bomb.aim=Vector2.RIGHT
 bomb.spawn_enemy("swordsman",Vector2(800,360));bomb.spawn_enemy("swordsman",Vector2(480,360))
 assert(bomb.use_bomb() and not bomb.enemies[0].active and bomb.enemies[1].active)
 assert(not bomb.use_bomb() and bomb.bomb_remaining>0)
 var event:Dictionary={}
 for loot in bomb.loot_events:
  if loot.active:event=loot;break
 assert(not event.is_empty() and event.bomb,"Only bomb kills get the bonus flag")
 bomb.hitstop=0;bomb.update(Combat.BOMB_COOLDOWN)
 assert(bomb.bomb_remaining==0 and bomb.use_bomb())
 print("MANUAL AIM + BOMB: no auto-turn, straight fire, aimed blast and cooldown passed")
 quit(0)
