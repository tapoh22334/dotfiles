import json, os, sys, tempfile, time, unittest
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'bin'))
import gate

H = 3600
NOW = 1_800_000_000


def snap(ts, seven, seven_reset, five=10.0, five_reset=None):
    return {"ts": ts,
            "five_hour": {"used_percentage": five, "resets_at": five_reset or ts + 2 * H},
            "seven_day": {"used_percentage": seven, "resets_at": seven_reset}}


class GateTest(unittest.TestCase):
    def setUp(self):
        self.d = tempfile.mkdtemp()
        self.snaps = os.path.join(self.d, 'snapshots.jsonl')
        self.runs = os.path.join(self.d, 'runs.jsonl')
        self.projects = os.path.join(self.d, 'projects')
        os.makedirs(os.path.join(self.projects, '-home-u-work'))
        self.activity(NOW - 3 * H)

    def activity(self, ts, name='-home-u-work'):
        p = os.path.join(self.projects, name, 's.jsonl')
        os.makedirs(os.path.dirname(p), exist_ok=True)
        open(p, 'w').close()
        os.utime(p, (ts, ts))

    def write(self, rows, path=None):
        with open(path or self.snaps, 'w') as f:
            for r in rows:
                f.write(json.dumps(r) + '\n')

    def run_gate(self, job_cost=10.0):
        return gate.evaluate(self.snaps, self.runs, self.projects, now=NOW, job_cost=job_cost)

    def test_passes_when_reset_near_and_large_surplus(self):
        reset = NOW + 10 * H
        self.write([snap(NOW - 24 * H, 38.0, reset), snap(NOW - 1 * H, 40.0, reset)])
        r = self.run_gate()
        self.assertTrue(r['ok'], r)

    def test_blocks_when_reset_far(self):
        reset = NOW + 60 * H
        self.write([snap(NOW - 1 * H, 20.0, reset)])
        r = self.run_gate()
        self.assertFalse(r['ok'])
        self.assertIn('reset_not_near', r['reasons'])

    def test_blocks_when_surplus_small(self):
        reset = NOW + 10 * H
        self.write([snap(NOW - 24 * H, 60.0, reset), snap(NOW - 1 * H, 80.0, reset)])
        r = self.run_gate()
        self.assertFalse(r['ok'])
        self.assertIn('surplus_too_small', r['reasons'])

    def test_blocks_when_five_hour_busy(self):
        reset = NOW + 10 * H
        self.write([snap(NOW - 1 * H, 40.0, reset, five=55.0)])
        self.assertIn('five_hour_busy', self.run_gate()['reasons'])

    def test_five_hour_ignored_after_its_reset(self):
        reset = NOW + 10 * H
        self.write([snap(NOW - 3 * H, 40.0, reset, five=90.0, five_reset=NOW - 1 * H)])
        self.assertNotIn('five_hour_busy', self.run_gate()['reasons'])

    def test_blocks_when_no_snapshots(self):
        r = self.run_gate()
        self.assertFalse(r['ok'])
        self.assertIn('no_snapshot', r['reasons'])

    def test_blocks_when_snapshot_stale(self):
        reset = NOW + 10 * H
        self.write([snap(NOW - 25 * H, 10.0, reset)])
        self.assertIn('snapshot_stale', self.run_gate()['reasons'])

    def test_blocks_when_window_already_rolled(self):
        self.write([snap(NOW - 5 * H, 10.0, NOW - 1 * H)])
        self.assertIn('window_rolled', self.run_gate()['reasons'])

    def test_blocks_when_user_active(self):
        reset = NOW + 10 * H
        self.write([snap(NOW - 1 * H, 40.0, reset)])
        self.activity(NOW - 10 * 60)
        self.assertIn('user_active', self.run_gate()['reasons'])

    def test_own_runs_do_not_count_as_activity(self):
        reset = NOW + 10 * H
        self.write([snap(NOW - 1 * H, 40.0, reset)])
        self.activity(NOW - 60, name='-home-u--local-state-proactive-work-run')
        self.assertNotIn('user_active', self.run_gate()['reasons'])

    def test_blocks_when_already_ran_this_window(self):
        reset = NOW + 10 * H
        self.write([snap(NOW - 1 * H, 40.0, reset)])
        self.write([{"ts": NOW - 2 * H, "window_resets_at": reset, "status": "posted"}], self.runs)
        self.assertIn('already_ran_this_window', self.run_gate()['reasons'])

    def test_failure_before_judge_does_not_consume_window(self):
        reset = NOW + 10 * H
        self.write([snap(NOW - 1 * H, 40.0, reset)])
        self.write([{"ts": NOW - 2 * H, "window_resets_at": reset, "status": "failed", "stage": "reap"}], self.runs)
        self.assertNotIn('already_ran_this_window', self.run_gate()['reasons'])

    def test_failure_after_spending_quota_consumes_window(self):
        reset = NOW + 10 * H
        self.write([snap(NOW - 1 * H, 40.0, reset)])
        for stage in ('judge', 'post'):
            self.write([{"ts": NOW - 2 * H, "window_resets_at": reset, "status": "failed", "stage": stage}], self.runs)
            self.assertIn('already_ran_this_window', self.run_gate()['reasons'], stage)

    def test_null_five_hour_percentage_is_tolerated(self):
        reset = NOW + 10 * H
        s = snap(NOW - 1 * H, 40.0, reset)
        s['five_hour']['used_percentage'] = None
        self.write([s])
        self.assertTrue(self.run_gate()['ok'])

    def test_snapshot_without_reset_is_ignored(self):
        reset = NOW + 10 * H
        bad = snap(NOW - 1 * H, 40.0, reset)
        del bad['seven_day']['resets_at']
        self.write([bad])
        self.assertIn('no_snapshot', self.run_gate()['reasons'])

    def test_main_exits_2_on_crash(self):
        import subprocess
        with open(self.snaps, 'w') as f:
            f.write(json.dumps({"ts": "x", "seven_day": {"used_percentage": "y", "resets_at": "z"}}) + '\n')
        r = subprocess.run([sys.executable, os.path.join(os.path.dirname(__file__), '..', 'bin', 'gate.py'),
                            '--snapshots', self.snaps, '--runs', self.runs, '--projects', self.projects],
                           capture_output=True, text=True)
        self.assertEqual(r.returncode, 2, r.stdout + r.stderr)

    def test_pace_uses_steeper_recent_slope(self):
        reset = NOW + 10 * H
        # window mean: 40% over 158h (~0.25%/h); recent: 20% in 20h (1%/h)
        self.write([snap(NOW - 21 * H, 20.0, reset), snap(NOW - 1 * H, 40.0, reset)])
        r = self.run_gate()
        self.assertAlmostEqual(r['metrics']['pace'], 1.0, places=2)

    def test_skips_malformed_lines(self):
        reset = NOW + 10 * H
        with open(self.snaps, 'w') as f:
            f.write('not json\n' + json.dumps(snap(NOW - 1 * H, 40.0, reset)) + '\n')
        self.assertTrue(self.run_gate()['ok'])


if __name__ == '__main__':
    unittest.main()
