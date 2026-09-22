---
name: backlog-resume
description: >-
  Pick a suspended session back up from the record backlog-suspend left behind,
  not from memory. Use when the user returns to resume parked work and says
  再開 / レジューム / 作業戻る / 続きから / どこまでやってたっけ(作業に戻る文脈)
  / suspend したやつ戻す / resume / pick up where I left off / continue that
  task. Its pair is backlog-suspend (which persisted the state); this reads
  that state — the Backlog task's resume notes and the landed branch — and
  reconstructs enough context to act, then continues from the recorded next
  step. Differs from brief (which only re-orients) — backlog-resume actually
  re-enters the work.
---

# Backlog Resume — 記録から作業に戻る

離席から戻った。頭の中の作業スタックは消えている。だが `backlog-suspend`
が去り際に**記録を残した**はずだ。このスキルの仕事は、その記録を読んで
作業に再着艦すること — 記憶からではなく、**残されたものから**。

対になる suspend は「状態をディスクに書いて止める」側。resume は「その
状態を読んで再開する」側。だから最初にやるのは思い出そうとすることでは
なく、**記録を探して読む**ことだ。

## 手順

### 1. 記録を読む(思い出そうとしない)

suspend は再開文脈を Backlog タスクに書いた。まずそれを探す。

- `backlog task list --status "In Progress" --plain` で中断中のタスクを見る。
  複数あれば、どれの続きかをユーザーに確認するか、文脈から絞る。
- `backlog task view TASK-N --plain` で**再開ノート全文**を読む。suspend は
  そこに「何をしていたか・どこまで進み何を判断したか・何が引っかかって
  いたか・次の一手とその狙い」を意味論で書いているはず。これが再開の地図。

### 2. 世界の状態を復元する

ノートが指すブランチやコミットに戻る。

- suspend が着地させたブランチに `git checkout` する(ノートにブランチ名が
  ある)。未 push なら push 状況も確認。
- 作業ツリーとノートの記述が食い違っていないか照合する — 食い違えば、
  ノートが古いか、間に別の変更が入った合図。鵜呑みにせず、実際の
  git/コードを一次情報として優先する(recalled note は書かれた時点の真実
  でしかない)。

### 3. 記録された「次の一手」から続ける

ノートの「次の一手」が出発点だ。それを起点に作業を再開する。ただし
機械的に従うのではなく、ノートの**狙い**(なぜその一手なのか)を理解して
から動く。狙いが今も有効かを一瞬確かめる — 有効なら進む、状況が変わって
いれば調整する。

### 4. 短く再着艦を報告する

作業に入る前に、ユーザーに一言:「TASK-N の続き。◯◯まで終わっていて、
次は××(ノートより)。ブランチ △△ に戻った。これから続けます」。
これで、ユーザーも同じ地図を共有した状態で再開できる。

## Backlog 連携(この環境)

このプロジェクトは Backlog.md(`backlog` CLI)。再開ノートはタスクの notes に
ある。`backlog task view TASK-N --plain` で読む。task md を直接編集せず、
状態を更新するとき(再開したら In Progress のままか、進捗を追記するか)は
CLI 経由で。

Backlog が無い環境では、suspend が代わりに残した場所を読む — 最後のコミット
メッセージ、draft PR の本文、既存の TODO。記録が見つからなければ、正直に
「再開できる記録が見つからない」と伝え、`brief`(痕跡からの再構成)に
切り替えるか、ユーザーに直接聞く。

## やってはいけないこと

- **記憶から再開する**:記録を読まず「確か…」で進める。記録が地図だ。
- **ノートを鵜呑み**:git/コードと食い違っても記録を信じる。一次情報が優先。
- **黙って作業に入る**:再着艦の一言なしに始める。ユーザーが地図を
  共有できない。
