---
name: repo-history
description: Explain THIS repository's history by joining its commits to the Claude Code sessions that produced them — which conversation caused a commit, what the user actually asked for, what was tried and rejected on the way. Use whenever the question is why the code looks like it does rather than what it says: このコミットなんで / なんでこうなってる / この変更どういう経緯 / 誰が決めた / いつ入った / このブランチ何だったっけ / このリポジトリの作業史 / 今月このリポジトリで何した / このファイルいつ触った / 経緯を教えて / why is this here / what was this commit about / who decided this / history of this change / what happened on this branch / archaeology. Also reach for it before rewriting code whose reasoning is unclear, when a commit message says what but not why, when picking up a repo after weeks away, or when someone asks what a branch was for. Distinct from session-map (inside ONE session) and global-session-map (ACROSS projects) — this one is scoped to one repo and is the only one that joins sessions to git.
---

# repo-history

`git log` records what changed. The session transcripts record why — what the
user asked for, what was tried first, what got rejected and on what grounds. The
two sit side by side on disk with nothing linking them, so the reasoning behind
a commit is effectively lost the moment everyone forgets it.

This joins them. The payoff is answering "why is this code like this" with the
actual conversation that decided it, rather than a commit message written after
the fact.

## Collect first

```bash
# the whole history of the repo you're standing in
python3 ~/.claude/skills/repo-history/scripts/collect_repo.py

# a period
python3 ~/.claude/skills/repo-history/scripts/collect_repo.py --since 2026-09-01

# include the human instruction each commit was working under
python3 ~/.claude/skills/repo-history/scripts/collect_repo.py --since 2026-09-01 --turns

# one branch's story
python3 ~/.claude/skills/repo-history/scripts/collect_repo.py --branch feat/session-transition-states

# find where a topic was worked (regex over subjects, session titles, turns)
python3 ~/.claude/skills/repo-history/scripts/collect_repo.py --search 'spinner|tput' --turns

# commits no session explains
python3 ~/.claude/skills/repo-history/scripts/collect_repo.py --unattributed

# a repo other than the current directory
python3 ~/.claude/skills/repo-history/scripts/collect_repo.py --repo ~/working/other
```

Per commit you get `short`, `when`, `subject`, `author`, `branches`, and
`session` (the conversation behind it, with `basis` and `gap_minutes`). With
`--turns`, also `turn` — the instruction it was working under, and how many
hours earlier it was given. Plus `session_index`, one row per session with the
commits it produced.

## How the join works, and how much to trust it

Every event in a transcript carries a timestamp **and the branch checked out at
that moment**. A session's real activity is therefore a series of (time, branch)
points, not one range on one branch — which matters, because sessions here stay
open for weeks. One spans 44 days across 8 turns; anything matching on a
session's overall span would claim every commit in those 44 days.

Each commit is matched to the session that was live, on that branch, nearest in
time. The `basis` field says which evidence carried it:

- **`branch+time`** — the session was sitting on a branch that contains this
  commit, seconds or minutes away. Treat as reliable.
- **`time-only`** — the timing lines up but the branch doesn't. Usually a merge
  commit (made on `main` while the session was on the feature branch), which is
  fine. On a non-merge commit, say you're less sure.

`gap_minutes` is the distance to the nearest activity. In practice real matches
land at 0.0; a gap of an hour on a busy repo deserves a hedge.

**Report the summary's numbers; never recount from the rows.** `commits`,
`attributed`, and `commits_before_records` always describe the whole repo in the
requested date range, while `history` holds only the rows left after `--search`
or `--unattributed`. `rows_shown` and `filtered` say which you are looking at.
Counting the rows under `--unattributed` and calling the result the repo's size
is how a coverage answer ends up claiming a repo is a third of its real age.

State each of these numbers once — a table is the natural place — and refer
back to it rather than repeating the figure in prose. A count restated from
memory a few paragraphs later is the one that comes out wrong, and a report
that contradicts itself is worse than one that omits the detail.

**Read the coverage fields before reporting any ratio.** `attributed` over
`commits` looks alarming on most repos — 68 of 258 here — but
`commits_before_records` explains nearly all of it: those commits predate the
oldest session on disk, so no transcript could ever explain them.
`unexplained_within_records` is the honest number, and it was 0 on this repo.
Reporting "190 unattributed" without that split describes a broken tool rather
than a history that started before the logs did.

## The instruction is the story

`--turns` attaches the last thing the user said before each commit, with no time
limit. That is deliberate: an agentic run works for hours off one instruction.
On this repo, "pushしてマージまでしておいて" produced nine commits over twenty-two
hours. Any window tight enough to look rigorous would have left eight of them
looking unexplained, hiding exactly the relationship worth showing.

So a long `hours_before` is information, not noise — it says this commit came
out of a long autonomous run rather than a fresh request. Show it.

## Output shape

Lead with what answers the question asked. For "why is this like this", the
commit is a supporting detail and the conversation is the answer; for "what
happened this month", the timeline leads.

A history reads as commits grouped under the instruction that caused them,
because that grouping is the thing git cannot show:

```
feat/session-transition-states · 09-07〜09-08 · 10 commits · 2 sessions

「Dを押したときの挙動ですが、すぐにカーソル下が消え、少したつと再度出現する」
  09-07 17:10  8818265  fix: detect a working session from its pane
  09-07 17:15  d66c386  fix: sort navigator project groups
  09-07 17:32  d41dbbf  feat: show what the navigator is doing during delete
  09-07 17:35  72e0cf2  fix: keep the deleting mark from being discarded

「pushしてマージまでしておいて」                        ← 22時間の自動実行
  09-08 20:38  1696650  fix: let a stated terminal size win over tput
  09-08 20:51  bde0c61  fix: count header bytes with wc -c, not awk length()
  09-08 20:53  bae593d  Merge pull request #21
```

Conventions that carry meaning:

- **Quote the user's words verbatim.** Their phrasing is the evidence — a
  paraphrase is your reading of the request, which is the thing a reader came
  here to check rather than to be told.
- **Mark inferred titles.** `title_inferred` means the session had no AI title
  and the opening turn is standing in. Say so (`~` works) rather than presenting
  your reading as a recorded fact.
- **Name the branch, and say whether it landed.** `branches` shows every ref
  containing the commit; one that never reached `main` is abandoned work, which
  is usually the most interesting row on the page.
- **Merges are punctuation.** They mark where work landed. Don't give a merge
  commit its own paragraph unless the merge itself was the decision.

## Going deeper on one commit

The join gets you to the right conversation. The reasoning is inside it, and the
cheapest sources in order of value:

```bash
# what the commit actually did -- often the message omits the why entirely
git show --stat <sha>

# the session's own reasoning near that moment
python3 ~/.claude/skills/session-map/scripts/collect.py --session <id>
```

Hand off to `session-map` once the question becomes "what happened inside that
session" — it is built for the inside of one conversation, and this skill is
built for the seam between conversations and code.

When the commit message and the conversation disagree, **the conversation is the
better record of intent** and the diff is the better record of effect. A message
saying "fix flaky test" over a conversation establishing the test was asserting
the wrong thing means the message is a summary written in a hurry. Report what
you found, not the tidier of the two.

## When there's nothing to find

Three different silences, and they are worth distinguishing out loud rather than
all reading as "no results":

- **Before the records begin.** `session_records_begin` tells you when the
  transcripts start. Older commits are unexplainable here; say so and stop,
  rather than implying the work was undocumented.
- **Unexplained inside the recorded era.** A real gap: work done outside Claude,
  a rebase that rewrote timestamps, or a session whose transcript was deleted. A
  rebase is worth naming as a suspect, since it detaches commits from the
  conversation that wrote them.
- **No match for a search.** The regex covers subjects, titles, and turns — not
  full transcripts. A topic discussed mid-session without appearing in any of
  those won't be found. Suggest a looser pattern before concluding it never
  happened.

## Notes on the data

- Commits are read from **all refs**, not just `HEAD`. Abandoned branches are
  part of the history — often the part someone is asking about.
- `--window` (default 120 minutes) bounds how far a commit may sit from session
  activity. Widen it for a repo worked in long quiet stretches; narrow it if a
  busy repo is producing loose matches.
- A commit authored by someone else still gets attributed if a session happened
  to be live; `author` is in the output, so check it before claiming a session
  produced a colleague's commit.
- Commit counts come from `git log`, which counts merges. `git log --oneline`
  and `git rev-list --no-merges` disagree by roughly 30 on this repo, so a
  recount by hand will rarely match the summary. Quote the summary.
- Sessions listed in `unreadable_sessions` had no usable timestamps — empty or
  truncated transcripts. A session that failed to record is itself worth
  mentioning, since it means a genuine hole in the history rather than an
  absence of work.
