1. `gh issue list --state open --search "Tail Navigator 入れ子"` — 既存判定。#37 が症状一致(Queue/Tail/Tile → Navigator 入れ子・自己attach)なので新規起票せず #37 を再利用。
2. 着手コメントを #37 に投稿(このタスクで着手する旨、スコープを「Tail ビューを左ペインの表示モードとして動かす」と明記)。
3. 判定表チェック: 「利用者に新しい振る舞いを約束する」(別窓→ペイン内モード)に該当 → vf-pipeline を実装経路として採用(暫定裁定として記録: 軽実装の閾値を超えると判断)。
4. vf-pipeline: orient — 現状の Tail 遷移・Navigator 入れ子ロジックを把握(関連: #41 のテスト隔離、#43 の pane 内切替は別件として触れない)。
5. vf-pipeline: articulate — 「Tail は左ペイン内表示モードであり、別ウィンドウ遷移を発生させない」という目標仕様を明文化。
6. vf-pipeline: requirements — 受入条件を列挙(例: Tail 表示中も Navigator は入れ子にならない/戻り操作で pane が縮まない、既存の Queue/Tile 経路は壊さない)。
7. vf-pipeline: userflows — Tail 開始→表示→終了(通常/異常系含む)のフローを整理。
8. vf-pipeline: harness — 既存 bats 環境で Tail/Navigator 遷移を再現するテスト足場を用意(#41 の状態ファイル汚染に注意し、隔離済みのテストパターンを使う)。
9. vf-pipeline: construct — 実装(Tail を別窓生成ではなく左ペイン表示モードとして描画するよう変更)。
10. vf-pipeline: acceptance — 手順6の受入条件を bats で検証。
11. vf-pipeline: trace — 実装と要件/受入条件の対応を確認。
12. tower-reviewer — 実装差分をレビューし、CONFIRMED 指摘があれば修正して再レビュー。
13. `git push` + `gh pr create` — ブランチから PR 作成、本文に「なぜ直すのか」(#37 の入れ子問題の解消)を記載、`Closes #37`。
14. PR の CI 結果を確認(既存 baseline 失敗があれば区別して報告、回帰のみ修正)。
15. github-tickets `apply.sh --verify` — #37 が Project「All Work」#4 に登録済みであることを確認(未登録なら manifest 経由で登録)。

Backlog after this task: 再利用した #37(Project「All Work」#4 への登録は手順15で verify し、未登録なら manifest 経由で登録する)。新規 Issue は作成しない。
