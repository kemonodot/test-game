extends SceneTree
const Combat=preload("res://src/combat.gd")
const Profile=preload("res://src/profile.gd")
func _initialize()->void:
 var p=Profile.new(false)
 for n in 5:
  var b=Combat.new(100+n)
  b.configure(p.equipped_templates())
  var frames:=0
  while not b.ended and frames<8000:
   var target:int=b.target_index(Combat.CENTER,b.aim,1000.0)
   if target>=0:b.aim=(b.enemies[target].pos-Combat.CENTER).normalized()
   b.update(0.05)
   frames+=1
  print("seed=%d elapsed=%.1f kills=%d hp=%.1f won=%s"%[100+n,b.elapsed,b.kills,b.hp,b.won])
 quit(0)
