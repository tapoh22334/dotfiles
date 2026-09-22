#!/usr/bin/env python3
"""Join a repository's git history to the Claude Code sessions that produced it.

The interesting question about a repo is rarely "what commits exist" (git log
answers that) or "what sessions exist" (session-map answers that). It is why a
commit looks the way it does -- which conversation decided it, what was tried
first, what the user pushed back on. That lives in the session transcripts, and
nothing on disk links the two.

This builds that link. Every event in a session transcript carries a timestamp
and the git branch that was checked out at that moment, so a session's real
activity is a set of (time, branch) points rather than one range on one branch.
Matching a commit against those points is accurate in a way that matching
against a session's overall span is not: sessions here routinely stay open for
weeks (one spans 44 days across 8 turns), so a span-based join would claim
every commit in those 44 days.
"""
import argparse
import bisect
import json
import os
import re
import subprocess
import sys
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path

PROJECTS = Path.home() / ".claude" / "projects"


def slug_for(repo: Path) -> str:
    """Claude stores a project under its path with separators turned into '-'."""
    return str(repo.resolve()).replace("/", "-")


def parse_ts(raw):
    if not raw:
        return None
    try:
        dt = datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone()


def text_of(message):
    """Flatten a message body to plain text, dropping tool payloads."""
    if not isinstance(message, dict):
        return ""
    content = message.get("content")
    if isinstance(content, str):
        return content
    out = []
    if isinstance(content, list):
        for block in content:
            if isinstance(block, dict) and block.get("type") == "text":
                out.append(block.get("text", ""))
    return "\n".join(out)


COMMAND_ARGS = re.compile(r"<command-args>(.*?)</command-args>", re.S)
COMMAND_NAME = re.compile(r"<command-name>(.*?)</command-name>", re.S)
TAG = re.compile(r"<[^>]+>")


def clean_turn(raw: str) -> str:
    """A slash command's visible intent lives in <command-args>; tags are machinery."""
    if not raw:
        return ""
    name = COMMAND_NAME.search(raw)
    args = COMMAND_ARGS.search(raw)
    if name:
        label = "/" + name.group(1).strip().lstrip("/")
        detail = args.group(1).strip() if args else ""
        return f"{label} {detail}".strip()
    return TAG.sub("", raw).strip()


def scan_session(path: Path):
    """Pull a session's activity points, turns, and per-branch presence.

    Returns None for a transcript with no usable timestamps -- an empty or
    truncated file, which is worth reporting separately rather than dropping.
    """
    points = []          # (timestamp, branch) for every dated event
    turns = []           # (timestamp, text) for human turns only
    branches = Counter()
    title = None
    session_id = path.stem

    try:
        with path.open(encoding="utf-8", errors="replace") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    ev = json.loads(line)
                except json.JSONDecodeError:
                    continue

                kind = ev.get("type")
                if kind == "ai-title" and not title:
                    title = (ev.get("title") or "").strip() or None

                ts = parse_ts(ev.get("timestamp"))
                if not ts:
                    continue
                branch = ev.get("gitBranch") or ""
                points.append((ts, branch))
                if branch:
                    branches[branch] += 1

                # isMeta turns are injected skill bodies, not human speech.
                if kind == "user" and not ev.get("isMeta"):
                    body = clean_turn(text_of(ev.get("message")))
                    if body and not body.startswith("[Request interrupted"):
                        turns.append((ts, body))
    except OSError:
        return None

    if not points:
        return None

    points.sort(key=lambda p: p[0])
    turns.sort(key=lambda t: t[0])
    # Short or still-running sessions often have no AI title. The opening turn
    # names the intent well enough to identify the session in a listing, so
    # use it rather than printing "(untitled)" -- but mark it as inferred, so
    # a reader can tell a recorded title from our reading of one.
    inferred = False
    if not title and turns:
        title = " ".join(turns[0][1].split())[:60]
        inferred = bool(title)
    return {
        "id": session_id,
        "title": title,
        "title_inferred": inferred,
        "points": points,
        "turns": turns,
        "branches": branches,
        "started": points[0][0],
        "ended": points[-1][0],
        "mb": round(path.stat().st_size / 1e6, 1),
    }


def agent_counts(session_dir: Path, session_id: str):
    """Count subagents from the .meta.json sidecars, which are tiny."""
    total, types = 0, Counter()
    root = session_dir / session_id
    if not root.is_dir():
        return 0, {}
    for meta in root.rglob("*.meta.json"):
        try:
            data = json.loads(meta.read_text(encoding="utf-8", errors="replace"))
        except (OSError, json.JSONDecodeError):
            continue
        total += 1
        types[data.get("subagentType") or data.get("agentType") or "?"] += 1
    return total, dict(types)


def git(repo: Path, *args):
    try:
        out = subprocess.run(
            ["git", "-C", str(repo), *args],
            capture_output=True, text=True, timeout=60,
        )
    except (OSError, subprocess.TimeoutExpired):
        return ""
    return out.stdout if out.returncode == 0 else ""


SEP = "\x1f"


def read_commits(repo: Path, since=None, until=None, branch=None):
    """Commits across all refs by default: work that was never merged still
    happened, and a repo history that only follows HEAD hides abandoned branches."""
    args = ["log", f"--format=%H{SEP}%h{SEP}%aI{SEP}%an{SEP}%s"]
    args.append(branch if branch else "--all")
    if since:
        args.append(f"--since={since}")
    if until:
        args.append(f"--until={until}")

    commits = []
    for line in git(repo, *args).splitlines():
        parts = line.split(SEP)
        if len(parts) != 5:
            continue
        full, short, iso, author, subject = parts
        ts = parse_ts(iso)
        if not ts:
            continue
        commits.append({
            "sha": full, "short": short, "ts": ts,
            "author": author, "subject": subject,
        })
    commits.sort(key=lambda c: c["ts"])
    return commits


def branches_of(repo: Path, sha: str):
    out = git(repo, "branch", "--all", "--contains", sha)
    names = []
    for line in out.splitlines():
        name = line.strip().lstrip("* ").strip()
        if not name or "HEAD" in name:
            continue
        names.append(name.replace("remotes/origin/", ""))
    return sorted(set(names))


def attribute(commit, sessions, window_minutes):
    """Attribute a commit to the session that was live, on that branch, nearest
    in time.

    Branch agreement is the strong signal and time is the tiebreaker. A commit
    made while a session sat on that same branch minutes earlier is almost
    certainly that session's work; the same timestamp with no branch agreement
    is a coincidence of two things happening at once. Reporting the basis lets
    a reader discount a weak match rather than trusting every row equally.
    """
    window = timedelta(minutes=window_minutes)
    best = None

    for sess in sessions:
        times = sess["_times"]
        idx = bisect.bisect_left(times, commit["ts"])
        for probe in (idx - 1, idx):
            if not 0 <= probe < len(times):
                continue
            point_ts, point_branch = sess["points"][probe]
            gap = abs(commit["ts"] - point_ts)
            if gap > window:
                continue
            on_branch = bool(point_branch) and point_branch in commit["branches"]
            # Prefer branch agreement first, then the smaller gap.
            rank = (0 if on_branch else 1, gap)
            if best is None or rank < best[0]:
                best = (rank, {
                    "session": sess["id"],
                    "title": sess["title"],
                    "title_inferred": sess.get("title_inferred", False),
                    "gap_minutes": round(gap.total_seconds() / 60, 1),
                    "basis": "branch+time" if on_branch else "time-only",
                    "session_branch": point_branch or None,
                })
    return best[1] if best else None


def nearest_turn(sess, ts):
    """The human turn a commit is working under -- the instruction behind it.

    Take the most recent turn before the commit, with no time window at all.
    An agentic run works for hours off one instruction: "push and merge it"
    produced nine commits across two days here, and any window short enough to
    look tight would have left eight of them unexplained. Within a session the
    last thing the user said IS the standing instruction until they say
    something else, so the gap is reported and left for the reader to judge
    rather than used to withhold the answer.
    """
    best = None
    for turn_ts, body in sess["turns"]:
        if turn_ts > ts:
            break
        gap = ts - turn_ts
        if best is None or gap < best[0]:
            best = (gap, body)
    if not best:
        return None
    text = " ".join(best[1].split())
    return {
        "text": text[:200],
        "hours_before": round(best[0].total_seconds() / 3600, 1),
    }


def main():
    ap = argparse.ArgumentParser(
        description="Join this repo's commits to the Claude sessions behind them.")
    ap.add_argument("--repo", default=os.getcwd(),
                    help="repository to map (default: cwd)")
    ap.add_argument("--since", help="ISO date passed to git log")
    ap.add_argument("--until", help="ISO date passed to git log")
    ap.add_argument("--branch", help="limit commits to one branch (default: all refs)")
    ap.add_argument("--search",
                    help="regex over commit subjects, session titles, and turns")
    ap.add_argument("--window", type=int, default=120,
                    help="minutes a commit may sit from session activity (default 120)")
    ap.add_argument("--turns", action="store_true",
                    help="include the human turn preceding each commit")
    ap.add_argument("--unattributed", action="store_true",
                    help="only commits no session explains")
    args = ap.parse_args()

    repo = Path(args.repo).resolve()
    if not (repo / ".git").exists():
        print(json.dumps({"error": f"not a git repository: {repo}"}), file=sys.stderr)
        return 1

    session_dir = PROJECTS / slug_for(repo)
    sessions, broken = [], []
    if session_dir.is_dir():
        for jsonl in sorted(session_dir.glob("*.jsonl")):
            scanned = scan_session(jsonl)
            if scanned is None:
                broken.append(jsonl.stem)
                continue
            scanned["agents"], scanned["types"] = agent_counts(session_dir, scanned["id"])
            scanned["_times"] = [p[0] for p in scanned["points"]]
            sessions.append(scanned)
    sessions.sort(key=lambda s: s["started"])

    commits = read_commits(repo, args.since, args.until, args.branch)
    for commit in commits:
        commit["branches"] = branches_of(repo, commit["sha"])

    pattern = re.compile(args.search, re.I) if args.search else None

    rows, per_session = [], defaultdict(list)
    # Totals over every commit read, before --search/--unattributed narrow the
    # rows. Reporting the filtered count as the repo's size is how a coverage
    # answer ends up claiming the repo is a third of its actual age.
    all_attributed = 0
    for commit in commits:
        match = attribute(commit, sessions, args.window)
        row = {
            "short": commit["short"],
            "when": commit["ts"].isoformat(timespec="minutes"),
            "subject": commit["subject"],
            "author": commit["author"],
            "branches": commit["branches"],
            "session": match,
        }
        if match and args.turns:
            sess = next((s for s in sessions if s["id"] == match["session"]), None)
            if sess:
                row["turn"] = nearest_turn(sess, commit["ts"])
        if pattern:
            hay = " ".join(filter(None, [
                commit["subject"],
                (match or {}).get("title") or "",
                row.get("turn") or "",
            ]))
            if not pattern.search(hay):
                continue
        if match:
            all_attributed += 1
        if args.unattributed and match:
            continue
        rows.append(row)
        if match:
            per_session[match["session"]].append(commit["short"])

    session_rows = []
    for sess in sessions:
        if args.unattributed:
            break
        session_rows.append({
            "id": sess["id"],
            "title": sess["title"],
            "title_inferred": sess.get("title_inferred", False),
            "started": sess["started"].isoformat(timespec="minutes"),
            "ended": sess["ended"].isoformat(timespec="minutes"),
            "user_turns": len(sess["turns"]),
            "agents": sess["agents"],
            "types": sess["types"],
            "mb": sess["mb"],
            # Every branch the session actually sat on, commonest first. The
            # single "branch" other tools report is only the last value seen.
            "branches": [b for b, _ in sess["branches"].most_common()],
            "commits": per_session.get(sess["id"], []),
        })

    # Most unattributed commits are usually not misses: they predate the oldest
    # session on disk, so no transcript could explain them. Separating the two
    # matters -- "190 unexplained" reads as a broken join, while "190 from
    # before any session was recorded" is just the shape of the history. Only
    # the commits inside the recorded era are real gaps worth investigating.
    coverage_start = min((s["started"] for s in sessions), default=None)
    before_records = sum(
        1 for c in commits
        if coverage_start and c["ts"] < coverage_start
        and not attribute(c, sessions, args.window)
    )
    gaps = len(commits) - all_attributed - before_records

    print(json.dumps({
        "repo": str(repo),
        "sessions_on_disk": len(sessions),
        "unreadable_sessions": broken,
        # These describe the whole repo in the requested date range, NOT the
        # rows below -- --search and --unattributed narrow `history` only.
        "commits": len(commits),
        "attributed": all_attributed,
        "unattributed": len(commits) - all_attributed,
        "session_records_begin": coverage_start.isoformat(timespec="minutes")
        if coverage_start else None,
        "commits_before_records": before_records,
        "unexplained_within_records": gaps,
        "rows_shown": len(rows),
        "filtered": bool(args.search or args.unattributed),
        "window_minutes": args.window,
        "session_index": session_rows,
        "history": rows,
    }, ensure_ascii=False, indent=1, default=str))
    return 0


if __name__ == "__main__":
    sys.exit(main())
