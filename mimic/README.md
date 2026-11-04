# MIMIC — Godot 4 検証版

固定されたミミックが、指定方向に自動発射するローグライト。Godot 4.6.3 / GDScript、16:9。リリース想定はAndroid、Web版は引き続き検証用です。Android向け実機ベンチマークは [操作方法](BENCHMARK_ANDROID.md) を参照してください。コンセプト画と、128×128の本体・パーツ、64×64の敵、48×48の系統アイコンは本作向けの素材です。素材は `assets/art/` 以下の同じパス・サイズで差し替えできます。戦闘背景とHUD・メニュー、ミミックおよび敵のピクセル素材は刷新済みです。

現在の操作・数値・解放条件は [現在の仕様書](SPEC.md) を参照してください。

## 起動

- Godot 4.6.3で `project.godot` を開き、F6ではなくF5で起動。
- Web版は `web/` に書き出し済み。HTTPサーバーで配信して開きます。`file://` で直接開く方法はWebAssemblyの制約で使えません。

```sh
cd mimic
python3 -m http.server 8000 --bind 127.0.0.1
# 同じマシンで http://127.0.0.1:8000/web/ を開く
```

戦闘中はマウスの位置、またはタッチ開始位置からドラッグした方向で照準を変えます。狙った方向に自動で発射します。ボム「破滅の供物」はSPACEキーまたは画面右下のボタンで発動し、20秒後に再使用できます。ボムで倒した敵の資金は3倍です。拠点の「永続強化」では進化ポイントを女性たちへの供物に使い、封印を順に解きます。取得した装備、資金、魔石、強化、解放状態はGodotの `user://mimic_save.json` に自動保存します。Web版の保存はブラウザごとのローカル領域です。

## 構成

`data/items.json` に44種の通常装備と10種の伝説装備、`affixes.json` に23種の追加効果、`balance.json` に出現率・敵強化を置いています。`src/combat.gd` は敵120、投射物256、演出の固定プールと戦闘ロジック、`profile.gd` は装備・鍛冶・永続強化・保存、`main.gd` は画面・入力・描画です。固定プール以外にも、戦利品生成や一部の計算では配列・辞書を使用します。

GodotのWeb書き出しは、公式4.6.3テンプレートを用意した上で実行します。

```sh
godot --headless --editor --import --path .
godot --headless --path . --export-release Web web/index.html
python3 tools/patch_web_storage.py
python3 tools/patch_web_audio.py
```

Webの実行ファイルを再書き出しした場合、最後の2つのスクリプトで、ブラウザ保存同期の通知とタッチ時の音声再開を復元します。既存のWebランタイムが対応しない形式ならスクリプトは停止します。

## 検証と残課題

`tests/` の `*_smoke.gd` はGodotヘッドレスで個別に実行できます。方向優先、装備変更、7系統、鍛冶・魔石、10種の伝説能力、敵の役割、ボスとステージ解放、敗北後の保存を確認しました。`run_trials.gd` は初期装備、`strong_trials.gd` は強化済みビルドによる自動試走です。

PCと横向きタッチのChromiumでWeb版の起動・ステージ開始・照準操作を確認しました。敵120体の負荷モードでは、GPUのないソフトウェア描画環境で背景と戦闘画面の刷新後は約23fpsでした（以前のタイトル画面は約35fps）。**通常PCのGPUで120体・60fpsを維持できるかは未検証です。** 計測用の `?stress=1` はデバッグ専用です。

完成条件に対して、戦闘スプライトとエフェクトは指定解像度のオリジナル素材ですが、添付参考画像の細密さには達していません。敵やアイテムは系統ごとに共通するパーツが多く、アニメーションも限定的です。比較画面は牙の威力・間隔、HP、軽減と系統数を表示し、追加効果すべての差分は表示しません。追加投射物は魔力弾、連鎖は呪術に適用されます。対人プレイによる長時間のバランス検証や、実機ブラウザでの保存・性能検証も未実施です。このため、完成品としての視覚品質と性能予算の達成はまだ確認できていません。

## 2026-11 最適化の測定

当時は敵の位置を追尾弾向けにまとめて参照し、同一フレームの戦利品保存をまとめました。連続ダメージの数字は同じ敵ごとに短時間集約し、同時表示は最大16個です。この測定後、攻撃はプレイヤー指定方向に変わりました。数値は変更前の参考測定です。

`tests/performance_bench.gd` のCPU計測では、敵120体・追尾弾80発の人工負荷が変更前4.439msから変更後2.778ms／更新でした（各1回、ウォームアップ後780更新の平均）。GPUを使わないChromiumの別の人工負荷テストでは、同条件の描画を含む計測が約19.3fpsから約19.7fpsでした。**どちらも実機の通常プレイや60fps達成を示す値ではありません。** 負荷と実機での描画性能は引き続き要検証です。

外部制作する画像のサイズ・位置・ファイル名は [ASSET_SPEC.md](ASSET_SPEC.md) を参照してください。

## 報酬演出に使用した素材

- [pixelfx](https://github.com/patch-gg/pixelfx) — MIT。`pickups/collect-burst`、`holy/holy-pillar`、`explosions/implosion`、`impacts/hit-spark`、`impacts/crit-hit` の透過スプライトシートを使用。生成条件と著作権表示は [素材ディレクトリ](assets/fx/pixelfx/README.md) を参照。Patch Pixel フォントは使用していません。
- [Kenney Interface Sounds](https://kenney.nl/assets/interface-sounds) — CC0 1.0。配布元および使用したファイルは [素材ディレクトリ](assets/audio/kenney-interface/README.md) を参照。
- [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds) — CC0 1.0。命中音に使用。配布元および使用したファイルは [素材ディレクトリ](assets/audio/kenney-impact/README.md) を参照。

ゲーム内の「設定 → 素材クレジット」にもライセンスを表示します。
