#!/usr/bin/env python3
"""Find expressions a glossary says to avoid, and print the term to use instead.

Usage: check_terms.py [--glossary FILE ...] PATH...

Reads every Markdown table whose header starts with 用語 and has a 避ける表現
column. Prints `<file>:<line> 「avoided」→「term」` per hit; exits 1 if any.
"""
import argparse
import os
import re
import sys

EXTS = {".md", ".markdown", ".txt"}
SKIP_DIRS = {".git", "node_modules", ".venv", "venv", "__pycache__"}


def cells(line):
    return [c.strip() for c in line.strip().strip("|").split("|")]


def load(path):
    entries = []  # (term, [avoided])
    header = None
    for line in open(path, encoding="utf-8"):
        if not line.lstrip().startswith("|"):
            header = None
            continue
        row = cells(line)
        if header is None:
            header = row if row and row[0] == "用語" else []
            continue
        if not header or set(row[0]) <= set("-: "):
            continue
        try:
            col = header.index("避ける表現")
        except ValueError:
            continue
        if col >= len(row) or not row[0]:
            continue
        avoided = [a.strip() for a in re.split(r"[、,]", row[col]) if a.strip()]
        entries.append((row[0], avoided))
    return entries


def files(paths, skip):
    for p in paths:
        if os.path.isfile(p):
            yield p
            continue
        for root, dirs, names in os.walk(p):
            dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
            for n in sorted(names):
                f = os.path.join(root, n)
                if os.path.splitext(n)[1] in EXTS and os.path.realpath(f) not in skip:
                    yield f


def scan(path, entries):
    hits = []
    fence = False
    for no, line in enumerate(open(path, encoding="utf-8", errors="replace"), 1):
        if line.lstrip().startswith(("```", "~~~")):
            fence = not fence
            continue
        if fence:
            continue
        text = re.sub(r"`[^`]*`", lambda m: " " * len(m.group()), line)
        text = re.sub(r"\]\([^)]*\)", lambda m: " " * len(m.group()), text)
        # Mask every defined term first, so 按分 inside the term 按分率 is not
        # reported as an avoided name for 家事按分
        base = text
        for t in sorted((t for t, _ in entries), key=len, reverse=True):
            base = base.replace(t, "\0" * len(t))
        for term, avoided in entries:
            masked = base
            # Longest first, and mask each hit, so 経費按分 is not also reported as 按分
            for a in sorted(avoided, key=len, reverse=True):
                if a in masked:
                    hits.append(f"{path}:{no} 「{a}」→「{term}」")
                    masked = masked.replace(a, "\0" * len(a))
    return hits


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--glossary", action="append")
    ap.add_argument("paths", nargs="+")
    args = ap.parse_args()
    gl = args.glossary or [
        g for g in ("docs/glossary.md", os.path.expanduser("~/.claude/glossary.md"))
        if os.path.isfile(g)
    ]
    if not gl:
        sys.exit("no glossary found; pass --glossary FILE")
    entries = [e for g in gl for e in load(g)]
    skip = {os.path.realpath(g) for g in gl}
    hits = [h for f in files(args.paths, skip) for h in scan(f, entries)]
    print("\n".join(hits) if hits else "避ける表現なし")
    sys.exit(1 if hits else 0)


if __name__ == "__main__":
    main()
