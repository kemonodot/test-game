class_name MimicProfile
extends RefCounted
const PATH := "user://mimic_save.json"
const SLOTS := ["fang", "organ1", "organ2", "organ3", "organ4", "shell", "core"]
const SALVAGE_VALUES := [3,10,30,100,250]
const FAMILIES := ["devour","blade","hex","poison","summon","defense","arcane"]
const UPGRADE_DEFS := [
 {"recipient":"hunter","key":"awakening","name":"飢えの目覚め","desc":"狩人への供物で進化の祭壇を開く","family":"devour","requires":"","max":1,"cost":3},
 {"recipient":"sister","key":"hp","name":"血肉の器","desc":"最大HPを増やす","family":"defense","requires":"awakening","max":10,"cost":8},
 {"recipient":"hunter","key":"damage","name":"飢えた牙","desc":"基礎攻撃力を増やす","family":"devour","requires":"awakening","max":10,"cost":8},
 {"recipient":"researcher","key":"organ_slot","name":"異形の器","desc":"器官の装備枠をひとつ増やす","family":"devour","requires":"damage","max":1,"cost":15},
 {"recipient":"blacksmith","key":"reroll","name":"歪みの炉","desc":"鍛冶で追加効果を再抽選できる","family":"blade","requires":"damage","max":1,"cost":15},
 {"recipient":"blacksmith","key":"fusion","name":"魔石の炉","desc":"魔石を三つ合わせて上位化する","family":"arcane","requires":"reroll","max":1,"cost":15},
 {"recipient":"black_mage","key":"family_hex","name":"呪眼の覚醒","desc":"呪術系の装備が現れる","family":"hex","requires":"damage","max":1,"cost":15},
 {"recipient":"researcher","key":"family_poison","name":"腐敗の覚醒","desc":"毒・腐食系の装備が現れる","family":"poison","requires":"family_hex","max":1,"cost":15},
 {"recipient":"fortune_teller","key":"family_summon","name":"眷属の覚醒","desc":"召喚系の装備が現れる","family":"summon","requires":"hp","max":1,"cost":15},
 {"recipient":"sister","key":"family_defense","name":"甲殻の覚醒","desc":"防御系の装備が現れる","family":"defense","requires":"family_summon","max":1,"cost":15},
 {"recipient":"merchant","key":"starting_gold","name":"埋蔵された金貨","desc":"狩りの開始時に資金を得る","family":"blade","requires":"hp","max":10,"cost":15},
 {"recipient":"thief","key":"drop","name":"収集の渇望","desc":"装備のドロップ率を高める","family":"arcane","requires":"starting_gold","max":10,"cost":15},
]
var templates: Array = []
var affix_defs: Array = []
var balance: Dictionary = {}
var data := {}
var rng := RandomNumberGenerator.new()
var save_path := PATH
var load_failed := false
var io_error := ""
func _init(load_existing: bool = true, path: String = PATH) -> void:
 save_path=path
 rng.randomize()
 templates = JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json"))
 affix_defs = JSON.parse_string(FileAccess.get_file_as_string("res://data/affixes.json"))
 balance = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json"))
 data = {"version":1,"gold":0,"points":0,"inventory":[],"equipped":{},"gems":{},"upgrades":{"awakening":0},"unlocked_stage":0,"unlocked_families":["devour","blade","arcane"],"collection":[],"next_id":1}
 if load_existing:
  var directory:=DirAccess.open(save_path.get_base_dir())
  if directory==null:
   load_failed=true;io_error="保存先を開けません"
  elif FileAccess.file_exists(save_path):
   load_game()
 if not load_failed:ensure_starter()
func ensure_starter() -> void:
 if data.inventory.is_empty():
  var starter := create_item("bite",0)
  data.inventory.append(starter)
  data.equipped["fang"] = starter.uid
func valid_save(candidate: Variant) -> bool:
 if not candidate is Dictionary or candidate.get("version")!=1:return false
 for key in ["gold","points","next_id","unlocked_stage"]:
  if not candidate.has(key) or typeof(candidate[key]) not in [TYPE_INT,TYPE_FLOAT]:return false
 for key in ["inventory","unlocked_families","collection"]:
  if not candidate.get(key) is Array:return false
 for key in ["equipped","gems","upgrades"]:
  if not candidate.get(key) is Dictionary:return false
 if candidate.has("settings") and not candidate.settings is Dictionary:return false
 var seen:={}
 for item in candidate.inventory:
  if not item is Dictionary:return false
  for key in ["uid","template","rarity","level","affixes","sockets","socket_count"]:
   if not item.has(key):return false
  if typeof(item.uid) not in [TYPE_INT,TYPE_FLOAT] or typeof(item.rarity) not in [TYPE_INT,TYPE_FLOAT] or typeof(item.level) not in [TYPE_INT,TYPE_FLOAT] or typeof(item.socket_count) not in [TYPE_INT,TYPE_FLOAT]:return false
  if not item.affixes is Array or not item.sockets is Array or get_template(str(item.template)).is_empty():return false
  if int(item.rarity)<0 or int(item.rarity)>=SALVAGE_VALUES.size() or int(item.uid)<1 or seen.has(int(item.uid)):return false
  seen[int(item.uid)]=true
  for affix in item.affixes:
   if not affix is Dictionary or not affix.has_all(["id","name","tier","value"]):return false
   if typeof(affix.tier) not in [TYPE_INT,TYPE_FLOAT] or typeof(affix.value) not in [TYPE_INT,TYPE_FLOAT]:return false
  for gem in item.sockets:
   if not gem is Dictionary or not gem.has("family") or not gem.has("tier"):return false
   if str(gem.family) not in FAMILIES or typeof(gem.tier) not in [TYPE_INT,TYPE_FLOAT]:return false
 for slot in candidate.equipped:
  if slot not in SLOTS or typeof(candidate.equipped[slot]) not in [TYPE_INT,TYPE_FLOAT]:return false
  if not seen.has(int(candidate.equipped[slot])):return false
 return true
func load_game() -> bool:
 var f:=FileAccess.open(save_path,FileAccess.READ)
 if f==null:
  load_failed=true;io_error="セーブを開けません"
  return false
 var length:int=f.get_length()
 var bytes:PackedByteArray=f.get_buffer(length)
 var read_error:Error=f.get_error()
 f.close()
 if bytes.size()!=length or (read_error!=OK and read_error!=ERR_FILE_EOF):
  load_failed=true;io_error="セーブを読み取れません"
  return false
 var json:=JSON.new()
 if json.parse(bytes.get_string_from_utf8())!=OK or not valid_save(json.data):
  load_failed=true;io_error="セーブの内容を読み込めません"
  return false
 data=json.data
 if not data.upgrades.has("awakening"):data.upgrades.awakening=1
 load_failed=false;io_error=""
 ensure_starter()
 return true
func save_game() -> bool:
 if load_failed:
  io_error="読み込み失敗のため保存を停止中"
  return false
 var temp_path:String=save_path+".tmp"
 var f:=FileAccess.open(temp_path,FileAccess.WRITE)
 if f==null:
  io_error="保存先を開けません"
  return false
 f.store_string(JSON.stringify(data))
 f.flush()
 var write_error:Error=f.get_error()
 f.close()
 if write_error!=OK:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
  io_error="セーブを書き込めません"
  return false
 var rename_error:Error=DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path),ProjectSettings.globalize_path(save_path))
 if rename_error!=OK:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
  io_error="セーブを確定できません"
  return false
 io_error=""
 return true
func salvage_preview(max_rarity: int) -> Dictionary:
 var result:Dictionary={"count":0,"gold":0}
 var equipped_ids:={}
 for uid in data.equipped.values():equipped_ids[int(uid)]=true
 for item in data.inventory:
  var rarity:int=int(item.rarity)
  if rarity<=mini(max_rarity,2) and rarity>=0 and not equipped_ids.has(int(item.uid)):
   result.count+=1;result.gold+=SALVAGE_VALUES[rarity]
 return result
func return_sockets(item: Dictionary) -> void:
 for gem in item.get("sockets",[]):add_gem(str(gem.family),int(gem.tier))
func salvage_item(uid: int) -> Dictionary:
 for equipped_uid in data.equipped.values():
  if int(equipped_uid)==uid:return {"count":0,"gold":0}
 for i in data.inventory.size():
  var item:Dictionary=data.inventory[i]
  if int(item.uid)!=uid:continue
  var rarity:int=int(item.rarity)
  if rarity<0 or rarity>=SALVAGE_VALUES.size():return {"count":0,"gold":0}
  var amount:int=SALVAGE_VALUES[rarity]
  return_sockets(item)
  data.inventory.remove_at(i);data.gold=int(data.gold)+amount
  return {"count":1,"gold":amount}
 return {"count":0,"gold":0}
func salvage_bulk(max_rarity: int) -> Dictionary:
 var result:Dictionary={"count":0,"gold":0}
 var equipped_ids:={}
 for uid in data.equipped.values():equipped_ids[int(uid)]=true
 var keep:Array=[]
 for item in data.inventory:
  var rarity:int=int(item.rarity)
  if rarity>=0 and rarity<=mini(max_rarity,2) and not equipped_ids.has(int(item.uid)):
   result.count+=1;result.gold+=SALVAGE_VALUES[rarity]
   return_sockets(item)
  else:keep.append(item)
 data.inventory=keep;data.gold=int(data.gold)+int(result.gold)
 return result
func get_template(id: String) -> Dictionary:
 for t in templates:
  if t.id == id: return t
 return {}
func roll_affixes(rarity: int) -> Array:
 var bag: Array = affix_defs.duplicate()
 var result := []
 for i in mini(rarity,4):
  var idx := rng.randi_range(0,bag.size()-1)
  var a: Dictionary = bag.pop_at(idx)
  var tier: int = rng.randi_range(1,mini(5,rarity+1))
  result.append({"id":a.id,"name":a.name,"tier":tier,"value":float(a.per_tier)*tier})
 return result
func create_item(id: String, rarity: int = 0) -> Dictionary:
 var socket_count := mini(2,rarity) if rng.randf()<0.65 else 0
 var item := {"uid":int(data.next_id),"template":id,"rarity":rarity,"level":0,"affixes":roll_affixes(rarity),"sockets":[],"socket_count":socket_count}
 data.next_id = int(data.next_id)+1
 return item
func get_item(uid: int) -> Dictionary:
 for item in data.inventory:
  if int(item.uid) == uid: return item
 return {}
func equip(uid: int, slot: String) -> bool:
 if slot not in SLOTS: return false
 if slot == "organ4" and not data.upgrades.get("organ_slot",false): return false
 var item := get_item(uid)
 if item.is_empty(): return false
 var t := get_template(item.template)
 var expected := "organ" if slot.begins_with("organ") else slot
 if t.get("slot") != expected: return false
 for s in data.equipped.keys():
  if int(data.equipped[s]) == uid: data.equipped.erase(s)
 data.equipped[slot] = uid
 return true
func unequip(slot: String) -> bool:
 if slot not in SLOTS or not data.equipped.has(slot):return false
 data.equipped.erase(slot)
 return true
func weighted(weights: Array) -> int:
 var total := 0.0
 for w in weights: total += float(w)
 var roll := rng.randf()*total
 for i in weights.size():
  roll -= float(weights[i])
  if roll < 0: return i
 return weights.size()-1
func drop(stage: int = 0, boss: bool = false) -> Dictionary:
 var rarity := weighted(balance.boss_rarity_weights if boss else balance.rarity_weights[clampi(stage,0,1)])
 var candidates := []
 for t in templates:
  if t.family in data.unlocked_families and (not t.has("unique") or rarity>=3): candidates.append(t)
 if candidates.is_empty(): return {}
 if rarity>=3:
  var uniques := candidates.filter(func(x): return x.has("unique"))
  if not uniques.is_empty(): candidates=uniques
 var chosen: Dictionary = candidates[rng.randi_range(0,candidates.size()-1)]
 var item := create_item(chosen.id,rarity)
 data.inventory.append(item)
 if chosen.has("unique") and chosen.id not in data.collection: data.collection.append(chosen.id)
 return item
func equipped_templates() -> Array:
 var items := []
 for uid in data.equipped.values():
  var item := get_item(int(uid))
  if not item.is_empty():
   var t := get_template(item.template).duplicate(true)
   t["item"] = item
   items.append(t)
 return items
func upgrade_item(uid: int) -> bool:
 var item := get_item(uid)
 if item.is_empty(): return false
 var cost := 25*(int(item.level)+1)
 if int(data.gold)<cost: return false
 data.gold -= cost
 item.level = int(item.level)+1
 return true
func reroll_item(uid: int) -> bool:
 var item := get_item(uid)
 if item.is_empty() or not data.upgrades.get("reroll",false) or int(data.gold)<40: return false
 data.gold -= 40
 item.affixes = roll_affixes(int(item.rarity))
 return true
func add_gem(family: String, tier: int = 1) -> void:
 var key := "%s:%d" % [family,tier]
 data.gems[key] = int(data.gems.get(key,0))+1
func fuse_gem(family: String, tier: int) -> bool:
 var key := "%s:%d" % [family,tier]
 if not data.upgrades.get("fusion",false) or tier>=5 or int(data.gems.get(key,0))<3: return false
 data.gems[key] -= 3
 add_gem(family,tier+1)
 return true
func socket_gem(uid: int, family: String, tier: int) -> bool:
 var item := get_item(uid)
 var key := "%s:%d" % [family,tier]
 if item.is_empty() or item.sockets.size()>=int(item.socket_count) or int(data.gems.get(key,0))<1: return false
 data.gems[key] -= 1
 item.sockets.append({"family":family,"tier":tier})
 return true
func remove_gem(uid: int, index: int) -> bool:
 var item:=get_item(uid)
 if item.is_empty() or index<0 or index>=item.sockets.size(): return false
 var gem:Dictionary=item.sockets.pop_at(index)
 add_gem(gem.family,int(gem.tier))
 return true
func upgrade_definition(key: String) -> Dictionary:
 for definition in UPGRADE_DEFS:
  if definition.key==key:return definition
 return {}
func upgrade_cost(key: String) -> int:
 var definition:=upgrade_definition(key)
 if definition.is_empty():return -1
 return int(definition.cost)*(int(data.upgrades.get(key,0))+1)
func upgrade_unsealed(key: String) -> bool:
 var definition:=upgrade_definition(key)
 if definition.is_empty():return false
 var requirement:String=definition.requires
 return requirement.is_empty() or int(data.upgrades.get(requirement,0))>0 or int(data.upgrades.get(key,0))>0
func upgrade(key: String) -> bool:
 var definition:=upgrade_definition(key)
 if definition.is_empty() or not upgrade_unsealed(key):return false
 var level:=int(data.upgrades.get(key,0))
 if level>=int(definition.max):return false
 var cost:=upgrade_cost(key)
 if int(data.points)<cost:return false
 data.points -= cost
 data.upgrades[key] = level+1
 if key.begins_with("family_"):
  var fam := key.trim_prefix("family_")
  if fam in FAMILIES and fam not in data.unlocked_families: data.unlocked_families.append(fam)
 return true
