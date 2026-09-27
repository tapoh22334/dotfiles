import os, sys, unittest
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'bin'))
import digest

P = {"repo": "/r/a", "kind": "merged_branches", "target": "", "title": "マージ済み3本を消す",
     "evidence": "main にマージ済み", "action": "git branch -d x y z", "why_safe": "main に含まれる"}


class DigestTest(unittest.TestCase):
    def test_key_is_stable_and_job_scoped(self):
        self.assertEqual(digest.key('git-hygiene', P), digest.key('git-hygiene', dict(P, title='別')))
        self.assertTrue(digest.key('git-hygiene', P).startswith('git-hygiene:'))

    def test_suppressed_and_duplicate_proposals_are_dropped(self):
        other = dict(P, repo='/r/b')
        kept = digest.select('git-hygiene', [P, dict(P), other], {digest.key('git-hygiene', other)})
        self.assertEqual([p['repo'] for p in kept], ['/r/a'])

    def test_caps_number_of_proposals(self):
        many = [dict(P, repo=f'/r/{i}') for i in range(15)]
        self.assertEqual(len(digest.select('git-hygiene', many, set())), digest.MAX_PROPOSALS)

    def test_render_puts_marker_on_checkbox_line(self):
        md = digest.render({'git-hygiene': [P]}, meta={'model': 'claude-sonnet-5', 'cost': 0.12},
                           stats={}, notices=[])
        line = next(l for l in md.splitlines() if l.startswith('- [ ]'))
        self.assertIn('<!-- pw:' + digest.key('git-hygiene', P) + ' -->', line)
        self.assertIn('claude-sonnet-5', md)

    def test_render_shows_notices_first(self):
        md = digest.render({'git-hygiene': [P]}, meta={}, stats={}, notices=['前回の実行が失敗'])
        self.assertLess(md.index('前回の実行が失敗'), md.index('- [ ]'))


if __name__ == '__main__':
    unittest.main()
