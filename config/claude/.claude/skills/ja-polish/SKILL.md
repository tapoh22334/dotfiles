---
name: ja-polish
description: Polish one Japanese paragraph (or a sentence, heading, short passage) until it fits its purpose, fully automatically — gather context, infer who reads it and what they should understand or do afterwards, generate dozens of rewrites along many axes (短縮・リズム・否定⇔肯定・視点・構造・強さ…), have simulated readers read them blind, and keep rewriting where readers missed or misread until the text lands. Returns one chosen version with the inferred purpose, its evidence, the diff, and 1–2 runners-up in a different direction. Use whenever the user says 推敲して / 推敲 / 磨いて / 言い換え案 / もっと伝わるように / しっくりこない / この段落を直して / 表現を練って / 目的に合う文に / ja-polish / polish this Japanese, or points at a Japanese paragraph and asks to make it better, clearer, shorter or more fitting — even without naming a purpose. Not for rule checks of a whole document (ja-review) or English copy (copy-editing).
---

# ja-polish

Make one paragraph fit its purpose. "Fit" is measured on the reader's side:
simulated readers read each candidate without knowing the purpose, and the
candidate whose readers come away with exactly the intended understanding and
action wins. Writing quality judged from the writer's side is not the measure.

The run is fully automatic. Do not ask the user anything mid-run, including
when the purpose is unclear — infer it, and put the inference at the top of the
output so a wrong guess is the first thing the user sees and can correct.

Spend freely on agents; accuracy matters more than cost here.

## Workspace

Write every intermediate file under
`~/tmp/ja-polish/<YYYY-MM-DD>-<slug>/` (`context.md`, `purpose.md`,
`round-N/candidates.md`, `round-N/readers/*.md`, `round-N/judge.md`,
`result.md`). Agents read and write these files; they are also the record a
user can open when they want to see why a version won.

## 0. Collect context

The input is either a file plus a locator (heading, line range, "2nd paragraph
of インストール") or pasted text. Collect, nearest first:

| Scope | What | Used for |
|---|---|---|
| Around the paragraph | previous and next paragraphs, its heading path | no repetition, flow, what the reader already knows |
| Whole document | kind of document, stated audience, terms used elsewhere | purpose, term consistency |
| Repository | README, glossary, CLAUDE.md, `.agents/product-marketing.md` if present | who the readers are, project vocabulary |
| History | `git log -L` on the paragraph's lines, linked issue/PR | why it was written |
| Rules | `~/.claude/doc-style.md` | the filter in step 3 |

Write `context.md`: facts only, each with where it came from (`README.md:3`).
For pasted text, record what the user said around it and state plainly that
context is thin; that statement goes into the output too.

## 1. Infer the purpose

Run **two agents in parallel**, each given only the paragraph and
`context.md`, each told to work independently. Each writes:

- **読者** — who, what they already know, what they do not
- **場面** — where and how they read (skimming a heading, studying a design doc…)
- **読後の状態** — 2–5 checkable items: what the reader understands, believes or
  does after reading. This is the core; everything later is scored against it.
- **保つ情報** — facts in the original that must survive, and facts that may go
- **制約** — length, register, medium; whether doc-style applies (it does for
  repository documents)
- **根拠** — the lines of `context.md` each judgement rests on

Merge into `purpose.md`. Where the two agree, take it. Where they differ, take
the one with stronger evidence and record the disagreement — it is reported
in the output, because a split here is the likeliest reason the result misses.

## 2. Diverge

Pick the axes that can plausibly move the paragraph toward 読後の状態 from
`references/axes.md` (usually 5–7 axis groups; skip ones the register rules
out, e.g. 韻 in a design doc). Run **one agent per axis group, all in one
message**. Each gets the paragraph, `context.md`, `purpose.md` and its axes,
and returns 4–6 candidates — 20–30 per round in total. Each candidate carries
its axis and a one-line note of what it changes.

Push for real variety: the point of this step is to reach rewrites nobody
would write on a first pass. A candidate that only swaps one word is fine only
if that word is where the reader trips.

## 3. Filter

One agent checks every candidate and drops it if:

- it loses an item of 保つ情報, or adds a claim the original does not support
- it breaks `doc-style.md` when 制約 says doc-style applies
- it duplicates another candidate in substance

Keep at most 10, preferring spread across axes over near-duplicates of one
strong idea. **Always add the original** to the set, unlabelled, so the
readers' results show whether anything actually improved.

## 4. Readers read

Build three reader personas from `purpose.md` and `context.md` — differing in
prior knowledge and reading mode (e.g. new to the project / experienced /
skimming). Ground each in evidence; a persona invented from nothing makes the
whole measurement fiction. Reuse the same personas every round.

Run **one agent per persona in parallel**. Give it the persona, what that
reader would have read just before (preceding paragraphs), and the candidates
under neutral ids (`A`, `B`, …) in a shuffled order that differs per reader.
**Never show the purpose.** For each candidate, independently of the others,
it reports:

- what it understood the paragraph to say, in its own words
- what it would do next
- where it hesitated, re-read, or was unsure
- anything it took differently from how it seems meant

## 5. Judge, then rewrite where readers missed

A judge agent compares each reader's report with 読後の状態, item by item:
**hit**, **miss** (not conveyed) or **misread** (conveyed wrongly — worse than
a miss). It also lists unwanted impressions and the exact phrase that caused
each miss or misread. Write `round-N/judge.md` with a ranking.

Stop when any of these holds:

- the top candidate has every item hit by every reader and no misread
- the top score has not improved for 2 rounds
- 4 rounds are done

Otherwise start the next round from step 2 with a narrower brief: the top 3
candidates as starting points, plus each miss/misread and the phrase behind
it. Divergence agents now rework those spots, and may combine the strengths of
different top candidates.

## 6. Output

Write `result.md` and show it in the reply, in Japanese, in this order:

```markdown
## 推定した目的
- 読者:…
- 場面:…
- 読後の状態:…(箇条書き)
- 根拠:…(context.md の出典)
- (推定が割れた点があれば、ここに明記する)
- (文脈が薄い場合は、その旨)

## 採用案
<本文>

## 原文との差分
<変えた箇所と、その理由(どの読者のどの誤読を解消したか)>

## 次点
### 案 B(<方向を一言で>)
<本文>
<採用案と何が違い、どんな目的なら こちらが勝つか>

## 経過
<周回数、読者ごとの結果(原文 → 採用案)、作業ディレクトリのパス>
```

Pick runners-up that differ from the winner in **direction** (e.g. shorter and
blunter vs. fuller), not the second-best near-copy: if the inferred purpose was
wrong, a different direction is what the user will want.

When the input was a file, do not edit the file unless the user asked for it;
the user decides which version goes in.
