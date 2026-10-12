1. gh issue create — new issue "navigator-list.sh: truncate_display outputs digits when width is 0"（既存 #37/#41/#43 は無関係）。裁定: 新規 issue を切る。根拠: 1関数バグは既存3件のどれとも対象範囲が重ならない。
2. github-tickets apply.sh — 作成した issue を Project「All Work」(#4) に登録・検証。
3. superpowers:systematic-debugging — truncate_display の該当コードを読み、幅0のとき数字を出力する原因（printf/cut の境界条件など）を特定。
4. TDD (superpowers:test-driven-development) — 幅0を含む境界値の失敗するテストを bats で先に書く（tests/ 配下、既存の truncate_display 関連テストファイルに追加）。
5. 実装修正 — truncate_display 内で幅0のとき何も出力しない/空文字を返すよう1関数のみ修正。
6. make test / make lint — 全体テストと shellcheck を実行し、baseline との差分（新規の失敗がないか）を確認。
7. tower-reviewer — tmux-plugin/ 配下の diff に対してレビューエージェントを実行。
8. git — ブランチ作成→コミット→push、PR 作成（本文に「なぜ直すか」を記載、Closes #<新規番号>）。
9. CI 結果を確認 — 赤ならログを見て systematic-debugging で原因切り分け、既存失敗なら明示、回帰なら修正して再push。
10. CI green を確認後、PR マージ。
11. gh issue close — 新規 issue に「何を・なぜ直したか」をコメントして close。

Backlog after this task: 新規作成した1件のみ使用（既存 #37/#41/#43 は不使用）、Project「All Work」(#4) に登録済み、マージ後 close 済み。
