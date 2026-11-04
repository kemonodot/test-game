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
 assert(FileAccess.get_sha256("res://assets/audio/jaggedstone/dungeon-hall.ogg")=="85419bca9f7da2ea87ff70d10482fb02ebf91f25ceb95d4d4d63f110576d8c02")
 var app=load("res://main.tscn").instantiate();root.add_child(app)
 app.profile=Profile.new(false);app.profile.data.settings={"sound":true,"music":false}
 assert(app.music_player.stream.resource_path.ends_with("dungeon-hall.ogg") and app.music_player.stream.loop)
 assert(app.ui_sound.stream.resource_path.ends_with("click1.ogg"))
 assert(app.casino_sound.stream.resource_path.ends_with("chips-handle-3.ogg"))
 var limiter_found:=false
 var bus:int=AudioServer.get_bus_index("Master")
 for i in AudioServer.get_bus_effect_count(bus):
  if AudioServer.get_bus_effect(bus,i) is AudioEffectLimiter:limiter_found=true
 assert(limiter_found)
 app.show_title()
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
 await create_timer(0.1).timeout
 app.queue_free();app=null;await process_frame
 print("CC0 AUDIO: verified source hashes, UI mute, actual legendary sound, limiter and loop")
 quit(0)
