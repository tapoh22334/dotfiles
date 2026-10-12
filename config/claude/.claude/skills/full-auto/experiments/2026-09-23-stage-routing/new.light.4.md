1. `gh issue list --state open --search "truncate_display"` で既存 Issue を検索 — #37/#41/#43 とは無関係なバグのため既存なしと判断
2. 既存なしと確定した場合: github-tickets(manifest 作成 + `apply.sh` 実行)で新規 Issue を起票し、Project「All Work」#4 に登録
3. superpowers:test-driven-development(RED)— `navigator-list.sh` の `truncate_display` に幅 0 を渡す bats テストを先に書き、失敗を確認
4. superpowers:test-driven-development(GREEN)— 幅 0 のとき数字ではなく空文字/安全値を返すよう `truncate_display` を最小修正
5. `make lint` / `make test` を実行し、既存テストが緑のままであることを自分で確認(サブエージェント成果物の実在確認)
6. tower-reviewer エージェントで diff をレビューし、CONFIRMED 指摘があれば修正してから再レビュー
7. ブランチをコミットし、起票した Issue を `Closes #<N>` として参照する PR を作成(main への直接コミット・push はしない)
8. CI の結果を確認 — 赤の場合は変更前 baseline と比較し回帰か既存不具合かを切り分けてから対応
9. github-tickets apply.sh --verify(または item-list)で当該 Issue が Project ボードに載っていることを確認
10. 完了報告(①成果と証拠 ②暫定裁定一覧 ③バックログ状況 ④依頼者にしか決められない残件)をまとめる

Backlog after this task: 新規作成した 1 件の Issue(`truncate_display` 幅 0 バグ)を使用。github-tickets apply.sh 経由で作成・Project「All Work」#4 に登録済み、apply.sh --verify で確認済み。PR の `Closes #<N>` でクローズ予定(手動 close はしない)。
