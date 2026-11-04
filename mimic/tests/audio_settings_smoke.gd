extends SceneTree
const Profile=preload("res://src/profile.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
 var app=load("res://main.tscn").instantiate();root.add_child(app)
 app.profile=Profile.new(false);app.profile.data.settings={"sound":true}
 app.show_settings();await process_frame
 var test_button:Button
 for child in app.ui.get_children():
  if child is Button and child.text=="音を確認":test_button=child;break
 assert(test_button!=null and not test_button.disabled)
 app.profile.data.settings.sound=false;app.show_settings();await process_frame
 test_button=null
 for child in app.ui.get_children():
  if child is Button and child.text=="音を確認":test_button=child;break
 assert(test_button!=null and test_button.disabled)
 app.kill_sound.stop()
 app.queue_free();test_button=null;app=null
 await process_frame
 print("AUDIO SETTINGS: test sound follows the player's sound setting")
 quit(0)
