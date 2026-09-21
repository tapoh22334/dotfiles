---
name: metalize
description: Step outside the work and criticize it from above — is this the right method at all, is the deliverable proportionate to the request, and is it still pointed at what the user actually wants. Dispatches an independent critic that reads the session itself rather than trusting Claude's own account of it. Use when the user says /metalize, メタ認知, メタ視点, 一段上から見て, 今のやり方どうなの, これ過剰じゃない, 作りすぎ, KISS で見て, 自省して, step back, sanity-check this, am I overengineering this. Also reach for it after a long build lands, when the same fix has failed twice, when work has stalled and needs a lateral idea, or before committing to an approach that has grown complicated. Distinct from code review and verification, which check whether the work is CORRECT — this asks whether it should have been done this way, or at all.
---

# metalize

Claude is a poor judge of its own work. Asked to evaluate what it just built, it
praises mediocre output and reasons its way past real problems — not from
dishonesty, but because the same context that produced the work also supplies
every justification for it. The way out is not to try harder at self-criticism;
it is to hand the evidence to someone who wasn't there.

So this skill dispatches a **separate critic** and gives it a session id, not a
summary. The critic reads the session for itself and decides what to look at.
That independence is the whole mechanism: whatever Claude is blind to, Claude
cannot choose to omit, because Claude is not choosing.

## Process

### 1. Hand over the session id — and nothing else

Find the current session id from the transcript path in your environment, or use
whichever id the user names. Dispatch one critic subagent with the prompt in
"The critic's brief" below.

**Do not summarize the work for the critic.** No "I built X and it went well",
no list of what you consider the important parts, no explanation of why a choice
was made. Every such sentence is you deciding what the critic gets to see, which
is exactly the judgment being audited. Give it the id and let it read.

The critic can reconstruct everything on its own:

```bash
# the shape of the session: user turns, every subagent, what each was asked
python3 ~/.claude/skills/session-map/scripts/collect.py --session <id> --cwd <project>

# across projects, if the work spans them
python3 ~/.claude/skills/global-session-map/scripts/collect_global.py --search '<topic>'
```

### 2. Let the critic run

It reports back in the shape below. Relay its finding to the user as-is — do not
soften it, do not add rebuttals in the same breath. If you disagree, say so
afterwards as your own separate view, so the user can see both rather than a
blend.

### 3. Act only if asked

metalize diagnoses. It does not fix. A finding is an argument for a change, and
whether to make that change is the user's call — announcing the problem and
immediately rewriting things buries the finding under new work.

## The critic's brief

Dispatch a subagent with this task:

> You are auditing a work session you did not participate in. Session id:
> `<id>`, project `<cwd>`. The original request was: `<the user's own words>`.
>
> Read the session yourself with
> `python3 ~/.claude/skills/session-map/scripts/collect.py --session <id> --cwd <cwd>`.
> That gives you the user's turns and every subagent with its brief and log size.
> Follow whatever looks worth following — read the deliverables, read agent
> transcripts, run `git log`, check file sizes. **You decide what to look at.**
> Nobody has told you which parts matter, and that is deliberate.
>
> Then work through the gate and the questions below, and report in the given
> format. Be specific and hard to dismiss: cite counts, line numbers, file paths.
> A criticism that could apply to any session is worthless.
>
> [paste "The gate: KISS", "If the gate passes", and "Output" sections here]

Give the critic the user's request verbatim. Paraphrasing it re-introduces
exactly the filtering this design removes.

## The gate: KISS

Ask three questions, in order. **If any of them lands, stop there and report.**
Do not proceed to the other checks.

Stopping matters. Once you start evaluating something complicated on its own
terms, you end up refining it — "is that regex correct?" — when the finding was
that it should not have existed. Judging the complicated thing skillfully is how
complexity survives review.

**① Was it needed at all?**
Would the user have been equally served without this piece, or without the whole
detour? Work that is well-built and unnecessary is the most expensive kind,
because nothing about its quality reveals the problem.

**② Could it have been simpler?**
Same outcome, fewer moving parts. Fewer agents, fewer files, fewer steps, less
abstraction. Not "could it be golfed" — could a competent person have reached the
same result by a plainer route.

**③ Does the grain match the reader and the lifespan?**
This one runs both directions, and both directions are common:

- *Too fine for what it is.* Throwaway scripts hardened with error handling and
  options they will never need. Issues written at the level of code lines when
  the reader needed the meaning — the detail is noise that hides the point.
  A one-off given the construction of something permanent.
- *Too coarse for what it is.* Something that will be read many times, or
  depended on, thrown together. A durable interface with no explanation of why
  it exists.

The test is not "is this good work" but "is this the right *weight* of work for
this artifact's audience and lifespan".

## If the gate passes

Only then, these three:

**Proportion.** Look at the raw counts — subagents spawned, files written, lines
produced, elapsed time — against what was asked. Both directions count: 500
lines for a one-line question is a failure, and so is a one-paragraph answer to
something that needed real work. Say which, with the numbers.

**Stall.** Did the same file get edited repeatedly, the same test keep failing,
the same fix get attempted twice in different clothes? Repetition without
progress means the method is wrong, not the effort insufficient. When you see
it, propose something genuinely different — a lateral move, not a more careful
version of what already failed. This is the one place where an unreasonable
suggestion is more useful than a sound one.

**Repeat failures.** Did the same class of mistake occur more than once? Two
instances is the threshold: once is an accident, twice is the method. Name the
class, not the two instances. If it warrants a systemic fix, say so — the
`five-whys-root-fix` skill exists for that and is the right handoff.

## Direction — one question

**Is this still aimed at what the user actually wanted?**

Executing an instruction faithfully and serving the person are different things,
and they come apart quietly. Signals worth weighing: the user redirected and the
work continued on its old heading anyway; options were offered and none were
chosen; a procedure was followed to completion without anyone asking whether it
fit; something was built without ever establishing what it was for.

One or two sentences. If it is aimed correctly, say so plainly and move on.

## Output

Keep it short enough to read in one pass. The value is in the single finding at
the end, not in the coverage above it.

```
metalize: <what was examined>

痕跡: <the raw counts — agents, files, lines, elapsed — and the original request>

KISS
  ① 要るか      … <verdict>
  ② 単純にできるか … <verdict>
  ③ 粒度        … <verdict>     ← mark the one that landed, if any

[if the gate passed:]
過不足 … <verdict>
停滞   … <verdict, plus a lateral proposal if stalled>
再発   … <verdict>

方向: <one or two sentences>

─ 最も重大 ─
<one finding, with evidence, and what should have happened instead>
```

**Exactly one finding at the bottom.** Five measured observations read as
thorough and change nothing; one specific criticism gets acted on. Choosing
forces a judgment about severity, which is the actual work.

**"No problems" is a legitimate result** — say it plainly when it is true. A
critic that must always find something will manufacture something, and once it
does that its findings stop being worth reading. The credibility of the hard
findings depends on the willingness to return an empty one.
