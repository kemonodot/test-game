"""Expose Godot 4.6.3's WebAudio resume method to the mobile HTML start control.

Run after exporting the generated Web runtime, alongside patch_web_storage.py.
"""
from pathlib import Path
path=Path(__file__).resolve().parent.parent/'web/index.js'
s=path.read_text()
needle='Module["initFS"]=GodotFS.init;'
patch=('Module["mimicResumeAudio"]=function(){const ctx=GodotAudio.ctx;'
       'if(ctx&&ctx.state!=="running"&&ctx.state!=="closed")'
       '{const p=ctx.resume();if(p&&p.catch)p.catch(function(){})}};'
       'Module["mimicAudioState"]=function(){return GodotAudio.ctx?GodotAudio.ctx.state:"unavailable"};')
if patch not in s:
 if s.count(needle)!=1:raise SystemExit('Godot Web runtime changed; cannot safely install audio resume')
 s=s.replace(needle,patch+needle,1)
path.write_text(s)
print('WebAudio gesture resume installed')
