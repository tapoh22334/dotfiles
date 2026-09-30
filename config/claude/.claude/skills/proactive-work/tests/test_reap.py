import json, os, sys, tempfile, unittest
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'bin'))
import reap

DAY = 86400
NOW = 1_800_000_000
BODY = ("## git-hygiene\n"
        "- [x] ブランチ削除 <!-- pw:git-hygiene:aaa -->\n"
        "- [ ] stash 破棄 <!-- pw:git-hygiene:bbb -->\n"
        "- [ ] 印なしの行\n")


def issue(n, state, created, body=BODY):
    return {"number": n, "state": state, "createdAt": created, "body": body}


def iso(ts):
    import datetime
    return datetime.datetime.fromtimestamp(ts, datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')


class ReapTest(unittest.TestCase):
    def setUp(self):
        self.ledger = os.path.join(tempfile.mkdtemp(), 'ledger.jsonl')

    def rows(self):
        with open(self.ledger) as f:
            return [json.loads(l) for l in f]

    def test_closed_issue_checked_adopted_unchecked_rejected(self):
        out = reap.reap([issue(1, 'CLOSED', iso(NOW - DAY))], self.ledger, now=NOW)
        verdicts = {r['key']: r['verdict'] for r in self.rows()}
        self.assertEqual(verdicts, {'git-hygiene:aaa': 'adopted', 'git-hygiene:bbb': 'rejected'})
        self.assertEqual(out['to_close'], [])

    def test_open_recent_issue_is_left_alone(self):
        out = reap.reap([issue(2, 'OPEN', iso(NOW - 3 * DAY))], self.ledger, now=NOW)
        self.assertFalse(os.path.exists(self.ledger))
        self.assertEqual(out['to_close'], [])

    def test_open_old_issue_marked_unanswered_and_closed(self):
        out = reap.reap([issue(3, 'OPEN', iso(NOW - 15 * DAY))], self.ledger, now=NOW)
        self.assertEqual({r['verdict'] for r in self.rows()}, {'unanswered'})
        self.assertEqual(out['to_close'], [3])

    def test_expired_issue_left_open_after_failed_close_is_closed_again(self):
        reap.reap([issue(3, 'OPEN', iso(NOW - 15 * DAY))], self.ledger, now=NOW)
        out = reap.reap([issue(3, 'OPEN', iso(NOW - 15 * DAY))], self.ledger, now=NOW)
        self.assertEqual(out['to_close'], [3])
        self.assertEqual(len(self.rows()), 2)

    def test_open_digest_keys_are_reported_for_suppression(self):
        out = reap.reap([issue(2, 'OPEN', iso(NOW - 3 * DAY))], self.ledger, now=NOW)
        self.assertEqual(out['open_keys'], ['git-hygiene:aaa', 'git-hygiene:bbb'])

    def test_reaping_is_idempotent(self):
        reap.reap([issue(1, 'CLOSED', iso(NOW - DAY))], self.ledger, now=NOW)
        reap.reap([issue(1, 'CLOSED', iso(NOW - DAY))], self.ledger, now=NOW)
        self.assertEqual(len(self.rows()), 2)

    def test_suppressed_keys_are_recent_answers(self):
        reap.reap([issue(1, 'CLOSED', iso(NOW - DAY))], self.ledger, now=NOW)
        self.assertEqual(reap.suppressed(self.ledger, now=NOW), ['git-hygiene:aaa', 'git-hygiene:bbb'])
        self.assertEqual(reap.suppressed(self.ledger, now=NOW + 31 * DAY), [])

    def test_stats_per_job(self):
        reap.reap([issue(1, 'CLOSED', iso(NOW - DAY))], self.ledger, now=NOW)
        s = reap.stats(self.ledger)
        self.assertEqual(s['git-hygiene'], {'adopted': 1, 'rejected': 1, 'unanswered': 0, 'rate': 0.5})


if __name__ == '__main__':
    unittest.main()
