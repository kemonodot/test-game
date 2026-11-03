extends SceneTree
const Profile=preload("res://src/profile.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var p=Profile.new(false)
 assert(not p.upgrade("awakening"))
 assert(not p.upgrade("damage"))
 p.data.points=100
 assert(p.upgrade("awakening"))
 assert(not p.upgrade("fusion"))
 assert(p.upgrade("damage") and p.upgrade("reroll") and p.upgrade("fusion"))
 var saved_gold:int=p.data.gold
 p.data.upgrades.erase("awakening")
 assert(p.save_game())
 var old=Profile.new(true)
 assert(old.data.upgrades.awakening==1 and old.data.upgrades.fusion==1 and old.data.gold==saved_gold)
 var app=load("res://main.tscn").instantiate();root.add_child(app)
 app.profile=Profile.new(false);app.start_battle()
 app.battle.spawn_budget=-1000;app.battle.stats.crit=0;app.battle.aim=Vector2.RIGHT
 app.battle.spawn_enemy("swordsman",Vector2(800,360))
 var key:=InputEventKey.new();key.keycode=KEY_SPACE;key.pressed=true
 app._input(key)
 assert(app.battle.bomb_remaining>0)
 app.battle.hitstop=0;app._process(0.01)
 assert(app.run_gold==15 and app.profile.data.gold==15)
 assert(app.bomb_button.disabled)
 var loaded=Profile.new(true)
 assert(loaded.data.gold==15)
 print("OFFERING + BOMB: gated gifts, old-save migration, Space, triple rewards and persistence passed")
 app.queue_free();quit(0)
