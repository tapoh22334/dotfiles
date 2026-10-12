1. `gh issue list --state open --search "truncate_display"` — check for an existing ticket on this bug (none of #37/#41/#43 match; expect no hit).
2. Reuse-or-create decision (provisional ruling): no existing issue covers `truncate_display` width-0 → create one via **github-tickets** (manifest + `apply.sh`), not bare `gh issue create`, so it lands on Project "All Work" #4 and gets verified.
3. **github-tickets** — write a single-Task manifest (no Epic/Story wrapper — per memory [[no-epic-for-small-trees]], user has declined Epics for small trees here) for: "navigator-list.sh: truncate_display outputs digits when width is 0."
4. `apply.sh` — apply the manifest, capturing the new issue number (call it #N).
5. `git checkout -b fix/truncate-display-zero-width` — branch for the change (repo rule: no direct commits to main).
6. Scope check against the routing table: single function, existing-behavior fix, no new command/mode, touches 1 file → **implementation(light)** lane, not vf-pipeline.
7. **superpowers:test-driven-development** — RED: write/extend a bats test in `tests/` that calls `truncate_display` with width 0 and asserts empty/no-digit output (reproduce the bug first).
8. **superpowers:test-driven-development** — GREEN: fix `truncate_display` in `tmux-plugin/scripts/navigator-list.sh` (or wherever it lives) to handle width 0 without emitting digits; rerun the new test plus full suite (`make test`) to confirm no regression, comparing against a pre-fix baseline run if any unrelated failures appear (per memory [[tower-suite-preexisting-failures]]).
9. `make lint` / `make format` — ShellCheck and shfmt compliance check on the touched file.
10. **tower-reviewer** agent — run against the diff before opening the PR (CLAUDE.md-named reviewer; required every time).
11. Fix any CONFIRMED findings from tower-reviewer, re-run TDD suite to confirm still green.
12. `git commit` — commit the fix + test with a message describing the diff reason.
13. `git push` + `gh pr create` — open PR against `main`, body states why (width-0 truncation emitted stray digits) and includes `Closes #N`; do not merge yet.
14. Wait for CI (GitHub Actions: Unit/Integration/Docker/ShellCheck) to report; do not merge on red.
15. On green CI, merge PR (squash via `gh pr merge`), which closes #N automatically via `Closes #N`.
16. `apply.sh --verify` — confirm #N is/was on Project "All Work" #4 and now closed cleanly (backlog verification, not manual close).

Backlog after this task: one new issue #N created via github-tickets manifest + apply.sh for the `truncate_display` width-0 bug, registered on Project "All Work" #4 and verified via `apply.sh --verify`; closed automatically by the merged PR's `Closes #N`. No other issues (#37/#41/#43) touched.
