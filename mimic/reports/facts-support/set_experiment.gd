extends "res://tests/early_progression_trials.gd"
const BUILDS:={
 "devour":[["bite","fang"],["mouth","organ1"],["suction","organ2"],["hunger","core"]],
 "blade":[["cleaver","fang"],["spindle","organ1"],["knife","organ2"],["edgecore","core"]],
 "hex":[["eyefang","fang"],["eye","organ1"],["mark","organ2"],["hexcore","core"]],
 "poison":[["acidfang","fang"],["gland","organ1"],["rot","organ2"],["rotcore","core"]],
 "summon":[["callfang","fang"],["minion","organ1"],["ghost","organ2"],["broodcore","core"]],
 "defense":[["spikefang","fang"],["shellorgan","organ1"],["rebound","organ2"],["aegis","core"]],
 "arcane":[["sparkfang","fang"],["orb","organ1"],["seeker","organ2"],["astral","core"]]
}
func run_all()->void:
 var output:Dictionary={"kind":"supplementary pre-equipped 4-piece builds; not normal new-save progression","samples_per_family":10,"stage":1,"builds":BUILDS,"runs":[]}
 for family in BUILDS:
  for n in range(1,11):
   var p=Profile.new(false);p.rng.seed=321000+n
   for pair in BUILDS[family]:
    var item:Dictionary=p.create_item(pair[0],0);p.data.inventory.append(item);assert(p.equip(item.uid,pair[1]))
   # Drop RNG starts equally for every paired build; battle seed is also shared.
   p.rng.seed=330000+n
   var record:Dictionary=play_one(p,0,340000+n)
   record["family"]=family;record["trial"]=n
   output.runs.append(record)
   print("set=%s trial=%d seconds=%.1f damage=%.2f set_damage=%.2f" % [family,n,record.elapsed,record.metric_damage,record.metric_set_damage[family]])
  var file:=FileAccess.open("/workspace/test-game/mimic/reports/facts-set-control.json",FileAccess.WRITE)
  if file:file.store_string(JSON.stringify(output,"  "));file.close()
  print("SET COMPLETED "+family)
 print("CONTROLLED SET EXPERIMENT COMPLETE")
 quit(0)
