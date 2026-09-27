#!/usr/bin/env python3
"""Render proposals into the weekly digest issue body.

The LLM only returns structured proposals; keys, suppression and the markdown are
decided here so the posted text never depends on the model following a format.

  digest.py <job> <proposals.json> <suppressed.txt> <stats.json> <meta.json> [notice ...]
  stdout: markdown body (empty when nothing survives filtering)
"""
import hashlib
import json
import sys

MAX_PROPOSALS = 10   # a digest nobody finishes reading teaches the reader to ignore it
HEADER = ('採用する提案に ☑ を付けてから、この issue を close してください'
          '(☐ のまま close = 却下。14 日放置は未回答として自動 close)。\n'
          '却下した提案は 30 日間再掲しません。')


def key(job, p):
    ident = '|'.join((p['repo'], p['kind'], p.get('target', '')))
    return f"{job}:{hashlib.sha1(ident.encode()).hexdigest()[:10]}"


def select(job, proposals, suppressed):
    seen, kept = set(suppressed), []
    for p in proposals:
        k = key(job, p)
        if k not in seen:
            seen.add(k)
            kept.append(p)
    return kept[:MAX_PROPOSALS]


def render(by_job, meta, stats, notices):
    out = [f'> {n}' for n in notices]
    out += ['' if notices else None, HEADER]
    out = [l for l in out if l is not None]
    for job, proposals in by_job.items():
        out += ['', f'## {job}']
        for p in proposals:
            out.append(f"- [ ] **{p['title']}** — `{p['repo']}` <!-- pw:{key(job, p)} -->")
            out.append(f"  - 根拠: {p['evidence']}")
            out.append(f"  - 推奨: {p['action']}")
            if p.get('why_safe'):
                out.append(f"  - 安全な理由: {p['why_safe']}")
    out += ['', '---']
    for job, s in sorted(stats.items()):
        rate = '—' if s.get('rate') is None else f"{s['rate']:.0%}"
        out.append(f"- {job} 採用率 {rate}(採用 {s['adopted']} / 却下 {s['rejected']} / 未回答 {s['unanswered']})")
    if meta:
        out.append('- 実行: ' + ', '.join(f'{k}={v}' for k, v in meta.items()))
    return '\n'.join(out) + '\n'


def main():
    if len(sys.argv) < 6:
        sys.exit(__doc__)
    job, props_f, supp_f, stats_f, meta_f, *notices = sys.argv[1:]
    with open(props_f) as f:
        proposals = json.load(f)
    with open(supp_f) as f:
        suppressed = {l.strip() for l in f if l.strip()}
    with open(stats_f) as f:
        stats = json.load(f)
    with open(meta_f) as f:
        meta = json.load(f)
    kept = select(job, proposals, suppressed)
    if kept:
        sys.stdout.write(render({job: kept}, meta, stats, notices))


if __name__ == '__main__':
    main()
