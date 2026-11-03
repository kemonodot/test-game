extends SceneTree
const Profile=preload("res://src/profile.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var app=load("res://main.tscn").instantiate()
 root.add_child(app)
 app.profile=Profile.new(false)
 app.profile.data.points=30
 assert(app.profile.upgrade("damage"))
 var before_gold:int=app.profile.data.gold
 var drop:Dictionary=app.profile.create_item("tongue",1)
 app.profile.data.inventory.append(drop)
 app.start_battle()
 assert(app.battle.stats.damage>1.0)
 app.battle.hp=0
 app.battle.hitstop=0
 app._process(0.02)
 assert(app.state=="result")
 var reloaded=Profile.new(true)
 assert(not reloaded.get_item(drop.uid).is_empty())
 assert(int(reloaded.data.upgrades.damage)==1)
 assert(int(reloaded.data.gold)>=before_gold)
 print("PERSISTENCE SMOKE: death retains loot, money, upgrades; upgrades affect next battle")
 app.queue_free();quit(0)
