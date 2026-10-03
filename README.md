# ブラウザゲーム公開ページ

GitHub Pagesで、2つのゲームを公開します。

| ゲーム | スマホから開くURL | ファイル |
| --- | --- | --- |
| セツカとチカゲ / 異常処理室 | https://kemonodot.github.io/test-game/chikage-setsuka/ | `chikage-setsuka/` |
| FLASH / PARRY | https://kemonodot.github.io/test-game/ | `index.html` とルートの `assets/` |

セツカとチカゲは、2人が自動で怪異事件を処理する、3択の育成と組み合わせを楽しむRPGです。通常CASE9件＋ボス1件、強化27種、シナジー9種、リザルトと再挑戦まで実装しています。

## セツカとチカゲの起動と操作

スマホでは上のURLを開き、「夜勤を開始する」をタップしてください。3択から強化を選び、BUILDで育成状況、ARCHIVEで連携の条件を確認できます。1プレイは1倍速で約10〜20分。再読み込みするとリセットされます。

ローカルでは `chikage-setsuka/index.html` をブラウザで開けます。ビルド、追加ライブラリ、インストールは不要です。詳しい遊び方、全ファイル、バランス調整の入口、注意点は [ゲームのREADME](chikage-setsuka/README.md) を参照してください。

開発用テストだけNode.jsを使います。

```sh
node --test chikage-setsuka/tests/game.test.cjs
```

## 公開の更新

GitHub Pagesの公開元は **main / / (root)** です。変更をmainにコミットしてpushすると反映されます。`.nojekyll`で静的ファイルをそのまま配信します。独自のビルドやGitHub Actionsのワークフローはありません。
