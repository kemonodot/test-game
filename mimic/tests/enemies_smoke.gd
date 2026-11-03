extends SceneTree
const Combat=preload("res://src/combat.gd")
func build(kind:String,pos:Vector2):
 var b=Combat.new(98);b.abilities.clear();b.spawn_budget=-10000
 b.spawn_enemy(kind,pos);return b
func _initialize()->void:
 var shield=build("shield",Vector2(750,360));shield.hit_enemy(0,10)
 assert(shield.enemies[0].max_hp-shield.enemies[0].hp<10)
 var archer=build("archer",Vector2(800,360));archer.enemies[0].cooldown=0;archer.update(.01)
 assert(archer.projectiles.any(func(x):return x.active and x.enemy))
 var mage=build("mage",Vector2(800,360));mage.enemies[0].cooldown=0;mage.update(.01)
 assert(mage.projectiles.filter(func(x):return x.active and x.enemy).size()==3)
 var priest=build("priest",Vector2(800,360));priest.spawn_enemy("swordsman",Vector2(810,360));priest.enemies[1].hp=1;priest.enemies[0].cooldown=0;priest.update(.01)
 assert(priest.enemies[1].hp>1)
 var thief=build("thief",Vector2(800,360));thief.enemies[0].timer=10;var old:Vector2=thief.enemies[0].pos;thief.update(.1)
 assert(thief.enemies[0].pos.distance_to(Combat.CENTER)>old.distance_to(Combat.CENTER))
 var fanatic=build("fanatic",Vector2(670,360));fanatic.update(.01)
 assert(fanatic.hp<100 and not fanatic.enemies[0].active)
 var lancer=build("lancer",Vector2(720,360));lancer.enemies[0].cooldown=0;lancer.update(.01)
 assert(lancer.enemies[0].phase==1)
 print("ENEMY SMOKE: shield, ranged, mage, heal, retreat, explosion and charge passed")
 quit(0)
