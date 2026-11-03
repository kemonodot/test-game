class_name MimicBenchmarkDeviceInfo
extends RefCounted

static func battery_percent() -> int:
 if OS.get_name()!="Android" or not Engine.has_singleton("AndroidRuntime"):return -1
 var runtime = Engine.get_singleton("AndroidRuntime")
 var context = runtime.getApplicationContext()
 if context==null:return -1
 var manager = context.getSystemService("batterymanager")
 if manager==null:return -1
 var percent: int = manager.getIntProperty(4) # BATTERY_PROPERTY_CAPACITY
 return percent if percent>=0 and percent<=100 else -1

static func gather() -> Dictionary:
 var screen:Vector2i=DisplayServer.screen_get_size()
 var memory:Dictionary=OS.get_memory_info()
 var result:Dictionary={"model":OS.get_model_name(),"version":OS.get_version(),"soc":"取得不可","memory":int(memory.get("physical",-1)),"width":screen.x,"height":screen.y,"hz":DisplayServer.screen_get_refresh_rate()}
 if OS.get_name()!="Android" or not Engine.has_singleton("JavaClassWrapper"):return result
 var jni = Engine.get_singleton("JavaClassWrapper")
 var version = jni.wrap("android.os.Build$VERSION")
 var build = jni.wrap("android.os.Build")
 if version!=null and build!=null:
  result.version=str(version.RELEASE)+" (API "+str(version.SDK_INT)+")"
  result.model=str(build.MANUFACTURER)+" "+str(build.MODEL)
  if int(version.SDK_INT)>=31:
   var soc:String=str(build.SOC_MODEL)
   if not soc.is_empty() and soc.to_lower()!="unknown":result.soc=soc
  if str(result.soc)=="取得不可":
   result.soc="取得不可 (hardware: "+str(build.HARDWARE)+")"
 return result

static func percent_text(value: int) -> String:
 return "%d%%" % value if value>=0 else "取得不可"
