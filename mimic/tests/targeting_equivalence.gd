extends SceneTree
const Combat=preload("res://src/combat.gd")
func reference(b,origin:Vector2,direction:Vector2,max_range:float)->int:
 var best:=-1;var best_dist:=INF;var best_front:=-1;var front_dist:=INF
 for i in b.enemies.size():
  var e:Dictionary=b.enemies[i]
  if not e.active:continue
  var offset:Vector2=e.pos-origin
  var d:float=offset.length()
  if d>max_range:continue
  if d<best_dist:best=i;best_dist=d
  if direction.dot(offset.normalized())>=0.5 and d<front_dist:best_front=i;front_dist=d
 return best_front if best_front>=0 else best
func _initialize()->void:
 var b=Combat.new(90210);var r=RandomNumberGenerator.new();r.seed=101
 for i in 120:
  b.spawn_enemy("swordsman",Vector2(r.randf_range(-100,1380),r.randf_range(-100,820)))
 b.enemies[0].pos=Vector2(640,360)
 for i in 3000:
  var origin:=Vector2(640,360) if i%7==0 else Vector2(r.randf_range(0,1280),r.randf_range(0,720))
  var direction:=Vector2.from_angle(r.randf_range(0,TAU))
  var distance:float=[0.0,50.0,400.0,2000.0][i%4]
  var expected:int=reference(b,origin,direction,distance)
  b.target_cache_active=false
  assert(b.target_index(origin,direction,distance)==expected,"linear mismatch %d"%i)
  b.sync_target_cache()
  b.target_cache_active=true
  assert(b.target_index(origin,direction,distance)==expected,"cache mismatch %d"%i)
 # A knockback, death and reuse of a pool slot must immediately update the snapshot.
 b.target_cache_active=true
 b.sync_target_cache()
 var moved:int=b.target_index(Vector2(640,360),Vector2.RIGHT,2000)
 b.hit_enemy(moved,0.01,Vector2(400,80))
 assert(b.target_index(Vector2(640,360),Vector2.RIGHT,2000)==reference(b,Vector2(640,360),Vector2.RIGHT,2000))
 b.hit_enemy(moved,1000000)
 assert(b.target_index(Vector2(640,360),Vector2.RIGHT,2000)==reference(b,Vector2(640,360),Vector2.RIGHT,2000))
 assert(b.spawn_enemy("swordsman",Vector2(641,360)))
 assert(b.target_index(Vector2(640,360),Vector2.RIGHT,2000)==reference(b,Vector2(640,360),Vector2.RIGHT,2000))
 print("TARGETING EQUIVALENCE: 3000 seeded comparisons plus knockback, death and reuse passed")
 quit(0)
