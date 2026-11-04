# BGM素材

両曲ともCC0 1.0。旋律のある既存曲を、ループ接続と音量を揃えるために編集している。ゲーム内の「設定 → 素材クレジット」にも掲載。

- 拠点・結果: `dark-forest-menu.ogg` — **Dark Forest Theme**, cynicmusic (The Cynic Project)。[取得元とCC0表記](https://github.com/Juulis/rpg-demo/blob/a9394a988d171d40a0075e63d74b9308f2024a0c/public/assets/musik/README.md)、[取得した原音源](https://github.com/Juulis/rpg-demo/blob/a9394a988d171d40a0075e63d74b9308f2024a0c/public/assets/musik/dark_forest_theme_cynicmusic_CC0.mp3)。原音源 SHA-256 `c9e83d01741e97a462c44963aff81645a9c2aa3a7a33e5849114a1399d1b0914`。1.5秒のクロスフェードを作り、44.1 kHz Ogg Vorbisに変換。ループは約91.56秒。
- 戦闘: `level-three-battle.ogg` — **Level 3**, Juhani Junkala, [5 Chiptunes (Action)](https://opengameart.org/content/5-chiptunes-action)。[取得元とCC0表記](https://github.com/starquake/voidmarch/blob/4a9cbd66a877a20d953be3dd722107012d3a2d9c/internal/web/static/audio/LICENSE.md)、[取得した原音源](https://github.com/starquake/voidmarch/blob/4a9cbd66a877a20d953be3dd722107012d3a2d9c/internal/web/static/audio/music/level-3.ogg)。原音源 SHA-256 `9ef9398a606e5964e89747b743474b3e8a037b098ce07bcfe5d9f9da389e5578`。固定で-10 dB音量を調整し、約17 msの接続用クロスフェードを加えて44.1 kHz Ogg Vorbisに変換。ループは約81.88秒。

出力ファイルのハッシュは `tests/index_cc0_audio_smoke.gd` で検証する。短いクロスフェードは波形の接続音を抑えるためのもの。スマートフォンの実機スピーカーでの聴感確認は別途必要。
