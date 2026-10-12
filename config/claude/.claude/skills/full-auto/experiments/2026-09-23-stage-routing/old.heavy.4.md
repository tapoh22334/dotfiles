1. superpowers:systematic-debugging — investigate current Tail-view launch path (why it opens a separate tmux window/client instead of rendering in the left pane) and confirm root cause, tying findings to #37 (nested Navigator/self-attach is the same underlying window-vs-pane confusion).
2. gh issue view 37 — read existing issue body/comments to check if this request is the same root cause or a separate one.
3. **裁定**: treat this as the same defect as #37 rather than opening a new issue. **根拠**: both are "Tail leaves the pane model and Navigator gets re-entered/nested" — same nested-window mechanism per tower-nav-shared-state-files / tmux-window-target-by-index memory. **反証行**: if investigation shows Tail's separate-window behavior is a distinct code path unrelated to #37's attach loop, split out a new issue instead. **veto可**: yes.
4. reuse #37 — comment with the refined scope ("Tail should render as a left-pane display mode, not a separate window") before starting work, per CLAUDE.md ticket discipline.
5. github-tickets apply.sh — verify #37 is correctly on Project "All Work" (#4); add it if missing.
6. vf-pipeline (orient → articulate → requirements → userflows → harness → construct → acceptance → trace) — scope the fix: define "Tail as left-pane display mode" requirements/userflow, build a test harness before implementation.
7. superpowers:test-driven-development — write failing bats tests (integration/e2e) asserting Tail renders in the existing left pane (no new window/client created, Navigator pane untouched) before writing implementation.
8. Implement the fix in tmux-plugin/scripts (Tail rendering path) to satisfy the tests, following tmux-window-target-by-index and claude-pane-working-signal memory constraints (index-based targeting, no nested client).
9. make test && make lint — run full suite plus shellcheck; capture baseline pre-existing failures first per tower-suite-preexisting-failures memory to distinguish regressions from known flakiness.
10. tower-reviewer — run the project review agent on the diff before opening the PR (mandatory per CLAUDE.md for tmux-plugin/ changes).
11. Fix any issues tower-reviewer flags; re-run make test/lint until clean relative to baseline.
12. git commit on a feature branch (not main) with message describing the fix.
13. gh pr create — open PR against main with body explaining why (nested Navigator / separate-window regression), referencing #37; do not merge without CI.
14. Monitor CI status (gh pr checks / gh run watch) as a background-polled step; do not end turn waiting idle.
15. Once CI is green, merge PR via gh (squash/merge per repo convention) — this is the one outward action explicitly implied by "run to completion," but if CI is red, stop merge and report failing checks as unresolved instead of forcing merge.
16. gh issue close 37 --comment — close with a comment stating what was fixed and why, per CLAUDE.md's "close 時に何を・なぜ直したかを残す" rule.

Backlog after this task: issue #37 reused (not a new issue created), confirmed/kept on Project "All Work" (#4) via github-tickets apply.sh; #41 and #43 untouched and left open for separate future work.
