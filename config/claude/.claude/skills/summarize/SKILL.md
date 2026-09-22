---
name: summarize
description: Use when the user wants to recap the current work session so they can step away and resume later — triggered by "/summarize", "今何してたっけ", "ここまでの作業まとめて", "一旦まとめて", "状況整理", "where were we", "recap", or any request to capture progress before a break, context switch, or handoff. Produces a short scannable recap — 2–4 labelled sections covering what was done (and *why*) plus what comes next — printed to the screen for the user to read.
---

# summarize

## Purpose

Someone steps away mid-task and comes back an hour — or a day — later. Or they're about to switch contexts and want a marker they can return to. This skill writes that marker: a short, readable account of where the work stands, so resuming takes seconds instead of re-deriving everything from scrollback.

The output is **for a human to read on screen**. It is not a file, not a commit message, not a formal report. Think of it as the note you'd leave yourself on a sticky pad: enough to reload the mental state, no more.

## What to produce

Write it for **scanning, not reading straight through**. Someone returning cold should find "where am I" in seconds, then drill into the part they need. Write in the language the user has been working in.

Use **2–4 labelled sections**, each a short heading followed by prose. The heading names the *meaning* of the block — "決めた設計方針", "効いていなかった部分", "次にやること" — never a contentless label like "概要" or "その他". Someone who reads only the headings should already know the shape of the session.

**Cap any single paragraph at ~150 words (日本語なら200字).** Past that, split it: a longer block is a wall no matter how good the sentences are. Japanese has no inter-word spaces, so dense blocks cost the reader more.

Under a heading, prose is the default. Drop to a list only when the content genuinely *is* a set of peer items — options to choose between, independent leftovers. A wall of 20 bullets is as bad as a wall of text.

The content, in this order:

1. **What happened and why** — the narrative: what was tried, what was ruled out, what was decided and on what reasoning. This is what stops the returning person from re-litigating settled questions or re-walking a dead end.

2. **What's next** — always the last section, headed in the language you're writing in ("次にやること" in Japanese). The immediate next step, anything waiting on a decision or review, anything left uncertain. If nothing is pending, say so plainly.

## How to do it well

**Read the actual context before writing.** The summary is only as good as your grounding in what happened. Skim the conversation for the arc: the original goal, the turns it took, corrections the user made, what's been committed vs. still in flight. If the work touched files or git, a quick `git status` / `git log --oneline -5` grounds the "what's next" in reality rather than memory. Don't summarize from a hazy impression — that's how you get a confident summary that's subtly wrong, which is worse than no summary.

**Capture the "why," not just the "what."** A returning reader can reconstruct *what* changed by looking at the diff. What they can't recover is the reasoning — why approach B was abandoned for A, why a threshold is 4.0 and not 20.0, what the user pushed back on. That context lives only in the conversation and evaporates when the session ends. Prioritize it.

**Write in meaning; anchor sparingly.** Lead with what a thing *means*, not what it is *called*. "盤面を作り直すとき文字を捨てていた" carries the finding to anyone; "`begin_mode_switch()` の異寸法パスが `current_index` を 0 にする" only carries it to someone already in that file. Name a concrete artifact — file, symbol, commit — **only when the reader must act on it or verify it**: the branch they'll check out, the file still uncommitted, the claim someone might dispute. Identifiers that merely decorate a sentence cost length and recall for nothing.

Numbers are the exception worth keeping. "総発音数は 848→170 だがピークは 96発/100ms のまま" *is* the finding; no paraphrase improves on it.

> **Example — thin vs. grounded:**
> ❌ "音まわりを直して、いくつか修正した。次はテストの続き。"
> ✅ "**効いていなかった部分** — 実機で「変わっていない」という指摘が正しかった。総発音数は 848→170（-80%）まで落ちたが、うるささを決めるピークは 96発/100ms のまま動いていない。原因は発音経路の取り違えで、音はエンジン側のイベントではなくフロントが文字変化を観測した瞬間に鳴っている。ユニットテストは通っていたが、測る対象が違った。"

**Match the weight of the session.** A 3-message exchange gets one section, maybe two; a long debugging marathon gets the full 4. Don't pad a short session to fill a template, and don't compress a complex one into a sentence. Length should track how much there actually is to reload.

**Stay concrete and honest.** If something failed, say it failed. If a step was skipped or a result is unverified, flag it — a summary that papers over loose ends sends the returning person in confident and wrong. Prefer specifics ("`test_score_threshold` is flaky, scores 3.5–4.4") over generalities ("some test issues").

## What to avoid

- **Don't write a file or commit anything** unless the user explicitly asks — this skill prints to the screen.
- **Don't turn it into a change-log or a formal report.** Sections are for finding your place, not for enumerating every change. Two to four of them, each holding actual prose — not a nest of sub-headings, not twenty bullets.
- **Don't restate the obvious or narrate tool mechanics** ("I ran ls, then I read the file…"). Summarize outcomes and reasoning, not your process.
- **Don't invent next steps** that were never discussed. If what's-next is genuinely open, say "no specific next step was decided — the session ended after X."
