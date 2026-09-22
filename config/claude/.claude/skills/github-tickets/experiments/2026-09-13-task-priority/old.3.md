| title | level | Status | Priority | Size |
|---|---|---|---|---|
| fork で作ったセッションが Navigator の一覧で親の下に見える | Story | Ready | P1 | (blank) |
| feature/fork-detection をレビュー指摘を解消して main に取り込む | Task | Ready | P1 | S |
| 親未登録の fork 行のタイトルも _fork_label 経由で生成する | Task | Backlog | P2 | XS |
| nearest-parent と compaction 非 fork の設計保証をテストで固定する | Task | Backlog | P2 | S |
| Navigator 起動時に端末を失った古い navigator プロセスを掃除する | Task | Backlog | P2 | S |
| navigator-list.sh を責務ごとに 500 行以下に分ける | Task | Backlog | P2 | M |

Priorityは、進行中の fork-detection 系(既にレビュー指摘が出ている取り込み待ちブランチ)をP1、それ以外の未着手改善をP2とし、緊急のバグではないためP0は使いませんでした。
