---
name: backlog-list
description: >-
  Show the current Backlog.md tasks grouped by status, readably. Use whenever
  the user wants to see what's tracked and says タスク一覧 / タスク出して /
  今のタスク / backlog 見せて / 何が残ってる / やることリスト / show tasks /
  list backlog / what's on the board / what's left to do. Reach for this the
  moment the user asks about the state of tracked work, even casually.
---

# Backlog List — 状況が一目でわかる一覧

タスク一覧の目的はただ一つ:**今どうなっているかを一目で掴ませる**こと。
生の CLI 出力をそのまま貼るのではなく、読む人が「次に何をすべきか」を
すぐ判断できる形にする。

## やること

1. **CLI で取得**する。既定は絞り込みなしの全件だが、件数が多い環境では
   状況で絞る:
   ```
   backlog task list --plain                      # 全件
   backlog task list --status "In Progress" --plain   # 進行中だけ
   backlog task list --search "queue" --plain     # キーワード
   ```
2. **状況ごとにまとめて**見せる。To Do / In Progress / Done を分け、各
   タスクは `TASK-ID - タイトル` の一行。優先度やラベル(`[HIGH]` `[bug]`)が
   あれば添える。
3. **意味の補足を一言**。ただの転記で終わらせず、読む人の判断を助ける
   短い注記を足す — 「進行中はゼロ、次に着手できるのは TASK-1」「TASK-7 は
   今セッションの成果で Done」のように。ただし KISS、一覧を埋め尽くさない。

## KISS

一覧は一覧だ。個々のタスクの中身を延々と展開しない。詳細が要るなら
`backlog task view TASK-N --plain` へ誘導する。全件が多すぎるときは
`--status` や `--limit` で絞り、「全部で N 件、うち進行中 M 件」と件数を
先に伝えてから主要なものを見せる。

## Backlog が無い環境

`backlog` CLI が無ければ、そのリポジトリの課題管理(GitHub issue、TODO.md
等)を代わりに読む。それも無ければ「このプロジェクトはタスク管理を
導入していない」と正直に伝える — 無いものを一覧しようとしない。
