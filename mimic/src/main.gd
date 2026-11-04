extends Control
const Battle = preload("res://src/combat.gd")
const RewardFX = preload("res://src/reward_presentation.gd")
const Profile = preload("res://src/profile.gd")
const HubButton = preload("res://src/hub_button.gd")
const BenchmarkProfile = preload("res://benchmark/profile.gd")
const FAMILY_NAMES := {"devour":"捕食","blade":"刃物","hex":"呪術","poison":"毒・腐食","summon":"召喚","defense":"防御","arcane":"魔力"}
const COMPANIONS := {"black_mage":"黒魔法使い", "thief":"盗賊", "sister":"シスター", "blacksmith":"鍛冶屋", "merchant":"商人", "researcher":"研究者", "hunter":"狩人", "fortune_teller":"占い師"}
const SLOTS := {"fang":"牙","organ1":"器官1","organ2":"器官2","organ3":"器官3","organ4":"器官4","shell":"甲殻","core":"核"}
const ABILITY_TEXT := {"bite":"噛みつき", "tongue":"伸びる舌", "maw":"広範囲の捕食", "pull":"敵を引き寄せる", "hide":"防護", "hunger":"飢餓の一撃", "slash":"正面斬り", "orbit":"偏った回転刃", "pierce":"貫く斬撃", "counter":"方向反撃", "curse":"呪い", "mark":"呪印と破裂", "spray":"毒液噴霧", "pool":"毒の残留域", "summon":"小箱召喚", "heal":"再生", "armor":"防御", "bolt":"照準魔弾", "nova":"魔力の範囲攻撃"}
const UNIQUE_TEXT := {"devour_chain":"連続捕食で威力・対象数が増加", "extra_blades":"刃物装備の数に応じて回転刃が強化", "curse_spread":"呪印のある敵の死亡時に周囲へ呪印を伝播", "poison_burst":"毒霧に即時腐食ダメージが加わる", "extra_minions":"召喚体の追撃が増加", "wide_counter":"反撃の範囲が拡大", "double_nova":"魔力攻撃が範囲攻撃に変化", "cleave":"刃が進行方向の敵をまとめて斬る", "curse_chain":"呪印を周囲の敵にも刻む", "last_stand":"致命傷を一度だけ耐える"}
const RARITY_COLORS := [Color("d8cbbd"),Color("8db8cf"),Color("c3a1d4"),Color("e8bb7a"),Color("e78a87")]
const RARITY := ["コモン","レア","エピック","レジェンダリー","ミシック"]
# Regions from the existing chest artwork used to cover its painted tongue while attacking.
const TONGUE_COVER := [[Rect2(52,75,24,23),Rect2(28,75,24,23)], [Rect2(56,98,4,6),Rect2(32,98,4,6)], [Rect2(68,98,4,6),Rect2(40,98,4,6)], [Rect2(56,104,16,9),Rect2(32,104,16,9)]]
const TONGUE_BODY_PIECES := [Rect2(0,0,128,75),Rect2(0,75,52,23),Rect2(76,75,52,23),Rect2(0,98,56,6),Rect2(60,98,8,6),Rect2(72,98,56,6),Rect2(0,104,56,9),Rect2(72,104,56,9),Rect2(0,113,128,15)]
var battle: MimicCombat
var profile
var state := "title"
var selected_stage := 0
var selected_uid := -1
var preview_slot := ""
var ui: Control
var persistence_ui: Control
var persistence_kind := ""
var web_storage_seq := -1
var web_failure_seq := 0
var web_sync_failed := false
var web_load_failed := false
var title_font: Font
var toast := ""
var toast_t := 0.0
var touch_origin := Vector2.ZERO
var run_gold := 0
var reward_given := false
var shot_sound: AudioStreamPlayer
var kill_sound: AudioStreamPlayer
var kill_thump: AudioStreamPlayer
var music_player: AudioStreamPlayer
var hit_sounds: Array = []
var hit_sound_index := 0
var hit_sound_cooldown := 0.0
var previous_impacts := 0
var rarity_sound: AudioStreamPlayer
var legendary_sounds: Array = []
var legendary_sound_index := 0
var boss_sound: AudioStreamPlayer
var reward_fx: RewardPresentation
var no_tongue: Dictionary = {}
var previous_shots := 0
var benchmark_mode := false
var web_quick_callback
var web_sound_callback
var mimic_texture: Texture2D
var concept_texture: Texture2D
var dungeon_texture: Texture2D
var hub_texture: Texture2D
var bomb_button: Button
var hub_time := 0.0
var hub_redraw_clock := 0.0
var part_textures := {}
var enemy_textures := {}
var icon_textures := {}
var companion_textures := {}
var reward_atlases := {}
var backgrounds := []
const FAM_COLORS := {"devour":Color("e75c72"),"blade":Color("dbccb0"),"hex":Color("d483da"),"poison":Color("8dc26e"),"summon":Color("e6ad68"),"defense":Color("d5cb98"),"arcane":Color("8eb5ef"),"enemy":Color("e85656"),"bomb":Color("f3a44e")}

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_STOP
 var font_path := "res://assets/jp.otf"
 if ResourceLoader.exists(font_path):
  theme=Theme.new()
  theme.default_font=load(font_path)
  theme.default_font_size=18
  for mode in ["normal","hover","pressed","focus","disabled"]:
   var style:=StyleBoxFlat.new()
   style.bg_color=Color("4b242b") if mode in ["hover","pressed"] else Color("20161c")
   if mode=="disabled":style.bg_color=Color("161218")
   style.border_color=Color("e8bb8e") if mode in ["hover","focus"] else Color("70505a")
   style.set_border_width_all(2 if mode=="focus" else 1)
   style.set_content_margin_all(10)
   style.shadow_size=2
   style.shadow_color=Color(0,0,0,0.45)
   style.shadow_offset=Vector2(0,2)
   theme.set_stylebox(mode,"Button",style)
  theme.set_color("font_color","Button",Color("f1e3d1"))
  theme.set_color("font_disabled_color","Button",Color("86777a"))
  theme.set_color("font_hover_color","Button",Color("fff2d9"))
  theme.set_font_size("font_size","Button",19)
 title_font = theme.default_font if theme and theme.default_font else ThemeDB.fallback_font
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 mimic_texture=load("res://assets/art/mimic_base.png")
 concept_texture=load("res://assets/mimic_concept.png")
 dungeon_texture=load("res://assets/art/dungeon.png")
 hub_texture=load("res://assets/art/hub.png")
 if dungeon_texture:
  var scene_image:Image=dungeon_texture.get_image()
  scene_image.resize(1280,720,Image.INTERPOLATE_NEAREST)
  dungeon_texture=ImageTexture.create_from_image(scene_image)
 for stage_index in 2:
  var gradient:=Gradient.new()
  gradient.offsets=PackedFloat32Array([0.0,0.58,1.0])
  gradient.colors=PackedColorArray([Color("292027"),Color("151018"),Color("060509")]) if stage_index==0 else PackedColorArray([Color("2b1922"),Color("170d15"),Color("080508")])
  var backdrop:=GradientTexture2D.new()
  backdrop.width=1280;backdrop.height=720;backdrop.gradient=gradient
  backdrop.fill=GradientTexture2D.FILL_RADIAL
  backdrop.fill_from=Vector2(0.5,0.5);backdrop.fill_to=Vector2(1.0,1.0)
  backgrounds.append(backdrop)
 for fam in Profile.FAMILIES:
  part_textures[fam]=load("res://assets/art/parts/%s.png" % fam)
  icon_textures[fam]=load("res://assets/art/icons/%s.png" % fam)
 for role in COMPANIONS:
  var portrait_path:String="res://assets/art/companions/%s.png" % role
  if ResourceLoader.exists(portrait_path):companion_textures[role]=load(portrait_path)
 for kind in ["swordsman","shield","archer","mage","priest","thief","fanatic","lancer","hero","captain"]:
  enemy_textures[kind]=load("res://assets/art/enemies/%s.png" % kind)
 for atlas_name in ["collect-burst","holy-pillar","implosion","hit-spark","crit-hit"]:
  var base_path:String="res://assets/fx/pixelfx/"+atlas_name
  var atlas_data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(base_path+".json"))
  reward_atlases[atlas_name]={"texture":load(base_path+".png"),"meta":atlas_data.meta.pixelfx}
 var bench_requested:bool=OS.has_feature("mimic_bench") or "--mimic-bench" in OS.get_cmdline_user_args()
 profile = BenchmarkProfile.new() if bench_requested else Profile.new()
 shot_sound=AudioStreamPlayer.new();shot_sound.stream=load("res://assets/audio/oculus/swing.ogg");shot_sound.volume_db=-14;add_child(shot_sound)
 kill_sound=AudioStreamPlayer.new();kill_sound.stream=load("res://assets/audio/oculus/defeat.ogg");kill_sound.volume_db=-12;add_child(kill_sound)
 kill_thump=AudioStreamPlayer.new();kill_thump.stream=load("res://assets/audio/oculus/impact.ogg");kill_thump.volume_db=-22;add_child(kill_thump)
 var bgm:AudioStreamOggVorbis=load("res://assets/audio/tanner/dark-knight.ogg")
 bgm.loop=true
 music_player=AudioStreamPlayer.new();music_player.stream=bgm;music_player.volume_db=-22;add_child(music_player)
 var hit_stream:AudioStream=load("res://assets/audio/oculus/impact.ogg")
 for i in 2:
  var hit_voice:=AudioStreamPlayer.new();hit_voice.stream=hit_stream;hit_voice.volume_db=-7;add_child(hit_voice);hit_sounds.append(hit_voice)
 rarity_sound=AudioStreamPlayer.new();rarity_sound.stream=load("res://assets/audio/oculus/rare.ogg");rarity_sound.volume_db=-8;add_child(rarity_sound)
 var legendary_stream:AudioStream=load("res://assets/audio/oculus/legendary.ogg")
 for i in 4:
  var voice:=AudioStreamPlayer.new();voice.stream=legendary_stream;voice.volume_db=-12;add_child(voice);legendary_sounds.append(voice)
 boss_sound=AudioStreamPlayer.new();boss_sound.stream=load("res://assets/audio/oculus/boss.ogg");boss_sound.volume_db=-11;add_child(boss_sound)
 ui = Control.new()
 ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(ui)
 persistence_ui=Control.new()
 persistence_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 persistence_ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(persistence_ui)
 show_title()
 if profile.load_failed:show_persistence_warning("load")
 if OS.has_feature("web"):poll_web_storage()
 if bench_requested:
  call_deferred("start_benchmark_mode")
  return
 if OS.has_feature("web"):
  web_quick_callback=JavaScriptBridge.create_callback(_web_quick_start)
  JavaScriptBridge.get_interface("window").mimicQuickStart=web_quick_callback
  web_sound_callback=JavaScriptBridge.create_callback(_web_sound_test)
  JavaScriptBridge.get_interface("window").mimicSoundTest=web_sound_callback
  JavaScriptBridge.eval("window.dispatchEvent(new Event('mimic-ready'))")
  benchmark_mode=bool(JavaScriptBridge.eval("new URLSearchParams(location.search).has('stress')",true))
  var inspect_family:String=str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('inspect') || ''",true))
  if inspect_family in ["devour","blade"]:
   start_battle()
   var ids:Array=["bite","tongue","mouth","jaw"] if inspect_family=="devour" else ["cleaver","spindle","piercer","knife"]
   var sample:Array=[]
   for id in ids:sample.append(profile.get_template(id))
   battle.configure(sample)
  if benchmark_mode:
   start_battle()
   battle.debug_invulnerable=true
   for i in Battle.MAX_ENEMIES:
    battle.spawn_enemy("swordsman",Battle.CENTER+Vector2.from_angle(TAU*i/Battle.MAX_ENEMIES)*310.0)
    battle.enemies[i].hp=1000000.0
    battle.enemies[i].max_hp=1000000.0
func start_benchmark_mode() -> void:
 var controller=load("res://benchmark/benchmark.gd").new()
 add_child(controller)
func _web_quick_start(_args: Array) -> void:
 if persistence_kind=="load":return
 if state=="title":
  selected_stage=0
  start_battle()
func _web_sound_test(_args: Array) -> void:
 if persistence_kind=="load":return
 if not profile.data.get("settings",{}).get("sound",true):
  JavaScriptBridge.eval("window.mimicSoundTestStatus='muted'")
  return
 kill_sound.pitch_scale=0.8
 kill_sound.play()
 JavaScriptBridge.eval("window.mimicSoundTestStatus='requested'")
func save_profile() -> bool:
 var ok:bool=profile.save_game()
 if not ok:
  show_persistence_warning("load" if profile.load_failed else "save")
 elif persistence_kind=="save" and not web_sync_failed:
  clear_persistence_warning()
 return ok
func clear_persistence_warning() -> void:
 persistence_kind=""
 if is_instance_valid(persistence_ui):
  for child in persistence_ui.get_children():child.queue_free()
func show_persistence_warning(kind: String) -> void:
 if not is_instance_valid(persistence_ui):return
 if persistence_kind=="load" and kind!="load":return
 if persistence_kind==kind:return
 clear_persistence_warning()
 persistence_kind=kind
 var block:=ColorRect.new()
 block.name="PersistenceWarning"
 block.color=Color(0,0,0,0.84) if kind=="load" else Color(0.08,0.025,0.035,0.98)
 block.position=Vector2.ZERO if kind=="load" else Vector2(330,8)
 block.size=Vector2(1280,720) if kind=="load" else Vector2(620,72)
 block.mouse_filter=Control.MOUSE_FILTER_STOP
 persistence_ui.add_child(block)
 var message:=Label.new()
 message.name="PersistenceMessage"
 message.text="セーブを読み込めません。\n保存領域を確認し、再試行してください。" if kind=="load" else "保存できません。再試行してください。"
 message.position=Vector2(330,240) if kind=="load" else Vector2(14,10)
 message.size=Vector2(620,90) if kind=="load" else Vector2(420,52)
 message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER if kind=="load" else HORIZONTAL_ALIGNMENT_LEFT
 message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 message.add_theme_font_size_override("font_size",24 if kind=="load" else 18)
 block.add_child(message)
 var retry:=Button.new()
 retry.name="PersistenceRetry";retry.text="再試行"
 retry.position=Vector2(510,360) if kind=="load" else Vector2(462,10)
 retry.size=Vector2(260,56) if kind=="load" else Vector2(145,52)
 retry.pressed.connect(retry_persistence)
 block.add_child(retry)
func retry_persistence() -> void:
 if persistence_kind=="load":
  if web_load_failed:
   if OS.has_feature("web"):JavaScriptBridge.eval("window.location.reload()")
   return
  if profile.load_game():clear_persistence_warning();show_title()
  return
 if save_profile() and web_sync_failed and OS.has_feature("web"):
  JavaScriptBridge.eval("window.mimicRetryStorage && window.mimicRetryStorage()")
func poll_web_storage() -> void:
 var seq:int=int(JavaScriptBridge.eval("window.mimicStorageState ? window.mimicStorageState.seq : -1",true))
 if seq==web_storage_seq:return
 web_storage_seq=seq
 var failure_seq:int=int(JavaScriptBridge.eval("window.mimicStorageState ? window.mimicStorageState.failureSeq : 0",true))
 if failure_seq>web_failure_seq:
  web_failure_seq=failure_seq
  var failure:String=str(JavaScriptBridge.eval("window.mimicStorageState.failureKind",true))
  if failure=="load_error":
   web_load_failed=true;profile.load_failed=true
   show_persistence_warning("load")
  elif failure=="save_error":
   web_sync_failed=true
   show_persistence_warning("save")
  return
 var status:String=str(JavaScriptBridge.eval("window.mimicStorageState ? window.mimicStorageState.status : ''",true))
 if status=="load_error":
  web_load_failed=true;profile.load_failed=true
  show_persistence_warning("load")
 elif status=="save_error":
  web_sync_failed=true
  show_persistence_warning("save")
 elif status=="ready":
  web_sync_failed=false
  if persistence_kind=="save" and profile.io_error.is_empty():clear_persistence_warning()

func clear_ui() -> void:
 for child in ui.get_children():child.queue_free()
 queue_redraw()
func button(text: String, pos: Vector2, size: Vector2, action: Callable, disabled: bool = false) -> Button:
 var b := Button.new()
 b.text = text
 b.position = pos
 b.size = size
 b.disabled = disabled
 b.pressed.connect(action)
 ui.add_child(b)
 return b
func label(text: String, pos: Vector2, size: Vector2, font_size: int = 22) -> Label:
 var l := Label.new()
 l.text = text
 l.position = pos
 l.size = size
 l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 l.add_theme_font_size_override("font_size",font_size)
 ui.add_child(l)
 return l
func heading(text: String) -> void:
 label("MIMIC   /   THE HUNGRY RELIQUARY",Vector2(44,16),Vector2(630,22),13).modulate=Color("d0a183")
 label(text,Vector2(40,38),Vector2(700,44),28)
 label("資金  %d      進化  %d" % [profile.data.gold,profile.data.points],Vector2(760,43),Vector2(320,35),18)
 button("拠点へ戻る",Vector2(1090,27),Vector2(150,48),show_title)
func list_panel(pos: Vector2, size: Vector2) -> VBoxContainer:
 var scroll := ScrollContainer.new()
 scroll.position=pos
 scroll.size=size
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 ui.add_child(scroll)
 var box := VBoxContainer.new()
 box.custom_minimum_size=Vector2(size.x-24,0)
 scroll.add_child(box)
 return box
func list_button(box: VBoxContainer, text: String, action: Callable, disabled: bool = false) -> Button:
 var b:=Button.new()
 b.text=text
 b.custom_minimum_size=Vector2(0,48)
 b.disabled=disabled
 b.alignment=HORIZONTAL_ALIGNMENT_LEFT
 b.add_theme_font_size_override("font_size",17)
 b.pressed.connect(action)
 box.add_child(b)
 return b
func style_item_button(b:Button,item:Dictionary) -> void:
 var color:Color=RARITY_COLORS[clampi(int(item.rarity),0,4)]
 b.add_theme_color_override("font_color",color)
 if selected_uid==int(item.uid):
  var highlight:StyleBoxFlat=theme.get_stylebox("normal","Button").duplicate()
  highlight.bg_color=Color("382228")
  highlight.border_color=color
  highlight.border_width_left=3
  b.add_theme_stylebox_override("normal",highlight)
func hub_button(title: String, subtitle: String, family: String, pos: Vector2, size: Vector2, action: Callable, primary: bool=false) -> Button:
 var b=HubButton.new()
 b.title=title;b.subtitle=subtitle;b.emblem=icon_textures.get(family);b.primary=primary
 b.position=pos;b.size=size;b.pressed.connect(action);ui.add_child(b)
 return b
func show_title() -> void:
 if is_instance_valid(music_player):music_player.stop()
 state="title"; clear_ui()
 if OS.has_feature("web"):JavaScriptBridge.eval("window.dispatchEvent(new Event('mimic-title'))")
 var mark:=label("MIMIC",Vector2(58,42),Vector2(450,80),64)
 mark.add_theme_color_override("font_color",Color("f1d2a5"))
 mark.add_theme_color_override("font_shadow_color",Color("1b080b"))
 mark.add_theme_constant_override("shadow_offset_x",3);mark.add_theme_constant_override("shadow_offset_y",3)
 label("THE HUNGRY RELIQUARY",Vector2(64,123),Vector2(420,26),14).modulate=Color("d0a078")
 label("宝箱は、獲物を待っている。",Vector2(64,168),Vector2(450,38),20).modulate=Color("e2c6aa")
 label("資金  %d    ◆    進化  %d" % [profile.data.gold,profile.data.points],Vector2(930,30),Vector2(320,40),17).modulate=Color("e8cfac")
 hub_button("狩場へ進む","HUNT  /  獲物を迎える","devour",Vector2(58,423),Vector2(350,92),show_stages,true)
 hub_button("装備", "EQUIP", "blade",Vector2(45,589),Vector2(226,88),show_inventory)
 hub_button("鍛冶", "FORGE", "defense",Vector2(285,589),Vector2(226,88),show_forge)
 var offering:=hub_button("貢ぎ物", "OFFERING", "hex",Vector2(525,589),Vector2(226,88),show_upgrades)
 if companion_textures.has("black_mage"):offering.emblem=companion_textures.black_mage
 hub_button("収集庫", "COLLECTION", "arcane",Vector2(765,589),Vector2(226,88),show_collection)
 hub_button("設定", "SETTINGS", "summon",Vector2(1005,589),Vector2(226,88),show_settings)
func show_stages() -> void:
 if OS.has_feature("web"):JavaScriptBridge.eval("window.dispatchEvent(new Event('mimic-leave-title'))")
 state="stages";clear_ui();heading("狩場を選ぶ")
 label("300秒以内にボスを倒す。敗北しても戦利品は残る。",Vector2(70,105),Vector2(1100,40),19).modulate=Color("d9c3af")
 label("01   /   THE FORGOTTEN CHAMBER",Vector2(100,170),Vector2(900,28),14).modulate=Color("d0a183")
 button("第一層　忘れられた石室       →",Vector2(100,208),Vector2(1000,74),func():selected_stage=0;start_battle())
 label("02   /   THE CHAPEL OF BLOOD",Vector2(100,326),Vector2(900,28),14).modulate=Color("d0a183")
 button("第二層　血の礼拝堂" + ("　　（未解放）" if int(profile.data.unlocked_stage)<1 else "       →"),Vector2(100,364),Vector2(1000,74),func():selected_stage=1;start_battle(),int(profile.data.unlocked_stage)<1)
 label("第二層は第一層のボスを倒すと解放されます。",Vector2(100,475),Vector2(900,36),16).modulate=Color("bcaaa1")
func start_battle() -> void:
 if persistence_kind=="load":return
 if OS.has_feature("web"):JavaScriptBridge.eval("window.dispatchEvent(new Event('mimic-leave-title'))")
 clear_ui()
 battle=Battle.new(Time.get_ticks_usec())
 battle.stage=selected_stage
 battle.configure(profile.equipped_templates(),profile.data.upgrades)
 state="battle";run_gold=0;reward_given=false;previous_shots=0;previous_impacts=0;hit_sound_cooldown=0.0
 if profile.data.get("settings",{}).get("music",true):music_player.play()
 else:music_player.stop()
 reward_fx=RewardFX.new()
 bomb_button=button("破滅の供物   READY\nSPACE / 撃破資金 ×3",Vector2(990,610),Vector2(270,90),try_bomb)
 bomb_button.add_theme_font_size_override("font_size",20)
 var starting:int=int(profile.data.upgrades.get("starting_gold",0))*10
 profile.data.gold+=starting
 run_gold+=starting
 save_profile()
func item_description(item: Dictionary) -> String:
 if item.is_empty(): return "装備を選ぶと詳細を表示"
 var t: Dictionary=profile.get_template(item.template)
 var result: String="%s  [%s]  %s / %s\n威力 %.1f　間隔 %.2f　射程 %.0f　強化 +%d\n能力 %s  ソケット %d/%d" % [t.name,RARITY[int(item.rarity)],SLOTS.get(t.slot,t.slot),FAMILY_NAMES.get(t.family,t.family),float(t.power),float(t.cooldown),float(t.range),int(item.level),ABILITY_TEXT.get(t.ability,t.ability),item.sockets.size(),item.socket_count]
 if t.has("unique"): result += "\n固有："+str(UNIQUE_TEXT.get(t.unique,t.unique))
 for affix in item.affixes: result += "\n%s T%d +%s" % [affix.name,affix.tier,affix.value]
 for gem in item.sockets: result += "\n魔石 %s T%d" % [FAMILY_NAMES.get(gem.family,gem.family),gem.tier]
 return result
func inventory_item_name(item: Dictionary) -> String:
 var t: Dictionary=profile.get_template(item.template)
 return "%s %s  [%s] +%d" % ["◆" if profile.data.equipped.values().has(item.uid) else "◇",t.name,RARITY[int(item.rarity)],item.level]
func select_equipment_slot(slot: String) -> void:
 preview_slot=slot;selected_uid=-1;show_inventory()
func remove_equipment_from_slot() -> void:
 if profile.unequip(preview_slot):save_profile()
 selected_uid=-1;show_inventory()
func equip_selected_item() -> void:
 if profile.equip(selected_uid,preview_slot):save_profile()
 selected_uid=-1;show_inventory()
func confirm_salvage(max_rarity: int = -1) -> void:
 var single:bool=max_rarity<0
 var selected:Dictionary=profile.get_item(selected_uid)
 var summary:Dictionary={"count":0,"gold":0}
 var title:String=""
 if single:
  if selected.is_empty():return
  for equipped_uid in profile.data.equipped.values():
   if int(equipped_uid)==selected_uid:return
  summary={"count":1,"gold":Profile.SALVAGE_VALUES[int(selected.rarity)]}
  title=profile.get_template(selected.template).name+" を解体"
 else:
  summary=profile.salvage_preview(max_rarity)
  title=("レア以下" if max_rarity==1 else "エピック以下")+"を一括解体"
 if int(summary.count)<=0:return
 var veil:=ColorRect.new()
 veil.name="SalvageConfirmation"
 veil.color=Color(0.01,0.005,0.01,0.88);veil.size=Vector2(1280,720)
 veil.mouse_filter=Control.MOUSE_FILTER_STOP;ui.add_child(veil)
 var card:=Panel.new();card.position=Vector2(315,205);card.size=Vector2(650,310)
 var style:=StyleBoxFlat.new();style.bg_color=Color("201419");style.border_color=Color("d4a16c");style.set_border_width_all(2)
 card.add_theme_stylebox_override("panel",style);veil.add_child(card)
 var caption:=Label.new();caption.name="SalvageSummary"
 caption.text="%s\n\n対象 %d 個　 /　 獲得資金 %d\n装備中は対象外。魔石は所持品に戻ります。" % [title,summary.count,summary.gold]
 caption.position=Vector2(25,32);caption.size=Vector2(600,170);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;caption.add_theme_font_size_override("font_size",21);card.add_child(caption)
 var cancel:=Button.new();cancel.text="戻る";cancel.position=Vector2(60,230);cancel.size=Vector2(230,55);cancel.pressed.connect(veil.queue_free);card.add_child(cancel)
 var apply:=Button.new();apply.name="ConfirmSalvage";apply.text="解体する";apply.position=Vector2(360,230);apply.size=Vector2(230,55)
 var uid:int=selected_uid
 apply.pressed.connect(func():
  var result:Dictionary=profile.salvage_item(uid) if single else profile.salvage_bulk(max_rarity)
  if int(result.count)>0:save_profile()
  selected_uid=-1
  show_inventory()
 )
 card.add_child(apply)
func show_inventory() -> void:
 if OS.has_feature("web"):JavaScriptBridge.eval("window.dispatchEvent(new Event('mimic-leave-title'))")
 if state!="inventory":preview_slot="fang";selected_uid=-1
 state="inventory";clear_ui();heading("装備を整える")
 label("①  枠を選ぶ",Vector2(50,103),Vector2(380,32),20).modulate=Color("e6c29c")
 label("②  装備を選んで比較",Vector2(560,103),Vector2(250,32),20).modulate=Color("e6c29c")
 var rare_bulk:=button("レア以下を全て解体",Vector2(800,100),Vector2(205,40),func():confirm_salvage(1),int(profile.salvage_preview(1).count)==0)
 rare_bulk.add_theme_font_size_override("font_size",15)
 var epic_bulk:=button("エピック以下を全て解体",Vector2(1015,100),Vector2(220,40),func():confirm_salvage(2),int(profile.salvage_preview(2).count)==0)
 epic_bulk.add_theme_font_size_override("font_size",15)
 var slots_order:=["fang","shell","organ1","organ2","organ3","organ4","core"]
 for i in slots_order.size():
  var slot:String=slots_order[i]
  var locked:bool=slot=="organ4" and not profile.data.upgrades.get("organ_slot",false)
  var equipped:Dictionary=profile.get_item(int(profile.data.equipped.get(slot,-1)))
  var description:String="封印中" if locked else ("空き" if equipped.is_empty() else str(profile.get_template(equipped.template).name))
  var slot_button:=button(("▶ " if preview_slot==slot else "")+SLOTS[slot]+"\n"+description,Vector2(46+(i%2)*238,148+int(i/2)*106),Vector2(226,96),func():select_equipment_slot(slot),locked)
  slot_button.alignment=HORIZONTAL_ALIGNMENT_LEFT
  slot_button.add_theme_font_size_override("font_size",17)
  if not equipped.is_empty():
   slot_button.icon=icon_textures.get(profile.get_template(equipped.template).family)
   slot_button.expand_icon=true
  var style:StyleBoxFlat=theme.get_stylebox("normal","Button").duplicate()
  style.bg_color=Color("3a2022") if preview_slot==slot else Color("1a1216")
  style.border_color=Color("e4b37e") if preview_slot==slot else Color("6b4c46")
  style.set_border_width_all(2 if preview_slot==slot else 1)
  slot_button.add_theme_stylebox_override("normal",style)
  if locked:slot_button.tooltip_text="貢ぎ物の祭壇で『異形の器』を解放"
 label("器官4は貢ぎ物で解放",Vector2(48,598),Vector2(450,28),16).modulate=Color("c3a898")
 var current:Dictionary=profile.get_item(int(profile.data.equipped.get(preview_slot,-1)))
 button("選んだ枠の装備を外す",Vector2(46,637),Vector2(464,48),remove_equipment_from_slot,current.is_empty())
 var expected:String="organ" if preview_slot.begins_with("organ") else preview_slot
 var candidates:=[]
 for item in profile.data.inventory:
  if profile.get_template(item.template).get("slot")==expected:candidates.append(item)
 label("%sに入る装備  /  %d個" % [SLOTS[preview_slot],candidates.size()],Vector2(560,140),Vector2(640,30),17).modulate=Color("d4b197")
 var box:=list_panel(Vector2(555,175),Vector2(670,182))
 if candidates.is_empty():
  var empty:=Label.new();empty.text="この枠に入る装備はまだありません。";empty.add_theme_font_size_override("font_size",18);box.add_child(empty)
 for item in candidates:
  var uid:int=item.uid
  var source_slot: String=""
  for existing_slot in profile.data.equipped:
   if int(profile.data.equipped[existing_slot])==uid:source_slot=existing_slot;break
  var marker:String=("  【この枠に装備中】" if source_slot==preview_slot else ("  【%sから移動】" % SLOTS[source_slot] if not source_slot.is_empty() else ""))
  var entry:=list_button(box,"%s  [%s]%s" % [profile.get_template(item.template).name,RARITY[int(item.rarity)],marker],func():selected_uid=uid;show_inventory())
  entry.add_theme_font_size_override("font_size",18)
  entry.icon=icon_textures.get(profile.get_template(item.template).family)
  style_item_button(entry,item)
 var selected:Dictionary=profile.get_item(selected_uid)
 if selected.is_empty() or profile.get_template(selected.template).get("slot")!=expected:
  selected_uid=-1
  label("装備を選ぶと、今の枠との違いを表示します。",Vector2(560,390),Vector2(650,70),18).modulate=Color("d6c5b3")
  return
 var t:Dictionary=profile.get_template(selected.template)
 var old_name:String=str(profile.get_template(current.template).name) if not current.is_empty() else "空き"
 label("%s： %s  →  %s" % [SLOTS[preview_slot],old_name,t.name],Vector2(560,375),Vector2(650,30),18).modulate=Color("f1d4ae")
 var info:=RichTextLabel.new()
 info.position=Vector2(560,410);info.size=Vector2(650,105);info.text=item_description(selected)
 info.add_theme_font_size_override("normal_font_size",17);info.add_theme_color_override("default_color",RARITY_COLORS[clampi(int(selected.rarity),0,4)])
 ui.add_child(info)
 var before_build:Array=profile.equipped_templates()
 var after_build:Array=[]
 var before_counts:={};var after_counts:={}
 for slot in profile.data.equipped:
  var equipped:Dictionary=profile.get_item(int(profile.data.equipped[slot]))
  if equipped.is_empty():continue
  var template:Dictionary=profile.get_template(equipped.template)
  var family:String=template.family
  before_counts[family]=int(before_counts.get(family,0))+1
  if slot!=preview_slot and int(equipped.uid)!=selected_uid:
   after_counts[family]=int(after_counts.get(family,0))+1
   var copy:Dictionary=template.duplicate(true);copy.item=equipped;after_build.append(copy)
 var replacement:Dictionary=t.duplicate(true);replacement.item=selected;after_build.append(replacement)
 after_counts[t.family]=int(after_counts.get(t.family,0))+1
 var current_battle=Battle.new(1);current_battle.configure(before_build,profile.data.upgrades)
 var proposed_battle=Battle.new(1);proposed_battle.configure(after_build,profile.data.upgrades)
 var changes:=""
 for family in Profile.FAMILIES:
  var before:int=int(before_counts.get(family,0));var after:int=int(after_counts.get(family,0))
  if before!=after:changes+="%s %d→%d%s  " % [FAMILY_NAMES[family],before,after," ★" if (before<2 and after>=2) or (before<4 and after>=4) else ""]
 if changes.is_empty():changes="系統の数に変化なし"
 var set_detail:String="\n召喚4：眷属の連鎖 / 命中時、周囲に威力50%" if int(after_counts.get("summon",0))>=4 else ""
 label("牙の威力 %+.1f　間隔 %+.2f秒　HP %+.0f　軽減 %+.1f%%\n%s\n★ は新しいセット効果（2個 / 4個）%s" % [proposed_battle.damage-current_battle.damage,proposed_battle.attack_interval-current_battle.attack_interval,proposed_battle.max_hp-current_battle.max_hp,(proposed_battle.stats.reduction-current_battle.stats.reduction)*100,changes,set_detail],Vector2(560,525),Vector2(650,95),17)
 var equipped_anywhere:=false
 for equipped_uid in profile.data.equipped.values():
  if int(equipped_uid)==selected_uid:equipped_anywhere=true;break
 var salvage:=button("解体  +%d資金" % Profile.SALVAGE_VALUES[int(selected.rarity)],Vector2(560,630),Vector2(250,54),func():confirm_salvage(),equipped_anywhere)
 salvage.add_theme_font_size_override("font_size",18)
 var already_equipped:bool=int(profile.data.equipped.get(preview_slot,-1))==selected_uid
 button("装備中" if already_equipped else "%sに装備する" % SLOTS[preview_slot],Vector2(835,630),Vector2(390,54),equip_selected_item,already_equipped)
func show_forge() -> void:
 if OS.has_feature("web"):JavaScriptBridge.eval("window.dispatchEvent(new Event('mimic-leave-title'))")
 state="forge";clear_ui();heading("鍛冶・魔石")
 var box:=list_panel(Vector2(40,95),Vector2(450,560))
 for item in profile.data.inventory:
  var uid:int=item.uid
  var entry:=list_button(box,inventory_item_name(item),func():selected_uid=uid;show_forge())
  var family:String=profile.get_template(item.template).family
  entry.icon=icon_textures.get(family)
  style_item_button(entry,item)
 var item:Dictionary=profile.get_item(selected_uid)
 var detail:=label(item_description(item),Vector2(525,105),Vector2(525,205),18)
 if not item.is_empty():detail.modulate=RARITY_COLORS[clampi(int(item.rarity),0,4)]
 if not item.is_empty():
  button("強化 %d 資金" % (25*(int(item.level)+1)),Vector2(525,320),Vector2(250,50),func():profile.upgrade_item(selected_uid);save_profile();show_forge())
  button("再抽選 40 資金",Vector2(795,320),Vector2(250,50),func():profile.reroll_item(selected_uid);save_profile();show_forge(),not profile.data.upgrades.get("reroll",false))
 if not item.is_empty() and not item.sockets.is_empty():
  button("最後の魔石を外す",Vector2(1060,320),Vector2(175,50),func():profile.remove_gem(selected_uid,item.sockets.size()-1);save_profile();show_forge())
 label("魔石：3個を合成 / 選択装備の空きソケットへ装着",Vector2(525,390),Vector2(700,40),17)
 var gems:=list_panel(Vector2(525,440),Vector2(710,210))
 for key in profile.data.gems.keys():
  if int(profile.data.gems[key])<=0: continue
  var pieces:PackedStringArray=key.split(":")
  var fam:String=pieces[0];var tier:int=int(pieces[1]);var qty:int=int(profile.data.gems[key])
  list_button(gems,"%s T%d ×%d　装着" % [FAMILY_NAMES.get(fam,fam),tier,qty],func():profile.socket_gem(selected_uid,fam,tier);save_profile();show_forge(),item.is_empty() or item.sockets.size()>=int(item.socket_count))
  list_button(gems,"%s T%d ×3 → T%d　合成" % [FAMILY_NAMES.get(fam,fam),tier,tier+1],func():profile.fuse_gem(fam,tier);save_profile();show_forge(),qty<3 or tier>=5 or not profile.data.upgrades.get("fusion",false))
func show_upgrades() -> void:
 if OS.has_feature("web"):JavaScriptBridge.eval("window.dispatchEvent(new Event('mimic-leave-title'))")
 state="upgrades";clear_ui();heading("貢ぎ物の祭壇")
 label("OFFERINGS   /   進化ポイントを彼女たちに捧げ、封印を解く",Vector2(65,96),Vector2(1050,30),16).modulate=Color("d6ab8b")
 var scroll:=ScrollContainer.new()
 scroll.position=Vector2(56,132);scroll.size=Vector2(1168,525)
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 ui.add_child(scroll)
 var grid:=GridContainer.new();grid.columns=3
 grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12)
 scroll.add_child(grid)
 for definition in Profile.UPGRADE_DEFS:
  var key:String=definition.key
  var level:int=int(profile.data.upgrades.get(key,0))
  var unsealed:bool=profile.upgrade_unsealed(key)
  var complete:bool=level>=int(definition.max)
  var requirement:Dictionary=profile.upgrade_definition(definition.requires)
  var status:String="封印  /  %s が必要" % requirement.get("name", "") if not unsealed else ("解放済み" if complete else ("無償で封印を解く" if profile.upgrade_cost(key)==0 else "供物 %d 進化ポイント" % profile.upgrade_cost(key)))
  var entry:=Button.new()
  entry.text="%sに捧ぐ  /  %s\n%s\n%s" % [COMPANIONS[definition.recipient],definition.name,definition.desc,status]
  entry.icon=companion_textures.get(definition.recipient,icon_textures.get(definition.family))
  entry.expand_icon=true
  entry.custom_minimum_size=Vector2(365,112)
  entry.alignment=HORIZONTAL_ALIGNMENT_LEFT
  entry.add_theme_font_size_override("font_size",15)
  entry.add_theme_color_override("font_disabled_color",Color("c1aba3") if unsealed else Color("a08c89"))
  entry.disabled=not unsealed or complete or int(profile.data.points)<profile.upgrade_cost(key)
  var card:StyleBoxFlat=theme.get_stylebox("normal","Button").duplicate()
  card.bg_color=Color("281719") if unsealed else Color("141116")
  card.border_color=Color("ad7855") if unsealed else Color("49353a")
  card.border_width_left=3 if unsealed else 1
  entry.add_theme_stylebox_override("normal",card)
  entry.add_theme_stylebox_override("disabled",card)
  entry.pressed.connect(func():purchase_upgrade(key))
  grid.add_child(entry)
func purchase_upgrade(key: String) -> void:
 var definition:Dictionary=profile.upgrade_definition(key)
 if not profile.upgrade(key):return
 save_profile()
 show_upgrades()
 show_unlock_celebration(definition)
func show_unlock_celebration(definition: Dictionary) -> void:
 var veil:=ColorRect.new()
 veil.color=Color(0.01,0.005,0.01,0.84);veil.size=Vector2(1280,720)
 veil.mouse_filter=Control.MOUSE_FILTER_STOP;ui.add_child(veil)
 var card:=Panel.new();card.position=Vector2(360,150);card.size=Vector2(560,410)
 var style:=StyleBoxFlat.new();style.bg_color=Color("201116");style.border_color=Color("d4a16c");style.set_border_width_all(2);style.shadow_size=20;style.shadow_color=Color(0,0,0,0.8)
 card.add_theme_stylebox_override("panel",style);veil.add_child(card)
 var icon:=TextureRect.new();icon.texture=companion_textures.get(definition.recipient,icon_textures.get(definition.family));icon.position=Vector2(232,42);icon.size=Vector2(96,96);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;card.add_child(icon)
 var caption:=Label.new();caption.text="✦   OFFERING ACCEPTED   ✦\n"+str(COMPANIONS[definition.recipient])+"への供物\n"+str(definition.name)+"\n"+str(definition.desc);caption.position=Vector2(30,151);caption.size=Vector2(500,150);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.add_theme_font_size_override("font_size",22);card.add_child(caption)
 var close:=Button.new();close.text="進化を刻む";close.position=Vector2(150,320);close.size=Vector2(260,55);close.pressed.connect(veil.queue_free);card.add_child(close)
 if not profile.data.get("settings",{}).get("reduce_fx",false):
  card.pivot_offset=card.size/2;card.scale=Vector2(0.88,0.88);card.modulate.a=0.0
  var tween:=create_tween().set_parallel();tween.tween_property(card,"modulate:a",1.0,0.3);tween.tween_property(card,"scale",Vector2.ONE,0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
func show_collection() -> void:
 if OS.has_feature("web"):JavaScriptBridge.eval("window.dispatchEvent(new Event('mimic-leave-title'))")
 state="collection";clear_ui();heading("伝説の収集庫")
 var box:=list_panel(Vector2(60,95),Vector2(1120,570))
 for t in profile.templates:
  if t.has("unique"):
   var found:bool=t.id in profile.data.collection
   var name:String=t.name if found else "？？？？"
   var unique:String=UNIQUE_TEXT.get(t.unique,t.unique) if found else "未発見"
   list_button(box,"%s　%s" % [name,unique],func():pass,true)
func show_settings() -> void:
 if OS.has_feature("web"):JavaScriptBridge.eval("window.dispatchEvent(new Event('mimic-leave-title'))")
 state="settings";clear_ui();heading("設定")
 label("照準：マウスの位置 / タッチしてドラッグ\n照準方向へ自動発射。SPACE / ボムボタンで破滅の供物。\nボムは20秒ごと、爆破撃破の資金は3倍。\nセーブはこのブラウザのローカル領域に保存します。",Vector2(80,120),Vector2(1080,180),22)
 var settings:Dictionary=profile.data.get("settings",{})
 var guide:bool=settings.get("aim_guide",true)
 var reduced:bool=settings.get("reduce_fx",false)
 button("照準ガイド："+("表示" if guide else "非表示"),Vector2(80,330),Vector2(420,55),func():settings.aim_guide=not guide;profile.data.settings=settings;save_profile();show_settings())
 button("エフェクト："+("控えめ" if reduced else "通常"),Vector2(80,400),Vector2(420,55),func():settings.reduce_fx=not reduced;profile.data.settings=settings;save_profile();show_settings())
 var sound_enabled:bool=settings.get("sound",true)
 button("音を確認",Vector2(600,400),Vector2(420,55),func():kill_sound.pitch_scale=0.8;kill_sound.play(),not sound_enabled)
 button("素材クレジット",Vector2(600,470),Vector2(420,55),show_credits)
 button("効果音："+("オン" if sound_enabled else "オフ"),Vector2(80,470),Vector2(420,55),func():settings.sound=not sound_enabled;profile.data.settings=settings;save_profile();show_settings())
 var music_enabled:bool=settings.get("music",true)
 button("BGM："+("オン" if music_enabled else "オフ"),Vector2(80,540),Vector2(420,55),toggle_music)
func toggle_music() -> void:
 var settings:Dictionary=profile.data.get("settings",{})
 settings.music=not bool(settings.get("music",true))
 profile.data.settings=settings
 if not settings.music:music_player.stop()
 save_profile();show_settings()
func show_credits() -> void:
 state="credits";clear_ui();heading("素材クレジット")
 var box:=list_panel(Vector2(60,105),Vector2(1120,550))
 var credit:=Label.new()
 credit.name="ThirdPartyLicenses"
 credit.custom_minimum_size=Vector2(1060,0)
 credit.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 credit.add_theme_font_size_override("font_size",17)
 credit.text="報酬エフェクト：pixelfx / Patch, Hugo Duprez\nhttps://github.com/patch-gg/pixelfx\nMIT License\n\n"
 credit.text+=FileAccess.get_file_as_string("res://assets/fx/pixelfx/LICENSE.txt")
 credit.text+="\n\n"+FileAccess.get_file_as_string("res://assets/fx/pixelfx/UPSTREAM-NOTICE.md")
 credit.text+="\n\n効果音：\n"+FileAccess.get_file_as_string("res://assets/audio/oculus/ATTRIBUTION.md")
 credit.text+="\n一部を短縮・フェード加工しています。\n\n"+FileAccess.get_file_as_string("res://assets/audio/oculus/LICENSE.txt")
 credit.text+="\n\n戦闘BGM：Dark Knight / Tanner Helland\nhttps://github.com/tannerhelland/free-music\nCC BY 4.0：Vorbis変換・フェード加工\nhttps://creativecommons.org/licenses/by/4.0/\n\n"
 credit.text+=FileAccess.get_file_as_string("res://assets/audio/tanner/LICENSE.txt")
 box.add_child(credit)
func play_rarity_sound(rarity: int) -> void:
 if not profile.data.get("settings",{}).get("sound",true):return
 if rarity>=3:
  var voice:AudioStreamPlayer=legendary_sounds[legendary_sound_index]
  legendary_sound_index=(legendary_sound_index+1)%legendary_sounds.size()
  voice.pitch_scale=1.2 if rarity==4 else 1.0
  voice.play()
 elif rarity>=1:
  rarity_sound.pitch_scale=1.25 if rarity==2 else 1.0
  rarity_sound.play()

# After victory the combat simulation has ended; keep only its visual debris moving.
func animate_victory_effects(delta: float) -> void:
 for spark in battle.sparks:
  if spark.active:
   spark.pos+=spark.vel*delta;spark.vel*=0.95;spark.ttl-=delta
   if spark.ttl<=0:spark.active=false
 for fx in battle.effects:
  if fx.active:
   fx.ttl-=delta
   if fx.ttl<=0:fx.active=false
 for impact in battle.impacts:
  if impact.active:
   impact.ttl-=delta
   if impact.ttl<=0:impact.active=false
 for tongue in battle.tongue_overflow:
  if tongue.active:
   tongue.ttl-=delta
   if tongue.ttl<=0:tongue.active=false
 for pop in battle.popups:
  if pop.active:
   pop.ttl-=delta;pop.pos.y-=delta*30
   if pop.ttl<=0:pop.active=false

func _process(delta: float) -> void:
 if OS.has_feature("web"):poll_web_storage()
 if persistence_kind=="load":return
 if state!="battle" and music_player.playing:music_player.stop()
 toast_t=maxf(0,toast_t-delta)
 if state=="title" and not profile.data.get("settings",{}).get("reduce_fx",false):
  hub_time+=delta;hub_redraw_clock+=delta
  if hub_redraw_clock>=0.05:hub_redraw_clock=0.0;queue_redraw()
 if state=="battle":
  hit_sound_cooldown=maxf(0.0,hit_sound_cooldown-delta)
  var reduced:bool=profile.data.get("settings",{}).get("reduce_fx",false)
  reward_fx.update(delta)
  if reward_fx.pending_sound_rarity>=0:
   play_rarity_sound(reward_fx.pending_sound_rarity)
   reward_fx.pending_sound_rarity=-1
  if benchmark_mode: battle.hp=battle.max_hp
  var speed:float=0.35 if reward_fx.slow_remaining>0.0 and not reduced else 1.0
  if battle.ended and reward_fx.boss_full_reveal and reward_fx.boss_result_wait>0.0:
   animate_victory_effects(minf(delta,0.05)*speed)
  else:
   battle.update(minf(delta,0.05)*speed)
  if is_instance_valid(bomb_button):
   bomb_button.disabled=battle.bomb_remaining>0 or battle.ended
   bomb_button.text=("破滅の供物   %.1f秒\n撃破資金 ×3" % battle.bomb_remaining) if battle.bomb_remaining>0 else "破滅の供物   READY\nSPACE / 撃破資金 ×3"
  if battle.shots>previous_shots:
   reward_fx.attack_pulse=0.14
   if profile.data.get("settings",{}).get("sound",true):shot_sound.play()
   previous_shots=battle.shots
  if battle.impact_serial>previous_impacts:
   if hit_sound_cooldown<=0.0 and profile.data.get("settings",{}).get("sound",true):
    var hit_voice:AudioStreamPlayer=hit_sounds[hit_sound_index]
    hit_sound_index=(hit_sound_index+1)%hit_sounds.size()
    hit_voice.pitch_scale=1.16 if battle.impact_critical_pending else 1.0
    hit_voice.play();hit_sound_cooldown=0.09
   previous_impacts=battle.impact_serial;battle.impact_critical_pending=false
  var needs_save:=false
  for event in battle.loot_events:
   if not event.active:continue
   needs_save=true
   event.active=false
   var death_position:Vector2=Vector2.INF if event.boss else event.position
   var pitch:float=reward_fx.on_kill(death_position,reduced,event.get("bomb",false))
   if pitch>0.0 and profile.data.get("settings",{}).get("sound",true):
    kill_sound.pitch_scale=pitch*0.8;kill_sound.play()
    kill_thump.pitch_scale=pitch*0.85;kill_thump.play()
   if event.boss:
    reward_fx.boss(event.position,event.kind,reduced)
    if profile.data.get("settings",{}).get("sound",true):boss_sound.play()
   var gold:int=(5+selected_stage*3)*(Battle.BOMB_GOLD_MULTIPLIER if event.get("bomb",false) else 1)
   reward_fx.money(event.position,gold,event.get("bomb",false))
   profile.data.gold+=gold;run_gold+=gold
   if event.boss or battle.rng.randf()<float(profile.balance.drop_chance[selected_stage])+float(profile.data.upgrades.get("drop",0))*0.02+float(battle.stats.drop):
    var item:Dictionary=profile.drop(selected_stage,event.boss)
    if not item.is_empty():
     var template:Dictionary=profile.get_template(item.template)
     if reward_fx.item(int(item.rarity),template.name,event.position,reduced,event.boss,template.family):play_rarity_sound(int(item.rarity))
     # Preserve the final drop icon briefly before replacing the battle with results.
     if battle.ended:reward_fx.boss_result_wait=maxf(reward_fx.boss_result_wait,0.85)
     battle.scatter(event.position,"arcane",5)
   if battle.rng.randf()<0.12: profile.add_gem(Profile.FAMILIES[battle.rng.randi_range(0,6)])
  if needs_save:save_profile()
  if battle.ended:
   if not reward_given and not reduced and reward_fx.banners.any(func(b):return b.active):
    reward_fx.boss_result_wait=maxf(reward_fx.boss_result_wait,1.0)
   finalize_battle_rewards()
   if reward_fx.boss_result_wait<=0.0:show_result()
  queue_redraw()
func finalize_battle_rewards() -> void:
 if reward_given:return
 var points:int=int(battle.kills/5)+int(battle.elapsed/30)+(20 if battle.won else 0)
 profile.data.points+=points
 if battle.won:profile.data.unlocked_stage=maxi(int(profile.data.unlocked_stage),mini(1,selected_stage+1))
 save_profile();reward_given=true
func show_result() -> void:
 music_player.stop()
 finalize_battle_rewards()
 state="result"
 clear_ui()
 label("狩りの成功" if battle.won else "宝箱は沈黙した",Vector2(380,150),Vector2(600,70),42)
 label("撃破 %d  /  獲得資金 %d  /  経過 %d秒\n装備、資金、魔石、進化ポイントは保持されます。" % [battle.kills,run_gold,battle.elapsed],Vector2(340,250),Vector2(720,90),21)
 if reward_fx and reward_fx.boss_item_rarity>=0:
  var boss_loot:=label("ボスの戦利品：%s  [%s]" % [reward_fx.boss_item_name,RARITY[reward_fx.boss_item_rarity]],Vector2(340,335),Vector2(720,34),18)
  boss_loot.modulate=RARITY_COLORS[reward_fx.boss_item_rarity]
 button("もう一度",Vector2(320,380),Vector2(300,60),start_battle)
 button("装備を確認",Vector2(650,380),Vector2(300,60),show_inventory)
 button("拠点へ",Vector2(485,460),Vector2(300,60),show_title)
func try_bomb() -> void:
 if state=="battle" and battle.use_bomb():queue_redraw()
func _input(event: InputEvent) -> void:
 if persistence_kind=="load":return
 if state=="battle" and event is InputEventKey and event.keycode==KEY_SPACE and event.pressed and not event.echo:
  try_bomb();get_viewport().set_input_as_handled()
func _gui_input(event: InputEvent) -> void:
 if persistence_kind=="load" or state!="battle":return
 if event is InputEventMouseMotion:
  var v:Vector2=event.position-Battle.CENTER
  if v.length()>2:battle.aim=v.normalized()
 if event is InputEventScreenTouch and event.pressed:
  touch_origin=event.position
 if event is InputEventScreenDrag:
  var v:Vector2=event.position-touch_origin
  if v.length()>2:battle.aim=v.normalized()
func panel(rect:Rect2, accent:bool=false) -> void:
 draw_rect(rect,Color(0.045,0.025,0.035,0.91))
 draw_rect(rect,Color("87604f") if accent else Color("503b40"),false,1.0)
 draw_line(rect.position+Vector2(12,3),rect.position+Vector2(minf(110,rect.size.x-12),3),Color("b88869"),2)
 draw_rect(Rect2(rect.position+Vector2(5,5),Vector2(3,3)),Color("d2aa81"))
 draw_rect(Rect2(rect.position+rect.size-Vector2(8,8),Vector2(3,3)),Color("d2aa81"))
# Draw the pre-rendered effect only; the pixelfx library is never run in game.
func draw_reward_atlas(name: String, position: Vector2, progress: float, scale: float, tint: Color, angle: float = 0.0) -> void:
 var atlas:Dictionary=reward_atlases.get(name,{})
 if atlas.is_empty():return
 var meta:Dictionary=atlas.meta
 var dims:=Vector2(float(meta.frameSize[0]),float(meta.frameSize[1]))
 var pivot:=Vector2(float(meta.pivot[0]),float(meta.pivot[1]))
 var frame:int=mini(int(meta.frames)-1,int(clampf(progress,0.0,1.0)*float(meta.frames)))
 var columns:int=int(meta.columns)
 var source:=Rect2(Vector2((frame%columns)*dims.x,int(frame/columns)*dims.y),dims)
 if absf(angle)>0.001:
  draw_set_transform(position.round(),angle,Vector2.ONE)
  draw_texture_rect_region(atlas.texture,Rect2(-pivot*scale,dims*scale),source,tint)
  draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
 else:
  var target:=Rect2((position-pivot*scale).round(),dims*scale)
  draw_texture_rect_region(atlas.texture,target,source,tint)

func draw_tongue(fx: Dictionary) -> void:
 var direction:Vector2=(fx.to-fx.from).normalized()
 var side:Vector2=direction.orthogonal()
 var extension:float=minf(clampf((Battle.TONGUE_DURATION-float(fx.ttl))/Battle.TONGUE_REACH_TIME,0.0,1.0),clampf(float(fx.ttl)/0.09,0.0,1.0))
 var tip:Vector2=fx.from.lerp(fx.to,extension)
 var length:float=fx.from.distance_to(tip)
 var bend:float=minf(15.0,length*0.04)
 var positions:=[0.0,0.18,0.40,0.65,0.85,1.0]
 var widths:=[11.0,17.0,22.0,21.0,17.0,11.0]
 var left:=PackedVector2Array();var right:=PackedVector2Array()
 var inner_left:=PackedVector2Array();var inner_right:=PackedVector2Array()
 var ridge:=PackedVector2Array()
 for i in positions.size():
  var t:float=positions[i]
  var center:Vector2=fx.from.lerp(tip,t)+side*(sin(t*PI*1.7)*bend)
  var width:float=widths[i]
  left.append(center+side*width);right.insert(0,center-side*width)
  inner_left.append(center+side*(width-4));inner_right.insert(0,center-side*(width-4))
  ridge.append(center-side*3.0)
 left.append_array(right);inner_left.append_array(inner_right)
 draw_colored_polygon(left,Color("531923"))
 draw_colored_polygon(inner_left,Color("b53b50"))
 draw_polyline(ridge,Color("f0a1a1"),5.0)
 draw_circle(tip,11,Color("b53b50"))
 draw_circle(tip-direction*3-side*2,5,Color("ffd1bb"))
 draw_line(tip-direction*3,tip+direction*4,Color("6b2531"),2)
 if fx.get("splash",false):
  var splash_color:=Color(0.88,0.35,0.39,0.55)
  splash_color.a*=clampf(float(fx.ttl)/0.12,0.0,1.0)
  draw_arc(fx.splash_center,65.0,0.0,TAU,32,splash_color,2.0)

# Several independent attacks can overlap. Render one tongue, prioritising the
# strike that just landed, then the next strike to land. All hits remain intact.
func visible_tongue() -> Dictionary:
 var chosen:Dictionary=no_tongue
 var best_score:float=-INF
 for fx in battle.effects:
  if not fx.active or fx.family!="devour":continue
  var score:float=tongue_visual_score(fx)
  if score>best_score:best_score=score;chosen=fx
 for fx in battle.tongue_overflow:
  if not fx.active:continue
  var score:float=tongue_visual_score(fx)
  if score>best_score:best_score=score;chosen=fx
 return chosen

func tongue_visual_score(fx: Dictionary) -> float:
 if not fx.active or fx.family!="devour":return -INF
 var age:float=Battle.TONGUE_DURATION-float(fx.ttl)
 var score:float=float(fx.ttl)
 if fx.get("hit",false) and age<=Battle.TONGUE_REACH_TIME+0.06:score+=300.0
 elif fx.get("pending",false):score+=200.0+age
 elif fx.get("hit",false):score+=100.0
 return score

func draw_chest_without_resting_tongue(rect: Rect2, tint: Color) -> void:
 var unit:Vector2=rect.size/128.0
 # Draw around the cutout first: transparent source pixels must not reveal
 # the old tongue underneath the patch.
 for source in TONGUE_BODY_PIECES:
  draw_texture_rect_region(mimic_texture,Rect2(rect.position+source.position*unit,source.size*unit),source,tint)
 for patch in TONGUE_COVER:
  var target:Rect2=patch[0]
  var source:Rect2=patch[1]
  draw_texture_rect_region(mimic_texture,Rect2(rect.position+target.position*unit,target.size*unit),source,tint)

func _draw() -> void:
 draw_rect(Rect2(0,0,1280,720),Color("08070b"))
 if state=="battle":
  draw_texture_rect(backgrounds[selected_stage],Rect2(0,0,1280,720),false)
 elif state=="title" and hub_texture:
  draw_texture_rect(hub_texture,Rect2(0,0,1280,720),false)
 elif dungeon_texture:
  var tint:=Color(0.76,0.74,0.78,1.0) if selected_stage==0 else Color(0.82,0.60,0.65,1.0)
  draw_texture_rect(dungeon_texture,Rect2(0,0,1280,720),false,tint)
 else:draw_texture(backgrounds[selected_stage],Vector2.ZERO)
 if state!="battle":
  draw_rect(Rect2(0,0,1280,720),Color(0.015,0.008,0.015,0.10 if state=="title" else 0.70))
  draw_line(Vector2(40,84),Vector2(1240,84),Color("6b4d49"),1)
  if state=="title":
   # Shadowed left vignette keeps the title readable while leaving the lair visible.
   draw_rect(Rect2(0,0,450,300),Color(0.015,0.006,0.012,0.35))
   draw_line(Vector2(64,153),Vector2(315,153),Color("a47754"),1)
   # Small embers rise from the candles; reduced-effects mode leaves the scene still.
   if not profile.data.get("settings",{}).get("reduce_fx",false):
    for i in 7:
     var phase:float=fposmod(hub_time*16.0+i*13.0,82.0)
     var x:float=675.0+i*48.0+sin(hub_time*0.7+i)*4.0
     var y:float=442.0-(i%3)*27.0-phase
     var alpha:float=0.45*(1.0-phase/82.0)
     draw_rect(Rect2(roundf(x),roundf(y),2,2),Color(1.0,0.53,0.25,alpha))
   draw_rect(Rect2(0,563,1280,157),Color(0.025,0.008,0.012,0.68))
   draw_line(Vector2(45,577),Vector2(1230,577),Color("a77b58"),1)

  elif state in ["inventory","forge"]:
   panel(Rect2(30,88,490 if state=="inventory" else 470,610))
   panel(Rect2(540 if state=="inventory" else 513,88,698 if state=="inventory" else 725,610))
   var selected:Dictionary=profile.get_item(selected_uid)
   if state=="forge" and not selected.is_empty():
    var family:String=profile.get_template(selected.template).family
    var item_icon:Texture2D=icon_textures.get(family)
    var frame_color:Color=RARITY_COLORS[clampi(int(selected.rarity),0,4)]
    draw_rect(Rect2(1091,119,100,100),frame_color,false,1)
    if item_icon:draw_texture_rect(item_icon,Rect2(1093,121,96,96),false)
  elif state in ["upgrades","collection","settings","stages","credits"]:
   panel(Rect2(30,88,1210,592))
  elif state=="result":panel(Rect2(300,125,680,435),true)
  return
 # Reward sprites are behind the enemies, aim guide, and HUD so targets stay readable.
 if not profile.data.get("settings",{}).get("reduce_fx",false):
  for burst in reward_fx.death_bursts:
   if burst.active:
    var death_tint:=Color(1.0,0.72,0.58,0.85) if burst.bomb else Color(1.0,0.78,0.68,0.72)
    draw_reward_atlas("hit-spark",burst.pos+Vector2(0,10),1.0-float(burst.ttl)/0.38,0.9 if burst.bomb else 0.7,death_tint)
  for spark in reward_fx.pickup_sparks:
   if spark.active:
    var sparkle_tint:Color=Color.WHITE.lerp(RARITY_COLORS[int(spark.rarity)],0.55)
    sparkle_tint.a=0.9
    draw_reward_atlas("collect-burst",spark.pos+Vector2(0,24),1.0-float(spark.ttl)/0.55,0.8,sparkle_tint)
  if reward_fx.beam_remaining>0.0 and reward_fx.beam_remaining<0.35:
   var beam_tint:Color=Color.WHITE.lerp(RARITY_COLORS[reward_fx.beam_rarity],0.3)
   beam_tint.a=0.8
   var beam_pos:Vector2=reward_fx.beam_position.clamp(Vector2(48,105),Vector2(1232,690))
   draw_reward_atlas("holy-pillar",beam_pos,1.0-reward_fx.beam_remaining/0.35,0.8,beam_tint)
 if reward_fx.boss_reveal_remaining>0.0:
  var boss_tex:Texture2D=enemy_textures.get(reward_fx.boss_kind)
  if boss_tex:
   var ghost_alpha:float=clampf(reward_fx.boss_reveal_remaining/reward_fx.boss_reveal_total,0.0,1.0)
   draw_texture_rect(boss_tex,Rect2(reward_fx.boss_position-Vector2(48,48),Vector2(96,96)),false,Color(1,0.8,0.7,ghost_alpha))
  if reward_fx.boss_full_reveal and not profile.data.get("settings",{}).get("reduce_fx",false):
   var boss_tint:=Color(0.94,0.66,0.51,0.75)
   draw_reward_atlas("implosion",reward_fx.boss_position,1.0-reward_fx.boss_reveal_remaining/reward_fx.boss_reveal_total,0.5,boss_tint)
 # Direction guide stays above reward effects.
 if profile.data.get("settings",{}).get("aim_guide",true):
  var sight:Vector2=Battle.CENTER+battle.aim*125
  var side:Vector2=battle.aim.orthogonal()
  draw_line(sight-battle.aim*7-side*7,sight+battle.aim*5,Color(0.94,0.70,0.48,0.7),2)
  draw_line(sight-battle.aim*7+side*7,sight+battle.aim*5,Color(0.94,0.70,0.48,0.7),2)
 for e in battle.enemies:
  if e.active:
   var size:float=96.0 if e.boss else 64.0
   var margin:float=70.0 if e.boss else size*0.5
   if e.pos.x < -margin or e.pos.x > 1280+margin or e.pos.y < -margin or e.pos.y > 720+margin:continue
   var tex:Texture2D=enemy_textures.get(e.kind)
   var bob:float=roundf(sin(battle.elapsed*7.0+float(e.index))*1.3)
   if tex:draw_texture_rect(tex,Rect2(e.pos-Vector2(size,size)*0.5+Vector2(0,bob),Vector2(size,size)),false)
   if e.kind=="shield":
    var facing:Vector2=(Battle.CENTER-e.pos).normalized()
    if facing.length_squared()>0.0:draw_arc(e.pos,32.0,facing.angle()-PI/4,facing.angle()+PI/4,12,Color("b9a782"),2.0)
   if e.boss:
    draw_rect(Rect2(e.pos+Vector2(-45,-60),Vector2(90,6)),Color("301622"))
    draw_rect(Rect2(e.pos+Vector2(-45,-60),Vector2(90*maxf(0,e.hp/e.max_hp),6)),Color("e45b6e"))
 # Local hit sparks show the true contact point; they never shift aim or enemy positions.
 if not profile.data.get("settings",{}).get("reduce_fx",false):
  for impact in battle.impacts:
   if impact.active:
    var crit:bool=impact.critical
    var impact_tint:=Color(1.0,0.86,0.7,0.9) if crit else Color(1.0,0.75,0.68,0.75)
    var spark_pos:Vector2=impact.pos+Vector2(0,16 if crit else 12)
    draw_reward_atlas("crit-hit" if crit else "hit-spark",spark_pos,1.0-float(impact.ttl)/float(impact.duration),1.0 if crit else 0.8,impact_tint,float(impact.angle))
 for p in battle.projectiles:
  if p.active:
   if p.pos.x < -20 or p.pos.x > 1300 or p.pos.y < -20 or p.pos.y > 740:continue
   var c:Color=FAM_COLORS.get(p.family,Color("e85f56"))
   var direction:Vector2=p.vel.normalized()
   draw_line(p.pos-direction*13,p.pos,c.darkened(0.5),5)
   draw_circle(p.pos,5,c)
   draw_rect(Rect2(p.pos-Vector2(2,2),Vector2(4,4)),Color("fff0d6"))
 var reduced_fx:bool=profile.data.get("settings",{}).get("reduce_fx",false)
 for spark in battle.sparks:
  if spark.active and not reduced_fx:
   if spark.pos.x < -4 or spark.pos.x > 1284 or spark.pos.y < -4 or spark.pos.y > 724:continue
   var spark_color:Color=FAM_COLORS.get(spark.family,Color.WHITE)
   draw_rect(Rect2(spark.pos,Vector2(3,3)),spark_color)
 for fx in battle.effects:
  if fx.active:
   var c:Color=FAM_COLORS.get(fx.family,Color.WHITE)
   var fade:float=clampf(fx.ttl/0.18,0.25,1.0)
   c.a=fade
   if fx.family=="devour":continue
   if fx.family=="blade":
    var direction:float=(fx.to-fx.from).angle()
    var r:float=maxf(50.0,fx.radius)
    draw_arc(fx.from,r,direction-0.9,direction+0.9,20,c.darkened(0.6),9)
    draw_arc(fx.from,r,direction-0.9,direction+0.9,20,c,4)
    draw_arc(fx.from,r-7,direction-0.7,direction+0.7,16,Color("fff1d7"),1)
   elif fx.family=="bomb":
    var r:float=fx.radius*(1.0-clampf(fx.ttl/0.55,0.0,1.0)*0.3)
    draw_circle(fx.to,r,Color(0.65,0.12,0.07,0.18*fade))
    draw_arc(fx.to,r,0,TAU,40,c.darkened(0.5),9)
    draw_arc(fx.to,r-5,0,TAU,40,c,3)
    for n in 8:
     var ray:=Vector2.from_angle(n*TAU/8.0)
     draw_line(fx.to+ray*(r*0.65),fx.to+ray*(r*1.08),c,3)
   elif fx.family in ["poison","defense","arcane","hex","summon"]:
    if fx.from.distance_to(fx.to)>5:draw_line(fx.from,fx.to,c.darkened(0.45),2)
    var r:float=maxf(14.0,fx.radius)
    draw_arc(fx.to,r,0,TAU,28,c.darkened(0.55),5)
    draw_arc(fx.to,r-3,0,TAU,28,c,2)
    draw_arc(fx.to,r*0.62,0,TAU,20,c.darkened(0.35),1)
   else:
    draw_line(fx.from,fx.to,c,3)
    if fx.radius>0:draw_arc(fx.to,fx.radius,0,TAU,24,c,2)
 var dominant:String=battle.dominant_family()
 var tint:Color=Color.WHITE
 if int(battle.family_counts.get(dominant,0))>=4: tint=FAM_COLORS.get(dominant,Color.WHITE).lerp(Color.WHITE,0.55)
 var mimic_bob:Vector2=Vector2(0,roundf(sin(battle.elapsed*2.2)))
 var pulse:float=0.0 if reduced_fx else clampf(reward_fx.attack_pulse/0.14,0.0,1.0)
 var mimic_size:=Vector2(128.0+8.0*pulse,128.0-5.0*pulse)
 var mimic_rect:=Rect2(Battle.CENTER-mimic_size*0.5+mimic_bob,mimic_size)
 var tongue:Dictionary=visible_tongue()
 var has_devour_part:bool=battle.family_counts.has("devour") and part_textures.has("devour")
 draw_circle(Battle.CENTER+Vector2(0,35),47,Color(0,0,0,0.50))
 if mimic_texture:
  if tongue.is_empty() and not has_devour_part:draw_texture_rect(mimic_texture,mimic_rect,false,tint)
  else:draw_chest_without_resting_tongue(mimic_rect,tint)
 if int(battle.family_counts.get(dominant,0))>=4:
  for x in [-28,0,28]:
   draw_rect(Rect2(Battle.CENTER+Vector2(x-4,-45),Vector2(8,5)),FAM_COLORS.get(dominant,Color.WHITE))
 for fam in battle.family_counts:
  if fam=="devour" and not tongue.is_empty():continue # the animated tongue is already visible
  var tex:Texture2D=part_textures.get(fam)
  if tex:draw_texture_rect(tex,mimic_rect,false)
 # Draw tongues above the mimic so a close-range hit is never hidden by its body.
 if not tongue.is_empty():draw_tongue(tongue)
 # Briefly show the acquired family icon at its actual drop location.
 for icon in reward_fx.drop_icons:
  if not icon.active:continue
  var rarity:int=int(icon.rarity)
  var displayed:int=maxi(0,rarity-1) if float(icon.reveal)>0.0 else rarity
  var alpha:float=clampf(float(icon.ttl)/0.18,0.0,1.0)
  var lift:float=0.0 if reduced_fx else (1.0-clampf(float(icon.ttl)/RewardFX.DROP_ICON_LIFETIME,0.0,1.0))*16.0
  var rect:=Rect2(icon.pos-Vector2(28,50+lift),Vector2(56,56))
  draw_rect(rect,Color(0.035,0.02,0.025,0.94*alpha))
  var tex:Texture2D=icon_textures.get(str(icon.family))
  if tex:draw_texture_rect(tex,rect.grow(-4),false,Color(1,1,1,alpha))
  var rarity_tint:Color=RARITY_COLORS[displayed];rarity_tint.a=alpha
  if not reduced_fx:
   var glow:Color=rarity_tint;glow.a*=0.23
   draw_rect(rect.grow(4),glow,false,3.0)
  draw_rect(rect,rarity_tint,false,4.0)
  draw_rect(Rect2(rect.position+Vector2(4,4),Vector2(6,6)),rarity_tint)
 if battle.family_counts.get("blade",0)>0:
  var orbit_center:Vector2=Battle.CENTER+battle.aim*45
  var blade_count:int=mini(9,1+int(battle.family_counts.blade)+(int(battle.family_counts.blade) if "extra_blades" in battle.unique_ids else 0))
  for n in blade_count:
   var orbit_pos:Vector2=orbit_center+Vector2.from_angle(battle.elapsed*2+n*TAU/blade_count)*80
   draw_rect(Rect2(orbit_pos-Vector2(3,8),Vector2(6,16)),FAM_COLORS.blade)
 for minion in battle.minions:
  if minion.active:draw_texture_rect(mimic_texture,Rect2(minion.pos-Vector2(16,16),Vector2(32,32)),false)
 for pop in battle.popups:
  if not pop.active:continue
  var crit:bool=pop.critical
  var pop_color:=Color("ffd071") if crit else Color("fff2d3")
  var pop_size:int=32 if crit else 25
  var pop_text:String=str(pop.value)+( "!" if crit else "")
  draw_string_outline(title_font,pop.pos,pop_text,HORIZONTAL_ALIGNMENT_CENTER,100,pop_size,3,Color(0.08,0.02,0.025,0.9))
  draw_string(title_font,pop.pos,pop_text,HORIZONTAL_ALIGNMENT_CENTER,100,pop_size,pop_color)
 panel(Rect2(18,16,310,72),true)
 draw_string(title_font,Vector2(32,37),"MIMIC   /   VITALITY",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("d1aa94"))
 draw_string(title_font,Vector2(32,63),"HP  %d / %d" % [battle.hp,battle.max_hp],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("fff0dc"))
 draw_rect(Rect2(160,48,146,12),Color("3b202a"))
 draw_rect(Rect2(160,48,146*maxf(0,battle.hp/battle.max_hp),12),Color("d34d5f"))
 if reward_fx.kill_count>=3:
  var chain_text:String="連続撃破  %d" % reward_fx.kill_count
  draw_string_outline(title_font,Vector2(475,56),chain_text,HORIZONTAL_ALIGNMENT_CENTER,330,32,3,Color(0.08,0.02,0.025,0.9))
  draw_string(title_font,Vector2(475,56),chain_text,HORIZONTAL_ALIGNMENT_CENTER,330,32,Color("ffc787"))
 panel(Rect2(952,16,310,72),true)
 draw_string(title_font,Vector2(970,37),"THE HUNT   /   %s" % ("I" if selected_stage==0 else "II"),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("d1aa94"))
 draw_string(title_font,Vector2(970,64),"%03d / 300秒     撃破 %d" % [battle.elapsed,battle.kills],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("fff0dc"))
 if benchmark_mode:
  var active_count:int=0
  for e in battle.enemies:
   if e.active:active_count+=1
  draw_string(title_font,Vector2(20,110),"BENCHMARK: %d ENEMIES" % active_count,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
 draw_reward_overlay()
 if toast_t>0:draw_string(title_font,Vector2(900,75),toast,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("f1d99a"))

func draw_reward_overlay() -> void:
 var reduced:bool=profile.data.get("settings",{}).get("reduce_fx",false)
 if reward_fx.edge_remaining>0.0 and not reduced:
  var glow:Color=RARITY_COLORS[reward_fx.edge_rarity]
  glow.a=0.11*clampf(reward_fx.edge_remaining/0.32,0.0,1.0)
  draw_rect(Rect2(0,0,14,720),glow);draw_rect(Rect2(1266,0,14,720),glow)
  draw_rect(Rect2(0,0,1280,10),glow);draw_rect(Rect2(0,710,1280,10),glow)
 for pop in reward_fx.money_popups:
  if not pop.active:continue
  var age:float=pop.age
  var rise:float=minf(1.0,age/0.20)
  var bounce:float=sin(rise*PI)*12.0 if pop.bomb and not reduced else 0.0
  var alpha:float=clampf(float(pop.ttl)/0.20,0.0,1.0)
  var color:Color=Color("ffcf65") if pop.bomb else Color("c3b5a5")
  color.a=alpha
  var rise_offset:float=0.0 if reduced else age*32.0
  var point:Vector2=pop.pos+Vector2(-30,-18-rise_offset-bounce)
  var gold_text:String="+%d" % int(pop.value)
  var gold_size:int=28 if pop.bomb else 19
  draw_string_outline(title_font,point,gold_text,HORIZONTAL_ALIGNMENT_CENTER,90,gold_size,3,Color(0.08,0.025,0.015,alpha*0.9))
  draw_string(title_font,point,gold_text,HORIZONTAL_ALIGNMENT_CENTER,90,gold_size,color)
 var row:=0
 for rarity in range(reward_fx.notifications.size()-1,-1,-1):
  var notice:Dictionary=reward_fx.notifications[rarity]
  if not notice.active:continue
  var r:int=notice.rarity
  var hidden:bool=notice.reveal>0.0
  var displayed:int=maxi(0,r-1) if hidden else r
  var col:Color=RARITY_COLORS[displayed]
  var rect:=Rect2(22,106+row*53,350,48)
  draw_rect(rect,Color(0.04,0.025,0.035,0.93))
  draw_rect(rect,col,false,2 if r>=1 else 1)
  draw_rect(Rect2(rect.position+Vector2(0,0),Vector2(4,rect.size.y)),col)
  if not reduced and notice.pulse>0.0:
   var pulse_color:Color=col;pulse_color.a=0.20*float(notice.pulse)/0.3
   draw_rect(rect,pulse_color)
  var rank:String="？？？" if hidden else RARITY[r]
  var count_label:String="  ×%d" % int(notice.count) if int(notice.count)>1 else ""
  draw_string(title_font,rect.position+Vector2(13,19),rank+count_label,HORIZONTAL_ALIGNMENT_LEFT,320,18,col)
  var item_name:String="？？？？" if hidden else str(notice.name)
  if int(notice.count)>1 and not hidden:item_name="最後："+item_name
  draw_string(title_font,rect.position+Vector2(13,42),item_name,HORIZONTAL_ALIGNMENT_LEFT,320,23,Color("fff0db"))
  row+=1
 if reduced:return
 var banner_row:=0
 for banner in reward_fx.banners:
  if not banner.active or banner.delay>0.0:continue
  var banner_y:float=200.0 if reward_fx.boss_full_reveal and reward_fx.boss_result_wait>0.0 else 112.0
  var rect:=Rect2(410,banner_y+banner_row*50,460,44)
  var col:Color=RARITY_COLORS[int(banner.rarity)]
  draw_rect(rect,Color(0.055,0.025,0.035,0.92));draw_rect(rect,col,false,2)
  var extra:String="  他 +%d" % int(banner.extra) if int(banner.extra)>0 else ""
  draw_line(rect.position+Vector2(12,5),rect.position+Vector2(110,5),col,2.0)
  draw_line(rect.position+Vector2(350,5),rect.position+Vector2(448,5),col,2.0)
  draw_string(title_font,rect.position+Vector2(12,30),"◆ %s%s" % [banner.name,extra],HORIZONTAL_ALIGNMENT_CENTER,436,21,col)
  banner_row+=1
 if reward_fx.boss_full_reveal and reward_fx.boss_result_wait>0.0:
  var rect:=Rect2(450,105,380,82)
  draw_rect(rect,Color(0.045,0.02,0.035,0.94));draw_rect(rect,Color("d6ac7a"),false,2)
  var spinning:bool=reward_fx.boss_reveal_remaining>0.0
  draw_string(title_font,rect.position+Vector2(15,22),"BOSS DROP   /   %s" % ("鑑定中" if spinning else "確定"),HORIZONTAL_ALIGNMENT_LEFT,350,15,Color("eee1cf"))
  var cycle:int=int((reward_fx.boss_reveal_total-reward_fx.boss_reveal_remaining)*12.0)%RARITY_COLORS.size()
  var revealed:int=reward_fx.boss_item_rarity
  var slot_color:Color=RARITY_COLORS[cycle] if spinning else (RARITY_COLORS[revealed] if revealed>=0 else Color("6e6165"))
  draw_rect(Rect2(rect.position+Vector2(18,37),Vector2(32,20)),slot_color)
  var result:String="戦利品を開示" if spinning else (RARITY[revealed]+"  "+reward_fx.boss_item_name if revealed>=0 else "装備なし")
  draw_string(title_font,rect.position+Vector2(65,54),result,HORIZONTAL_ALIGNMENT_LEFT,300,16,Color("e9dccd") if spinning else slot_color)
