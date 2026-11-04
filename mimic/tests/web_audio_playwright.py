"""Portrait Web audio regression check; run after exporting mimic/web/index.pck.

Requires Python Playwright and Chromium. The test uses an isolated browser context
and an ephemeral localhost server; it does not touch the player's save.
"""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Thread
import os
from playwright.sync_api import sync_playwright

WEB = Path(__file__).resolve().parent.parent / 'web'
class Quiet(SimpleHTTPRequestHandler):
    def log_message(self, *_): pass
server = ThreadingHTTPServer(('127.0.0.1', 0), partial(Quiet, directory=str(WEB)))
Thread(target=server.serve_forever, daemon=True).start()
url = f'http://127.0.0.1:{server.server_port}/?audio-regression=1'
probe = '''(() => {
 const Native = window.AudioContext || window.webkitAudioContext;
 window.__audioContexts=[]; window.__audioAnalysers=[];window.__audioPeak=0;
 class Tracked extends Native { constructor(...args){ super(...args);window.__audioContexts.push(this); } }
 window.AudioContext=Tracked;
 const orig=AudioNode.prototype.connect;
 AudioNode.prototype.connect=function(...args){
  if(args[0]===this.context.destination){ const a=this.context.createAnalyser();a.fftSize=256;orig.call(this,a);window.__audioAnalysers.push(a); }
  return orig.apply(this,args);
 };
 function monitor(){for(const a of window.__audioAnalysers){const d=new Float32Array(a.fftSize);a.getFloatTimeDomainData(d);for(const x of d)window.__audioPeak=Math.max(window.__audioPeak,Math.abs(x));}requestAnimationFrame(monitor)}monitor();
})()'''
try:
    with sync_playwright() as p:
        browser=p.chromium.launch(executable_path=os.environ.get('MIMIC_CHROMIUM','/usr/bin/chromium'),headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--autoplay-policy=user-gesture-required'])
        context=browser.new_context(viewport={'width':390,'height':844},is_mobile=True,has_touch=True)
        context.add_init_script(probe)
        page=context.new_page();errors=[]
        page.on('pageerror',lambda e:errors.append(str(e)))
        page.goto(url,wait_until='domcontentloaded')
        page.wait_for_function('typeof window.mimicQuickStart === "function" && typeof window.mimicSoundTest === "function"',timeout=60000)
        page.wait_for_function("window.mimicStorageState.status === 'ready'",timeout=30000)
        assert '音源更新版' in page.locator('#phone-helper').inner_text()
        page.evaluate('Promise.all(window.__audioContexts.map(x => x.suspend()))')
        assert page.evaluate('window.__audioContexts[0].state')=='suspended'
        page.locator('#phone-sound').tap();page.wait_for_timeout(500)
        assert page.evaluate('window.__audioContexts[0].state')=='running'
        assert page.evaluate('window.__audioPeak')>0.001, 'no audio signal from test button'
        assert '再生を試しました' in page.locator('#phone-audio-status').inner_text()
        page.evaluate('Promise.all(window.__audioContexts.map(x => x.suspend()))')
        page.locator('#phone-start').tap();page.wait_for_timeout(400)
        assert page.evaluate('window.__audioContexts[0].state')=='running'
        page.evaluate('Promise.all(window.__audioContexts.map(x => x.suspend()))')
        page.touchscreen.tap(195,420);page.wait_for_timeout(400)
        assert page.evaluate('window.__audioContexts[0].state')=='running'
        assert not errors,errors
        context.close()
        muted=browser.new_context(viewport={'width':390,'height':844},is_mobile=True,has_touch=True)
        muted.add_init_script(probe)
        page=muted.new_page();page.goto(url,wait_until='domcontentloaded')
        page.wait_for_function('typeof window.mimicSoundTest === "function"',timeout=60000)
        box=page.locator('canvas').bounding_box()
        scale=min(box['width']/1280,box['height']/720)
        left=box['x']+(box['width']-1280*scale)/2
        top=box['y']+(box['height']-720*scale)/2
        def game_tap(x,y):
            page.touchscreen.tap(left+x*scale,top+y*scale);page.wait_for_timeout(350)
        game_tap(1100,630) # settings
        game_tap(290,495)  # sound off
        game_tap(1150,50)  # hub
        page.locator('#phone-sound').tap()
        assert page.evaluate('window.mimicSoundTestStatus')=='muted'
        assert '効果音をオン' in page.locator('#phone-audio-status').inner_text()
        # Sound effects are off, so the observed battle signal must come from BGM.
        page.evaluate('window.__audioPeak=0')
        page.locator('#phone-start').tap();page.wait_for_timeout(1800)
        assert page.evaluate('window.__audioPeak')>0.001, 'no BGM signal with effects muted'
        muted.close()
        effects=browser.new_context(viewport={'width':390,'height':844},is_mobile=True,has_touch=True)
        effects.add_init_script(probe)
        page=effects.new_page();page.goto(url,wait_until='domcontentloaded')
        page.wait_for_function('typeof window.mimicQuickStart === "function"',timeout=60000)
        box=page.locator('canvas').bounding_box()
        scale=min(box['width']/1280,box['height']/720)
        left=box['x']+(box['width']-1280*scale)/2
        top=box['y']+(box['height']-720*scale)/2
        def effects_tap(x,y):
            page.touchscreen.tap(left+x*scale,top+y*scale);page.wait_for_timeout(350)
        effects_tap(1100,630) # settings
        effects_tap(290,570)  # BGM off, effects remain on
        effects_tap(1150,50)  # hub
        page.evaluate('window.__audioPeak=0')
        page.locator('#phone-start').tap();page.wait_for_timeout(1200)
        assert page.evaluate('window.__audioPeak')>0.001, 'no effects signal with BGM muted'
        effects.close();browser.close()
    print('WEB AUDIO: portrait start, interruption recovery and independently audible BGM/effects passed')
finally:
    server.shutdown()
