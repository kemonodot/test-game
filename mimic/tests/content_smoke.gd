extends SceneTree
const Profile=preload("res://src/profile.gd")
const Combat=preload("res://src/combat.gd")
func _initialize()->void:
 var p=Profile.new(false)
 var unique_ids:=[]
 var normal:=0
 for t in p.templates:
  if t.has("unique"):
   assert(t.unique not in unique_ids)
   unique_ids.append(t.unique)
   var b=Combat.new(10)
   b.configure([t])
   assert(t.unique in b.unique_ids)
  else:normal+=1
 assert(unique_ids.size()==10 and normal>=40)
 assert(p.affix_defs.size()>=20)
 var b=Combat.new(20)
 var kinds=["swordsman","shield","archer","mage","priest","thief","fanatic","lancer"]
 for kind in kinds: assert(b.spawn_enemy(kind))
 for i in kinds.size():
  assert(b.enemies[i].kind==kinds[i])
  var at:Vector2=b.enemies[i].pos
  assert(at.x<0 or at.x>1280 or at.y<0 or at.y>720)
 var base=load("res://assets/art/mimic_base.png")
 assert(base.get_size()==Vector2(128,128))
 for family in Profile.FAMILIES:
  var icon=load("res://assets/art/icons/%s.png"%family)
  var part=load("res://assets/art/parts/%s.png"%family)
  assert(icon.get_size()==Vector2(48,48) and part.get_size()==Vector2(128,128))
 for kind in kinds:
  var sprite=load("res://assets/art/enemies/%s.png"%kind)
  assert(sprite.get_size()==Vector2(64,64))
 print("CONTENT SMOKE: 44 normal items, 10 legendary IDs, 23 affixes, eight enemy types and asset sizes passed")
 quit(0)
