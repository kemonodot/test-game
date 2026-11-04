extends SceneTree
const Combat=preload("res://src/combat.gd")

func _initialize() -> void:
 var battle=Combat.new(125)
 battle.spawn_budget=-10000;battle.stats.crit=0.0
 assert(battle.spawn_enemy("swordsman",Combat.CENTER+Vector2(200,0)))
 var victim:Dictionary=battle.enemies[0]
 victim.hp=1.0;victim.speed=0.0
 var attack:Dictionary=battle.abilities[0]
 assert(battle.cast(attack))
 battle.abilities.clear()
 var tongue:Dictionary=battle.effects.filter(func(fx):return fx.active and fx.family=="devour")[0]
 assert(victim.active and battle.kills==0 and battle.impact_serial==0)
 battle.update(0.04)
 assert(victim.active and battle.kills==0 and battle.impact_serial==0)
 assert((Combat.TONGUE_DURATION-tongue.ttl)/Combat.TONGUE_REACH_TIME<1.0)
 # A moving target is tracked during the extension, up to the actual impact.
 victim.pos+=Vector2(0,12)
 var contact:Vector2=victim.pos
 battle.update(0.05)
 assert(not victim.active and battle.kills==1 and battle.impact_serial==1)
 assert((Combat.TONGUE_DURATION-tongue.ttl)/Combat.TONGUE_REACH_TIME>=0.999)
 assert(tongue.to==contact and not tongue.pending)
 assert(battle.loot_events.any(func(e):return e.active))
 battle.hitstop=0.0;battle.update(0.05)
 assert(battle.kills==1 and battle.impact_serial==1,"A tongue must hit only once")

 # A recycled enemy slot must not receive a strike aimed at its predecessor.
 var reused=Combat.new(126);reused.spawn_budget=-10000;reused.stats.crit=0.0
 assert(reused.spawn_enemy("swordsman",Combat.CENTER+Vector2(160,0)))
 assert(reused.cast(reused.abilities[0]));reused.abilities.clear()
 reused.enemies[0].active=false
 assert(reused.spawn_enemy("swordsman",Combat.CENTER+Vector2(170,0)))
 var replacement_hp:float=reused.enemies[0].hp
 reused.update(0.05);reused.update(0.05)
 assert(reused.enemies[0].hp==replacement_hp and reused.impact_serial==0)
 print("TONGUE TIMING: no early hit or loot, tracked contact, single impact and recycled slot passed")
 quit(0)
