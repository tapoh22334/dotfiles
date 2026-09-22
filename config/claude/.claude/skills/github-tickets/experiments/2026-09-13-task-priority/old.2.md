| title | level | Status | Priority | Size |
|---|---|---|---|---|
| fork で作ったセッションが Navigator の一覧で親の下に見える | Story | Backlog | P1 | (blank) |
| feature/fork-detection をレビュー指摘を解消して main に取り込む | Task | Backlog | P1 | S |
| 親未登録の fork 行のタイトルも _fork_label 経由で生成する | Task | Backlog | P1 | S |
| nearest-parent と compaction 非 fork の設計保証をテストで固定する | Task | Backlog | P1 | S |
| Navigator 起動時に端末を失った古い navigator プロセスを掃除する | Task | Backlog | P2 | S |
| navigator-list.sh を責務ごとに 500 行以下に分ける | Task | Backlog | P2 | M |

fork 関連の4件は既存のレビュー指摘を抱えたブランチを main に取り込む作業なので P1、残る2件(プロセス掃除・ファイル分割)は独立した改善で緊急性がないため P2 とした。
