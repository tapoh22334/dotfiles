---
name: global-session-map
description: Map Claude Code work across ALL projects on this machine — every project's sessions on one timeline, grouped by project, plus a cross-project search for "where did I do that". Use whenever the question spans more than the current project or reaches back beyond the current session: 全体マップ / 全プロジェクト / 最近何やってた / 8月何してた / 先月の作業 / どのプロジェクトが動いてた / あの作業どこでやったっけ / どのセッションでやった / 前にどこかで調べた / 横断で見せて / global session map / what have I been working on / which project was I in / where did I do X / find that session / across all projects / last month's work. Also reach for it when the user names a topic but not a project, when they're deciding what to pick back up, or when a project has been dormant and they want to know how long. Distinct from session-map, which maps a single session (or a single project) in depth — this one spans projects and answers where/when before drilling in.
---

# global-session-map

Work spreads across projects. The same afternoon touches three repos, an
investigation started in one project finishes in another, and a month later
nobody remembers which. The single-session map (`session-map`) shows depth —
what happened under one turn. This one shows breadth: which projects were alive
when, and where a given piece of work actually lives.

Reach for it when the question is *where* or *when* rather than *what came of
it*. Once the user picks a session, hand off to `session-map --session <id>`,
which is built for the inside of one session.

## Collect first

```bash
# every project, every session
python3 ~/.claude/skills/global-session-map/scripts/collect_global.py

# narrow by time — both accept ISO dates
python3 ~/.claude/skills/global-session-map/scripts/collect_global.py --since 2026-08-01
python3 ~/.claude/skills/global-session-map/scripts/collect_global.py --since 2026-08-01 --until 2026-08-31

# find where a topic was worked on (regex, case-insensitive)
python3 ~/.claude/skills/global-session-map/scripts/collect_global.py --search 'splitflap|フラップ'

# one project's slice of the global picture
python3 ~/.claude/skills/global-session-map/scripts/collect_global.py --project game-flood

# only sessions with real delegation behind them
python3 ~/.claude/skills/global-session-map/scripts/collect_global.py --min-agents 5
```

Filters compose, so "August, and only where I delegated heavily" is one call.
Results are cached under the skill directory keyed by file size and mtime; a
cold run over a few hundred megabytes takes a second or two, later runs a tenth
of that. Pass `--no-cache` if you have reason to distrust it.

Per session you get: `project`, `id`, `title`, `branch`, `started`, `ended`,
`user_turns`, `count` (agents), `types` (agent type histogram), `forks`, `mb`,
and `opening_turns`. Plus a per-project rollup and the overall span.

## Dates come from inside the files

The collector reports `started`/`ended` from timestamps Claude wrote, and also
`mtime`. **Use `started`/`ended`.** File mtime gets touched by backups, syncs,
and indexers long after work stops — on this machine a majority of sessions
carry an mtime months newer than their last real activity. A map built on mtime
claims everything happened recently, which is both wrong and useless.

`mtime` is still worth a glance when it's *older* than `ended`, which usually
means a partially-copied or truncated file.

## Output shape

Group by project, order projects by weight, and put a timeline first when the
question was about time. One line per session; the project line carries the
totals.

```
39 sessions · 7 projects · 386 agents · 2026-07-10 → 2026-09-06

game-flood            118 agents · 3 sessions · 07-11 → 08-03
  ├─ 07-11..07-20  ゲーム量産プロセスの立ち上げ            118ag  main
  ├─ 07-12..08-03  (untitled)                                0ag  main
  └─ 07-25..07-25  (untitled)                                0ag  main

claude-tower           65 agents · 5 sessions · 07-11 → 08-31
  ├─ 07-11..07-24  fork 検出とタイル表示                    30ag  feat-fork
  ├─ 07-20..08-03  Navigator Queue view                     16ag  main
  └─ 07-25..08-31  タスク生成の実装                          19ag  main
    …
```

Conventions that carry meaning:

- **Agent count is the honest weight.** Session file size mostly tracks how much
  got read, not how much was decided; a 20MB session with zero agents was one
  long conversation. Sort and summarise by agents, mention MB only if asked.
- **Show a date range, not a point.** Sessions here routinely span weeks because
  they get resumed. `07-11..08-31` is the fact; "07-11" alone hides that the
  session was still live in August.
- **Name untitled sessions from their opening turn.** Short sessions often have
  no AI title. `opening_turns` usually makes the intent obvious — use it, and
  mark it as your reading rather than a recorded title.
- **Same id in two projects is normal.** A session id can repeat across project
  directories; treat `project + id` as the identity, and always pass `--cwd`
  alongside `--session` when handing off.

## Answering "where did I do that"

Run `--search` and lead with the strongest hit. The collector labels each hit by
where it matched and sorts them `title → agent → turn → branch → path`, because
the labels differ enormously in what they prove: a match in an **agent brief**
means a subagent was dispatched to work on that topic, while a match on the
**project path** only means the session sat in a similarly-named directory.
Path-only matches are dropped for that reason — use `--project` when directory
is what you actually mean.

The payoff is finding work in places the user wouldn't have looked. A search for
`splitflap` surfaces a session in `claude-tower`, because that session's agents
were briefed on splitflap; no per-project map could have found it.

Report the hit that justifies the match, not just the session title:

```
「splitflap のトランジション」→ 3 セッション

  08-02  ma-splitflap   スマホブラウザでレポート表示
         └ agent: Market research: splitflap/ambient apps
  07-25  claude-tower   フォークセッションの表示名を修正      ← 別プロジェクト
         └ turn: /full-auto ma-splitflap ...
```

If nothing matches, say so and suggest a looser pattern before concluding the
work doesn't exist — the regex is matched against titles, opening turns, and
agent briefs, not full transcripts, so a topic discussed only mid-session won't
be found here. That limit is worth stating out loud rather than letting the user
read a silent empty result as "never happened".

**When one session clearly wins, don't stop at naming it.** "どのセッションでやった"
is usually asked in service of a real question — what was decided, what changed,
where the code went. Locating the session and handing back an id answers the
literal question while leaving the user to do the actual work.

So once the field narrows to one or two sessions, spend a little more and say
what came of it. The cheap sources, roughly in order of value per token:

```bash
# what actually changed, if the project is a git repo and you know the branch
git -C <project> log --oneline --since=<start> --until=<end+1day> <branch>

# the session's own conclusion -- the tail is where decisions land
tail -c 4000 <session.jsonl> | python3 -c "import sys,json; [print(json.loads(l).get('message',{}).get('content','')) for l in sys.stdin if l.strip()]" 2>/dev/null | tail -30
```

A branch name plus a date range makes `git log` a precise query, and commits are
the highest-signal record of what a session produced. Two or three sentences of
outcome — the problem, the fix, where it lives — is usually the difference
between a lookup and an answer.

Judgement call: skip this when the search returned many comparable hits (the
user is still choosing) or when they only asked *where*. Depth on the wrong
session is wasted; depth on the obvious one is the whole point.

## After the map

Two or three sentences, only where they add something the tree doesn't: a
project dormant for weeks, an unusual concentration of agents, work on one topic
split across projects. If the user asked "what should I pick back up", the
dormancy and the open branch names are the useful signal.

When the user wants the inside of one session, stop here and hand off:

```bash
python3 ~/.claude/skills/session-map/scripts/collect.py --session <id> --cwd <project>
```

## Notes on the data

- Sessions with `started: null` are empty or corrupt transcripts. Sort them last
  and label them `(no timestamps)` — don't silently drop them, since a session
  that failed to record is itself worth noticing.
- `types` is a histogram of agent types. A session that is 90% `Explore` was a
  research session; one heavy on `general-purpose` was doing varied delegation.
  This is a cheap way to characterise a session you haven't opened.
- Project paths are reconstructed from directory names where `/` became `-`,
  which is ambiguous when a directory name itself contains a hyphen. The script
  resolves it against the real filesystem, so a project that has since been
  deleted or renamed may show a mangled path. `project_slug` is the ground
  truth if a path looks wrong.
- If you drop to shell against these directories, note that their names begin
  with `-`, which `find`, `du`, and friends read as the start of a flag. Prefix
  paths with `./` or use `--`. Quote glob patterns too, since zsh errors on a
  pattern that matches nothing instead of passing it through. Both are easy to
  mistake for "no sessions found".
