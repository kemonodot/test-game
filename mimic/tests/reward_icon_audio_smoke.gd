extends SceneTree
const Reward=preload("res://src/reward_presentation.gd")
const Profile=preload("res://src/profile.gd")

func _initialize() -> void:call_deferred("run")
func run() -> void:
 var fx=Reward.new()
 assert(fx.drop_icons.filter(func(x):return x.active).is_empty())
 for rarity in 5:
  var pos:=Vector2(100+rarity*80,200)
  fx.item(rarity,"装備",pos,false,false,"devour")
  var icon:Dictionary=fx.drop_icons[rarity]
  assert(icon.active and icon.pos==pos and icon.rarity==rarity and icon.family=="devour")
  assert((icon.reveal>0.0)==(rarity>=3))
 fx.update(Reward.REVEAL_DELAY+0.01)
 assert(fx.drop_icons[3].reveal==0.0 and fx.drop_icons[4].reveal==0.0)
 for i in 30:fx.item(0,"装備",Vector2(i,50),false,false,"blade")
 assert(fx.drop_icons.filter(func(x):return x.active).size()==16)
 var reduced=Reward.new()
 reduced.item(2,"装備",Vector2(500,300),true,false,"hex")
 assert(reduced.drop_icons[0].active and reduced.drop_icons[0].family=="hex")
 var boss=Reward.new();boss.boss(Vector2(700,400),"hero",false)
 boss.item(4,"神話",Vector2(700,400),false,true,"arcane")
 assert(not boss.drop_icons[0].active)
 for i in 22:boss.update(0.05)
 assert(boss.drop_icons[0].active and boss.drop_icons[0].rarity==4 and boss.drop_icons[0].family=="arcane")

 var app=load("res://main.tscn").instantiate();root.add_child(app)
 app.profile=Profile.new(false);app.profile.data.settings={"sound":false,"music":true}
 assert(app.music_player.stream is AudioStreamOggVorbis and app.music_player.stream.loop)
 app.start_battle();assert(app.music_player.playing)
 app.show_result();assert(not app.music_player.playing)
 app.show_settings();app.toggle_music()
 assert(not app.profile.data.settings.music and not app.profile.data.settings.sound)
 app.start_battle();assert(not app.music_player.playing)
 app.profile.data.settings.sound=true
 app.battle.spawn_budget=-10000;app.battle.stats.drop=1.0
 var pos:=Vector2(800,360)
 assert(app.battle.spawn_enemy("swordsman",pos))
 app.battle.hit_enemy(0,10000.0);app._process(0.01)
 var icons:Array=app.reward_fx.drop_icons.filter(func(x):return x.active)
 assert(icons.size()==1 and icons[0].pos==pos)
 var acquired:Dictionary=app.profile.data.inventory.back()
 assert(icons[0].rarity==acquired.rarity and icons[0].family==app.profile.get_template(acquired.template).family)
 assert(app.kill_thump.playing and not app.music_player.playing)
 # Even reduced effects must show a boss drop before switching to results.
 app.profile.data.settings.reduce_fx=true;app.profile.data.settings.sound=false
 app.start_battle();assert(app.battle.spawn_enemy("hero",pos));app.battle.hit_enemy(0,1000000.0)
 app._process(0.01)
 assert(app.state=="battle" and app.reward_fx.drop_icons.any(func(x):return x.active))
 for i in 20:app._process(0.05)
 assert(app.state=="result")
 app.set_process(false)
 for child in app.get_children():
  if child is AudioStreamPlayer:child.stop()
 await create_timer(0.1).timeout
 app.queue_free();app=null;fx=null;reduced=null;boss=null
 await process_frame
 print("REWARD ICON + AUDIO: actual drop location and rarity, truthful reveal, bounded pool, independent music passed")
 quit(0)
