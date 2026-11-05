# safe-close 改善履歴

## 2026-11-04 記録先が Backlog.md 前提のままで、タスク管理の正本と食い違っていた
- 実物: 旧 `session-close-safe` の「Backlog 連携」節と G3 は、記録先を Backlog タスクにして
  `backlog` CLI を使うように指示していた。`~/CLAUDE.md` のタスク管理節は 2026-09-12 に
  GitHub Issues に移行しており、`~/.claude/improvement-log.md` の同日エントリに未処理の
  残件として記録されていた。ユーザーの依頼「基本は git やドキュメント issue に記録を残す」
  「名前を safe-close に変えて」(issue tapoh22334/dotfiles#57)
- 分類: 矛盾欠陥(スキルが古い側)
- 5-why の終点: タスク管理の方針を CLAUDE.md で切り替えたとき、同じ主題を扱うスキルを
  追従させる仕組みがなく、古い記録先が残った
- 修正: 改名(`session-close-safe` → `safe-close`)。Backlog 連携節を「記録先」節に置き換え、
  残す内容の種類ごとにコミットメッセージ・issue コメント・リポジトリ文書を割り当てた。
  `backlog-suspend` への参照を削除し、1 セッションのときもこのスキルで閉じると明記した。
  会話の未加工のログは SessionEnd hook `~/.claude/hooks/archive-transcripts.sh` が
  `~/.claude/transcript-archive/` へ zstd 圧縮で保存する(スキルからは操作しない)。
  evals の id 2 を issue 前提に書き換えた
- 実験: 矛盾欠陥の検収として、dotfiles 全体を `session-close-safe` と `backlog` で grep した。
  このスキル内の残存は「Backlog.md は使わない」の 1 行のみ。hook は tmux kill-session
  (claude-tower の D)で起動し、5 秒かかる処理も最後まで実行されることを実機で確認した
  (`reason: "other"`、transcript_path が渡る)
- 回帰: 関門 G1〜G3 と三段の手順、やってはいけないことは記録先の語以外を変えていない
- 残件: backlog-create / backlog-list / backlog-suspend / backlog-resume / backlog-steward は
  まだ Backlog.md 前提のまま(本エントリの対象外)

## 2026-11-04 改名後も skill-map に旧名が残っていた(前エントリの検収の訂正)
- 実物: 前エントリは「dotfiles 全体を grep して残存はこのスキル内の 1 行のみ」と書いたが、
  `skill-map/references/groups.json` に `session-close-safe` が残っていた。
  Backlog 系スキルの削除(issue tapoh22334/dotfiles#61)で grep し直して見つかった
- 分類: 矛盾欠陥の検収漏れ
- 5-why の終点: 検収の grep を別コマンドと連結して実行し、出力が空であることを
  「残存なし」と読んだ。grep が実際に dotfiles 全体を走査したかを確かめていなかった
- 修正: groups.json の旧名を `safe-close` に直した(#61 の PR に同梱)
- 実験: 単独の `grep -rn "session-close-safe" --exclude-dir=.git .` を dotfiles の root で実行し、
  improvement-log 以外の該当が 0 件であることを確認した
- 回帰: groups.json の他の群は変更していない

## 2026-11-05 閉じてよいかを判断せずに片付け始め、調査が要る懸念を記録しないか issue コメントに埋めていた
- 実物: 利用者の依頼(issue tapoh22334/dotfiles#67)。safe-close はチケット単位で閉じるために使う。
  主題が未完なら続行を推奨し、主題から離れた作業はチケットを作り直して閉じ、対応要否の調査が要る事項は
  メモでなく triage の issue にしたい。旧文面で状況 A・B(evals id 3・4)を各 3 回、sonnet に計画させた対照群:
  A(主題 #40 の回帰テストが未達・待ちなし・まれに失敗するテスト)は 3 回とも続行を推奨せず閉じた。
  失敗するテストを issue にしたのは 1/3(ラベル bug)、2/3 は #40 のコメントに書いただけだった。
  B(主題 #41 完了、別作業の JSON ログ化が未コミット、DeprecationWarning)は 3 回とも別作業を issue にしたが、
  警告を issue にしたのは 1/3 で、2/3 は「再現が容易で失う文脈ではない」として記録しなかった
- 分類: 不在欠陥(閉じるかどうかの判定と、調査が要る懸念の置き場を扱う指示がなかった)
- 5-why の終点: スキルの関心が「所有の確認」だけで、主題(チケット)と作業の照合が手順に無かった。
  「再現困難なものだけ残す」原則が、未調査の懸念を捨てる根拠として読まれた
- 修正: 関門の前に「閉じる前に」節(S1 主題の完了判定と続行推奨、S2 離れた作業の別 issue 化、
  S3 triage の issue 化と置き場の表)を足した。報告と記録先の表に S1〜S3 の結果を加えた。
  description に「チケット単位で閉じる」の発火語を足した。github-tickets に `triage` ラベル
  (確約の軸、labels.tsv)と Triage の本文テンプレートを新設した(利用者が既存の idea 流用ではなく新設を選んだ)
- 実験: 新文面 1 版で A・B 各 3 回。A は 3/3 で続行推奨と triage 起票。B は 3/3 で別作業の issue 化と
  triage 起票ができたが、2/3 が別作業の続行を推奨した(「新しい主題についても S1 を判定する」の 1 文が原因)。
  その文を「離れた作業は未完でも続行を推奨しない。issue に記録して閉じ、新しいセッションで始める」に
  置き換えた 2 版で A・B 各 3 回: A 3/3 続行推奨+triage、B 3/3 別作業の issue 化+閉じる推奨+triage
- 回帰: 関門 G1〜G3、畳む三段、やってはいけないことは、報告の段落に S1〜S3 の項目を足した以外は
  変えていない。2 版の A・B 全 6 回で、`git add -A` 不使用・fast-forward 確認・コメントで追記が維持された
