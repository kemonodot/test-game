# Cosmetic state only. It never draws random numbers or changes rewards.
class_name RewardPresentation
extends RefCounted
const REVEAL_DELAY := 0.30
const BIG_COOLDOWN := 1.7
const BIG_SLOW_DURATION := 0.36
const NOTIFICATION_LIFETIME := 2.5
var notifications: Array = []
var money_popups: Array = []
var pickup_sparks: Array = []
var death_bursts: Array = []
var kill_count := 0
var attack_pulse := 0.0
var kill_window := 0.0
var kill_level := 0
var kill_sound_cooldown := 0.0
var rarity_sound_cooldown := [0.0,0.0,0.0,0.0,0.0]
var big_cooldown := 0.0
var slow_remaining := 0.0
var edge_remaining := 0.0
var edge_rarity := 0
var beam_remaining := 0.0
var beam_position := Vector2.ZERO
var beam_rarity := 0
var banners: Array = []
var boss_reveal_remaining := 0.0
var boss_reveal_total := 1.05
var boss_item_rarity := -1
var boss_item_name := ""
var boss_position := Vector2.ZERO
var boss_kind := ""
var boss_result_wait := 0.0
var boss_full_reveal := false
var boss_pending := false
var pending_sound_rarity := -1

func _init() -> void:
 for rarity in 5:
  notifications.append({"active":false,"rarity":rarity,"count":0,"ttl":0.0,"reveal":0.0,"name":"","pulse":0.0})
 for i in 3:banners.append({"active":false,"name":"","rarity":0,"ttl":0.0,"delay":0.0,"extra":0})
 for i in 8:death_bursts.append({"active":false,"pos":Vector2.ZERO,"ttl":0.0,"bomb":false})
 for i in 4:pickup_sparks.append({"active":false,"pos":Vector2.ZERO,"rarity":0,"ttl":0.0})
 for i in 12:
  money_popups.append({"active":false,"bomb":false,"value":0,"pos":Vector2.ZERO,"ttl":0.0,"age":0.0})

func update(delta: float) -> void:
 kill_window=maxf(0.0,kill_window-delta)
 if kill_window<=0.0:kill_count=0
 attack_pulse=maxf(0.0,attack_pulse-delta)
 kill_sound_cooldown=maxf(0.0,kill_sound_cooldown-delta)
 big_cooldown=maxf(0.0,big_cooldown-delta)
 slow_remaining=maxf(0.0,slow_remaining-delta)
 edge_remaining=maxf(0.0,edge_remaining-delta)
 beam_remaining=maxf(0.0,beam_remaining-delta)
 for banner in banners:
  if banner.active:
   banner.delay=maxf(0.0,float(banner.delay)-delta)
   banner.ttl-=delta
   if banner.ttl<=0:banner.active=false
 var revealing:bool=boss_reveal_remaining>0.0
 boss_reveal_remaining=maxf(0.0,boss_reveal_remaining-delta)
 boss_result_wait=maxf(0.0,boss_result_wait-delta)
 if revealing and boss_reveal_remaining<=0.0 and boss_pending:
  boss_pending=false
  if publish_item(boss_item_rarity,boss_item_name,boss_position,false):pending_sound_rarity=boss_item_rarity
 for i in rarity_sound_cooldown.size():rarity_sound_cooldown[i]=maxf(0.0,float(rarity_sound_cooldown[i])-delta)
 for notice in notifications:
  if notice.active:
   notice.ttl-=delta;notice.reveal=maxf(0.0,float(notice.reveal)-delta);notice.pulse=maxf(0.0,float(notice.pulse)-delta)
   if notice.ttl<=0:notice.active=false;notice.count=0
 for burst in death_bursts:
  if burst.active:
   burst.ttl-=delta
   if burst.ttl<=0:burst.active=false
 for spark in pickup_sparks:
  if spark.active:
   spark.ttl-=delta
   if spark.ttl<=0:spark.active=false
 for pop in money_popups:
  if pop.active:
   pop.ttl-=delta;pop.age+=delta
   if pop.ttl<=0:pop.active=false

# The ladder grows per kill, even when a very dense burst is audio-rate-limited.
func on_kill(position: Vector2 = Vector2.INF, reduced: bool = false, bomb: bool = false) -> float:
 kill_count=mini(99,kill_count+1) if kill_window>0.0 else 1
 kill_level=mini(7,kill_level+1) if kill_window>0.0 else 0
 kill_window=0.65
 if position.is_finite() and not reduced:
  for burst in death_bursts:
   if not burst.active:
    burst.active=true;burst.pos=position;burst.ttl=0.38;burst.bomb=bomb
    break
 if kill_sound_cooldown>0.0:return 0.0
 kill_sound_cooldown=0.045
 return 1.0+float(kill_level)*0.09

func money(pos: Vector2, amount: int, bomb: bool) -> void:
 for pop in money_popups:
  if pop.active and pop.bomb==bomb and float(pop.age)<0.12:
   pop.value+=amount
   return
 for pop in money_popups:
  if not pop.active:
   pop.merge({"active":true,"bomb":bomb,"value":amount,"pos":pos.clamp(Vector2(25,100),Vector2(1180,630)),"ttl":0.85,"age":0.0},true)
   return
 # If the bounded pool fills, keep the total visible without allocating more nodes.
 for pop in money_popups:
  if pop.bomb==bomb:pop.value+=amount;return

func begin_big(reduced: bool) -> bool:
 var full:bool=big_cooldown<=0.0 and not reduced
 big_cooldown=BIG_COOLDOWN
 if full:slow_remaining=BIG_SLOW_DURATION
 return full

func boss(pos: Vector2, kind: String, reduced: bool) -> bool:
 var full:=begin_big(reduced)
 boss_full_reveal=full
 boss_position=pos;boss_kind=kind
 boss_item_rarity=-1;boss_item_name=""
 if full:
  boss_reveal_remaining=boss_reveal_total;boss_result_wait=2.0
 elif not reduced:
  boss_result_wait=0.8
  add_banner("BOSS 撃破",3,0.0)
 return full

# Returns whether a rarity sound should play. Boss rolls always carry their actual result.
func item(rarity: int, item_name: String, pos: Vector2, reduced: bool, from_boss: bool) -> bool:
 rarity=clampi(rarity,0,4)
 if from_boss:
  boss_item_rarity=rarity;boss_item_name=item_name
  if boss_reveal_remaining>0.0:
   boss_pending=true
   return false
 return publish_item(rarity,item_name,pos,reduced)

func publish_item(rarity: int, item_name: String, pos: Vector2, reduced: bool) -> bool:
 var notice:Dictionary=notifications[rarity]
 if not notice.active:notice.count=0
 notice.active=true;notice.count+=1;notice.ttl=NOTIFICATION_LIFETIME
 notice.name=item_name;notice.pulse=0.3
 if rarity>=3:notice.reveal=REVEAL_DELAY
 if rarity>=1 and rarity<=2 and not reduced:
  edge_remaining=0.32;edge_rarity=rarity
  for spark in pickup_sparks:
   if not spark.active:
    spark.active=true;spark.pos=pos;spark.rarity=rarity;spark.ttl=0.55
    break
 if rarity>=3:
  var full:=begin_big(reduced)
  # A boss and its own drop are one sequence; the second big event is shortened.
  if not reduced:
   add_banner(item_name,rarity,REVEAL_DELAY)
   if full:beam_remaining=0.65;beam_position=pos;beam_rarity=rarity
 if rarity<1:return false
 if rarity>=3:return true
 var play:bool=float(rarity_sound_cooldown[rarity])<=0.0
 if play:rarity_sound_cooldown[rarity]=0.12
 return play

func add_banner(item_name: String, rarity: int, delay: float) -> void:
 for banner in banners:
  if not banner.active:
   banner.merge({"active":true,"name":item_name,"rarity":rarity,"ttl":1.5,"delay":delay,"extra":0},true)
   return
 banners[2].extra+=1
