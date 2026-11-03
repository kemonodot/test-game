extends SceneTree
# Original, hand-positioned native-resolution pixel clusters. Assets can be replaced at these paths.
const INK=Color("100a10")
const DARK=Color("2b1820")
const WOOD=Color("563128")
const RED=Color("9c3943")
const GLOW=Color("db5961")
const GOLD=Color("a77b50")
const LIGHT=Color("dfc9a9")
const WHITE=Color("f3ead6")
const PURPLE=Color("705674")
const GREEN=Color("536a51")
func box(im:Image,x:int,y:int,w:int,h:int,c:Color)->void: im.fill_rect(Rect2i(x,y,w,h),c)
func save(im:Image,path:String)->void: assert(im.save_png(path)==OK)
func _initialize()->void:
 var chest=Image.create_empty(128,128,false,Image.FORMAT_RGBA8)
 chest.fill(Color.TRANSPARENT)
 box(chest,17,44,94,65,INK);box(chest,20,48,88,57,WOOD);box(chest,23,51,82,49,DARK)
 box(chest,26,55,76,42,WOOD)
 for y in [59,69,79,89,98]:
  box(chest,27,y,74,2,DARK);box(chest,31,y+2,26,1,GOLD);box(chest,70,y+2,27,1,Color("865143"))
 box(chest,13,34,102,24,INK);box(chest,16,31,96,24,GOLD);box(chest,21,34,86,18,WOOD);box(chest,25,36,78,12,RED);box(chest,28,38,69,3,Color("c35c55"));box(chest,20,49,88,5,INK)
 for x in [26,93]:
  box(chest,x,32,8,69,INK);box(chest,x+1,34,5,64,GOLD);box(chest,x+1,35,2,57,LIGHT)
  for y in [39,51,92]:box(chest,x+2,y,2,2,WHITE)
 box(chest,26,56,76,24,INK);box(chest,31,58,66,18,Color("591e2e"));box(chest,34,63,60,10,RED);box(chest,36,68,56,5,DARK)
 for x in range(34,94,10):
  box(chest,x,57,6,4,LIGHT);box(chest,x+1,61,4,3,WHITE);box(chest,x+2,64,2,2,LIGHT)
  box(chest,x+3,72,5,4,LIGHT);box(chest,x+4,69,3,3,WHITE)
 box(chest,51,73,26,6,RED);box(chest,54,78,20,7,GLOW);box(chest,57,85,13,7,RED);box(chest,60,91,8,6,RED);box(chest,62,86,3,8,GLOW)
 box(chest,47,35,12,7,INK);box(chest,69,35,12,7,INK);box(chest,50,37,7,4,GLOW);box(chest,72,37,7,4,GLOW);box(chest,53,38,2,2,WHITE);box(chest,75,38,2,2,WHITE)
 box(chest,52,100,24,7,INK);box(chest,55,101,18,4,GOLD);box(chest,61,99,6,7,LIGHT)
 for x in [17,99]:box(chest,x,104,13,6,INK);box(chest,x+2,106,9,4,GOLD)
 save(chest,"res://assets/art/mimic_base.png")
 var families=["devour","blade","hex","poison","summon","defense","arcane"]
 for fam in families:
  var im=Image.create_empty(128,128,false,Image.FORMAT_RGBA8);im.fill(Color.TRANSPARENT)
  match fam:
   "devour":
    box(im,58,75,12,28,RED);box(im,61,94,8,13,GLOW);box(im,64,102,5,9,RED);box(im,62,80,3,20,LIGHT)
   "blade":
    for side in [-1,1]:
     var x=6 if side<0 else 109
     box(im,x,49,13,10,INK);box(im,x+3,45,7,22,GOLD);box(im,x+5,22,3,29,LIGHT);box(im,x+6,17,2,6,WHITE)
   "hex":
    for x in [35,61,87]:
     box(im,x-6,16,12,10,INK);box(im,x-4,18,8,6,RED);box(im,x-2,19,4,4,GLOW);box(im,x-1,20,2,2,WHITE)
   "poison":
    for x in [24,40,81,98]:
     box(im,x,87,7,11,GREEN);box(im,x+1,96,4,8,Color("78845c"));box(im,x+2,102,2,5,GREEN)
   "summon":
    for x in [1,110]:
     box(im,x,91,17,13,INK);box(im,x+2,93,13,9,WOOD);box(im,x+3,97,11,3,RED);box(im,x+4,96,2,2,WHITE);box(im,x+10,96,2,2,WHITE)
   "defense":
    for x in [14,102]:box(im,x,56,12,42,INK);box(im,x+2,58,8,38,GOLD);box(im,x+3,61,2,31,LIGHT)
    box(im,31,26,66,7,INK);box(im,34,28,60,4,GOLD)
   "arcane":
    for x in [20,104]:
     box(im,x,16,4,16,PURPLE);box(im,x-6,22,16,4,PURPLE);box(im,x-2,20,8,8,GLOW);box(im,x,22,4,4,WHITE)
  save(im,"res://assets/art/parts/%s.png" % fam)
 var colors={"swordsman":Color("c4aaa0"),"shield":Color("9298a6"),"archer":Color("a7a36d"),"mage":Color("ad84be"),"priest":Color("ddd2b7"),"thief":Color("aa7c75"),"fanatic":Color("c4504c"),"lancer":Color("c5a173"),"hero":Color("e5bd72"),"captain":Color("e0d1d3")}
 for kind in colors:
  var im=Image.create_empty(64,64,false,Image.FORMAT_RGBA8);im.fill(Color.TRANSPARENT)
  var base:Color=colors[kind]
  box(im,18,10,28,44,INK);box(im,22,12,20,15,base);box(im,24,14,16,10,LIGHT);box(im,23,24,18,5,INK)
  box(im,21,29,22,17,base);box(im,24,31,16,12,DARK);box(im,27,32,10,3,base);box(im,19,34,5,14,base);box(im,40,34,5,14,base)
  box(im,22,45,8,12,INK);box(im,34,45,8,12,INK);box(im,23,46,5,9,base);box(im,36,46,5,9,base)
  box(im,27,19,3,2,INK);box(im,35,19,3,2,INK);box(im,30,25,5,2,RED)
  match kind:
   "shield":box(im,10,31,16,21,GOLD);box(im,13,34,10,15,base);box(im,17,34,2,15,LIGHT)
   "archer":box(im,46,25,3,25,GOLD);box(im,49,28,2,19,LIGHT)
   "mage":box(im,17,8,30,5,PURPLE);box(im,21,4,22,5,PURPLE);box(im,29,0,8,7,GOLD)
   "priest":box(im,28,30,7,14,WHITE);box(im,24,34,15,4,WHITE)
   "thief":box(im,21,19,22,6,DARK);box(im,25,20,3,2,WHITE);box(im,36,20,3,2,WHITE)
   "fanatic":box(im,20,9,24,6,RED);box(im,28,12,8,13,RED)
   "lancer":box(im,45,10,3,43,GOLD);box(im,44,6,5,6,LIGHT)
   "hero":box(im,20,7,24,5,GOLD);box(im,24,2,4,8,GOLD);box(im,36,2,4,8,GOLD);box(im,46,18,4,34,LIGHT)
   "captain":box(im,19,5,26,7,LIGHT);box(im,29,0,6,13,GOLD);box(im,10,30,15,24,LIGHT);box(im,14,34,7,15,RED)
  save(im,"res://assets/art/enemies/%s.png" % kind)
 for fam in families:
  var im=Image.create_empty(48,48,false,Image.FORMAT_RGBA8);im.fill(Color.TRANSPARENT)
  box(im,5,5,38,38,INK);box(im,7,7,34,34,DARK);box(im,9,9,30,30,WOOD)
  match fam:
   "devour":box(im,13,17,22,16,RED);box(im,17,16,4,6,WHITE);box(im,27,16,4,6,WHITE);box(im,22,24,6,12,GLOW)
   "blade":box(im,22,9,4,27,LIGHT);box(im,15,31,18,4,GOLD);box(im,21,34,6,5,WOOD)
   "hex":box(im,11,19,26,10,PURPLE);box(im,16,16,16,16,RED);box(im,21,19,6,10,WHITE)
   "poison":box(im,18,10,12,6,GREEN);box(im,14,16,20,21,GREEN);box(im,17,22,14,12,Color("8a986c"))
   "summon":box(im,12,19,24,18,WOOD);box(im,14,16,20,5,GOLD);box(im,16,25,16,5,RED);box(im,18,23,3,3,WHITE);box(im,27,23,3,3,WHITE)
   "defense":box(im,13,12,22,22,GOLD);box(im,16,15,16,17,LIGHT);box(im,20,31,8,7,GOLD)
   "arcane":box(im,20,9,8,30,PURPLE);box(im,9,20,30,8,PURPLE);box(im,18,18,12,12,GLOW);box(im,21,21,6,6,WHITE)
  save(im,"res://assets/art/icons/%s.png" % fam)
 print("Original pixel assets created at 128, 64 and 48 pixels")
 quit(0)
