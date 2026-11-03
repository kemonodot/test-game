extends SceneTree
const Profile=preload("res://src/profile.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
 var app=load("res://main.tscn").instantiate();root.add_child(app)
 app.profile=Profile.new(false);app.profile.data.settings={"sound":false}
 app.start_battle();app.profile.rng.seed=12345;app.battle.rng.seed=67890
 app.battle.stats.crit=0.0;app.battle.spawn_budget=-1000
 for i in 30:app.battle.spawn_enemy("swordsman",Vector2(780,100+i*14))
 for i in 30:app.battle.hit_enemy(i,100000,Vector2.ZERO,"devour",i%2==0)
 app._process(0.001)
 app.battle.spawn_enemy("hero",Vector2(760,360));app.battle.hit_enemy(0,100000)
 app._process(0.001)
 print("COMPARE "+JSON.stringify({"profile":app.profile.data,"battle_rng":app.battle.rng.state,"profile_rng":app.profile.rng.state,"gold":app.run_gold,"kills":app.battle.kills}))
 app.free();quit(0)
