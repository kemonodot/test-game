extends SceneTree
const Combat=preload("res://src/combat.gd")
const Profile=preload("res://src/profile.gd")
func _initialize()->void:
 var p=Profile.new(false)
 var ids=["kingtongue","thousand","carnivore","gland","lastshell","cursejewel"]
 var equip:=[]
 for id in ids:
  var t:Dictionary=p.get_template(id).duplicate(true)
  t.item={"level":10,"rarity":4,"affixes":[],"sockets":[]}
  equip.append(t)
 for stage in 2:
  var b=Combat.new(100+stage)
  b.stage=stage;b.configure(equip,{"hp":10,"damage":10})
  var frames:=0
  while not b.ended and frames<8000:
   var target:int=b.target_index(Combat.CENTER,b.aim,1000.0)
   if target>=0:b.aim=(b.enemies[target].pos-Combat.CENTER).normalized()
   b.update(0.05);frames+=1
  print("stage=%d elapsed=%.1f kills=%d hp=%.1f boss=%s won=%s"%[stage,b.elapsed,b.kills,b.hp,b.boss_spawned,b.won])
 quit(0)
