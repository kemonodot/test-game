extends Control

const Battle=preload("res://src/combat.gd")
const BenchProfile=preload("res://benchmark/profile.gd")
const Stats=preload("res://benchmark/stats.gd")
const Device=preload("res://benchmark/device_info.gd")
const GEAR := ["cleaver","bladeplate","thousand","venomheart","minion","knife","cursejewel"]
var game: Control
var battle: MimicCombat
var stats := Stats.new()
var run_seconds := 180
var running := false
var interrupted := false
var initial_battery := -1
var device_info: Dictionary={}
var last_hud := 0
var hud: Label
var run_label: Label
var result_text := ""
var active_min := 120
var active_max := 0
var active_now := 0
var bomb_count := 0
var maintained_frames := 0

func _ready() -> void:
 game=get_parent()
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 DisplayServer.screen_set_keep_on(true)
 start_run(180)

func clear_overlay() -> void:
 for child in get_children():child.queue_free()

func add_label(text: String, pos: Vector2, dimensions: Vector2, size: int=20) -> Label:
 var label:=Label.new()
 label.text=text;label.position=pos;label.size=dimensions
 label.add_theme_font_size_override("font_size",size)
 label.add_theme_color_override("font_color",Color("fff1da"))
 add_child(label)
 return label

func add_button(text: String, pos: Vector2, dimensions: Vector2, action: Callable) -> Button:
 var button:=Button.new()
 button.text=text;button.position=pos;button.size=dimensions
 button.add_theme_font_size_override("font_size",20)
 button.pressed.connect(action);add_child(button)
 return button

func start_run(seconds: int) -> void:
 running=false
 clear_overlay()
 run_seconds=seconds;interrupted=false;bomb_count=0;maintained_frames=0;active_min=120;active_max=0
 game.profile=BenchProfile.new()
 game.selected_stage=1
 game.start_battle()
 game.bomb_button.visible=false
 battle=game.battle
 battle.stage=1;battle.elapsed=240.0;battle.spawn_budget=-1000000.0;battle.boss_spawned=true;battle.debug_invulnerable=true;battle.aim=Vector2.RIGHT
 var gear:=[]
 for id in GEAR:
  var item:Dictionary=game.profile.get_template(id).duplicate(true)
  item.item={"rarity":4,"level":0,"affixes":[],"sockets":[]}
  gear.append(item)
 battle.configure(gear,{"organ_slot":1})
 fill_enemies()
 # A small cluster begins in reach so poison and curse can interact immediately.
 for i in 6:
  battle.enemies[i].pos=Battle.CENTER+Vector2(145.0+(i%3)*12.0,(i-2.5)*14.0)
 # Pre-establish the requested summon cap and the lingering poison pool.
 for ability in battle.abilities:
  if ability.family=="summon":
   for i in 3:battle.cast(ability)
  elif ability.family=="poison":battle.cast(ability)
  elif ability.family=="hex":battle.cast(ability)
 fill_enemies()
 var panel:=ColorRect.new()
 panel.position=Vector2(335,10);panel.size=Vector2(615,90);panel.color=Color(0.025,0.015,0.02,0.93);panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(panel)
 hud=add_label("FPS --   /   1分平均 --   /   1% low --   /   敵 120",Vector2(350,16),Vector2(590,34),18)
 run_label=add_label("",Vector2(350,51),Vector2(590,30),17)
 add_button("3分に切替",Vector2(20,638),Vector2(200,60),func():start_run(180))
 add_button("10分に切替",Vector2(232,638),Vector2(210,60),func():start_run(600))
 device_info=Device.gather()
 initial_battery=Device.battery_percent()
 stats.begin(Time.get_ticks_usec())
 last_hud=0;running=true

func fill_enemies() -> void:
 var active:=0
 for enemy in battle.enemies:
  if enemy.active:
   active+=1
   enemy.pos.x=clampf(enemy.pos.x,32.0,1248.0)
   enemy.pos.y=clampf(enemy.pos.y,32.0,688.0)
 while active<Battle.MAX_ENEMIES:
  var angle:float=TAU*float((maintained_frames*17+active*37)%120)/120.0
  var direction:=Vector2.from_angle(angle)
  var radius:float=minf(550.0/maxf(absf(direction.x),0.001),300.0/maxf(absf(direction.y),0.001))
  var roster:Array=Battle.STAGE_ROSTERS[1]
  var kind:String=roster[(maintained_frames+active)%roster.size()]
  if not battle.spawn_enemy(kind,Battle.CENTER+direction*radius):break
  active+=1
 active_now=active;active_min=mini(active_min,active);active_max=maxi(active_max,active)

func _process(_delta: float) -> void:
 if not running:return
 var now:int=Time.get_ticks_usec()
 stats.record(now)
 var elapsed_us:int=now-stats.start_us
 maintained_frames+=1
 battle.elapsed=240.0
 battle.spawn_budget=-1000000.0
 battle.aim=Vector2.RIGHT
 if battle.bomb_remaining<=0.0 and battle.use_bomb():bomb_count+=1
 fill_enemies()
 if now-last_hud>=1000000:
  last_hud=now
  var rolling:Dictionary=stats.rolling()
  var current:float=1000000.0/stats.frame_us[-1] if not stats.frame_us.is_empty() else 0.0
  hud.text="FPS %.1f   /   1分平均 %.1f   /   1%% low %.1f   /   敵 %d" % [current,rolling.fps,rolling.low,active_now]
  run_label.text="%d分測定   残り %02d:%02d   自動照準・自動ボム" % [int(run_seconds/60),maxi(0,int((run_seconds-elapsed_us/1000000.0)/60)),maxi(0,int(run_seconds-elapsed_us/1000000.0))%60]
 if elapsed_us>=run_seconds*1000000:finish_run()

func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_PAUSED and running:
  interrupted=true
  finish_run()

func finish_run() -> void:
 if not running:return
 running=false
 var end_battery:int=Device.battery_percent()
 var total:Dictionary=stats.all()
 var elapsed_us:int=stats.end_us[-1] if not stats.end_us.is_empty() else 0
 var first:Dictionary=stats.range_summary(0,mini(elapsed_us,60000000))
 var last:Dictionary=stats.range_summary(maxi(0,elapsed_us-60000000),elapsed_us)
 var memory:int=int(device_info.get("memory",-1))
 var ram_text:String="%.2f GiB" % (float(memory)/1073741824.0) if memory>0 else "取得不可"
 var hz:float=float(device_info.get("hz",-1.0))
 var hz_text:String="%.1f Hz" % hz if hz>0 else "取得不可"
 var status:String="中断：参考値（再計測してください）" if interrupted else "完了"
 result_text="MIMIC Android BENCHMARK  /  %s\n測定：%d分  実測 %.1f秒  フレーム %d\n平均 FPS %.2f     1%% low %.2f     16.7ms超 %.2f%%\n開始60秒 FPS %.2f     終了60秒 FPS %.2f\n敵 %d〜%d体   ボム %d回\nバッテリー %s → %s\n端末 %s\nAndroid %s\nSoC %s\nメモリ %s   画面 %d×%d   リフレッシュ %s\n条件：第二層240秒固定・敵補充・無敵・ボム自動\n※通常セーブには保存されません。" % [status,int(run_seconds/60),elapsed_us/1000000.0,total.frames,total.fps,total.low,total.over_pct,first.fps,last.fps,active_min,active_max,bomb_count,Device.percent_text(initial_battery),Device.percent_text(end_battery),device_info.get("model","取得不可"),device_info.get("version","取得不可"),device_info.get("soc","取得不可"),ram_text,int(device_info.get("width",0)),int(device_info.get("height",0)),hz_text]
 game.state="bench_result"
 game.clear_ui();game.queue_redraw()
 clear_overlay()
 var background:=ColorRect.new();background.color=Color(0.025,0.015,0.025,0.97);background.position=Vector2(25,15);background.size=Vector2(1230,600);background.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(background)
 var report:=add_label(result_text,Vector2(60,35),Vector2(1160,555),21)
 report.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var copy:=add_button("結果をコピー",Vector2(50,638),Vector2(365,60),func():DisplayServer.clipboard_set(result_text))
 copy.pressed.connect(func():copy.text="コピーしました")
 add_button("3分を再計測",Vector2(455,638),Vector2(365,60),func():start_run(180))
 add_button("10分を計測",Vector2(860,638),Vector2(365,60),func():start_run(600))
