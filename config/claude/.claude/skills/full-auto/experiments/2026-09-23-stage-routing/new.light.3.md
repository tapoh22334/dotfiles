1. `gh issue list --state open --search "truncate_display"` — check for an existing ticket matching this bug before creating one.
2. Since no existing issue matches (#37/#41/#43 are unrelated), decide via provisional ruling: this is a 1-function bug fix (no new behavior, no new screen/command, single file touched, one acceptance condition) → route through github-tickets (manifest + `apply.sh`), not vf-pipeline.
3. structuring-work — draft a minimal single-Task manifest (no Epic, per `[[no-epic-for-small-trees]]`) for "truncate_display outputs a digit when width is 0."
4. github-tickets `apply.sh` — apply the manifest to create the issue and register it on Project "All Work" (#4); verify with `apply.sh --verify`.
5. `git checkout -b fix/truncate-display-zero-width` — create a branch off `main` (never commit directly to main).
6. superpowers:test-driven-development — write a failing bats test in `tests/` reproducing `truncate_display` emitting a digit at width 0 (RED).
7. superpowers:test-driven-development — fix `truncate_display` in `navigator-list.sh` to handle width 0 correctly (GREEN).
8. Run `make lint` and `make test` to confirm no regressions; if pre-existing failures appear, compare against baseline per `[[tower-suite-preexisting-failures]]` before attributing anything to this change.
9. tower-reviewer — run the project review agent on the diff (required before any PR touching `tmux-plugin/`); fix any CONFIRMED findings.
10. Commit the fix and test with a message describing why (width-0 case was truncating into invalid substring/digit output).
11. `gh pr create` — open PR against `main`, body explains why (root cause of the width-0 bug), references the issue with `Closes #<new-issue-number>`.
12. Wait for CI, inspect results; do not merge while red. If red, classify failures (pre-existing vs. regression) using the same baseline check from step 8.
13. Merge PR via GitHub (not local `git merge`+push) once CI is green.
14. github-tickets `apply.sh --verify` (or item-list) — confirm the issue is on the Project board and gets closed automatically via the PR's `Closes #N`.

Backlog after this task: one new issue created via github-tickets manifest + `apply.sh` for the `truncate_display` width-0 bug; verified on Project "All Work" (#4) via `apply.sh --verify`; closed automatically by the merged PR's `Closes #N`. No existing issue (#37/#41/#43) reused.
