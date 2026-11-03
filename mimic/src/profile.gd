class_name MimicProfile
extends RefCounted
const PATH := "user://mimic_save.json"
const SLOTS := ["fang", "organ1", "organ2", "organ3", "organ4", "shell", "core"]
const FAMILIES := ["devour","blade","hex","poison","summon","defense","arcane"]
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
 data = {"version":1,"gold":0,"points":0,"inventory":[],"equipped":{},"gems":{},"upgrades":{},"unlocked_stage":0,"unlocked_families":["devour","blade","arcane"],"collection":[],"next_id":1}
 if load_existing and FileAccess.file_exists(PATH):
  var f := FileAccess.open(PATH, FileAccess.READ)
  if f:
   var parsed: Variant = JSON.parse_string(f.get_as_text())
   if parsed is Dictionary and parsed.get("version") == 1: data = parsed
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
func upgrade(key: String) -> bool:
 var level := int(data.upgrades.get(key,0))
 var one_time: bool = key in ["organ_slot","reroll","fusion"] or key.begins_with("family_")
 if (one_time and level>0) or (not one_time and level>=10): return false
 var cost: int = (8 if key in ["hp","damage"] else 15) * (level+1)
 if int(data.points)<cost: return false
 data.points -= cost
 data.upgrades[key] = level+1
 if key.begins_with("family_"):
  var fam := key.trim_prefix("family_")
  if fam in FAMILIES and fam not in data.unlocked_families: data.unlocked_families.append(fam)
 return true
