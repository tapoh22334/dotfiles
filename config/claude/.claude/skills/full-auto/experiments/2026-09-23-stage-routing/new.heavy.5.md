1. `gh issue list --state open --search "Tail"` を実行し、既存 Issue を確認する
2. #37(Navigator 入れ子・pane 縮小)を再利用 — Tail を左ペイン表示モード化すれば別窓遷移自体がなくなり根本解決になるため。着手コメントを投稿する
3. 実装規模を判定: 新しい表示モード追加・複数ファイル変更・受入条件複数 → vf-pipeline 該当
4. vf-pipeline: orient → articulate → requirements → userflows → harness → construct → acceptance → trace を実行
5. 作業中に派生課題(例: Tile/Queue 側の遷移ロジックとの整合、#43 のタイトル更新タイミングとの相互作用)を見つけた場合、github-tickets(manifest + apply.sh)で新規 Issue を起票し、本 PR 本文に番号を記載
6. vf-pipeline の construct 段階が TDD ベースであることを確認しつつ実装(RED→GREEN、既存 harness 利用)
7. `make lint` / `make format` / `make test` を実行し baseline と比較(既存失敗と回帰を区別)
8. tower-reviewer エージェントを diff に対して起動し、CONFIRMED 指摘を修正
9. ブランチをコミットし、`gh pr create` で PR を作成(本文に「なぜ直すのか」と `Closes #37` を明記)
10. CI 結果を確認し、赤があれば原因を分類(一過性/インフラ/本質的)して対処後に再確認
11. CI green を確認後、PR をマージ
12. `apply.sh --verify`(または item-list)で #37 および新規起票 Issue が Project「All Work」に載っていることを検証
13. マージにより #37 が自動 close されたことを確認(手動 close はしない)

Backlog after this task: #37(既存再利用、PR の `Closes #37` でクローズ)+ vf-pipeline の過程で発見した派生課題があれば github-tickets 経由で新規起票し番号を追記。全て `apply.sh --verify` で Project「All Work」登録を確認する。
