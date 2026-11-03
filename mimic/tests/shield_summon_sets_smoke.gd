extends SceneTree
const Combat=preload("res://src/combat.gd")
const Profile=preload("res://src/profile.gd")
func hit_from(source:Vector2)->float:
 var b=Combat.new(7);b.stats.crit=0;b.spawn_enemy("shield",Vector2(800,360))
 b.hit_enemy(0,10,Vector2.ZERO,"devour",false,source)
 return b.enemies[0].max_hp-b.enemies[0].hp
func summon_case(count:int) -> Array:
 var p=Profile.new(false);var b=Combat.new(1)
 var gear:=[]
 for id in ["callfang","minion","ghost","broodcore"].slice(0,count):gear.append(p.get_template(id))
 b.configure(gear);b.abilities.clear();b.stats.crit=0;b.spawn_budget=-10000
 for pos in [Vector2(721,360),Vector2(750,390),Vector2(840,360)]:
  b.spawn_enemy("swordsman",pos)
 for enemy in b.enemies:
  if enemy.active:enemy.hp=1000;enemy.max_hp=1000;enemy.speed=0
 b.projectile(Vector2(700,360),Vector2.RIGHT,20,"summon")
 b.update(0.05)
 return [b.enemies[0].hp,b.enemies[1].hp,b.enemies[2].hp,b.effects]
func _initialize()->void:
 var pos:=Vector2(800,360)
 assert(is_equal_approx(hit_from(pos+Vector2.LEFT*100),5.5))
 assert(is_equal_approx(hit_from(pos+Vector2.from_angle(3*PI/4)*100),5.5))
 assert(is_equal_approx(hit_from(pos+Vector2.LEFT.rotated(deg_to_rad(-45.0))*100),5.5))
 assert(is_equal_approx(hit_from(pos+Vector2.LEFT.rotated(deg_to_rad(46.0))*100),10.0))
 assert(is_equal_approx(hit_from(pos+Vector2.UP*100),10.0))
 assert(is_equal_approx(hit_from(pos+Vector2.RIGHT*100),10.0))
 var projectile_test=Combat.new(2);projectile_test.stats.crit=0;projectile_test.abilities.clear();projectile_test.spawn_budget=-1000
 projectile_test.spawn_enemy("shield",pos);projectile_test.enemies[0].speed=0
 projectile_test.projectile(Vector2(821,360),Vector2.LEFT,10,"arcane")
 projectile_test.update(0.05)
 assert(is_equal_approx(projectile_test.enemies[0].max_hp-projectile_test.enemies[0].hp,10.0))
 var profile=Profile.new(false);var orbit=Combat.new(1);orbit.stats.crit=0;orbit.spawn_budget=-1000
 var spindle:Dictionary=profile.get_template("spindle")
 orbit.configure([spindle]);orbit.stats.crit=0;orbit.aim=Vector2.RIGHT
 orbit.spawn_enemy("shield",Vector2(670,360));orbit.cast(orbit.abilities[0])
 assert(is_equal_approx(orbit.enemies[0].max_hp-orbit.enemies[0].hp,float(spindle.power)))
 var poison=Combat.new(3);poison.stats.crit=0;poison.abilities.clear();poison.spawn_budget=-1000
 poison.spawn_enemy("shield",pos);poison.enemies[0].speed=0
 poison.apply_poison(poison.enemies[0],4.0,pos+Vector2.RIGHT*50)
 var before:float=poison.enemies[0].hp;poison.update(0.01)
 assert(is_equal_approx(before-poison.enemies[0].hp,3.0))
 var three:=summon_case(3);var four:=summon_case(4)
 assert(three[0]<1000 and is_equal_approx(three[1],1000.0))
 assert(four[0]<1000 and four[1]<1000 and is_equal_approx(four[2],1000.0))
 assert(is_equal_approx(1000.0-float(four[1]),(1000.0-float(four[0]))*0.5))
 assert(four[3].any(func(fx):return fx.active and fx.family=="summon" and fx.radius==Combat.SUMMON_BURST_RADIUS))
 print("SHIELD + SUMMON: front, boundary, side, back, poison and 4-piece area passed")
 quit(0)
