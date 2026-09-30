---
name: proactive-work
description: Spend Claude Max quota that would otherwise expire on maintenance proposals nobody asked for — currently git leftovers across ~/working (uncommitted changes, unpushed or merged branches, stashes, local-only commits on main) — delivered as ONE weekly digest issue whose checkboxes record what was adopted. Use when the user asks about the digest or its adoption rate, wants to run it by hand, asks why it did or didn't run, wants to add a job, or says proactive-work / ダイジェスト / 余った枠を使う / 指示なしで保守 / 自動で後片付け / 採用率 / なぜ走らなかった. Not for doing the cleanup itself — the digest proposes, the user decides.
---

# proactive-work

使わなければ週リセットで消える Claude Max の枠だけを使い、誰も頼んでいない保守の提案を
週 1 本のダイジェスト(`tapoh22334/proactive-digest` の issue)にまとめる。
希少なのはトークンではなく**読む人の注意**なので、成果は提案数ではなく**採用率**で測る。

設計と根拠: dotfiles `docs/superpowers/specs/2026-09-27-proactive-work-design.md`、
先行調査 `docs/research/2026-09-23-proactive-agent-work.md`。

## 仕組み(変えるときに壊してはいけない所)

| 部品 | 役割 | 守っている性質 |
|---|---|---|
| `bin/usage-snapshot.sh` | statusline。`rate_limits` を `~/.local/state/claude-usage/` に記録 | 使用率は対話セッションの statusline にしか来ない。`claude -p` からは読めない |
| `bin/gate.py` | 週リセット 24h 以内・余りが十分・5h 枠が空いている・利用者が 60 分無操作・今週未実行、の全てで実行可 | 材料が欠けたら実行しない |
| `bin/run.sh` | 課金検査 → 採否回収 → 収集 → 判断 → 投稿 | 書き込みはこのスクリプトだけ |
| `jobs/<job>/collect.sh` | 事実だけを JSON で出す | LLM を使わない |
| `jobs/<job>/prompt.md` + `schema.json` | 判断基準と構造化出力 | モデルは `--tools Read,Grep,Glob --strict-mcp-config` で書き込み手段を持たない |
| `bin/digest.py` / `bin/reap.py` | 描画・重複/却下済みの除外・上限 10 件 / 採否を台帳へ | 形式と抑制はコードで決める。モデルに任せない |

**課金の不変条件**: `ANTHROPIC_API_KEY`・`apiKeyHelper` があれば中止、`claude auth status` が
claude.ai の Max でなければ中止。**`--bare` は使わない**(認証が API キー限定になり従量課金に落ちる)。
`--allowedTools` では読み取り専用にならない(ユーザー設定が Edit/Write を許可しているため)。道具は `--tools` で絞る。

## よく使う操作

```bash
~/.claude/skills/proactive-work/bin/gate.py; echo $?          # 今走れるか、なぜ走れないか
~/.claude/skills/proactive-work/bin/run.sh --force --dry-run  # ゲート無視・投稿せずに本文を見る
~/.claude/skills/proactive-work/bin/run.sh --force            # 手動で1回投稿
~/.claude/skills/proactive-work/bin/reap.py stats ~/.local/state/proactive-work/ledger.jsonl
journalctl --user -u proactive-work -n 50                     # 無人実行のログ
tail ~/.local/state/proactive-work/runs.jsonl                 # 実行記録(モデル・一覧価格換算コスト)
```

初回セットアップは `install.sh`(statusline 登録・`digest` ラベル・timer 有効化)。
claude.ai の Settings > Usage で **usage credits を OFF** にしておくこと(スクリプトからは確認できない)。

## ダイジェストへの答え方

採用する提案に ☑ を付けて issue を close。☐ のまま close は却下、14 日放置は未回答。
却下した提案(repo・種類・対象が同じもの)は 30 日間再掲しない。

## ジョブを足すとき

`jobs/<name>/` に `collect.sh`(事実 JSON、LLM なし)・`prompt.md`・`schema.json` を置き、
`run.sh` の `JOB` を複数対応にする。足す順番と条件は Epic tapoh22334/dotfiles#6 の保留欄に従う
(採否台帳に 2 週分以上の実績がたまってから、採用率を見て)。
