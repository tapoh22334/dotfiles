---
name: ja-review
description: Review a Japanese text from every viewpoint at once — out-of-place words (話し言葉・広告・比喩), style rules (文末・表記), and more as they are added — by running one reviewer agent per viewpoint in parallel and merging their findings into one list of 「原文」→「修正案」. Use after writing or heavily revising a Japanese README, design doc, Issue or PR body, or note, and whenever the user says 日本語レビュー / 文章をチェックして / 全観点で見て / 書いた文書を検査して / 話し言葉を直して / 場違いな言葉 / 位相 / 広告っぽい / 文体チェック / ja-review. Also the place to look up each viewpoint's rules before writing.
---

# ja-review

Each viewpoint has its own rules file and its own reviewer agent, so each can be
fixed and measured on its own. This skill is the single entry: it picks the
viewpoints that apply, runs their reviewers in parallel, and merges the results.

## Viewpoints

| 観点 | Reviewer agent | Rules | Applies to |
|---|---|---|---|
| 言葉 | `ja-word-reviewer` | `viewpoints/word.md` | every text: repository documents, Issue/PR bodies, notes |
| 文体・表記 | `ja-style-reviewer` | `~/.claude/doc-style.md` | repository documents only |

Planned (dotfiles #44): 文書の構成, リスト・表・強調, 文の作り. Add a row when a
viewpoint's rules and reviewer exist.

Before writing, read the rules of every viewpoint that applies to the text.

## Steps

1. **Get the text into a file.** If it is an Issue/PR body, a draft in the
   conversation or a Notion page, write it to
   `~/tmp/ja-review/<YYYY-MM-DD>-<slug>/text.md` first; reviewers read files.
2. **Pick the viewpoints** from the table by the kind of text. If the user names
   viewpoints, run only those.
3. **Run the reviewers in parallel**, all in one message, each given the file
   path and nothing about the other viewpoints. Each returns lines of
   `<file>:<line> [観点] 「原文」→「修正案」`, then a 要確認 section.
4. **Merge.**
   - Sort by line.
   - When two viewpoints touch the same phrase, write one 修正案 that satisfies
     both, and tag it with both viewpoints. If they cannot both be satisfied,
     show both and say which you would take.
   - Keep each reviewer's 要確認 items in a separate section.

## Output

```
<line> [観点] 「原文」→「修正案」
...

要確認
<line> [観点] 「原文」→「修正案」 — <前提とした読み・迷った理由>

言葉 N 件 / 文体・表記 M 件
```

Apply the fixes only when the user asked for the text to be fixed, or when
CLAUDE.md says to reflect the findings. Then apply every finding except 要確認,
and ask about those.
