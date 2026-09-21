#!/usr/bin/env python3
"""Collect a cross-project index of every Claude Code session on this machine.

Emits JSON on stdout. The single-project counterpart lives in
~/.claude/skills/session-map/scripts/collect.py; this one spans
~/.claude/projects/* so the model can answer "what was I working on in August"
and "where did I do that" without opening any transcript by hand.

Two things make this more than a directory listing:

  * Timestamps come from inside the files. File mtime is routinely touched long
    after the work ended (backups, syncs, indexers), so mtime answers "when was
    this file last poked", not "when did I do this". Only the timestamps Claude
    itself wrote are evidence of when work happened.
  * Results are cached. Reading every transcript costs hundreds of megabytes of
    I/O; sessions that have not changed since the last run are served from
    ~/.claude/skills/global-session-map/.cache.json instead.

Usage:
    collect_global.py                      # index every project
    collect_global.py --since 2026-08-01   # only sessions active on/after a date
    collect_global.py --search <regex>     # find sessions/agents matching a topic
    collect_global.py --project <substr>   # restrict to matching project paths
    collect_global.py --no-cache           # force a full re-read
"""
import argparse
import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path

PROJECTS = Path.home() / ".claude" / "projects"
CACHE = Path(__file__).resolve().parent.parent / ".cache.json"
CACHE_VERSION = 3

# User-shaped lines that aren't the human talking. Kept in sync with the
# single-session collector -- if these diverge the two maps disagree about what
# the user actually said, which is worse than either being slightly wrong.
NOISE = re.compile(
    r"<system-reminder>|<local-command-|<task-notification>|"
    r"tool_use_error|Caveat: The messages below|"
    r"\[SYSTEM NOTIFICATION|Base directory for this skill:",
)


def unslug(name: str) -> str:
    """Project dirs are absolute paths with '/' replaced by '-'.

    The mapping is lossy: a hyphen in a real directory name is indistinguishable
    from a separator, so '-home-iwase-working-game-flood' could be
    /home/iwase/working/game-flood or /home/iwase/working/game/flood. Resolve it
    by walking the real filesystem and, at each level, preferring the longest
    hyphenated name that actually exists -- 'game-flood' wins over 'game'
    because only one of them is a directory.

    Projects whose directory has since been deleted or moved can't be resolved
    this way, so fall back to treating every hyphen as a separator. The label is
    then a guess, which is why callers show the slug too.
    """
    parts = name.lstrip("-").split("-")
    resolved = Path("/")
    index = 0
    while index < len(parts):
        for end in range(len(parts), index, -1):
            candidate = resolved / "-".join(parts[index:end])
            if candidate.exists():
                resolved, index = candidate, end
                break
        else:
            # Nothing at this level matches; the rest is unresolvable.
            return str(resolved / "/".join(parts[index:]))
    return str(resolved)


def text_of(message) -> str:
    if not isinstance(message, dict):
        return ""
    content = message.get("content")
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return " ".join(
            b.get("text", "")
            for b in content
            if isinstance(b, dict) and b.get("type") == "text"
        )
    return ""


def slash_command(raw: str):
    name = re.search(r"<command-name>/?([^<]+)</command-name>", raw)
    if not name:
        return None
    args = re.search(r"<command-args>(.*?)</command-args>", raw, re.S)
    detail = args.group(1).strip() if args else ""
    return f"/{name.group(1).strip()}" + (f" {detail}" if detail else "")


def scan_session(jsonl: Path):
    """One pass over a transcript for everything the index needs.

    Returns real start/end timestamps, the branch, an AI title, and the first
    few user turns -- enough for the model to name a session that has no title,
    which is common for short sessions.
    """
    title = branch = first_ts = last_ts = None
    turns = []
    user_turns = 0
    with jsonl.open(errors="replace") as fh:
        for line in fh:
            if not line.strip():
                continue
            try:
                rec = json.loads(line)
            except ValueError:
                continue

            if rec.get("type") == "ai-title" and not title:
                title = rec.get("aiTitle")
            branch = rec.get("gitBranch") or branch

            ts = rec.get("timestamp")
            if ts:
                if not first_ts:
                    first_ts = ts[:19]
                last_ts = ts[:19]

            if rec.get("type") != "user" or rec.get("isSidechain") or rec.get("isMeta"):
                continue
            raw = text_of(rec.get("message"))
            if not raw.strip():
                continue
            cmd = slash_command(raw)
            if cmd:
                body = cmd
            elif NOISE.search(raw):
                continue
            else:
                body = raw.strip()
            body = " ".join(body.split())
            if not body:
                continue
            user_turns += 1
            if len(turns) < 6:
                turns.append(body[:200])

    return {
        "title": title,
        "branch": branch,
        "started": first_ts,
        "ended": last_ts,
        "user_turns": user_turns,
        "opening_turns": turns,
    }


def scan_agents(session_dir: Path):
    """Agent facts from the .meta.json sidecars -- tiny, so this stays cheap."""
    subagents = session_dir / "subagents"
    if not subagents.is_dir():
        return {"count": 0, "types": {}, "forks": 0, "descriptions": []}

    types, forks, descriptions = {}, 0, []
    count = 0
    for meta_path in sorted(subagents.glob("agent-*.meta.json")):
        try:
            meta = json.loads(meta_path.read_text())
        except (ValueError, OSError):
            continue
        count += 1
        if meta.get("isFork"):
            forks += 1
        atype = meta.get("agentType") or "?"
        types[atype] = types.get(atype, 0) + 1
        desc = (meta.get("description") or "").strip()
        if desc:
            descriptions.append(desc[:120])
    return {"count": count, "types": types, "forks": forks, "descriptions": descriptions}


def load_cache(use_cache: bool):
    if not use_cache or not CACHE.exists():
        return {}
    try:
        blob = json.loads(CACHE.read_text())
    except (ValueError, OSError):
        return {}
    if blob.get("version") != CACHE_VERSION:
        return {}
    return blob.get("entries", {})


def save_cache(entries):
    try:
        CACHE.write_text(json.dumps({"version": CACHE_VERSION, "entries": entries}))
    except OSError:
        pass  # A read-only home is not a reason to fail the whole run.


def collect(use_cache=True):
    if not PROJECTS.is_dir():
        return None, []

    cache = load_cache(use_cache)
    fresh = {}
    sessions = []

    for pdir in sorted(PROJECTS.iterdir()):
        if not pdir.is_dir():
            continue
        for jsonl in sorted(pdir.glob("*.jsonl")):
            try:
                st = jsonl.stat()
            except OSError:
                continue
            # Size+mtime is a cheap stand-in for a content hash: transcripts are
            # append-only, so a session that has grown or been rewritten always
            # changes at least one of the two.
            key = f"{pdir.name}/{jsonl.stem}"
            stamp = f"{st.st_size}:{int(st.st_mtime)}"
            cached = cache.get(key)

            if cached and cached.get("stamp") == stamp:
                entry = cached
            else:
                info = scan_session(jsonl)
                info.update(scan_agents(pdir / jsonl.stem))
                entry = {"stamp": stamp, **info}
            fresh[key] = entry

            sessions.append(
                {
                    "project": unslug(pdir.name),
                    "project_slug": pdir.name,
                    "id": jsonl.stem,
                    "mb": round(st.st_size / 1_048_576, 1),
                    "mtime": datetime.fromtimestamp(st.st_mtime).isoformat(timespec="seconds"),
                    **{k: v for k, v in entry.items() if k != "stamp"},
                }
            )

    save_cache(fresh)
    # Undated sessions (empty or corrupt) sort last rather than crashing the sort.
    sessions.sort(key=lambda s: s.get("started") or "9999")
    return PROJECTS, sessions


def matches(session, pattern):
    """Search titles, branches, opening turns, and agent briefs.

    Agent descriptions matter most here: the topic a user remembers is often
    something a subagent was told to investigate and never appears in the title.

    Hits are labelled and ranked by how much they tell you. A project path
    matching 'splitflap' is nearly worthless -- it fires for every session in
    that directory -- while the same word inside an agent brief means that
    session genuinely worked on it. Returning them in that order keeps the
    caller from leading with the noise.
    """
    fields = [
        ("title", session.get("title") or ""),
        ("branch", session.get("branch") or ""),
        *(("turn", t) for t in session.get("opening_turns") or []),
        *(("agent", d) for d in session.get("descriptions") or []),
        ("path", session.get("project") or ""),
    ]
    rank = {"title": 0, "agent": 1, "turn": 2, "branch": 3, "path": 4}
    hits = [{"where": w, "text": t} for w, t in fields if t and pattern.search(t)]
    hits.sort(key=lambda h: rank.get(h["where"], 9))
    return hits


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--since", help="ISO date; keep sessions active on/after it")
    ap.add_argument("--until", help="ISO date; keep sessions started on/before it")
    ap.add_argument("--search", help="regex over titles, turns, and agent briefs")
    ap.add_argument("--project", help="substring filter on the project path")
    ap.add_argument("--min-agents", type=int, default=0)
    ap.add_argument("--no-cache", action="store_true")
    args = ap.parse_args()

    root, sessions = collect(use_cache=not args.no_cache)
    if root is None:
        json.dump({"error": f"no session store at {PROJECTS}"}, sys.stdout)
        return

    total = len(sessions)

    if args.project:
        needle = args.project.lower()
        sessions = [s for s in sessions if needle in s["project"].lower()]
    if args.since:
        sessions = [s for s in sessions if (s.get("ended") or "") >= args.since]
    if args.until:
        sessions = [s for s in sessions if (s.get("started") or "9999") <= args.until + "T99"]
    if args.min_agents:
        sessions = [s for s in sessions if s.get("count", 0) >= args.min_agents]

    if args.search:
        pattern = re.compile(args.search, re.I)
        matched = []
        for s in sessions:
            hits = matches(s, pattern)
            # A hit only on the project path says the session lives in a
            # matching directory, not that it worked on the topic. Use
            # --project for that; here it would bury the real matches.
            if hits and any(h["where"] != "path" for h in hits):
                matched.append({**s, "hits": hits[:5]})
        sessions = matched

    # Roll up by project: the caller groups the map this way, so pre-computing
    # the aggregates keeps the model from having to sum things by hand.
    projects = {}
    for s in sessions:
        p = projects.setdefault(
            s["project"],
            {"project": s["project"], "sessions": 0, "agents": 0, "mb": 0.0,
             "first": None, "last": None},
        )
        p["sessions"] += 1
        p["agents"] += s.get("count", 0)
        p["mb"] = round(p["mb"] + s["mb"], 1)
        if s.get("started") and (p["first"] is None or s["started"] < p["first"]):
            p["first"] = s["started"]
        if s.get("ended") and (p["last"] is None or s["ended"] > p["last"]):
            p["last"] = s["ended"]

    dated = [s["started"] for s in sessions if s.get("started")]
    json.dump(
        {
            "mode": "search" if args.search else "global",
            "root": str(root),
            "total_sessions_on_disk": total,
            "shown": len(sessions),
            "span": {"first": min(dated), "last": max(s.get("ended") or "" for s in sessions)}
            if dated
            else None,
            "total_agents": sum(s.get("count", 0) for s in sessions),
            "projects": sorted(projects.values(), key=lambda p: -p["agents"]),
            "sessions": sessions,
        },
        sys.stdout,
        ensure_ascii=False,
        indent=1,
    )


if __name__ == "__main__":
    main()
