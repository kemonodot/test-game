extends SceneTree
# Original native-resolution pixel sprites. These coordinates are authored directly at 128/64/48 px.
const C={"ink":Color("10090f"),"shadow":Color("26151b"),"wood0":Color("382024"),"wood1":Color("603631"),"wood2":Color("8c5140"),"wood3":Color("b47756"),"iron0":Color("29232c"),"iron1":Color("5c5052"),"iron2":Color("8a7973"),"iron3":Color("b5a193"),"bone0":Color("8e7669"),"bone1":Color("c8ae90"),"bone2":Color("ede0c0"),"gold0":Color("5d3c31"),"gold1":Color("987052"),"gold2":Color("d2a875"),"gold3":Color("f2d4a2"),"red0":Color("431524"),"red1":Color("812536"),"red2":Color("b43c4a"),"red3":Color("ed7370"),"violet":Color("a481ad"),"green":Color("72916e"),"blue":Color("8eaec1")}
func rect(im:Image,x:int,y:int,w:int,h:int,c:String)->void: im.fill_rect(Rect2i(x,y,w,h),C[c])
func pix(im:Image,x:int,y:int,c:String)->void:
 if x>=0 and y>=0 and x<im.get_width() and y<im.get_height(): im.set_pixel(x,y,C[c])
func poly(im:Image,coords:Array,c:String)->void:
 var points:=PackedVector2Array()
 var minx:=im.get_width();var miny:=im.get_height();var maxx:=0;var maxy:=0
 for v in coords:
  points.append(v);minx=mini(minx,int(v.x));miny=mini(miny,int(v.y));maxx=maxi(maxx,int(v.x));maxy=maxi(maxy,int(v.y))
 for y in range(maxi(0,miny),mini(im.get_height(),maxy+1)):
  for x in range(maxi(0,minx),mini(im.get_width(),maxx+1)):
   if Geometry2D.is_point_in_polygon(Vector2(x+0.5,y+0.5),points):pix(im,x,y,c)
func save(im:Image,path:String)->void:
 var result:int=im.save_png(path)
 assert(result==OK)
func blank(w:int,h:int)->Image:
 var im:=Image.create_empty(w,h,false,Image.FORMAT_RGBA8);im.fill(Color.TRANSPARENT);return im
func chest_art()->Image:
 var a:=blank(128,128)
 # Cast silhouette and clawed feet are deliberately asymmetric.
 poly(a,[Vector2(9,43),Vector2(17,27),Vector2(30,20),Vector2(94,20),Vector2(111,28),Vector2(119,44),Vector2(112,52),Vector2(114,96),Vector2(108,105),Vector2(110,118),Vector2(99,116),Vector2(94,109),Vector2(34,109),Vector2(29,116),Vector2(18,119),Vector2(20,106),Vector2(14,99),Vector2(15,53)],"ink")
 for side in [0,1]:
  var x:=11 if side==0 else 96
  poly(a,[Vector2(x,101),Vector2(x+18,96),Vector2(x+21,109),Vector2(x+14,118),Vector2(x+8,113),Vector2(x,121),Vector2(x-3,116)],"wood0")
  poly(a,[Vector2(x+2,104),Vector2(x+16,100),Vector2(x+18,108),Vector2(x+13,113),Vector2(x+8,109),Vector2(x+3,116)],"wood2")
  rect(a,x+4,108,4,6,"bone1");rect(a,x+11,107,3,5,"bone1");rect(a,x+5,108,2,3,"bone2")
 # Case, planks and wear.
 poly(a,[Vector2(18,55),Vector2(109,55),Vector2(107,100),Vector2(99,106),Vector2(29,106),Vector2(21,100)],"wood0")
 rect(a,23,59,81,42,"wood1")
 for y in [61,71,81,91,99]:
  rect(a,24,y,79,2,"wood0");rect(a,28,y+2,28,1,"wood2");rect(a,65,y+3,30,1,"wood2")
 for p in [[33,64],[38,65],[46,74],[72,65],[87,75],[80,94],[34,95],[63,85],[93,97]]:
  rect(a,p[0],p[1],5,1,"wood3");rect(a,p[0]+4,p[1]+1,2,1,"wood0")
 # Raised lid with a layered rim, corner fittings and fractured planks.
 poly(a,[Vector2(15,40),Vector2(22,28),Vector2(35,22),Vector2(92,22),Vector2(105,29),Vector2(113,40),Vector2(110,54),Vector2(17,54)],"gold0")
 poly(a,[Vector2(20,39),Vector2(27,30),Vector2(38,26),Vector2(89,26),Vector2(100,31),Vector2(108,39),Vector2(106,49),Vector2(21,49)],"wood1")
 poly(a,[Vector2(26,37),Vector2(33,30),Vector2(44,28),Vector2(84,28),Vector2(96,31),Vector2(102,37),Vector2(101,46),Vector2(26,46)],"red0")
 rect(a,30,35,67,2,"red1");rect(a,35,32,47,1,"wood3");rect(a,27,43,75,2,"wood2")
 for x in [26,94]:
  rect(a,x,29,7,73,"gold0");rect(a,x+1,30,4,70,"gold1");rect(a,x+2,31,2,66,"gold2")
  for y in [34,44,56,91,99]:rect(a,x+2,y,2,2,"gold3")
 rect(a,18,48,94,6,"ink");rect(a,20,48,90,2,"gold2");rect(a,21,51,88,2,"gold0")
 # Mouth, gums and teeth; each tooth is drawn at final resolution.
 poly(a,[Vector2(25,55),Vector2(103,55),Vector2(99,79),Vector2(94,85),Vector2(34,85),Vector2(28,79)],"ink")
 poly(a,[Vector2(29,58),Vector2(99,58),Vector2(95,76),Vector2(89,80),Vector2(36,80),Vector2(32,75)],"red0")
 rect(a,31,58,66,4,"red2");rect(a,34,76,61,4,"red1")
 for x in range(33,96,9):
  poly(a,[Vector2(x,59),Vector2(x+7,59),Vector2(x+5,65),Vector2(x+3,69),Vector2(x+1,65)],"bone1")
  rect(a,x+2,60,2,4,"bone2")
  poly(a,[Vector2(x+2,80),Vector2(x+8,80),Vector2(x+7,75),Vector2(x+5,72),Vector2(x+3,76)],"bone1")
  rect(a,x+4,76,2,3,"bone2")
 # Tongue, with a serrated rim and reflected edge.
 poly(a,[Vector2(51,75),Vector2(76,75),Vector2(79,81),Vector2(75,90),Vector2(71,98),Vector2(68,110),Vector2(60,113),Vector2(56,109),Vector2(58,101),Vector2(59,91),Vector2(54,86)],"red1")
 poly(a,[Vector2(55,77),Vector2(72,77),Vector2(75,82),Vector2(69,93),Vector2(65,107),Vector2(61,109),Vector2(61,100),Vector2(63,88),Vector2(56,83)],"red2")
 rect(a,58,79,13,2,"red3");rect(a,65,86,2,14,"red3");rect(a,63,100,2,5,"red3")
 # Decorative central mask and eyes.
 poly(a,[Vector2(52,29),Vector2(76,29),Vector2(79,35),Vector2(76,42),Vector2(72,45),Vector2(71,49),Vector2(57,49),Vector2(56,45),Vector2(52,42),Vector2(49,35)],"ink")
 poly(a,[Vector2(54,31),Vector2(74,31),Vector2(76,35),Vector2(73,42),Vector2(69,43),Vector2(68,47),Vector2(60,47),Vector2(59,43),Vector2(55,42),Vector2(52,35)],"bone0")
 rect(a,55,32,18,2,"bone2");rect(a,55,35,7,4,"red1");rect(a,66,35,7,4,"red1");rect(a,57,35,3,2,"red3");rect(a,68,35,3,2,"red3");rect(a,63,38,3,4,"ink")
 rect(a,58,44,12,2,"ink");rect(a,60,44,2,3,"bone1");rect(a,65,44,2,3,"bone1")
 rect(a,45,99,38,4,"gold0");rect(a,48,99,32,2,"gold2");rect(a,59,96,10,10,"gold0");rect(a,61,98,6,6,"gold2");rect(a,63,99,2,3,"red2")
 return a
func part_art(fam:String)->Image:
 var a:=blank(128,128)
 match fam:
  "devour":
   poly(a,[Vector2(48,81),Vector2(60,79),Vector2(64,92),Vector2(61,111),Vector2(51,119),Vector2(47,114),Vector2(54,102)],"red0")
   poly(a,[Vector2(52,82),Vector2(58,82),Vector2(61,93),Vector2(58,107),Vector2(52,115),Vector2(51,112),Vector2(56,101)],"red2")
   rect(a,55,84,2,18,"red3")
  "blade":
   for side in [0,1]:
    var x:=5 if side==0 else 110
    poly(a,[Vector2(x,62),Vector2(x+9,61),Vector2(x+10,44),Vector2(x+7,20),Vector2(x+5,10),Vector2(x+2,22)],"ink")
    rect(a,x+3,23,4,31,"iron2");rect(a,x+4,15,2,33,"bone2");rect(a,x,54,10,3,"gold2");rect(a,x+3,57,4,8,"wood2")
  "hex":
   for x in [36,64,92]:
    poly(a,[Vector2(x-8,18),Vector2(x-4,13),Vector2(x+4,13),Vector2(x+8,18),Vector2(x+4,24),Vector2(x-4,24)],"ink")
    rect(a,x-4,16,8,5,"red1");rect(a,x-2,15,4,7,"red2");rect(a,x-1,17,2,3,"bone2")
  "poison":
   for x in [22,38,85,101]:
    rect(a,x,89,7,8,"green");rect(a,x+1,96,5,7,"green");rect(a,x+2,102,3,4,"green");rect(a,x+1,90,2,4,"bone1")
  "summon":
   for x in [0,109]:
    rect(a,x,91,19,15,"ink");rect(a,x+2,92,15,12,"wood1");rect(a,x+3,96,13,5,"red1");rect(a,x+4,94,3,3,"bone2");rect(a,x+11,94,3,3,"bone2");rect(a,x+4,97,2,2,"bone2");rect(a,x+10,97,2,2,"bone2")
  "defense":
   for x in [12,103]:
    poly(a,[Vector2(x,52),Vector2(x+11,48),Vector2(x+15,58),Vector2(x+13,93),Vector2(x+8,100),Vector2(x,96)],"iron0")
    rect(a,x+2,55,8,38,"iron1");rect(a,x+3,57,2,31,"iron3");rect(a,x+3,61,3,2,"bone2")
   rect(a,34,20,60,4,"gold0");rect(a,38,20,52,2,"gold2")
  "arcane":
   for x in [17,107]:
    rect(a,x,16,4,21,"violet");rect(a,x-8,24,20,4,"violet");rect(a,x-3,21,10,10,"red2");rect(a,x,23,4,5,"bone2")
 return a
func enemy_art(kind:String,base:String)->Image:
 var a:=blank(64,64)
 # Broad silhouettes, visible at actual 64px; armour edges are clustered at native resolution.
 poly(a,[Vector2(14,28),Vector2(20,21),Vector2(23,8),Vector2(39,8),Vector2(43,21),Vector2(50,27),Vector2(55,46),Vector2(48,51),Vector2(46,61),Vector2(34,61),Vector2(31,54),Vector2(28,61),Vector2(16,61),Vector2(15,51),Vector2(8,47)],"ink")
 # Cape and split lower tunic.
 poly(a,[Vector2(15,29),Vector2(25,23),Vector2(41,23),Vector2(50,29),Vector2(53,47),Vector2(46,54),Vector2(18,54),Vector2(10,47)],"red0" if kind in ["fanatic","hero","captain"] else "shadow")
 poly(a,[Vector2(18,30),Vector2(27,25),Vector2(40,25),Vector2(47,30),Vector2(48,46),Vector2(41,52),Vector2(23,52),Vector2(16,46)],base)
 poly(a,[Vector2(20,32),Vector2(42,32),Vector2(42,43),Vector2(38,48),Vector2(24,48),Vector2(20,43)],"iron0")
 rect(a,21,30,22,2,"iron3");rect(a,23,33,18,2,base);rect(a,25,37,14,1,"iron2");rect(a,24,42,16,1,"iron2")
 rect(a,18,46,28,3,"gold0");rect(a,22,46,20,1,"gold1");rect(a,30,46,4,3,"gold2")
 # Paired armoured boots and highlights.
 poly(a,[Vector2(18,48),Vector2(28,48),Vector2(29,58),Vector2(26,61),Vector2(15,61),Vector2(16,55)],"iron0")
 poly(a,[Vector2(35,48),Vector2(45,48),Vector2(47,59),Vector2(44,61),Vector2(33,61),Vector2(33,55)],"iron0")
 rect(a,19,49,7,7,base);rect(a,36,49,7,7,base);rect(a,17,58,10,1,"iron3");rect(a,35,58,9,1,"iron3")
 # Head, cheek guards, a narrow visor and different silhouettes.
 poly(a,[Vector2(19,15),Vector2(22,8),Vector2(26,6),Vector2(38,6),Vector2(43,10),Vector2(46,16),Vector2(44,24),Vector2(40,28),Vector2(23,28),Vector2(19,24)],"iron0")
 poly(a,[Vector2(22,14),Vector2(25,9),Vector2(38,9),Vector2(42,14),Vector2(41,22),Vector2(37,26),Vector2(26,26),Vector2(22,22)],base)
 rect(a,25,10,12,2,"iron3");rect(a,22,16,20,3,"ink");rect(a,24,17,4,1,"bone2");rect(a,35,17,4,1,"bone2");rect(a,25,21,14,3,"iron0");rect(a,29,22,6,1,"bone0")
 poly(a,[Vector2(13,29),Vector2(20,27),Vector2(22,35),Vector2(19,45),Vector2(11,46),Vector2(10,39)],base)
 poly(a,[Vector2(44,28),Vector2(51,29),Vector2(54,39),Vector2(52,46),Vector2(44,44),Vector2(42,35)],base)
 rect(a,14,31,3,9,"iron3");rect(a,47,31,3,9,"iron3");rect(a,10,42,8,3,"iron0");rect(a,46,42,8,3,"iron0")
 match kind:
  "swordsman":
   rect(a,29,5,6,7,"red1");rect(a,30,2,4,4,"red2");rect(a,53,13,4,35,"iron2");rect(a,54,10,2,29,"bone2");rect(a,49,40,12,3,"gold2");rect(a,53,43,4,8,"wood2")
  "shield":
   poly(a,[Vector2(3,28),Vector2(16,24),Vector2(27,29),Vector2(27,47),Vector2(17,57),Vector2(6,50)],"gold0")
   poly(a,[Vector2(6,30),Vector2(16,27),Vector2(24,31),Vector2(23,46),Vector2(17,53),Vector2(9,48)],"iron1")
   rect(a,15,30,3,19,"bone1");rect(a,10,37,13,2,"bone1");rect(a,8,32,2,10,"iron3")
  "archer":
   poly(a,[Vector2(17,18),Vector2(20,9),Vector2(26,5),Vector2(38,5),Vector2(44,10),Vector2(46,18),Vector2(41,15),Vector2(37,11),Vector2(25,11),Vector2(21,17)],"wood0")
   rect(a,51,22,2,26,"gold1");rect(a,48,20,4,3,"gold2");rect(a,48,47,4,3,"gold2");rect(a,55,25,1,21,"bone1");rect(a,46,34,12,2,"bone1")
  "mage":
   poly(a,[Vector2(13,16),Vector2(23,11),Vector2(30,1),Vector2(34,0),Vector2(44,13),Vector2(51,17)],"shadow")
   poly(a,[Vector2(18,15),Vector2(26,12),Vector2(32,3),Vector2(39,13),Vector2(46,15)],"violet")
   rect(a,17,16,30,3,"iron0");rect(a,25,13,15,2,"bone0");rect(a,53,20,3,34,"gold1");rect(a,51,16,7,7,"violet");rect(a,53,18,3,3,"bone2")
   poly(a,[Vector2(18,42),Vector2(45,42),Vector2(49,58),Vector2(15,58)],"shadow");rect(a,20,51,24,2,"violet")
  "priest":
   poly(a,[Vector2(15,19),Vector2(19,9),Vector2(25,5),Vector2(39,5),Vector2(45,11),Vector2(48,22),Vector2(41,24),Vector2(38,13),Vector2(25,13),Vector2(23,24)],"bone1")
   rect(a,29,30,6,17,"bone2");rect(a,24,34,16,4,"bone2");rect(a,31,30,2,17,"gold2")
  "thief":
   poly(a,[Vector2(14,18),Vector2(20,9),Vector2(27,5),Vector2(38,7),Vector2(45,15),Vector2(44,24),Vector2(21,24)],"wood0")
   rect(a,21,17,23,6,"shadow");rect(a,24,18,4,2,"bone2");rect(a,35,18,4,2,"bone2")
   poly(a,[Vector2(16,26),Vector2(41,26),Vector2(47,31),Vector2(55,28),Vector2(52,35),Vector2(45,36),Vector2(38,31),Vector2(17,32)],"red1")
   rect(a,3,38,10,3,"iron2");rect(a,1,39,8,1,"bone2")
  "fanatic":
   poly(a,[Vector2(17,18),Vector2(22,7),Vector2(32,0),Vector2(42,7),Vector2(47,21),Vector2(42,26),Vector2(38,15),Vector2(25,15),Vector2(21,26)],"red1")
   rect(a,23,15,18,3,"red3");rect(a,28,22,8,6,"red2");rect(a,31,23,2,5,"bone2")
   poly(a,[Vector2(15,44),Vector2(48,44),Vector2(51,58),Vector2(45,54),Vector2(40,61),Vector2(34,55),Vector2(29,61),Vector2(23,54),Vector2(15,59)],"red0")
  "lancer":
   # A skeletal mount is represented as a distinct lower silhouette.
   poly(a,[Vector2(3,45),Vector2(14,39),Vector2(43,39),Vector2(53,34),Vector2(60,37),Vector2(57,46),Vector2(51,49),Vector2(48,59),Vector2(43,59),Vector2(43,49),Vector2(17,49),Vector2(14,59),Vector2(9,59),Vector2(10,49)],"bone0")
   rect(a,14,42,29,3,"bone1");rect(a,18,45,24,2,"bone2");rect(a,52,38,5,2,"bone2");rect(a,47,4,3,39,"gold1");poly(a,[Vector2(45,7),Vector2(48,0),Vector2(51,7)],"bone2")
  "hero":
   rect(a,20,7,24,3,"gold2");rect(a,22,2,4,7,"gold2");rect(a,30,0,4,8,"gold3");rect(a,38,2,4,7,"gold2");rect(a,53,10,4,38,"bone1");rect(a,54,7,2,29,"bone2");rect(a,49,40,12,3,"gold2")
   rect(a,23,32,18,2,"gold2");rect(a,27,36,10,1,"gold3")
  "captain":
   rect(a,20,6,24,5,"bone2");rect(a,29,0,6,13,"gold2");rect(a,24,4,16,3,"gold2")
   poly(a,[Vector2(3,28),Vector2(16,24),Vector2(27,29),Vector2(27,47),Vector2(17,57),Vector2(6,50)],"gold0")
   poly(a,[Vector2(6,30),Vector2(16,27),Vector2(24,31),Vector2(23,46),Vector2(17,53),Vector2(9,48)],"bone1")
   rect(a,15,30,3,19,"red1");rect(a,10,37,13,2,"red1");rect(a,51,12,4,37,"bone2")
 return a
func icon_art(fam:String)->Image:
 var a:=blank(48,48)
 rect(a,3,3,42,42,"ink");rect(a,5,5,38,38,"gold0");rect(a,6,6,36,36,"shadow");rect(a,8,8,32,32,"wood0")
 rect(a,7,7,2,2,"gold2");rect(a,39,7,2,2,"gold2");rect(a,7,39,2,2,"gold2");rect(a,39,39,2,2,"gold2")
 match fam:
  "devour":poly(a,[Vector2(11,19),Vector2(37,19),Vector2(34,31),Vector2(14,31)],"red1");rect(a,14,19,4,5,"bone2");rect(a,30,19,4,5,"bone2");rect(a,21,25,6,12,"red2")
  "blade":poly(a,[Vector2(23,7),Vector2(27,10),Vector2(26,30),Vector2(22,30)],"bone1");rect(a,23,10,1,18,"bone2");rect(a,16,30,16,3,"gold2");rect(a,22,33,4,6,"wood2")
  "hex":poly(a,[Vector2(9,24),Vector2(16,16),Vector2(24,13),Vector2(32,16),Vector2(39,24),Vector2(32,32),Vector2(24,35),Vector2(16,32)],"iron0");rect(a,16,20,16,8,"red1");rect(a,21,17,6,14,"red2");rect(a,23,21,2,6,"bone2")
  "poison":rect(a,20,9,8,5,"gold1");rect(a,16,14,16,22,"green");rect(a,18,17,12,16,"wood0");rect(a,19,24,10,8,"green");rect(a,20,26,3,2,"bone1")
  "summon":rect(a,10,15,28,22,"ink");rect(a,12,17,24,18,"wood1");rect(a,12,15,24,4,"gold2");rect(a,14,23,20,6,"red1");rect(a,15,21,3,4,"bone2");rect(a,29,21,3,4,"bone2")
  "defense":poly(a,[Vector2(12,11),Vector2(36,11),Vector2(34,30),Vector2(24,38),Vector2(14,30)],"gold0");poly(a,[Vector2(15,14),Vector2(33,14),Vector2(31,28),Vector2(24,34),Vector2(17,28)],"iron2");rect(a,22,16,4,14,"bone2")
  "arcane":poly(a,[Vector2(24,8),Vector2(31,17),Vector2(38,24),Vector2(31,31),Vector2(24,39),Vector2(17,31),Vector2(10,24),Vector2(17,17)],"violet");rect(a,20,18,8,12,"red2");rect(a,22,20,4,8,"bone2")
 return a
func _initialize()->void:
 save(chest_art(),"res://assets/art/mimic_base.png")
 var families=["devour","blade","hex","poison","summon","defense","arcane"]
 for fam in families:
  save(part_art(fam),"res://assets/art/parts/%s.png"%fam)
  save(icon_art(fam),"res://assets/art/icons/%s.png"%fam)
 var colors={"swordsman":"iron2","shield":"iron1","archer":"gold1","mage":"violet","priest":"bone1","thief":"wood2","fanatic":"red2","lancer":"gold1","hero":"gold2","captain":"bone1"}
 for kind in colors:save(enemy_art(kind,colors[kind]),"res://assets/art/enemies/%s.png"%kind)
 print("Authored native-resolution mimic, seven parts/icons and ten enemies.")
 quit(0)
