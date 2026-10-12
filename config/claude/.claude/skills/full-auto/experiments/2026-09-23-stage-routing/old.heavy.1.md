1. gh issue list の #37 を再確認 — 「Navigator 入れ子/自己 attach」問題は Tail を別窓に飛ばしている現行実装が原因であり、今回の要求「Tail を左ペインの表示モードにする」で構造的に解消できるため、新規 issue は作らず #37 を reuse する(暫定裁定: 新規 issue ではなく既存 issue に統合)。
2. github-tickets スキルで #37 のマニフェストを更新し、スコープを「Tail を別 tmux window ではなく左ペイン内の表示モードとして実装する」に書き換え、apply.sh --verify で Project「All Work」#4 に載っていることを確認。
3. vf-pipeline を起動(orient → articulate → requirements → userflows → harness → construct → acceptance → trace)し、現行の Tail/Navigator 遷移フローと左ペイン表示モード化の要件・受け入れ基準を明文化する。
4. superpowers:systematic-debugging で、現状の「戻ると入れ子になる」再現手順を先に固定化する(回帰検知の基準点として)。
5. superpowers:test-driven-development で、左ペイン内モード切替(Navigator⇄Tail)の統合/E2E テスト(bats、tests/integration または tests/e2e)を先に書き、red を確認。
6. fable-orchestrate で調査系サブタスク(現行 window 切替コードの特定、他モード=Queue/Tile との実装比較)を並列委譲。
7. TDD で実装: Tail を新規 window ではなく現在の左ペイン内に描画するモード切替に変更し、Navigator への復帰が入れ子 attach を起こさないようにする。green まで回す。
8. #41(テストが実機 /tmp/claude-tower を汚染する問題)は今回のテスト追加が実機状態に触れるなら前提としてブロッキングになるため、先に軽く確認 — 触れる場合のみ #41 を reuse して隔離を先行修正、触れないなら着手せず back log に残す(暫定裁定)。
9. #43(pane 内でセッション切替時に行タイトルが古い id のまま)は Tail の左ペイン化と隣接領域のため、影響がないか確認するだけ(スコープ外、着手しない・暫定裁定)。
10. make test / make lint / make format を実行し、baseline(main 上の既知の pre-existing failures)と比較して新規 regression か既存かを切り分ける。
11. tower-reviewer エージェントを diff に対して実行し、tmux ネストクライアント・状態ファイル不整合・グローバル配列 subshell 破棄・楽観更新のキャッシュ巻き戻り・端末エコー/カーソル残留の失敗クラスをチェック。
12. 指摘があれば TDD サイクルで修正 → 再度 tower-reviewer。
13. ブランチ(現行 fix/settle-not-in-subshell とは別に、今回用の新ブランチ、例 feat/tail-inline-pane)を切り、コミット。main への直接コミットはしない。
14. PR を作成(本文に「なぜ直すのか」= 別窓遷移が Navigator 入れ子/自己 attach の根因であること書く)。CI 結果を待ち、green を確認してからマージ候補とする(マージ自体は明示指示がない限り実行しない — 暫定裁定: 外向き操作のためユーザー確認を待つ)。
15. #37 をクローズし、「何を・なぜそう直したか」をコメントに残す(#41・#43 は今回未着手ならその旨をコメントし、必要なら backlog として明示)。

Backlog after this task: 使用/更新した issue は #37(今回のスコープに合わせて更新・Project #4 に登録済み・完了後クローズ予定)。#41・#43 は状況確認のみで着手判断を暫定裁定として記録し、着手しなかった場合は open のまま Project #4 に残存。新規 issue 作成はなし。
