extends SceneTree
const Combat=preload("res://src/combat.gd")
const Profile=preload("res://src/profile.gd")
func _initialize()->void:
 var p=Profile.new(false);var b=Combat.new(1)
 b.configure([p.get_template("bite"),p.get_template("mouth"),p.get_template("suction"),p.get_template("hunger")]);b.stats.crit=0
 b.spawn_enemy("swordsman",Vector2(800,360));b.enemies[0].hp=1000.0
 var initial:float=b.enemies[0].hp
 b.cast(b.abilities[0])
 var visual_count:=0
 for fx in b.effects:
  if fx.active and fx.family=="devour":visual_count+=1
 assert(visual_count==1,"Four-piece bonus should not draw a second tongue for one attack")
 var damage_after_first:float=b.enemies[0].hp
 b.cast(b.abilities[1])
 assert(b.enemies[0].hp<damage_after_first and damage_after_first<initial,"Different equipped abilities must still attack independently")
 print("DEVOUR EFFECT: one tongue per ability; separate equipped attacks still deal damage")
 quit(0)
