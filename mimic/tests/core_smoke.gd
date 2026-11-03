extends SceneTree
const Battle = preload("res://src/combat.gd")
func _initialize() -> void:
 var b = Battle.new(123)
 assert(b.enemies.size() == 120)
 assert(b.spawn_enemy("swordsman", Vector2(700,360)))
 assert(b.target_index(Battle.CENTER, Vector2.RIGHT, 300) >= 0)
 var id: int = b.target_index(Battle.CENTER, Vector2.RIGHT, 300)
 var before: float = b.enemies[id].hp
 b.update(0.1)
 assert(b.shots == 1 and b.enemies[id].hp < before)
 b.hit_enemy(id, 10000)
 assert(b.kills == 1)
 b.hp = 0
 b.hitstop = 0
 b.update(0.1)
 assert(b.ended and not b.won)
 var side = Battle.new(4)
 assert(side.spawn_enemy("swordsman",Vector2(630,360)))
 assert(side.spawn_enemy("swordsman",Vector2(680,360)))
 assert(side.target_index(Battle.CENTER,Vector2.RIGHT,100) == 1)
 print("CORE SMOKE: directional priority, automatic attacks, pool and defeat passed")
 quit(0)
