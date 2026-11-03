extends SceneTree
const Profile=preload("res://src/profile.gd")
const Combat=preload("res://src/combat.gd")
func make(id:String):
 var p=Profile.new(false);var b=Combat.new(7)
 b.configure([p.get_template(id)]);b.aim=Vector2.RIGHT
 b.spawn_enemy("swordsman",Vector2(760,360));b.enemies[0].hp=1000;b.enemies[0].max_hp=1000
 return b
func _initialize()->void:
 var a=make("kingtongue")
 a.cast(a.abilities[0]);a.cast(a.abilities[0]);assert(a.devour_chain==2)
 var blade=make("thousand")
 blade.spawn_enemy("swordsman",Vector2(780,390));blade.enemies[1].hp=1000
 blade.cast(blade.abilities[0]);assert(blade.enemies[1].hp<1000)
 var curse=make("cursejewel")
 curse.spawn_enemy("swordsman",Vector2(780,360));curse.enemies[0].mark=2
 curse.hit_enemy(0,100000);assert(curse.enemies[1].mark==2)
 var venom=make("venomheart")
 venom.cast(venom.abilities[0]);assert(venom.enemies[0].poison>0 and venom.enemies[0].hp<1000)
 var brood=make("broodking")
 for i in 5:brood.cast(brood.abilities[0])
 assert(brood.minions.filter(func(x):return x.active).size()==5)
 var armor=make("revenge")
 armor.enemies[0].pos=Vector2(820,360);armor.cast(armor.abilities[0]);assert(armor.enemies[0].hp<1000)
 var prism=make("moonprism")
 prism.cast(prism.abilities[0]);assert(prism.enemies[0].hp<1000)
 var sword=make("redcleaver")
 sword.spawn_enemy("swordsman",Vector2(780,390));sword.enemies[1].hp=1000
 sword.cast(sword.abilities[0]);assert(sword.enemies[1].hp<1000)
 var eye=make("hungryeye")
 eye.spawn_enemy("swordsman",Vector2(780,360));eye.cast(eye.abilities[0]);assert(eye.enemies[1].mark>0)
 var shell=make("lastshell")
 shell.hurt_player(10000);assert(shell.hp>0 and shell.last_stand_used)
 print("LEGENDARY SMOKE: all ten unique abilities affected battle")
 quit(0)
