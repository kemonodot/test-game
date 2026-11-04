extends SceneTree
const Profile=preload("res://src/profile.gd")

func _initialize() -> void:call_deferred("run")
func run() -> void:
 var entries:Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/index-cc0/selection.json"))
 assert(entries.size()==9)
 for entry in entries:
  assert(entry.license=="CC0-1.0")
  var path:String="res://assets/audio/index-cc0/"+str(entry.file_ogg).get_file()
  assert(FileAccess.get_sha256(path)==entry.sha256_ogg,"Downloaded SFX must match the index checksum")
 assert(FileAccess.get_sha256("res://assets/audio/jaggedstone/dungeon-hall.ogg")=="ff7d0f8a49023605661b10e10253fb39278fc86153757dce9dffdbd222de9944")
 var app=load("res://main.tscn").instantiate();root.add_child(app)
 app.profile=Profile.new(false);app.profile.data.settings={"sound":true,"music":false}
 assert(app.music_player.stream.resource_path.ends_with("dungeon-hall.ogg") and app.music_player.stream.loop)
 assert(not app.play_music_preview() and not app.music_player.playing)
 app.profile.data.settings.music=true;app.apply_music_volume()
 assert(is_equal_approx(app.music_player.volume_db,-2.0))
 assert(app.play_music_preview() and app.music_player.playing)
 app._process(0.1);assert(app.music_player.playing)
 app._process(app.MUSIC_PREVIEW_SECONDS);assert(not app.music_player.playing)
 app.toggle_music_volume()
 assert(app.profile.data.settings.music_level==2 and is_equal_approx(app.music_player.volume_db,3.0))
 var restored=Profile.new(true)
 assert(restored.data.settings.music_level==2)
 app.profile.data.settings.music=false;app.show_title()
 assert(app.ui_sound.stream.resource_path.ends_with("click1.ogg"))
 assert(app.casino_sound.stream.resource_path.ends_with("chips-handle-3.ogg"))
 var limiter_found:=false
 var bus:int=AudioServer.get_bus_index("Master")
 for i in AudioServer.get_bus_effect_count(bus):
  if AudioServer.get_bus_effect(bus,i) is AudioEffectLimiter:limiter_found=true
 assert(limiter_found)
 app.show_title()
 await process_frame
 var hunt:Button
 for child in app.ui.get_children():
  if child is Button and child.get("title")=="狩場へ進む":hunt=child;break
 assert(hunt!=null)
 hunt.pressed.emit()
 assert(app.state=="stages" and app.ui_sound.playing)
 app.ui_sound.stop();app.profile.data.settings.sound=false
 app.play_ui_sound();assert(not app.ui_sound.playing)
 app.profile.data.settings.sound=true
 app.casino_sound.stop();app.play_rarity_sound(2);assert(not app.casino_sound.playing)
 app.play_rarity_sound(3);assert(app.casino_sound.playing)
 app.set_process(false)
 for child in app.get_children():
  if child is AudioStreamPlayer:child.stop()
 await create_timer(0.4).timeout
 app.queue_free();app=null;await process_frame
 print("CC0 AUDIO: verified source hashes, UI mute, actual legendary sound, limiter and loop")
 quit(0)
