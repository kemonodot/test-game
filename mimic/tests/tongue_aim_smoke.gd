extends SceneTree
const Combat=preload("res://src/combat.gd")
const Profile=preload("res://src/profile.gd")
func _initialize()->void:
 var profile=Profile.new(false)
 var battle=Combat.new(6);battle.configure(profile.equipped_templates());battle.stats.crit=0
 battle.spawn_enemy("swordsman",Combat.CENTER+Vector2(200,60))
 battle.spawn_enemy("swordsman",Combat.CENTER+Vector2(160,75))
 battle.spawn_enemy("swordsman",Combat.CENTER+Vector2(-160,0))
 var first:float=battle.enemies[0].hp
 var outside:float=battle.enemies[1].hp
 var behind:float=battle.enemies[2].hp
 battle.aim=Vector2.RIGHT
 battle.cast(battle.abilities[0])
 assert(battle.enemies[0].hp<first,"Enemy 60px to the side should be struck")
 assert(battle.enemies[1].hp==outside,"Enemy outside the corridor should not be struck")
 assert(battle.enemies[2].hp==behind,"Manual aim must not hit behind the mimic")
 var found:=false
 for fx in battle.effects:
  if fx.active and fx.family=="devour":
   found=true
   assert(fx.to==Combat.CENTER+Vector2(200,60))
   assert(is_equal_approx(fx.ttl,Combat.TONGUE_DURATION))
 assert(found)
 print("TONGUE: wider aimed corridor, directional boundary and visual target passed")
 quit(0)
