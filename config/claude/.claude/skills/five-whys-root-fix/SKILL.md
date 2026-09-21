---
name: five-whys-root-fix
description: Analyze a failure with 5-why root-cause analysis and fix the ROOT, not just the symptom. Use this whenever something misbehaved and the user asks why, reports a bug/incident/failure, says a fix "didn't take effect", the wrong model/config/version was used, a pipeline completed but the deliverable is missing, or the same class of failure has happened more than once. Trigger on words like 失敗, 原因, なぜ, 再発, 根本原因, root cause, incident, "why did this happen", "it happened again" — even when the user only asks for an explanation, walk the full analysis and apply fixes.
---

# Five Whys → Root Fix

A failure report is a symptom. Patching the symptom leaves the mechanism that
produced it running, so the same class of failure returns wearing different
clothes. This skill walks the causal chain down to something systemic and
actionable, fixes at multiple depths, and verifies each fix empirically.

## Process

### 1. Pin the problem as observable fact

One sentence, falsifiable, with evidence attached. "The scouts ran on the
flagship model" — backed by transcript fields, not recollection. If you cannot
state the problem with evidence, gather evidence first; do not start asking
"why" about a rumor.

### 2. Gather evidence BEFORE asking why

Timestamps decide causality. Typical evidence worth collecting up front:
logs, transcripts, `git log` vs process start time (`ps -o lstart=`), file
mtimes vs deploy time, config files vs what the running process actually
loaded. Cheap probes beat speculation — a one-line test run that prints the
live behavior settles arguments no amount of reasoning can.

### 3. Walk the whys (≈5, stop at actionable-systemic)

Each "why" must cite evidence, not plausibility. Rules of the walk:

- **Don't stop at a human.** "Someone forgot to restart" is never a root
  cause — ask why forgetting was possible and why nothing noticed. Blaming
  a person (or an agent) ends the analysis exactly where the fixable
  mechanism begins.
- **Separate proximate from root.** The proximate cause explains this
  incident; the root cause explains why this *class* of incident is
  possible. Name both explicitly.
- **Watch for the invisibility pattern.** A remarkable share of root causes
  reduce to "the true state of the system was not observable" — stale code
  running silently, policy living in someone's head or a personal default,
  a success status covering a missing deliverable. If the failure could
  have persisted a long time without anyone noticing, invisibility IS the
  root cause.
- Five is a guide, not a ritual. Stop when the next "why" leaves what you
  can act on (e.g., "why does the universe permit entropy" is one too far).

### 4. Fix at three depths

| Depth | Question | Example |
|---|---|---|
| Operational | Is the system healthy *now*? | restart with the new code |
| Preventive | Can this mechanism fire again? | pass the policy explicitly in code |
| Observability | Would we SEE it next time? | expose version/policy in status output; log it at startup |

The operational fix alone is what "patching the symptom" means — never stop
there. If the root cause is instruction text — a CLAUDE.md, a skill, a memory
file, settings/hooks — hand the preventive fix to the skill-improver skill so it
gets classified, form-matched, regression-checked and logged; do not patch the
text ad hoc here. The observability fix is the most commonly skipped and usually the
cheapest; it converts a silent failure class into a loud one.

### 5. Verify each fix empirically

A fix without verification is a hypothesis. Rerun the failing path, probe the
live system, read the telemetry you just added. Verification must observe the
*behavior*, not the code ("the diff looks right" does not count).

### 6. Check the blast radius

The same root cause rarely has exactly one symptom. Search for siblings:
other callers of the same mechanism, other policies that live only in
defaults, other processes that can run stale. Fix or at least record them.

### 7. Record the chain

Write a compact incident note — problem → why-chain → fixes (three depths) →
verification — wherever the project keeps durable knowledge (docs/, doctrine,
memory). The note's audience is whoever hits the *next* symptom of a similar
root: make the chain scannable in under a minute.

## Worked example (real, 2026-07-04)

**Problem**: research-agent runs executed on the flagship model
(claude-fable-5) though a cheap tier was intended. Evidence: 119 transcript
messages tagged `claude-fable-5`, quota exhausted at 23:5x.

1. Why? `claude -p` was spawned with no `--model` → inherited the user's
   personal default (flagship).
2. Why no `--model`? Model policy was implicit — it lived in a personal
   setting, not in the system; no one had decided "research = cheap tier"
   until cost pain surfaced.
3. Why did it persist after the tiering code was written? The production
   server loads code once (no watch); the fix sat on disk while the stale
   process kept spawning flagship runs. (An earlier fix had already sat
   unbooted for ~13h and caused a separate misattribution incident — same
   root, different symptom: blast radius confirmed.)
4. Why did nobody notice the stale server? The server exposed no runtime
   provenance — no start time, no code version, no active policy in its API.
5. **Root**: runtime policy and provenance were not observable artifacts.
   Drift between intent, code, and the running process was invisible.

**Fixes**: operational — restart (verified: research runs now tagged
`claude-sonnet-5` in transcripts, lead correctly stays on default);
preventive — `--model` passed per role kind, env-overridable; observability —
startup log line + `researchModel`/`serverStartedAt` exposed in the status
API. **Verification**: live transcript fields + status API probe after
restart.
