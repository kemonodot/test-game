extends SceneTree
const Combat=preload("res://src/combat.gd")
func _initialize()->void:
 var b=Combat.new(10);b.stats.crit=0
 b.spawn_enemy("swordsman",Vector2(750,360));b.enemies[0].hp=1000
 b.hit_enemy(0,10);b.hit_enemy(0,10);b.hit_enemy(0,10)
 var used=b.popups.filter(func(p):return p.active)
 assert(used.size()==1 and used[0].value==30)
 used[0].ttl=0.1
 b.hit_enemy(0,10)
 assert(is_equal_approx(used[0].ttl,0.1) and used[0].value==40)
 assert(b.popups.size()==16)
 var first_generation:int=b.enemies[0].generation
 b.hit_enemy(0,10000)
 assert(b.spawn_enemy("swordsman",Vector2(750,360)))
 assert(b.enemies[0].generation!=first_generation)
 b.hit_enemy(0,10)
 used=b.popups.filter(func(p):return p.active)
 assert(used.size()==2 and used[1].value==10)
 print("DAMAGE DISPLAY: repeated hits aggregate; reused enemy slots remain separate")
 quit(0)
