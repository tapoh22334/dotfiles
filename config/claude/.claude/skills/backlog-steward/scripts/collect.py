#!/usr/bin/env python3
"""Collect a GitHub issue board into one JSON blob for the steward's critic.

Reads every open issue (plus recently-closed ones for context), with the fields
that reveal rot: age, last activity, parent/child links, labels, assignee.

Usage:
    collect.py [--repo owner/name] [--limit N] [--json]

Without --json it prints a compact digest meant to be read by an agent.
"""
import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone

QUERY = """
query($owner:String!, $name:String!, $limit:Int!, $after:String) {
  repository(owner:$owner, name:$name) {
    issues(first:$limit, after:$after, states:[OPEN],
           orderBy:{field:UPDATED_AT, direction:ASC}) {
      pageInfo { hasNextPage endCursor }
      nodes {
        number title state createdAt updatedAt
        author { login }
        assignees(first:5) { nodes { login } }
        labels(first:20) { nodes { name } }
        comments { totalCount }
        parent { number title }
        subIssuesSummary { total completed percentCompleted }
        timelineItems(last:1, itemTypes:[CROSS_REFERENCED_EVENT,
                                          CONNECTED_EVENT]) {
          totalCount
        }
      }
    }
  }
}
"""


def run_gh(args, **kw):
    try:
        return subprocess.run(
            args, capture_output=True, text=True, check=True, **kw
        ).stdout
    except FileNotFoundError:
        sys.exit("gh CLI not found. Install it or run this where gh is available.")
    except subprocess.CalledProcessError as e:
        sys.exit(f"gh failed: {e.stderr.strip() or e}")


def detect_repo():
    out = run_gh(["gh", "repo", "view", "--json", "nameWithOwner"])
    return json.loads(out)["nameWithOwner"]


def fetch(repo, limit):
    owner, name = repo.split("/", 1)
    nodes, after = [], None
    while True:
        args = [
            "gh", "api", "graphql",
            "-f", f"query={QUERY}",
            "-F", f"owner={owner}", "-F", f"name={name}",
            "-F", f"limit={min(limit, 100)}",
        ]
        if after:
            args += ["-F", f"after={after}"]
        data = json.loads(run_gh(args))["data"]["repository"]["issues"]
        nodes.extend(data["nodes"])
        if not data["pageInfo"]["hasNextPage"] or len(nodes) >= limit:
            break
        after = data["pageInfo"]["endCursor"]
    return nodes[:limit]


def days_since(iso):
    t = datetime.fromisoformat(iso.replace("Z", "+00:00"))
    return (datetime.now(timezone.utc) - t).days


def level_of(labels):
    if "type::epic" in labels:
        return "Epic"
    if "type::story" in labels:
        return "Story"
    return "Task"


def enrich(nodes):
    out = []
    for n in nodes:
        labels = [x["name"] for x in n["labels"]["nodes"]]
        summary = n.get("subIssuesSummary") or {}
        out.append({
            "number": n["number"],
            "title": n["title"],
            "level": level_of(labels),
            "labels": labels,
            "age_days": days_since(n["createdAt"]),
            "idle_days": days_since(n["updatedAt"]),
            "comments": n["comments"]["totalCount"],
            "assignees": [a["login"] for a in n["assignees"]["nodes"]],
            "parent": (n.get("parent") or {}).get("number"),
            "children_total": summary.get("total", 0),
            "children_done": summary.get("completed", 0),
        })
    return out


def digest(items):
    lines = []
    lines.append(f"OPEN ISSUES: {len(items)}")
    by_level = {}
    for i in items:
        by_level.setdefault(i["level"], []).append(i)
    for lvl in ("Epic", "Story", "Task"):
        if lvl in by_level:
            lines.append(f"  {lvl}: {len(by_level[lvl])}")
    lines.append("")
    lines.append("Sorted by idle time (most neglected first).")
    lines.append("cols: #num [level] idle/age days | children done/total | title")
    lines.append("")
    for i in sorted(items, key=lambda x: -x["idle_days"]):
        kids = (
            f"{i['children_done']}/{i['children_total']}"
            if i["children_total"] else "-"
        )
        parent = f" ^{i['parent']}" if i["parent"] else ""
        who = f" @{','.join(i['assignees'])}" if i["assignees"] else ""
        lines.append(
            f"#{i['number']} [{i['level']}] "
            f"{i['idle_days']}d/{i['age_days']}d | {kids}{parent}{who} | "
            f"{i['title']}"
        )
    return "\n".join(lines)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--repo", help="owner/name (default: current repo)")
    p.add_argument("--limit", type=int, default=300)
    p.add_argument("--json", action="store_true")
    a = p.parse_args()

    repo = a.repo or detect_repo()
    items = enrich(fetch(repo, a.limit))
    if a.json:
        print(json.dumps({"repo": repo, "issues": items}, indent=2))
    else:
        print(f"REPO: {repo}")
        print(digest(items))


if __name__ == "__main__":
    main()
