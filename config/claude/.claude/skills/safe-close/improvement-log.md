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
