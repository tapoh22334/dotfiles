#!/usr/bin/env python3
"""Decide whether proactive-work may spend quota now.

Runs only on quota that would otherwise expire: the weekly window must be about
to reset, the projected surplus must be large, and the user must not be working.
Missing or stale evidence means "don't run". Exit 0 = run, 1 = don't.
"""
import argparse
import glob
import json
import os
import sys
import time

H = 3600.0
RESET_HORIZON_H = 24      # only spend quota that expires within this many hours
BASE_MARGIN = 15.0        # % kept free regardless of forecast
MAX_STALENESS_H = 24
FIVE_HOUR_LIMIT = 50.0
IDLE_MINUTES = 60
DEFAULT_PACE = 1.0        # %/h when there is not enough history
OWN_RUN_MARKER = 'proactive-work-run'


def read_jsonl(path):
    rows = []
    try:
        with open(path) as f:
            for line in f:
                try:
                    rows.append(json.loads(line))
                except ValueError:
                    continue
    except FileNotFoundError:
        pass
    return rows


def last_user_activity(projects_dir):
    latest = 0.0
    for p in glob.glob(os.path.join(projects_dir, '*', '**', '*.jsonl'), recursive=True):
        if OWN_RUN_MARKER in p:
            continue
        latest = max(latest, os.path.getmtime(p))
    return latest


def pace_in_window(snaps, reset, now_ts):
    """Consumption rate in %/h: the steeper of the window mean and the last 24h."""
    latest = snaps[-1]
    used = latest['seven_day']['used_percentage']
    rates = []
    since_start_h = (latest['ts'] - (reset - 7 * 24 * H)) / H
    if since_start_h >= 1:
        rates.append(used / since_start_h)
    recent = [s for s in snaps if latest['ts'] - s['ts'] <= 24 * H]
    if len(recent) >= 2 and (latest['ts'] - recent[0]['ts']) >= H:
        rates.append((used - recent[0]['seven_day']['used_percentage'])
                     / ((latest['ts'] - recent[0]['ts']) / H))
    return max(rates) if rates else DEFAULT_PACE


def evaluate(snapshots_path, runs_path, projects_dir, now=None, job_cost=10.0):
    now = time.time() if now is None else now
    reasons, metrics = [], {}
    snaps = [s for s in read_jsonl(snapshots_path)
             if isinstance(s.get('seven_day'), dict) and 'ts' in s]
    if not snaps:
        return {'ok': False, 'reasons': ['no_snapshot'], 'metrics': metrics}

    snaps.sort(key=lambda s: s['ts'])
    latest = snaps[-1]
    reset = latest['seven_day']['resets_at']
    used = latest['seven_day']['used_percentage']
    staleness_h = (now - latest['ts']) / H
    metrics.update(seven_day_used=used, window_resets_at=reset,
                   staleness_h=round(staleness_h, 2))

    if reset <= now:
        return {'ok': False, 'reasons': ['window_rolled'], 'metrics': metrics}
    if staleness_h > MAX_STALENESS_H:
        reasons.append('snapshot_stale')

    window = [s for s in snaps if abs(s['seven_day']['resets_at'] - reset) < H]
    pace = pace_in_window(window, reset, now)
    hours_to_reset = (reset - now) / H
    margin = BASE_MARGIN + pace * max(staleness_h, 0)
    projected = used + pace * (reset - latest['ts']) / H
    surplus = 100.0 - projected - margin
    metrics.update(pace=round(pace, 4), hours_to_reset=round(hours_to_reset, 2),
                   projected=round(projected, 2), margin=round(margin, 2),
                   surplus=round(surplus, 2), job_cost=job_cost)

    if hours_to_reset > RESET_HORIZON_H:
        reasons.append('reset_not_near')
    if surplus < 2 * job_cost:
        reasons.append('surplus_too_small')

    five = latest.get('five_hour') or {}
    if five.get('resets_at', 0) > now and five.get('used_percentage', 0) >= FIVE_HOUR_LIMIT:
        reasons.append('five_hour_busy')

    idle_min = (now - last_user_activity(projects_dir)) / 60
    metrics['idle_minutes'] = round(idle_min, 1)
    if idle_min < IDLE_MINUTES:
        reasons.append('user_active')

    for r in read_jsonl(runs_path):
        if r.get('status') != 'failed' and abs(r.get('window_resets_at', 0) - reset) < H:
            reasons.append('already_ran_this_window')
            break

    return {'ok': not reasons, 'reasons': reasons, 'metrics': metrics}


def main():
    state = os.path.expanduser('~/.local/state')
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--snapshots', default=os.path.join(state, 'claude-usage/snapshots.jsonl'))
    ap.add_argument('--runs', default=os.path.join(state, 'proactive-work/runs.jsonl'))
    ap.add_argument('--projects', default=os.path.expanduser('~/.claude/projects'))
    ap.add_argument('--job-cost', type=float, default=10.0)
    a = ap.parse_args()
    result = evaluate(a.snapshots, a.runs, a.projects, job_cost=a.job_cost)
    print(json.dumps(result))
    sys.exit(0 if result['ok'] else 1)


if __name__ == '__main__':
    main()
