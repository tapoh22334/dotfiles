#!/usr/bin/env python3
"""Collect the skeleton of a Claude Code session: user turns + the agent tree.

Emits JSON on stdout. This exists so the model never has to parse multi-megabyte
JSONL itself -- it reads a compact skeleton and writes the prose summary.

Usage:
    collect.py                    # current project, most recently modified session
    collect.py --session <id>     # one specific session
    collect.py --project          # every session in the project (index only)
    collect.py --cwd <path>       # project other than $PWD
"""
import argparse
import json
import os
import re
import sys
from pathlib import Path

# Lines that are shaped like user messages but aren't the human talking.
NOISE = re.compile(
    r"<system-reminder>|<local-command-|<task-notification>|"
    r"tool_use_error|Caveat: The messages below|"
    r"\[SYSTEM NOTIFICATION|Base directory for this skill:",
)

# Skill bodies and similar injections are recorded as user turns but carry
# isMeta -- they are instructions to Claude, not something the human said, so
# including them would misrepresent the conversation.


def project_dir(cwd: str) -> Path:
    """Claude stores sessions under a slugified absolute path."""
    slug = str(Path(cwd).resolve()).replace("/", "-")
    return Path.home() / ".claude" / "projects" / slug


def text_of(message) -> str:
    """Message content is either a string or a list of typed blocks."""
    if not isinstance(message, dict):
        return ""
    content = message.get("content")
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return " ".join(
            block.get("text", "")
            for block in content
            if isinstance(block, dict) and block.get("type") == "text"
        )
    return ""


def slash_command(raw: str):
    """A /command turn wraps the name in tags; the visible ask is in args."""
    name = re.search(r"<command-name>/?([^<]+)</command-name>", raw)
    if not name:
        return None
    args = re.search(r"<command-args>(.*?)</command-args>", raw, re.S)
    detail = (args.group(1).strip() if args else "")
    return f"/{name.group(1).strip()}" + (f" {detail}" if detail else "")


def read_turns(path: Path, limit: int = 400):
    """Human turns from the main thread, in order, with noise stripped."""
    turns = []
    with path.open(errors="replace") as fh:
        for line in fh:
            try:
                rec = json.loads(line)
            except ValueError:
                continue
            if rec.get("type") != "user" or rec.get("isSidechain") or rec.get("isMeta"):
                continue
            raw = text_of(rec.get("message"))
            if not raw.strip():
                continue

            cmd = slash_command(raw)
            if cmd:
                body = cmd
            elif NOISE.search(raw):
                continue  # machine-generated turn, not the user
            else:
                body = raw.strip()

            body = " ".join(body.split())
            if not body:
                continue
            turns.append({"at": (rec.get("timestamp") or "")[:19], "text": body[:limit]})
    return turns


def read_agents(session_dir: Path):
    """The agent tree, from the tiny .meta.json sidecars beside each transcript."""
    subagents = session_dir / "subagents"
    if not subagents.is_dir():
        return []

    agents = []
    for meta_path in sorted(subagents.glob("agent-*.meta.json")):
        agent_id = meta_path.name[len("agent-"):-len(".meta.json")]
        try:
            meta = json.loads(meta_path.read_text())
        except ValueError:
            continue

        transcript = subagents / f"agent-{agent_id}.jsonl"
        stat = transcript.stat() if transcript.exists() else None
        agents.append(
            {
                "id": agent_id,
                "type": meta.get("agentType", "?"),
                "description": meta.get("description", ""),
                "parent": meta.get("parentAgentId"),
                "depth": meta.get("spawnDepth", 1),
                "is_fork": bool(meta.get("isFork")),
                "model": meta.get("model"),
                "transcript": str(transcript) if stat else None,
                "kb": round(stat.st_size / 1024) if stat else 0,
                "ended_at": (
                    __import__("datetime").datetime.fromtimestamp(stat.st_mtime).isoformat(timespec="seconds")
                    if stat
                    else None
                ),
            }
        )

    # Order children under parents so the caller can print a tree directly.
    by_parent = {}
    for a in agents:
        by_parent.setdefault(a["parent"], []).append(a)
    for group in by_parent.values():
        group.sort(key=lambda a: a["ended_at"] or "")

    ordered = []

    def walk(parent_id):
        for a in by_parent.get(parent_id, []):
            ordered.append(a)
            walk(a["id"])

    walk(None)
    # Any agent whose parent is missing from this session still deserves output.
    seen = {a["id"] for a in ordered}
    ordered.extend(a for a in agents if a["id"] not in seen)
    return ordered


def session_summary(jsonl: Path):
    title, branch, started = None, None, None
    with jsonl.open(errors="replace") as fh:
        for line in fh:
            try:
                rec = json.loads(line)
            except ValueError:
                continue
            if rec.get("type") == "ai-title" and not title:
                title = rec.get("aiTitle")
            branch = rec.get("gitBranch") or branch
            ts = rec.get("timestamp")
            if ts and not started:
                started = ts[:19]
    return title, branch, started


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cwd", default=os.getcwd())
    ap.add_argument("--session")
    ap.add_argument("--project", action="store_true")
    ap.add_argument("--max-turns", type=int, default=60)
    args = ap.parse_args()

    root = project_dir(args.cwd)
    if not root.is_dir():
        json.dump({"error": f"no session store at {root}"}, sys.stdout)
        return

    files = sorted(root.glob("*.jsonl"), key=lambda p: p.stat().st_mtime, reverse=True)
    if not files:
        json.dump({"error": f"no sessions in {root}"}, sys.stdout)
        return

    if args.project:
        index = []
        for f in files:
            title, branch, started = session_summary(f)
            sub = root / f.stem / "subagents"
            index.append(
                {
                    "id": f.stem,
                    "title": title,
                    "branch": branch,
                    "started": started,
                    "ended": __import__("datetime").datetime.fromtimestamp(f.stat().st_mtime).isoformat(timespec="seconds"),
                    "mb": round(f.stat().st_size / 1_048_576, 1),
                    "agents": len(list(sub.glob("agent-*.meta.json"))) if sub.is_dir() else 0,
                }
            )
        json.dump({"mode": "project", "project": str(root), "sessions": index}, sys.stdout, ensure_ascii=False, indent=1)
        return

    target = root / f"{args.session}.jsonl" if args.session else files[0]
    if not target.exists():
        json.dump({"error": f"session not found: {target}"}, sys.stdout)
        return

    title, branch, started = session_summary(target)
    turns = read_turns(target)
    json.dump(
        {
            "mode": "session",
            "id": target.stem,
            "title": title,
            "branch": branch,
            "started": started,
            "turn_count": len(turns),
            "turns": turns[: args.max_turns],
            "truncated_turns": max(0, len(turns) - args.max_turns),
            "agents": read_agents(root / target.stem),
        },
        sys.stdout,
        ensure_ascii=False,
        indent=1,
    )


if __name__ == "__main__":
    main()
