#!/usr/bin/env python3
"""Turn answered digest issues into ledger rows (the acceptance-rate record).

A closed digest: [x] = adopted, [ ] = rejected. A digest left open for
UNANSWERED_DAYS counts as unanswered and is listed for closing.

  reap.py reap <ledger>        stdin: `gh issue list --json number,state,createdAt,body`
                               stdout: {"to_close": [...], "added": n}
  reap.py suppressed <ledger>  keys rejected in the last SUPPRESS_DAYS, one per line
  reap.py stats <ledger>       per-job counts and adoption rate as JSON
"""
import datetime
import json
import re
import sys
import time

DAY = 86400
UNANSWERED_DAYS = 14
SUPPRESS_DAYS = 30
ITEM = re.compile(r'^\s*- \[( |x|X)\] .*<!-- pw:([\w.-]+:[\w.-]+) -->')


def read_ledger(path):
    try:
        with open(path) as f:
            return [json.loads(l) for l in f if l.strip()]
    except FileNotFoundError:
        return []


def parse_items(body):
    for line in (body or '').splitlines():
        m = ITEM.match(line)
        if m:
            yield m.group(2), m.group(1) != ' '


def created_ts(issue):
    return datetime.datetime.strptime(issue['createdAt'], '%Y-%m-%dT%H:%M:%SZ') \
        .replace(tzinfo=datetime.timezone.utc).timestamp()


def reap(issues, ledger_path, now=None):
    now = time.time() if now is None else now
    done = {r['issue'] for r in read_ledger(ledger_path)}
    rows, to_close = [], []
    for issue in issues:
        if issue['number'] in done:
            continue
        closed = issue['state'].upper() == 'CLOSED'
        expired = not closed and now - created_ts(issue) >= UNANSWERED_DAYS * DAY
        if not (closed or expired):
            continue
        for key, checked in parse_items(issue['body']):
            verdict = 'unanswered' if expired else ('adopted' if checked else 'rejected')
            rows.append({'ts': int(now), 'issue': issue['number'], 'key': key, 'verdict': verdict})
        if expired:
            to_close.append(issue['number'])
    if rows:
        with open(ledger_path, 'a') as f:
            for r in rows:
                f.write(json.dumps(r, ensure_ascii=False) + '\n')
    return {'to_close': to_close, 'added': len(rows)}


def suppressed(ledger_path, now=None):
    now = time.time() if now is None else now
    return sorted({r['key'] for r in read_ledger(ledger_path)
                   if r['verdict'] == 'rejected' and now - r['ts'] < SUPPRESS_DAYS * DAY})


def stats(ledger_path):
    out = {}
    for r in read_ledger(ledger_path):
        job = r['key'].split(':', 1)[0]
        s = out.setdefault(job, {'adopted': 0, 'rejected': 0, 'unanswered': 0})
        s[r['verdict']] += 1
    for s in out.values():
        answered = s['adopted'] + s['rejected']
        s['rate'] = round(s['adopted'] / answered, 3) if answered else None
    return out


def main():
    if len(sys.argv) != 3 or sys.argv[1] not in ('reap', 'suppressed', 'stats'):
        sys.exit(__doc__)
    cmd, ledger = sys.argv[1], sys.argv[2]
    if cmd == 'reap':
        print(json.dumps(reap(json.load(sys.stdin), ledger)))
    elif cmd == 'suppressed':
        print('\n'.join(suppressed(ledger)))
    else:
        print(json.dumps(stats(ledger)))


if __name__ == '__main__':
    main()
