extends SceneTree
const Profile=preload("res://src/profile.gd")
func _initialize()->void:call_deferred("run")
func find_button(node:Node,part:String) -> Button:
 if node is Button and part in node.text:return node
 for child in node.get_children():
  var match_button:=find_button(child,part)
  if match_button:return match_button
 return null
func run()->void:
 var app=load("res://main.tscn").instantiate();root.add_child(app)
 app.profile=Profile.new(false)
 var organ:Dictionary=app.profile.create_item("mouth")
 var replacement:Dictionary=app.profile.create_item("tongue")
 app.profile.data.inventory.append(organ);app.profile.data.inventory.append(replacement)
 app.show_inventory();await process_frame
 assert(app.preview_slot=="fang" and app.selected_uid==-1)
 assert(find_button(app.ui,"伸びる舌")!=null and find_button(app.ui,"飢えた胃袋")==null)
 var locked:=find_button(app.ui,"器官4");assert(locked!=null and locked.disabled)
 var slot:=find_button(app.ui,"器官1");assert(slot!=null);slot.pressed.emit();await process_frame
 assert(app.preview_slot=="organ1")
 assert(find_button(app.ui,"伸びる舌")==null)
 var candidate:=find_button(app.ui,"飢えた胃袋");assert(candidate!=null);candidate.pressed.emit();await process_frame
 assert(app.selected_uid==organ.uid)
 var equip:=find_button(app.ui,"器官1に装備する");assert(equip!=null);equip.pressed.emit();await process_frame
 assert(int(app.profile.data.equipped.organ1)==organ.uid)
 var saved=Profile.new(true);assert(int(saved.data.equipped.organ1)==organ.uid)
 app.select_equipment_slot("organ2");await process_frame
 candidate=find_button(app.ui,"器官1から移動");assert(candidate!=null)
 candidate.pressed.emit();await process_frame
 app.equip_selected_item();await process_frame
 assert(not app.profile.data.equipped.has("organ1") and int(app.profile.data.equipped.organ2)==organ.uid)
 app.remove_equipment_from_slot();await process_frame
 assert(not app.profile.data.equipped.has("organ2") and not app.profile.get_item(organ.uid).is_empty())
 print("INVENTORY FLOW: slot-first filtering, lock, compare selection, save, move and unequip passed")
 app.queue_free();await process_frame;quit(0)
