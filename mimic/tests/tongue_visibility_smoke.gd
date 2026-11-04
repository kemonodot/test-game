extends SceneTree
const Combat=preload("res://src/combat.gd")
const Profile=preload("res://src/profile.gd")
func _initialize()->void:
 var p=Profile.new(false)
 var b=Combat.new(21);b.configure(p.equipped_templates());b.stats.crit=0.0
 # A close enemy stands inside the mimic's 128x128 canvas. The visible tongue
 # must still end at the damaged target, even though the body covers its world position.
 var close_pos:Vector2=Combat.CENTER+Vector2(22,0)
 assert(b.spawn_enemy("swordsman",close_pos));var hp:float=b.enemies[0].hp
 assert(b.cast(b.abilities[0]));assert(b.enemies[0].hp==hp)
 var tongues:Array=b.effects.filter(func(fx):return fx.active and fx.family=="devour")
 assert(tongues.size()==1 and tongues[0].to==close_pos)
 b.advance_tongue(tongues[0],Combat.TONGUE_REACH_TIME);assert(b.enemies[0].hp<hp)
 # Saturate every shared effect slot: poison and other effects must stay intact,
 # while a separate bounded pool preserves the tongue for the next attack.
 var crowded=Combat.new(22);crowded.configure(p.equipped_templates());crowded.stats.crit=0.0
 for fx in crowded.effects:fx.active=true;fx.family="poison";fx.ttl=4.0
 var target:=Combat.CENTER+Vector2(160,0)
 assert(crowded.spawn_enemy("swordsman",target));var before:float=crowded.enemies[0].hp
 assert(crowded.cast(crowded.abilities[0]) and crowded.enemies[0].hp==before)
 assert(crowded.tongue_overflow.filter(func(fx):return fx.active and fx.to==target).size()==1)
 assert(crowded.effects.filter(func(fx):return fx.active and fx.family=="poison" and fx.ttl==4.0).size()==Combat.MAX_EFFECTS)
 crowded.abilities.clear();crowded.hitstop=0.0;crowded.spawn_budget=-10000;crowded.update(0.05)
 assert(crowded.tongue_overflow[0].ttl<Combat.TONGUE_DURATION)
 assert(crowded.enemies[0].hp==before)
 crowded.update(0.05)
 assert(crowded.enemies[0].hp<before)
 # Area damage gets an explicit outline at the actual damage center.
 var splash=Combat.new(23)
 splash.configure([p.get_template("bite"),p.get_template("mouth"),p.get_template("suction"),p.get_template("hunger")]);splash.stats.crit=0.0
 assert(splash.spawn_enemy("swordsman",Combat.CENTER+Vector2(160,0)))
 assert(splash.spawn_enemy("swordsman",Combat.CENTER+Vector2(175,35)))
 var second_hp:float=splash.enemies[1].hp
 assert(splash.cast(splash.abilities[0]));assert(splash.enemies[1].hp==second_hp)
 var hit_fx:Array=splash.effects.filter(func(fx):return fx.active and fx.family=="devour")
 splash.advance_tongue(hit_fx[0],Combat.TONGUE_REACH_TIME)
 assert(splash.enemies[1].hp<second_hp)
 assert(hit_fx.size()==1 and hit_fx[0].splash and hit_fx[0].splash_center==splash.enemies[0].pos)
 print("TONGUE VISIBILITY: close target, saturated effects, protected poison and splash indicator passed")
 quit(0)
