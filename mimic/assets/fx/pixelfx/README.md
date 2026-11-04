# pixelfx のスプライトシート

- 配布元: https://github.com/patch-gg/pixelfx
- 対象コミット: `a84159688af3ca37a4be05a0d422b94451b2e24e`
- ライセンス: MIT。著作権表示と許諾文は `LICENSE.txt`、原作者の通知は `UPSTREAM-NOTICE.md` を参照。
- `pickups/collect-burst`（Collect burst、pickup）: レア／エピックの戦利品。
- `holy/holy-pillar`（Holy pillar、holy）: レジェンダリー／ミシックの光柱。
- `explosions/implosion`（Implosion、explosions）: ボス撃破。

いずれもキャラクターを直接描かないエフェクト。ライブラリ本体を実行時に組み込まず、透明PNGとpixelfxのJSONだけを使う。Patch Pixelフォントは含めず使用しない。12fpsで書き出し、再生尺・表示サイズと色味はゲーム側で調整する。

再作成は同コミットをチェックアウトしたpixelfxで以下を実行し、各エフェクトのPNG・JSONをこのディレクトリへコピーする。`contact.png` は確認用であり同梱しない。

```sh
node tools/render.mjs pickups/collect-burst holy/holy-pillar explosions/implosion \
  --sheet --no-actor --bg none --fps 12 --seed 7 \
  --opts '{"palette":["#130c12","#32171e","#5a2930","#8c3d3d","#bc694e","#df9b6c","#f1d4ae","#fff1d6"]}' \
  --out /tmp/mimic-pixelfx-render
```
