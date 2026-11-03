extends SceneTree
const Profile=preload("res://src/profile.gd")
const HubButton=preload("res://src/hub_button.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var app=load("res://main.tscn").instantiate()
 root.add_child(app);app.profile=Profile.new(false)
 app.companion_textures.black_mage=app.icon_textures.hex
 var destinations={"狩場へ進む":"stages","装備":"inventory","鍛冶":"forge","貢ぎ物":"upgrades","収集庫":"collection","設定":"settings"}
 for caption in destinations:
  app.show_title();await process_frame
  var found:Button
  for child in app.ui.get_children():
   if child is HubButton and child.title==caption:found=child;break
  assert(found!=null,"Missing hub destination "+caption)
  assert(found.size.x>=200 and found.size.y>=80)
  if caption=="貢ぎ物":assert(found.emblem==app.companion_textures.black_mage)
  found.pressed.emit()
  assert(app.state==destinations[caption],"Wrong destination for "+caption)
 app.queue_free();await process_frame
 print("HUB NAVIGATION: all six destinations, usable targets and existing screens passed")
 quit(0)
