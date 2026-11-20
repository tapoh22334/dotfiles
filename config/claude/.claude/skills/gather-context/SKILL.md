---
name: gather-context
description: >-
  Use when the user names a topic and wants what is already recorded about it
  pulled together from GitHub (repos, PRs, commits, code), tickets (GitHub
  Issues and the All Work project board) and Notion — 〜について情報を集めて /
  〜の経緯を調べて / コンテキスト収集 / 関連情報をまとめて / 〜ってどうなってたっけ /
  〜の資料ある? / gather context on X / what do we have on X / dig up everything
  about X. Also use before designing, reviewing or resuming work on a topic whose
  history is spread across several repos and Notion pages. Differs from brief
  (re-orients on the whole workspace, no topic given) and global-session-map
  (searches Claude session history, not GitHub or Notion).
---

# gather-context — 話題の情報収集

利用者が指定した話題について、GitHub・チケット・Notion に残っている記録を集め、
出典つきの一つの文書にまとめる。読み手はこのまとめから元の記録を開き、判断の根拠を確かめる。
そのため、すべての記述に出典のリンクを付ける。

読み取るだけにする。Issue・PR・Notion ページを書き換えない。

## 手順

### 1. 検索語を決める

話題の名前だけで検索すると一部の記録を検出できない。次の手がかりから、別名と識別子を集める。

- メモリの索引(MEMORY.md)と、関係するメモリファイル
- 話題の英語名・日本語名・略称
- リポジトリ名・ホスト名・サービス名・Issue 番号など、記録に現れる識別子

検索語は 3〜6 個にする。検索の結果から新しい識別子が見つかれば、それも検索語に加える。

### 2. 3 つの情報源を検索する

情報源どうしは独立しているので、並列に検索する。GitHub は `gh` CLI で調べる。
GitHub の MCP サーバーは接続できないことがあるため、それに頼らない。
owner は既定で `tapoh22334` とし、話題が別の owner のものならそちらを使う。

| 情報源 | 調べ方 |
|---|---|
| チケット | `gh search issues "<語>" --owner <owner> --limit 30`。状態は `gh project item-list 4 --owner tapoh22334 --format json --limit 500` で確かめる。Project の状態と Issue の Open/Closed が食い違うことがある |
| GitHub | `gh search prs "<語>" --owner <owner>`・`gh search commits "<語>" --owner <owner>`・`gh search code "<語>" --owner <owner>`。手元に clone があれば、commits と code の検索は `git log --grep` と `git grep` で代えてよい。clone の remote が検索の owner と違うときは、`gh repo view <remote>` で転送先を確かめる |
| Notion | `notion-search` を検索語ごとに実行する。検索結果の抜粋に、ほかの情報源にない事実が含まれるページを `notion-fetch` で開く。日報・振り返りなど日付つきのページは、経緯の時期を確かめるのに使う |

話題が稼働中のシステムに関わるときは、読み取りだけのコマンド(`systemctl status`・`journalctl` など)で
現在の状態を確かめてよい。その結果は「探索範囲」の「3 つの情報源の外」の行に書く。

### 3. 参照をたどる

検索で見つかった Issue・PR・ページの本文とコメントを読み、そこから参照されている
Issue・PR・ページを開く。新しい事実が得られなくなったら打ち切る。
開かなかったものは、理由とともに「探索範囲」に書く。

### 4. 照合する

情報源どうしで記述が食い違うときは、新しい記録を優先する。食い違い自体も
「食い違い・古い記録」に書く。Notion の Wiki やメモリは更新が遅れやすい。
古い記録は直さず、どう直せばよいかを同じ項目に書く。
Project「All Work」に登録されていない Issue も、食い違いとして書く。

推測は事実と分ける。「〜とみられる」と書き、根拠を添える。

## 出力

次の順に書く。セクションに書くことがなければ「なし」と書く。

```markdown
## 要約
<話題の現状を 3〜5 行。何が済み、何が残り、誰の判断待ちか>

## 要注意
- <記録を照合して初めて判明した危険や見落とし。根拠> (出典)

## 経緯
- YYYY-MM-DD: <出来事> ([owner/repo#N](URL))
- YYYY-MM-DD: <出来事> ([Notion: ページ名](URL)、[owner/repo#M](URL))

## 未完了
| 項目 | 状態 | 残っていること | 出典 |
|---|---|---|---|

## 食い違い・古い記録
- <記録 A と記録 B の食い違い。どちらを採用したか> (出典)

## 探索範囲
| 情報源 | 検索語 | 件数 | 開いたもの・開かなかったもの |
|---|---|---|---|
```

出典の書き方は次のとおりである。

- Issue・PR は `owner/repo#N` を表示名にして URL へリンクする。同じリポジトリが続いても `#N` だけにしない。読み手がリポジトリを推測しなければならなくなるからである。
- コミットは `owner/repo@短縮ハッシュ` をリンクにする。
- Notion のページは `Notion: ページ名` をリンクにする。
- 一つの項目に出典が複数あるときは、読点で区切って並べる。
- 情報源の検索が 0 件だったときも、「探索範囲」に 0 件と書く。0 件は「探していない」と区別できなければならない。

## よくある誤り

| 誤り | 直し方 |
|---|---|
| 話題の名前だけで検索して、別名で書かれた Issue を検出できない | 手順 1 で別名と識別子を集め、見つかった識別子でも検索し直す |
| `#12` のようにリポジトリを省いて書く | 常に `owner/repo#N` で書き、リンクを付ける |
| Project の状態だけを見て「完了」と書く | Issue の Open/Closed と完了条件のチェックも見る。食い違いは書く |
| 経緯を長い文章で書く | 経緯は日付と出来事と出典の一行にする。解釈は要約に書く |
