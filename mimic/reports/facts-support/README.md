# 再現手順

対象コミット: `9718529`、Godot 4.6.3。ゲーム本体を変更しないため、一時コピーにのみ計測を追加する。ラン条件・種・方策・購入順は `tests/early_progression_trials.gd` のまま。保存機能を使わない試行用プロフィールを使用し、通常プレイのセーブに触れない。

`prepare_instrumentation.py` は実験時の `/tmp/mimic-facts-copy` を対象にしている。すでに同名のコピーがあれば内容を確認して別の場所に移動し、未計測のコピーから実行する。

```sh
cp -a mimic /tmp/mimic-facts-copy
python3 mimic/reports/facts-support/prepare_instrumentation.py
cp mimic/reports/facts-support/{instrumentation_check,set_experiment}.gd /tmp/mimic-facts-copy/tests/
XDG_DATA_HOME=/tmp/mimic-facts-data XDG_CONFIG_HOME=/tmp/mimic-facts-config XDG_CACHE_HOME=/tmp/mimic-facts-cache godot --headless --path /tmp/mimic-facts-copy --script res://tests/instrumentation_check.gd
MIMIC_TRIAL_OUTPUT="$PWD/mimic/reports/facts-progress-data.json" MIMIC_TRIAL_SAMPLES=10 MIMIC_TRIAL_MAX_RUNS=50 XDG_DATA_HOME=/tmp/mimic-facts-data XDG_CONFIG_HOME=/tmp/mimic-facts-config XDG_CACHE_HOME=/tmp/mimic-facts-cache godot --headless --path /tmp/mimic-facts-copy --script res://tests/early_progression_trials.gd
XDG_DATA_HOME=/tmp/mimic-facts-data XDG_CONFIG_HOME=/tmp/mimic-facts-config XDG_CACHE_HOME=/tmp/mimic-facts-cache godot --headless --path /tmp/mimic-facts-copy --script res://tests/set_experiment.gd
python3 mimic/reports/facts-support/build_report.py
```

比較実験の出力先は `/workspace/test-game/mimic/reports/facts-set-control.json` に固定されているため、別の作業場所ではコピーした `set_experiment.gd` の出力先を変更する。集計スクリプトは元の `early-progression-data.json` と記録全件を比較し、差異があれば停止する。実装差やGodotバージョンで乱数系列が変われば再現されない場合がある。セットの直接ダメージの定義、呪術の帰属範囲、死の定義は報告書を参照。
