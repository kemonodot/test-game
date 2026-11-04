"""Expose Godot 4.6.3 Web IDBFS completion to the game's save warning UI.
Run after replacing the generated Web engine JS. This changes no save data.
"""
from pathlib import Path
path=Path(__file__).resolve().parent.parent/'web/index.js'
s=path.read_text()
replacements=[
 ('FS.syncfs(true,function(err){if(err){GodotFS._mount_points=[];GodotFS._idbfs=false;GodotRuntime.print(`IndexedDB not available: ${err.message}`)}else{GodotFS._idbfs=true}resolve(err)',
  'FS.syncfs(true,function(err){if(err){GodotFS._mount_points=[];GodotFS._idbfs=false;GodotRuntime.print(`IndexedDB not available: ${err.message}`)}else{GodotFS._idbfs=true}globalThis.mimicStorageReport?.(err?"load_error":"ready");resolve(err)'),
 ('FS.syncfs(false,function(error){if(error){GodotRuntime.error(`Failed to save IDB file system: ${error.message}`)}GodotFS._syncing=false;resolve(error)',
  'FS.syncfs(false,function(error){if(error){GodotRuntime.error(`Failed to save IDB file system: ${error.message}`)}GodotFS._syncing=false;globalThis.mimicStorageReport?.(error?"save_error":"ready");resolve(error)'),
 ('Module["initFS"]=GodotFS.init;',
  'Module["mimicSyncFS"]=function(){if(!GodotFS._idbfs){globalThis.mimicStorageReport?.("load_error");return}if(GodotFS._syncing){setTimeout(Module["mimicSyncFS"],50);return}GodotFS.sync()};Module["initFS"]=GodotFS.init;')]
for original,modified in replacements:
 if modified in s:continue
 if s.count(original)!=1:raise SystemExit('Godot Web runtime changed; cannot safely install storage reporting')
 s=s.replace(original,modified,1)
path.write_text(s)
print('Web IDBFS reporting installed')
