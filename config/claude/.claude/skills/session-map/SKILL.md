---
name: session-map
description: Draw a tree of what happened in a Claude Code session — the user's turns plus every subagent, fork, and /subtask spawned underneath them, each with a one-line outcome. Use whenever the user wants to see the shape of the work rather than its conclusions: セッションマップ / session-map / どんなエージェントが動いた / サブタスクの一覧 / fork も含めて / 会話の流れを見せて / この作業の全体像 / どこで何を調べた / エージェント何個動いた / show me the session tree / what subagents ran / map this session / what did we explore. Also reach for it when a session sprawled across many parallel agents and the user has lost track of which investigation produced which finding, or when they ask how a past session reached some conclusion. Distinct from summarize/brief, which narrate state in prose — this one shows structure.
---

# session-map

Long sessions fan out. A single request can spawn a dozen agents, some of which spawn their own, plus forks that branch the conversation sideways. By the end nobody remembers which investigation produced which finding, or how much work is hiding under one innocent-looking turn.

This skill reconstructs that shape from the session files on disk and renders it as a tree.

## Collect the skeleton first

Run the bundled script. It reads the session store and returns a compact JSON skeleton — user turns and the agent tree — so you never have to parse the raw JSONL, which routinely runs to tens of megabytes.

```bash
# this session (default)
python3 ~/.claude/skills/session-map/scripts/collect.py

# every session in the project — an index, not full detail
python3 ~/.claude/skills/session-map/scripts/collect.py --project

# one specific session
python3 ~/.claude/skills/session-map/scripts/collect.py --session <session-id>

# a project other than the current directory
python3 ~/.claude/skills/session-map/scripts/collect.py --cwd /path/to/project
```

Default to the current session. Use `--project` when the user asks across sessions ("前のセッションでも」「プロジェクト全体で"), then offer to drill into one with `--session`.

The skeleton gives you, per agent: `type` (the subagent type, or `fork`), `description` (what it was asked), `depth`, `parent`, `is_fork`, and `transcript` (path to its full log).

## Getting outcomes

The skeleton says what each agent was *asked*. It doesn't say what came back — and the outcome is the part worth reading.

Recover outcomes from the conversation you already have in context. You lived through this session; you know that the pricing research came back with a $10 ceiling and that the broadcast idea was rejected on three grounds. Use that.

When context doesn't cover it — an older session, or one you're mapping for someone else — read the tail of the agent's transcript, where its final report lands:

```bash
tail -c 4000 <transcript-path> | python3 -c "import sys,json; [print(json.loads(l).get('message',{}).get('content','')) for l in sys.stdin if l.strip()]" 2>/dev/null | tail -40
```

Read selectively. Pulling the tail of five interesting agents beats skimming all forty-five. If an outcome genuinely isn't recoverable, write `→ ?` rather than inventing one — a fabricated finding in a map is worse than a gap, because the map is what someone will trust later.

## Output shape

One line per node. Type tag, what it was for, then the outcome after an arrow.

```
session: 収益化戦略レポート  (08-02 〜 08-03, feat-board-transition, 45 agents)
│
├─ /full-auto 収益化シナリオ作成・市場調査・売上予測
│  ├─ [Explore] モードとゲート箇所の棚卸し → モード21種、課金ゲートは未実装
│  ├─ [gp] 市場調査: splitflap/ambient → 直接競合の単価上限は $10
│  │  ├─ [gp] ポモドーロ系の価格調査 → Lifetime $39.99 前後
│  │  └─ [gp] 市場規模シグナル → Fliqlo 日本44位、カテゴリは小さい
│  ├─ [gp] プラットフォーム経済 → MS Store 自前決済0%、iOSは鍵ゲート不可
│  └─ [pdm] 価値判断 → モード分割は「パレットの分割」で不採用
│
├─ 「スマホで読みたい」 → Artifact 公開
├─ 「QRにできる？」 → 自作エンコーダは検証で失敗、qrcode-terminal に交代
│
├─ 「有料で全員に配信は？」
│  ├─ [pdm] 価値判断 → 不採用（算数/Apple 1.2/広告性）
│  └─ [gp] 先行事例 → Yik Yak・Sarahah 等、嫌がらせ回避例はゼロ
│
└─ 「協賛でロゴ表示は？」
   └─ ⑂ fork → 採用。ボード外の「支援者クレジット」として
```

Conventions that carry meaning:

- **`⑂` marks a fork.** Forks branch the conversation rather than delegating a task, so they read differently — the description is the user's own words, not a task brief.
- **Indentation is spawn depth.** An agent nested two levels was spawned by another agent, not by the user. That distinction explains where the token spend went.
- **Abbreviate long agent types** (`general-purpose` → `gp`, `pdm-value-guardian` → `pdm`) once the tree is wide. Consistency matters more than the specific abbreviation.
- **Group by user turn**, not by wall-clock time. The user's question is the unit of meaning; agents hang beneath the turn that caused them.

Keep each line to roughly one terminal width. If an outcome needs more room, the map isn't the place — say so in a sentence below the tree.

## After the tree

Add two or three sentences only where they earn their place: parallel agents that reached the same conclusion independently, a branch that turned out to be a dead end, or where the bulk of the work went. If the tree speaks for itself, stop.

For `--project` mode, list sessions with title, dates, branch, and agent count, then ask which to expand. Don't map eleven sessions in full — that buries the answer.

## Notes on the data

- `.meta.json` sidecars next to each transcript hold the tree structure. They're tiny, so building the tree is cheap even when transcripts are hundreds of megabytes.
- Turns marked `isMeta` are injected skill bodies, not human speech. The script drops them; don't add them back by reading raw files.
- A slash command's visible intent lives in `<command-args>`, which the script extracts. The surrounding tags are machinery.
- Subagents that are still running have a `.meta.json` but a short transcript. Mark them `(running)` rather than guessing an outcome.
