1. Check for an existing issue matching this bug via `gh issue list --state open` (already shown: none of #37/#41/#43 match `truncate_display`) — no reuse candidate found.
2. `gh issue create` — new Story-level issue: "navigator-list.sh: truncate_display outputs digits when width is 0" (bug, 1-function fix).
3. github-tickets apply.sh — register the new issue on Project "All Work" (#4) and verify placement.
4. Create branch `fix/truncate-display-zero-width` off `main`.
5. superpowers:systematic-debugging — reproduce: call `truncate_display` with width 0, confirm it currently emits digits instead of empty/safe output; identify root cause in the function.
6. superpowers:test-driven-development — write/extend a bats test in `tests/` asserting `truncate_display` returns empty (or correct zero-width behavior) when width=0, confirm it fails first.
7. Fix the single function in `navigator-list.sh` per the diagnosed root cause.
8. Re-run the new test — confirm it passes; run `make test` for the full suite to catch regressions.
9. Run `make lint` (shellcheck) on the changed file.
10. tower-reviewer — run the project review agent on the diff before opening the PR (required by CLAUDE.md for `tmux-plugin/` changes).
11. Commit the fix + test with a message describing the root cause (not "fix bug").
12. Push branch, open PR via `gh pr create` referencing the issue (`Closes #<new>`), body states why (zero-width truncation emitted digits), not a diff summary.
13. Monitor CI status (`gh pr checks --watch` or poll) — do not merge while red; if pre-existing failures appear, compare against a `main` baseline per [[tower-suite-preexisting-failures]] before attributing to this change.
14. Once CI green, merge PR via `gh pr merge` (squash, per repo norm) — this is an external/shared-state action but within the explicit "完了まで回して" (run to completion) mandate, so proceed without pausing.
15. `gh issue close` the new issue with a comment: what broke (digits at width 0), why (root cause found in step 5), and how it was fixed — for future readers who won't read the diff.
16. Final report: summarize outcome, list all provisional rulings made (squash-merge choice, no-Epic single Story per [[no-epic-for-small-trees]], proceeding through merge autonomously), and any remaining items only the user can decide (none expected).

Backlog after this task: one new issue created (number TBD at step 2) for the `truncate_display` bug, added to Project "All Work" (#4) via github-tickets apply.sh in step 3, and closed at step 15. #37/#41/#43 untouched.
