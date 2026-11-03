class_name MimicProfile
extends RefCounted
const PATH := "user://mimic_save.json"
const SLOTS := ["fang", "organ1", "organ2", "organ3", "organ4", "shell", "core"]
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
func _init(load_existing: bool = true) -> void:
 rng.randomize()
 templates = JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json"))
 affix_defs = JSON.parse_string(FileAccess.get_file_as_string("res://data/affixes.json"))
 balance = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json"))
 data = {"version":1,"gold":0,"points":0,"inventory":[],"equipped":{},"gems":{},"upgrades":{"awakening":0},"unlocked_stage":0,"unlocked_families":["devour","blade","arcane"],"collection":[],"next_id":1}
 if load_existing and FileAccess.file_exists(PATH):
  var f := FileAccess.open(PATH, FileAccess.READ)
  if f:
   var parsed: Variant = JSON.parse_string(f.get_as_text())
   if parsed is Dictionary and parsed.get("version") == 1:
    data = parsed
    # Existing saves keep all their upgrades and have already opened the altar.
    if not data.upgrades.has("awakening"): data.upgrades.awakening=1
 if data.inventory.is_empty():
  var starter := create_item("bite",0)
  data.inventory.append(starter)
  data.equipped["fang"] = starter.uid
func save_game() -> bool:
 var f := FileAccess.open(PATH, FileAccess.WRITE)
 if f == null: return false
 f.store_string(JSON.stringify(data))
 return true
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
