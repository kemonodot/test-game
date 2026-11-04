extends SceneTree
const Profile=preload("res://src/profile.gd")
const Battle=preload("res://src/combat.gd")

func _initialize() -> void:call_deferred("run")
func run() -> void:
 var app=load("res://main.tscn").instantiate();root.add_child(app)
 app.profile=Profile.new(false);app.profile.data.settings={"sound":false,"music":false}
 app.start_battle()
 var b=app.battle
 b.configure([app.profile.get_template("bite"),app.profile.get_template("mouth"),app.profile.get_template("suction"),app.profile.get_template("hunger")]);b.stats.crit=0.0
 assert(app.visible_tongue().is_empty())
 assert(b.spawn_enemy("swordsman",Battle.CENTER+Vector2(160,0)))
 b.enemies[0].hp=1000.0
 for ability in b.abilities:assert(b.cast(ability))
 var tongues:Array=b.effects.filter(func(fx):return fx.active and fx.family=="devour")
 assert(tongues.size()==4 and app.visible_tongue() in tongues)
 var before:float=b.enemies[0].hp
 for tongue in tongues:b.advance_tongue(tongue,Battle.TONGUE_REACH_TIME)
 assert(b.damage_events==4 and b.enemies[0].hp<before,"Every equipped attack must still deal its own damage")
 assert(app.visible_tongue().hit,"A tongue that just hit must be visible")
 app.set_process(false);app.queue_free();app=null
 await process_frame
 print("SINGLE TONGUE: overlapping abilities render one tongue, all attacks still hit")
 quit(0)
