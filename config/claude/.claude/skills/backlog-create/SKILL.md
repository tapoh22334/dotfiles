---
name: backlog-create
description: >-
  Turn a piece of work worth tracking into a Backlog.md task written by
  MEANING, not mechanics — outcome and why, never a step list. Use whenever
  the user wants to file/capture/record work in Backlog and says
  タスク作成 / タスクにして / backlog に積んで / チケット切って / これ記録しといて
  / 課題として登録 / file a task / add to backlog / make a ticket / capture this
  as a task, or when a review, bug, or idea surfaces mid-work that should be
  tracked rather than done now. Also use when the user hands you a rough
  intention ("あとで X を直したい") that needs to become a real, actionable
  task a future agent can pick up with zero conversation context.
---

# Backlog Create — 意味で書くタスク

タスクは未来の誰か(明日の自分、別のエージェント)への発注書だ。その人は
今のこの会話を持っていない。だから良いタスクの条件はただ一つ:**会話の
文脈がゼロでも、それを読んだだけで着手できるか**。

このスキルは、雑な意図(「あとで queue-view の色を直したい」)を、その
条件を満たす一枚に変える。

## 意味を書く、手順を書かない(最重要)

一番やりがちな失敗は、**やり方(how)を書いてしまう**こと。「navigator-list.sh
を開いて 200 行目の関数を書き換えて…」——これは発注書ではなく、書き手が
今わかっているつもりの手順で、明日には古くなる。コードは変わる。タスクが
固定すべきなのは手順ではなく、**変わらないもの — 何を・なぜ・何で完了か**。

- **何を(タイトル)**: 成果を一行で。「◯◯を直す」ではなく「◯◯が××に
  なるようにする」。結果が見える動詞で。
- **なぜ(説明)**: この作業がなぜ要るのか。どんな不都合・きっかけから
  生まれたか。diff からは読めない、頭の中にしかない理由。
- **完了条件(受け入れ基準)**: 何が満たされたら「終わった」と言えるか。
  検証できる形で。「ちゃんと動く」ではなく「◯◯の場合に××になる」。

手順は書かない。それは着手した人がその時のコードを見て決める(backlog の
task-creation ガイドもそう言っている — 作成時に実装計画を入れるな)。
例外は、既に着手済みの作業をそのまま In Progress で登録するときだけ。

## KISS — 一枚に一つ

タスクは小さく、一つの結果に絞る。「レビューして、直して、テストも足す」は
三つの発注。分けると、それぞれが独立して着手・完了・レビューできる。
一枚が大きくなってきたら、それは分割の合図だ(`--dep` で順序を、`-p` で
親子を付けられる)。

過剰も避ける。受け入れ基準を 10 個並べるより、本当に効く 2〜3 個。冗長な
背景説明より、効く一文。KISS は手抜きではなく、**読む側の負荷を最小にする**
規律だ。

## 書き方の例

**悪い例(手順・曖昧)**:
> タイトル: queue-view.sh を修正
> 説明: get_wait_state を見て tmux 分岐を直す
> 受け入れ: ちゃんと動く

手順が古びるし、「ちゃんと動く」は検証できない。何のための修正かも不明。

**良い例(意味・検証可能)**:
> タイトル: 許可待ちセッションに ⚠ アイコンが表示されるようにする
> 説明: Queue view で permission-wait のセッションに出るはずの ⚠ が
>   描画されない。classify_pane_wait は正しく "permission" を返すと
>   確認済みなので、原因は下流(状態→描画の経路)にある。ユーザーが
>   「どのセッションが許可待ちか」を一目で判断できないのが実害。
> 受け入れ基準:
>   - permission-wait のセッション行に ⚠ が表示される
>   - 他の待ち種別(input/question)のアイコンは従来どおり

同じ短さでも、後者は明日そのまま着手できる。

## 手順

1. **既存を検索**してから作る。同じ作業が既にタスク化されていないか
   `backlog task list --plain` や `backlog search "keyword" --plain` で確認。
   あれば新規作成でなくそれを使う(重複は管理コスト)。
2. **意味で下書き**する — 上の三点(何を・なぜ・完了条件)。手順は書かない。
3. **CLI で作成**する:
   ```
   backlog task create "結果が見えるタイトル" \
     -d "なぜ要るか・何が実害か" \
     --ac "検証できる完了条件1" --ac "検証できる完了条件2"
   ```
4. 作成後、返ってきた **TASK-ID を一行要旨とともに報告**する。

## Backlog 連携(この環境)

このプロジェクトは Backlog.md(`backlog` CLI)でタスクを管理している。
作成の前に一度 `backlog instructions task-creation` を読む(検索・スコープ・
作成の正しい手順が載っている)。task md を直接編集せず、必ず `backlog` CLI
経由で作る — メタデータ・ファイル名・履歴の一貫性が壊れるため。

Backlog が無いプロジェクトでは、既存の課題管理(issue、TODO.md 等)に
合わせる。無ければ**そもそもタスク化が要るか**を問い直す — 記録媒体が
無いのに新しいファイルを作るのは、散らかりを増やすだけ。

## やってはいけないこと

- **手順を書く**:「◯行目を直す」。コードは変わる。意味を書け。
- **検証できない完了条件**:「ちゃんと動く」「きれいにする」。何をもって
  完了かを、確かめられる形で。
- **一枚に複数の結果**:「直してテストして文書化」。分けろ。
- **会話依存**:「さっきの件」。文脈ゼロの読者に通じる自己完結を。
- **task md 直接編集**:CLI を通せ。メタデータが壊れる。
