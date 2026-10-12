1. `gh issue list --state open --search "truncate_display"` — check for an existing ticket (expected: no match among #37/#41/#43, none address truncate_display).
2. Reuse none found → skill github-tickets: write a minimal manifest for one Task-level issue ("navigator-list.sh: truncate_display outputs a digit at width 0") and run `apply.sh` to create it and register it on Project "All Work" (#4).
3. Comment on the new issue marking start of work (作業はチケットから始め).
4. superpowers:systematic-debugging — reproduce the width-0 case for `truncate_display` in navigator-list.sh and localize the exact faulty line/condition.
5. superpowers:test-driven-development — write a failing bats test asserting `truncate_display` at width 0 outputs no digit (RED), then implement the minimal fix (GREEN).
6. Run `make lint` and `make test` to confirm no regressions; if pre-existing failures appear, compare against known baseline (per memory: tower-suite-preexisting-failures) before judging pass/fail.
7. Commit the fix + test on branch `fix/settle-not-in-subshell`... — **provisional ruling**: since current branch is mid-flight on an unrelated fix, create a new branch off `main` (e.g. `fix/truncate-display-width-zero`) for this isolated 1-function bug rather than piggybacking on the unrelated branch; veto-able.
8. Run tower-reviewer agent on the diff (touches `tmux-plugin/`) before opening PR; address any CONFIRMED findings.
9. Open PR via `gh pr create` with body explaining why (digit leaking at width 0) and `Closes #<new-issue-number>`.
10. Monitor CI (`gh pr checks --watch` equivalent) — do not merge on red; if failures exist, classify against measured baseline.
11. Once CI green, merge PR via `gh pr merge` (squash, per repo norm) — this closes the issue automatically.
12. github-tickets `apply.sh --verify` (or item-list) — confirm the issue is on the Project board and now closed.
13. Report: fix summary + test evidence, provisional rulings (new branch instead of reusing current branch; squash merge), backlog status.

Backlog after this task: 1 new issue created via github-tickets manifest + apply.sh (registered on Project "All Work" #4), closed automatically by the PR's `Closes #N`; verified via `apply.sh --verify`.
