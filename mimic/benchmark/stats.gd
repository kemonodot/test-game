class_name MimicBenchmarkStats
extends RefCounted

var start_us: int = 0
var previous_us: int = 0
var frame_us := PackedInt64Array()
var end_us := PackedInt64Array()
var window_start := 0
var window_total_us: int = 0

func begin(now_us: int) -> void:
 start_us = now_us
 previous_us = now_us
 frame_us.clear()
 end_us.clear()
 window_start = 0
 window_total_us = 0

func record(now_us: int) -> void:
 var elapsed := now_us-previous_us
 previous_us = now_us
 if elapsed <= 0:return
 frame_us.append(elapsed)
 end_us.append(now_us-start_us)
 window_total_us += elapsed
 while window_start < end_us.size() and end_us[window_start] <= now_us-start_us-60000000:
  window_total_us -= frame_us[window_start]
  window_start += 1

static func describe(values: PackedInt64Array) -> Dictionary:
 if values.is_empty():return {"frames":0,"fps":0.0,"low":0.0,"over_pct":0.0}
 var sum: int = 0
 var over := 0
 for value in values:
  sum += value
  if value > 16700:over += 1
 var sorted := values.duplicate()
 sorted.sort()
 var tail := maxi(1,ceili(sorted.size()*0.01))
 var slow_sum: int = 0
 for i in range(sorted.size()-tail,sorted.size()):slow_sum += sorted[i]
 return {"frames":values.size(),"fps":1000000.0*values.size()/sum,"low":1000000.0*tail/slow_sum,"over_pct":100.0*over/values.size()}

func rolling() -> Dictionary:
 var values:=PackedInt64Array()
 for i in range(window_start,frame_us.size()):values.append(frame_us[i])
 return describe(values)

func all() -> Dictionary:
 return describe(frame_us)

func range_summary(from_us: int, to_us: int) -> Dictionary:
 var values:=PackedInt64Array()
 for i in frame_us.size():
  if end_us[i]>from_us and end_us[i]<=to_us:values.append(frame_us[i])
 return describe(values)
