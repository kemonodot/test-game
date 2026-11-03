extends SceneTree
const Stats=preload("res://benchmark/stats.gd")
const BenchProfile=preload("res://benchmark/profile.gd")
const Device=preload("res://benchmark/device_info.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var values:=PackedInt64Array()
 for i in 99:values.append(16000)
 values.append(40000)
 var sample:Dictionary=Stats.describe(values)
 assert(sample.frames==100 and is_equal_approx(sample.low,25.0) and is_equal_approx(sample.over_pct,1.0))
 var timing=Stats.new();timing.begin(1000000)
 for i in 121:timing.record(1000000+(i+1)*1000000)
 assert(timing.all().frames==121 and timing.rolling().frames==60)
 assert(timing.range_summary(0,60000000).frames==60 and timing.range_summary(61000000,121000000).frames==60)
 var path:="user://mimic_save.json"
 var original:String=FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
 var baseline=load("res://src/profile.gd").new(false);baseline.data.gold=741;assert(baseline.save_game())
 var sentinel:=FileAccess.get_file_as_string(path)
 var memory_profile=BenchProfile.new();memory_profile.data.gold=123456;assert(memory_profile.save_game())
 assert(FileAccess.get_file_as_string(path)==sentinel)
 var game=load("res://main.tscn").instantiate();root.add_child(game)
 game.start_benchmark_mode();await process_frame
 var controller:Control=game.get_child(game.get_child_count()-1)
 assert(controller.running and controller.run_seconds==180 and controller.game.state=="battle")
 assert(controller.battle.stage==1 and controller.active_now==120 and controller.battle.boss_spawned)
 var minions:=0;var pools:=0
 for minion in controller.battle.minions:
  if minion.active:minions+=1
 for fx in controller.battle.effects:
  if fx.active and fx.family=="poison" and fx.ttl>0.25:pools+=1
 assert(minions==3 and pools>=1)
 assert("extra_blades" in controller.battle.unique_ids and "curse_spread" in controller.battle.unique_ids)
 controller.start_run(600);await process_frame
 assert(controller.run_seconds==600 and controller.running and controller.active_now==120)
 controller.battle.bomb_remaining=0;controller._process(0.016)
 assert(controller.bomb_count>0)
 controller.stats.start_us=Time.get_ticks_usec()-601000000
 controller.stats.previous_us=Time.get_ticks_usec()-16000
 controller._process(0.016)
 assert(not controller.running and "開始60秒" in controller.result_text and "バッテリー" in controller.result_text and "SoC" in controller.result_text)
 controller.start_run(180)
 controller.stats.start_us=Time.get_ticks_usec()-181000000
 controller.stats.previous_us=Time.get_ticks_usec()-16000
 controller._process(0.016)
 assert(not controller.running and "3分" in controller.result_text)
 assert(FileAccess.get_file_as_string(path)==sentinel)
 if original.is_empty():DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 else:
  var restore:=FileAccess.open(path,FileAccess.WRITE);restore.store_string(original);restore.close()
 print("BENCHMARK: rolling and total metrics, durations, 120 enemies, build, bombs, report, save isolation passed")
 game.queue_free();await process_frame;quit(0)
