extends SceneTree
const Profile=preload("res://src/profile.gd")
const Battle=preload("res://src/combat.gd")

func _initialize() -> void:call_deferred("run")
func run() -> void:
 var app=load("res://main.tscn").instantiate();root.add_child(app)
 app.profile=Profile.new(false);app.profile.data.settings={"sound":false}
 app.start_battle()
 var b=app.battle
 b.spawn_budget=-10000;b.stats.crit=0.0
 assert(b.spawn_enemy("swordsman",Battle.CENTER+Vector2(200,0)))
 b.enemies[0].hp=1.0;b.enemies[0].speed=0.0
 # The shot begins automatically; touching while it travels only changes input.
 assert(b.cast(b.abilities[0]));b.abilities.clear();b.update(0.10)
 var touch:=InputEventScreenTouch.new();touch.pressed=true;touch.position=Vector2(900,360)
 app._gui_input(touch)
 assert(b.enemies[0].active and b.kills==0 and b.impact_serial==0)
 b.update(0.05)
 assert(b.enemies[0].active and b.kills==0 and b.impact_serial==0)
 b.update(0.06)
 assert(not b.enemies[0].active and b.kills==1 and b.impact_serial==1)
 app.queue_free();await process_frame
 print("TONGUE TOUCH: touch cannot deal damage while an automatic attack is travelling")
 quit(0)
