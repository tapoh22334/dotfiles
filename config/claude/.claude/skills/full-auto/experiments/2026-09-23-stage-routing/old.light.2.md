1. Reuse existing issue if one matches — `gh issue list --search "truncate_display"` / review #37,#41,#43 (none match) → `gh issue create` for the truncate_display width-0 bug, then `github-tickets` apply.sh to register it on Project "All Work" (#4) and verify.
2. `superpowers:systematic-debugging` — reproduce the width-0 case in `navigator-list.sh`'s `truncate_display`, confirm root cause before touching code.
3. `superpowers:test-driven-development` — write a failing bats test (width=0 → empty/no numeric output) in `tests/`, confirm it fails, then implement the minimal fix in `truncate_display`.
4. Run `make test` and `make lint` — capture baseline vs. post-fix results per CLAUDE.md (measure pre-existing failures first, don't conflate with regressions).
5. `tower-reviewer` agent — run against the diff (touches `tmux-plugin/`) before opening PR.
6. Commit on a feature branch (not `main`), push, open PR via `gh pr create` referencing the issue; PR body states why (truncate_display bug), not a diff summary.
7. Monitor CI (`gh pr checks` polling) — do not merge until green; if red, classify failure (pre-existing vs. regression) per baseline from step 4.
8. On green CI, merge PR via `gh pr merge` (squash, delete branch) — provisional ruling, veto-able.
9. Close the issue with a comment stating what was wrong and why the fix works; confirm it's off the board or marked done per Project workflow.

Backlog after this task: 1 new issue created for the truncate_display bug (registered on Project "All Work" #4 via github-tickets apply.sh); #37, #41, #43 remain open/untouched.
