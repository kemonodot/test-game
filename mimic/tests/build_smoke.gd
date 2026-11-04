extends SceneTree
const Combat = preload("res://src/combat.gd")
const Profile = preload("res://src/profile.gd")
func _initialize() -> void:
 var p = Profile.new(false)
 var keys := ["bite","cleaver","eyefang","acidfang","callfang","spikefang","sparkfang"]
 for key in keys:
  var b = Combat.new(40)
  var t: Dictionary = p.get_template(key)
  b.configure([t])
  b.spawn_enemy("swordsman",Vector2(760,360))
  b.spawn_enemy("swordsman",Vector2(560,360))
  b.aim = Vector2.RIGHT
  b.update(0.01)
  assert(b.shots > 0, "%s did not attack" % key)
  if t.family=="devour":
   b.abilities.clear()
   for i in 5:b.update(0.05)
  if t.family in ["devour","blade","hex"]: assert(b.enemies[0].hp < b.enemies[1].hp, "%s did not favor aim" % key)
  if t.family == "poison": assert(b.enemies[0].poison > b.enemies[1].poison)
  if t.family in ["summon","arcane"]: assert(b.projectiles.any(func(x):return x.active and x.vel.x > 0))
 var set = Combat.new(9)
 set.configure([p.get_template("bite"),p.get_template("tongue"),p.get_template("mouth"),p.get_template("jaw")])
 assert(set.family_counts.devour == 4 and set.stats.devour > 1.0)
 print("BUILD SMOKE: seven aimed families and four-piece set passed")
 quit(0)
