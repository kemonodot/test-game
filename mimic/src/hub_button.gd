extends Button

# A carved, keyboard-accessible menu plate drawn at the game's native scale.
var title := ""
var subtitle := ""
var emblem: Texture2D
var primary := false

func _ready() -> void:
 text=""
 focus_mode=Control.FOCUS_ALL
 mouse_entered.connect(queue_redraw)
 mouse_exited.connect(queue_redraw)
 focus_entered.connect(queue_redraw)
 focus_exited.connect(queue_redraw)
 button_down.connect(queue_redraw)
 button_up.connect(queue_redraw)
 var empty:=StyleBoxEmpty.new()
 for mode in ["normal","hover","pressed","focus","disabled"]:
  add_theme_stylebox_override(mode,empty)

func _draw() -> void:
 var active:=is_hovered() or has_focus()
 var w:=size.x
 var h:=size.y
 var cut:=12.0
 var points:=PackedVector2Array([Vector2(cut,0),Vector2(w-cut,0),Vector2(w,cut),Vector2(w,h-cut),Vector2(w-cut,h),Vector2(cut,h),Vector2(0,h-cut),Vector2(0,cut)])
 var fill:=Color("301519") if primary else Color("160e13")
 if active:fill=fill.lightened(0.20)
 draw_colored_polygon(points,fill)
 var edge:=Color("d9a463") if active else (Color("b88a58") if primary else Color("84664c"))
 for i in points.size():draw_line(points[i],points[(i+1)%points.size()],edge,2.0)
 var inset:=Rect2(5,5,w-10,h-10)
 draw_rect(inset,Color(edge.r,edge.g,edge.b,0.36),false,1)
 # Rivets and inset blade-shaped corners are deliberately large enough to survive mobile scaling.
 for p in [Vector2(10,10),Vector2(w-10,10),Vector2(10,h-10),Vector2(w-10,h-10)]:
  draw_rect(Rect2(p-Vector2(2,2),Vector2(4,4)),edge)
 var image_size:=58.0 if primary else 48.0
 if emblem:draw_texture_rect(emblem,Rect2(14,(h-image_size)/2,image_size,image_size),false,Color(1,1,1,1 if active or primary else 0.88))
 var x:=83.0 if primary else 69.0
 var font:=get_theme_default_font()
 var font_color:=Color("fff1d2") if active else Color("ead6bd")
 draw_string(font,Vector2(x, h/2-2),title,HORIZONTAL_ALIGNMENT_LEFT,w-x-8,25 if primary else 20,font_color)
 draw_string(font,Vector2(x,h/2+23),subtitle,HORIZONTAL_ALIGNMENT_LEFT,w-x-8,12,Color("d3a47b") if primary else Color("b79b83"))
 if primary:
  draw_string(font,Vector2(w-38,h/2+8),"›",HORIZONTAL_ALIGNMENT_LEFT,30,30,Color("f1bd79"))
