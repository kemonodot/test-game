extends Control
const Battle = preload("res://src/combat.gd")
const Profile = preload("res://src/profile.gd")
const FAMILY_NAMES := {"devour":"捕食","blade":"刃物","hex":"呪術","poison":"毒・腐食","summon":"召喚","defense":"防御","arcane":"魔力"}
const SLOTS := {"fang":"牙","organ1":"器官1","organ2":"器官2","organ3":"器官3","organ4":"器官4","shell":"甲殻","core":"核"}
const ABILITY_TEXT := {"bite":"噛みつき", "tongue":"伸びる舌", "maw":"広範囲の捕食", "pull":"敵を引き寄せる", "hide":"防護", "hunger":"飢餓の一撃", "slash":"正面斬り", "orbit":"偏った回転刃", "pierce":"貫く斬撃", "counter":"方向反撃", "curse":"呪い", "mark":"呪印と破裂", "spray":"毒液噴霧", "pool":"毒の残留域", "summon":"小箱召喚", "heal":"再生", "armor":"防御", "bolt":"追尾魔弾", "nova":"魔力の範囲攻撃"}
const UNIQUE_TEXT := {"devour_chain":"連続捕食で威力・対象数が増加", "extra_blades":"刃物装備の数に応じて回転刃が強化", "curse_spread":"呪印のある敵の死亡時に周囲へ呪印を伝播", "poison_burst":"毒霧に即時腐食ダメージが加わる", "extra_minions":"召喚体の追撃が増加", "wide_counter":"反撃の範囲が拡大", "double_nova":"魔力攻撃が範囲攻撃に変化", "cleave":"刃が進行方向の敵をまとめて斬る", "curse_chain":"呪印を周囲の敵にも刻む", "last_stand":"致命傷を一度だけ耐える"}
const RARITY_COLORS := [Color("d8cbbd"),Color("8db8cf"),Color("c3a1d4"),Color("e8bb7a"),Color("e78a87")]
const RARITY := ["コモン","レア","エピック","レジェンダリー","ミシック"]
var battle: MimicCombat
var profile
var state := "title"
var selected_stage := 0
var selected_uid := -1
var preview_slot := ""
var ui: Control
var title_font: Font
var toast := ""
var toast_t := 0.0
var touch_origin := Vector2.ZERO
var run_gold := 0
var reward_given := false
var shot_sound: AudioStreamPlayer
var kill_sound: AudioStreamPlayer
var previous_shots := 0
var benchmark_mode := false
var web_quick_callback
var mimic_texture: Texture2D
var concept_texture: Texture2D
var dungeon_texture: Texture2D
var part_textures := {}
var enemy_textures := {}
var icon_textures := {}
var backgrounds := []
const FAM_COLORS := {"devour":Color("e75c72"),"blade":Color("dbccb0"),"hex":Color("d483da"),"poison":Color("8dc26e"),"summon":Color("e6ad68"),"defense":Color("d5cb98"),"arcane":Color("8eb5ef"),"enemy":Color("e85656")}

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
 if dungeon_texture:
  var scene_image:Image=dungeon_texture.get_image()
  scene_image.resize(1280,720,Image.INTERPOLATE_NEAREST)
  dungeon_texture=ImageTexture.create_from_image(scene_image)
 for stage_index in 2:
  var img:=Image.create_empty(1280,720,false,Image.FORMAT_RGBA8)
  img.fill(Color("08070b") if stage_index==0 else Color("10080e"))
  var tile_color:=Color("17121a") if stage_index==0 else Color("1b1017")
  for y in range(0,720,80):
   for x in range(0,1280,80):
    var offset:int=40 if int(y/80)%2 else 0
    img.fill_rect(Rect2i(x+offset,y,78,1),tile_color)
    img.fill_rect(Rect2i(x+offset,y,1,78),tile_color)
  backgrounds.append(ImageTexture.create_from_image(img))
 for fam in Profile.FAMILIES:
  part_textures[fam]=load("res://assets/art/parts/%s.png" % fam)
  icon_textures[fam]=load("res://assets/art/icons/%s.png" % fam)
 for kind in ["swordsman","shield","archer","mage","priest","thief","fanatic","lancer","hero","captain"]:
  enemy_textures[kind]=load("res://assets/art/enemies/%s.png" % kind)
 profile = Profile.new()
 shot_sound=AudioStreamPlayer.new();shot_sound.stream=make_sound(155.0,0.055);shot_sound.volume_db=-18;add_child(shot_sound)
 kill_sound=AudioStreamPlayer.new();kill_sound.stream=make_sound(78.0,0.13);kill_sound.volume_db=-16;add_child(kill_sound)
 ui = Control.new()
 ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(ui)
 show_title()
 if OS.has_feature("web"):
  web_quick_callback=JavaScriptBridge.create_callback(_web_quick_start)
  JavaScriptBridge.get_interface("window").mimicQuickStart=web_quick_callback
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
func _web_quick_start(_args: Array) -> void:
 if state=="title":
  selected_stage=0
  start_battle()
func make_sound(frequency: float, duration: float) -> AudioStreamWAV:
 var wav:=AudioStreamWAV.new()
 wav.format=AudioStreamWAV.FORMAT_16_BITS
 wav.mix_rate=22050
 var frames:int=int(wav.mix_rate*duration)
 var bytes:=PackedByteArray()
 bytes.resize(frames*2)
 for i in frames:
  var envelope:float=pow(1.0-float(i)/frames,2.0)
  var sample:float=(sin(TAU*frequency*i/wav.mix_rate)+0.35*sin(TAU*frequency*2.7*i/wav.mix_rate))*envelope
  bytes.encode_s16(i*2,int(clampf(sample*9000,-32768,32767)))
 wav.data=bytes
 return wav
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
func show_title() -> void:
 state="title"; clear_ui()
 if OS.has_feature("web"):JavaScriptBridge.eval("window.dispatchEvent(new Event('mimic-title'))")
 label("THE HUNGRY RELIQUARY   /   01",Vector2(100,92),Vector2(510,28),14).modulate=Color("dfb18b")
 label("M I M I C",Vector2(96,118),Vector2(530,100),64)
 label("宝箱は動かない。飢えだけが進化する。",Vector2(100,208),Vector2(560,42),21).modulate=Color("d9c3af")
 label("資金  %d     /     進化  %d" % [profile.data.gold,profile.data.points],Vector2(100,258),Vector2(490,35),18).modulate=Color("c6a593")
 var play:=button("狩場へ進む      →",Vector2(100,318),Vector2(505,64),show_stages)
 play.add_theme_font_size_override("font_size",22)
 button("装備と構築",Vector2(100,397),Vector2(245,55),show_inventory)
 button("鍛冶・魔石",Vector2(360,397),Vector2(245,55),show_forge)
 button("永続強化",Vector2(100,465),Vector2(245,55),show_upgrades)
 button("収集庫",Vector2(360,465),Vector2(245,55),show_collection)
 button("設定",Vector2(100,533),Vector2(505,48),show_settings)
 label("自動攻撃  /  マウスまたはドラッグで狙う",Vector2(100,615),Vector2(520,30),14).modulate=Color("aa928b")
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
 if OS.has_feature("web"):JavaScriptBridge.eval("window.dispatchEvent(new Event('mimic-leave-title'))")
 clear_ui()
 battle=Battle.new(Time.get_ticks_usec())
 battle.stage=selected_stage
 battle.configure(profile.equipped_templates(),profile.data.upgrades)
 state="battle";run_gold=0;reward_given=false;previous_shots=0
 var starting:int=int(profile.data.upgrades.get("starting_gold",0))*10
 profile.data.gold+=starting
 run_gold+=starting
 profile.save_game()
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
func show_inventory() -> void:
 if OS.has_feature("web"):JavaScriptBridge.eval("window.dispatchEvent(new Event('mimic-leave-title'))")
 state="inventory";clear_ui();heading("装備の比較・変更")
 if profile.get_item(selected_uid).is_empty() and not profile.data.inventory.is_empty():selected_uid=int(profile.data.inventory[0].uid)
 label("所持品  /  INVENTORY",Vector2(56,93),Vector2(500,30),14).modulate=Color("d0a183")
 var box:=list_panel(Vector2(40,125),Vector2(530,540))
 for item in profile.data.inventory:
  var uid: int=item.uid
  var entry:=list_button(box,inventory_item_name(item),func():selected_uid=uid;preview_slot="";show_inventory())
  var family:String=profile.get_template(item.template).family
  entry.icon=icon_textures.get(family)
  style_item_button(entry,item)
 var selected: Dictionary=profile.get_item(selected_uid)
 label("選択した装備  /  SELECTED",Vector2(600,94),Vector2(600,25),14).modulate=Color("d0a183")
 var detail:=label(item_description(selected),Vector2(600,128),Vector2(465,190),18)
 if not selected.is_empty():detail.modulate=RARITY_COLORS[clampi(int(selected.rarity),0,4)]
 if selected.is_empty(): return
 var t: Dictionary=profile.get_template(selected.template)
 var compatible:Array=[]
 for slot in SLOTS:
  if ("organ" if slot.begins_with("organ") else slot)==t.slot and (slot!="organ4" or profile.data.upgrades.get("organ_slot",false)):
   compatible.append(slot)
 if compatible.is_empty():return
 if preview_slot not in compatible:preview_slot=compatible[0]
 var previous:Dictionary=profile.get_item(int(profile.data.equipped.get(preview_slot,-1)))
 var old_t:Dictionary=profile.get_template(previous.template) if not previous.is_empty() else {}
 var before_build: Array=profile.equipped_templates()
 var after_build: Array=[]
 for slot in profile.data.equipped:
  var equipped:Dictionary=profile.get_item(int(profile.data.equipped[slot]))
  if not equipped.is_empty() and slot!=preview_slot and int(equipped.uid)!=selected_uid:
   var template:Dictionary=profile.get_template(equipped.template).duplicate(true)
   template.item=equipped
   after_build.append(template)
 var replacement:Dictionary=t.duplicate(true)
 replacement.item=selected
 after_build.append(replacement)
 var current_battle=Battle.new(1)
 current_battle.configure(before_build,profile.data.upgrades)
 var proposed_battle=Battle.new(1)
 proposed_battle.configure(after_build,profile.data.upgrades)
 var delta:float=proposed_battle.damage-current_battle.damage
 var hp_delta:float=proposed_battle.max_hp-current_battle.max_hp
 var cooldown_delta:float=proposed_battle.attack_interval-current_battle.attack_interval
 var reduction_delta:float=(proposed_battle.stats.reduction-current_battle.stats.reduction)*100
 var before_counts:={}
 var after_counts:={}
 for slot in profile.data.equipped:
  var equipped:Dictionary=profile.get_item(int(profile.data.equipped[slot]))
  if equipped.is_empty():continue
  var family:String=profile.get_template(equipped.template).family
  before_counts[family]=int(before_counts.get(family,0))+1
  if slot!=preview_slot and int(equipped.uid)!=selected_uid:after_counts[family]=int(after_counts.get(family,0))+1
 after_counts[t.family]=int(after_counts.get(t.family,0))+1
 var changes:=""
 for family in Profile.FAMILIES:
  var before:int=int(before_counts.get(family,0))
  var after:int=int(after_counts.get(family,0))
  if before!=after:changes+="%s %d→%d%s  " % [FAMILY_NAMES[family],before,after," ★" if (before<2 and after>=2) or (before<4 and after>=4) else ""]
 label("%sへ変更：牙の威力 %+.1f / 間隔 %+.2f秒\nHP %+.0f / 軽減 %+.1f%%\n%s\n2 / 4個でセット発動（★：新規発動）" % [SLOTS[preview_slot],delta,cooldown_delta,hp_delta,reduction_delta,changes],Vector2(600,325),Vector2(620,100),17)
 var x:=600
 for slot in compatible:
  var target:String=slot
  button(("◆ " if preview_slot==slot else "")+SLOTS[slot],Vector2(x,435),Vector2(110,52),func():preview_slot=target;show_inventory())
  x+=120
 button("この枠に装備",Vector2(600,510),Vector2(250,52),func():profile.equip(selected_uid,preview_slot);profile.save_game();show_inventory())
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
  button("強化 %d 資金" % (25*(int(item.level)+1)),Vector2(525,320),Vector2(250,50),func():profile.upgrade_item(selected_uid);profile.save_game();show_forge())
  button("再抽選 40 資金",Vector2(795,320),Vector2(250,50),func():profile.reroll_item(selected_uid);profile.save_game();show_forge(),not profile.data.upgrades.get("reroll",false))
 if not item.is_empty() and not item.sockets.is_empty():
  button("最後の魔石を外す",Vector2(1060,320),Vector2(175,50),func():profile.remove_gem(selected_uid,item.sockets.size()-1);profile.save_game();show_forge())
 label("魔石：3個を合成 / 選択装備の空きソケットへ装着",Vector2(525,390),Vector2(700,40),17)
 var gems:=list_panel(Vector2(525,440),Vector2(710,210))
 for key in profile.data.gems.keys():
  if int(profile.data.gems[key])<=0: continue
  var pieces:PackedStringArray=key.split(":")
  var fam:String=pieces[0];var tier:int=int(pieces[1]);var qty:int=int(profile.data.gems[key])
  list_button(gems,"%s T%d ×%d　装着" % [FAMILY_NAMES.get(fam,fam),tier,qty],func():profile.socket_gem(selected_uid,fam,tier);profile.save_game();show_forge(),item.is_empty() or item.sockets.size()>=int(item.socket_count))
  list_button(gems,"%s T%d ×3 → T%d　合成" % [FAMILY_NAMES.get(fam,fam),tier,tier+1],func():profile.fuse_gem(fam,tier);profile.save_game();show_forge(),qty<3 or tier>=5 or not profile.data.upgrades.get("fusion",false))
func show_upgrades() -> void:
 if OS.has_feature("web"):JavaScriptBridge.eval("window.dispatchEvent(new Event('mimic-leave-title'))")
 state="upgrades";clear_ui();heading("永続強化")
 var box:=list_panel(Vector2(60,95),Vector2(1120,570))
 var upgrades := [["hp","最大HP"],["damage","攻撃力"],["organ_slot","器官枠 +1"],["reroll","再抽選を解放"],["fusion","魔石合成を解放"],["starting_gold","開始資金"],["drop","ドロップ率"],["family_hex","呪術を解放"],["family_poison","毒・腐食を解放"],["family_summon","召喚を解放"],["family_defense","防御を解放"]]
 for pair in upgrades:
  var key:String=pair[0];var level:int=int(profile.data.upgrades.get(key,0))
  var cost:int=(8 if key in ["hp","damage"] else 15)*(level+1)
  list_button(box,"%s   Lv%d   /   %d 進化ポイント" % [pair[1],level,cost],func():profile.upgrade(key);profile.save_game();show_upgrades())
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
 label("照準：マウスの位置 / タッチしてドラッグ\n戦闘中の攻撃は自動。画面比率は16:9です。\nセーブはこのブラウザのローカル領域に保存します。",Vector2(80,120),Vector2(1080,180),22)
 var settings:Dictionary=profile.data.get("settings",{})
 var guide:bool=settings.get("aim_guide",true)
 var reduced:bool=settings.get("reduce_fx",false)
 button("照準ガイド："+("表示" if guide else "非表示"),Vector2(80,330),Vector2(420,55),func():settings.aim_guide=not guide;profile.data.settings=settings;profile.save_game();show_settings())
 button("エフェクト："+("控えめ" if reduced else "通常"),Vector2(80,400),Vector2(420,55),func():settings.reduce_fx=not reduced;profile.data.settings=settings;profile.save_game();show_settings())
 var sound_enabled:bool=settings.get("sound",true)
 button("効果音："+("オン" if sound_enabled else "オフ"),Vector2(80,470),Vector2(420,55),func():settings.sound=not sound_enabled;profile.data.settings=settings;profile.save_game();show_settings())
func _process(delta: float) -> void:
 toast_t=maxf(0,toast_t-delta)
 if state=="battle":
  if benchmark_mode: battle.hp=battle.max_hp
  battle.update(minf(delta,0.05))
  if battle.shots>previous_shots:
   if profile.data.get("settings",{}).get("sound",true):shot_sound.play()
   previous_shots=battle.shots
  var needs_save:=false
  for event in battle.loot_events:
   if not event.active:continue
   needs_save=true
   event.active=false
   if profile.data.get("settings",{}).get("sound",true):kill_sound.play()
   var gold:int=5+selected_stage*3
   profile.data.gold+=gold;run_gold+=gold
   if event.boss or battle.rng.randf()<float(profile.balance.drop_chance[selected_stage])+float(profile.data.upgrades.get("drop",0))*0.02+float(battle.stats.drop):
    var item:Dictionary=profile.drop(selected_stage,event.boss)
    if not item.is_empty():
     toast="獲得："+profile.get_template(item.template).name;toast_t=3
     battle.scatter(event.position,"arcane",5)
   if battle.rng.randf()<0.12: profile.add_gem(Profile.FAMILIES[battle.rng.randi_range(0,6)])
  if needs_save:profile.save_game()
  if battle.ended: show_result()
  queue_redraw()
func show_result() -> void:
 state="result"
 if not reward_given:
  var points:int=int(battle.kills/5)+int(battle.elapsed/30)+(20 if battle.won else 0)
  profile.data.points+=points
  if battle.won:profile.data.unlocked_stage=maxi(int(profile.data.unlocked_stage),mini(1,selected_stage+1))
  profile.save_game();reward_given=true
 clear_ui()
 label("狩りの成功" if battle.won else "宝箱は沈黙した",Vector2(380,150),Vector2(600,70),42)
 label("撃破 %d  /  獲得資金 %d  /  経過 %d秒\n装備、資金、魔石、進化ポイントは保持されます。" % [battle.kills,run_gold,battle.elapsed],Vector2(340,250),Vector2(720,90),21)
 button("もう一度",Vector2(320,380),Vector2(300,60),start_battle)
 button("装備を確認",Vector2(650,380),Vector2(300,60),show_inventory)
 button("拠点へ",Vector2(485,460),Vector2(300,60),show_title)
func _gui_input(event: InputEvent) -> void:
 if state!="battle":return
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
func _draw() -> void:
 draw_rect(Rect2(0,0,1280,720),Color("08070b"))
 if dungeon_texture:
  var tint:=Color(0.76,0.74,0.78,1.0) if selected_stage==0 else Color(0.82,0.60,0.65,1.0)
  draw_texture_rect(dungeon_texture,Rect2(0,0,1280,720),false,tint)
 else:draw_texture(backgrounds[selected_stage],Vector2.ZERO)
 if state!="battle":
  draw_rect(Rect2(0,0,1280,720),Color(0.015,0.008,0.015,0.70))
  draw_line(Vector2(40,84),Vector2(1240,84),Color("6b4d49"),1)
  if state=="title":
   panel(Rect2(68,70,568,566),true)
   if concept_texture:draw_texture_rect(concept_texture,Rect2(680,80,530,530),false)
  elif state in ["inventory","forge"]:
   panel(Rect2(30,88,550 if state=="inventory" else 470,592))
   panel(Rect2(588 if state=="inventory" else 513,88,650 if state=="inventory" else 725,592))
   var selected:Dictionary=profile.get_item(selected_uid)
   if not selected.is_empty():
    var family:String=profile.get_template(selected.template).family
    var item_icon:Texture2D=icon_textures.get(family)
    var frame_color:Color=RARITY_COLORS[clampi(int(selected.rarity),0,4)]
    draw_rect(Rect2(1091,119,100,100),frame_color,false,1)
    if item_icon:draw_texture_rect(item_icon,Rect2(1093,121,96,96),false)
  elif state in ["upgrades","collection","settings","stages"]:
   panel(Rect2(30,88,1210,592))
  elif state=="result":panel(Rect2(300,125,680,435),true)
  return
 # Direction guide remains visible beneath the battle effects.
 if profile.data.get("settings",{}).get("aim_guide",true):
  draw_line(Battle.CENTER+battle.aim*64,battle.aim*120+Battle.CENTER,Color(0.94,0.55,0.40,0.65),2)
  var sight:Vector2=Battle.CENTER+battle.aim*125
  draw_circle(sight,3,Color("f0c392"))
 for e in battle.enemies:
  if e.active:
   var size:float=96.0 if e.boss else 64.0
   var margin:float=70.0 if e.boss else size*0.5
   if e.pos.x < -margin or e.pos.x > 1280+margin or e.pos.y < -margin or e.pos.y > 720+margin:continue
   var tex:Texture2D=enemy_textures.get(e.kind)
   var bob:float=roundf(sin(battle.elapsed*7.0+float(e.index))*1.3)
   if tex:draw_texture_rect(tex,Rect2(e.pos-Vector2(size,size)*0.5+Vector2(0,bob),Vector2(size,size)),false)
   if e.boss:
    draw_rect(Rect2(e.pos+Vector2(-45,-60),Vector2(90,6)),Color("301622"))
    draw_rect(Rect2(e.pos+Vector2(-45,-60),Vector2(90*maxf(0,e.hp/e.max_hp),6)),Color("e45b6e"))
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
   if fx.family=="devour":
    draw_line(fx.from,fx.to,c.darkened(0.55),10)
    draw_line(fx.from,fx.to,c,5)
    draw_line(fx.from,fx.to,Color("ffd1b4"),1)
    draw_arc(fx.to,12,0,TAU,12,c,2)
   elif fx.family=="blade":
    var direction:float=(fx.to-fx.from).angle()
    var r:float=maxf(50.0,fx.radius)
    draw_arc(fx.from,r,direction-0.9,direction+0.9,20,c.darkened(0.6),9)
    draw_arc(fx.from,r,direction-0.9,direction+0.9,20,c,4)
    draw_arc(fx.from,r-7,direction-0.7,direction+0.7,16,Color("fff1d7"),1)
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
 draw_circle(Battle.CENTER+Vector2(0,35),47,Color(0,0,0,0.50))
 if mimic_texture:draw_texture_rect(mimic_texture,Rect2(Battle.CENTER-Vector2(64,64)+mimic_bob,Vector2(128,128)),false,tint)
 if int(battle.family_counts.get(dominant,0))>=4:
  for x in [-28,0,28]:
   draw_rect(Rect2(Battle.CENTER+Vector2(x-4,-45),Vector2(8,5)),FAM_COLORS.get(dominant,Color.WHITE))
 for fam in battle.family_counts:
  var tex:Texture2D=part_textures.get(fam)
  if tex:draw_texture_rect(tex,Rect2(Battle.CENTER-Vector2(64,64)+mimic_bob,Vector2(128,128)),false)
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
  draw_string(title_font,pop.pos,str(pop.value),HORIZONTAL_ALIGNMENT_CENTER,60,16,Color("fff2d3"))
 panel(Rect2(18,16,310,72),true)
 draw_string(title_font,Vector2(32,37),"MIMIC   /   VITALITY",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("d1aa94"))
 draw_string(title_font,Vector2(32,63),"HP  %d / %d" % [battle.hp,battle.max_hp],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("fff0dc"))
 draw_rect(Rect2(160,48,146,12),Color("3b202a"))
 draw_rect(Rect2(160,48,146*maxf(0,battle.hp/battle.max_hp),12),Color("d34d5f"))
 panel(Rect2(952,16,310,72),true)
 draw_string(title_font,Vector2(970,37),"THE HUNT   /   %s" % ("I" if selected_stage==0 else "II"),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("d1aa94"))
 draw_string(title_font,Vector2(970,64),"%03d / 300秒     撃破 %d" % [battle.elapsed,battle.kills],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("fff0dc"))
 if benchmark_mode:
  var active_count:int=0
  for e in battle.enemies:
   if e.active:active_count+=1
  draw_string(title_font,Vector2(20,110),"BENCHMARK: %d ENEMIES" % active_count,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
 if toast_t>0:draw_string(title_font,Vector2(900,75),toast,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("f1d99a"))
