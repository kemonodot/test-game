extends SceneTree
const Combat=preload("res://src/combat.gd")
func _initialize()->void:
 var b=Combat.new(1);b.stats.crit=0;b.abilities.clear();b.spawn_budget=-1000
 b.spawn_enemy("swordsman",Vector2(800,360));b.enemies[0].hp=10
 b.hit_enemy(0,100,Vector2.ZERO,"devour",false,Combat.CENTER,"devour")
 assert(is_equal_approx(b.metric_damage,10) and is_equal_approx(b.metric_raw_damage,100) and is_equal_approx(b.metric_set_damage.devour,10))
 var c=Combat.new(2);c.stats.crit=0;c.abilities.clear();c.spawn_budget=-1000
 c.spawn_enemy("swordsman",Vector2(800,360));c.enemies[0].hp=10
 c.metric_record_damage(c.enemies[0],16,"hex_half")
 assert(is_equal_approx(c.metric_damage,10) and is_equal_approx(c.metric_set_damage.hex,2))
 var incoming=Combat.new(3);incoming.abilities.clear();incoming.spawn_budget=-1000
 incoming.projectile(Combat.CENTER+Vector2(35,0),Vector2.LEFT,6,"enemy",true,"archer")
 incoming.update(.05)
 assert(incoming.metric_incoming.size()==1 and incoming.metric_incoming[0].kind=="archer" and is_equal_approx(incoming.metric_incoming[0].hp_loss,6.0))
 print("INSTRUMENTATION: effective/raw/overkill, set marginal, enemy projectile attribution passed")
 quit(0)
