1. `gh issue list --state open --search "truncate_display"` — check for an existing ticket before creating one (none of #37/#41/#43 match; expect no hit)
2. reuse none found → github-tickets: write manifest for a Task-level issue ("navigator-list.sh: truncate_display outputs digits when width is 0") and run `apply.sh` to create it on the Project board with verify
3. Comment on the new issue noting start of work (착수 comment), per "着手前に対象 issue を確認し…着手をコメントし"
4. superpowers:test-driven-development — RED: write/extend a bats test in `tests/` asserting `truncate_display` at width 0 returns empty/no digits, confirm it fails against current code
5. superpowers:test-driven-development — GREEN: fix the width-0 branch in `truncate_display` inside `navigator-list.sh`, rerun the test to confirm it passes
6. `make lint` and `make test` — full local check (baseline-aware only if failures appear; per memory, pre-existing bats failures vary by branch, so if anything fails, diff against current branch baseline before calling it a regression)
7. tower-reviewer — run project review agent on the diff (touches `tmux-plugin/`, mandatory per CLAUDE.md)
8. Fix any CONFIRMED findings from tower-reviewer, rerun `make test`
9. Commit the fix on the current branch `fix/settle-not-in-subshell` — wait, scope mismatch: this is a new unrelated 1-function bug fix, so create a fresh branch off `main` (e.g. `fix/truncate-display-width-zero`) instead of piggybacking on the unrelated in-progress branch
10. `gh pr create` — open PR against `main`, body states why (bug symptom + root cause), references `Closes #<new-issue-number>`
11. Monitor CI on the PR (GitHub Actions: Unit/Integration/Docker/ShellCheck jobs) until it reports back; do not merge while red
12. If CI is green: merge the PR (squash or per repo convention) — this closes the issue automatically via `Closes #`
13. github-tickets `apply.sh --verify` — confirm the issue is on Project "All Work" (#4) and now shows closed
14. Report completion with provisional rulings (new branch name choice, test file location, lint/test baseline treatment) and backlog status

Backlog after this task: created and closed 1 new issue via github-tickets manifest + apply.sh (number known only after step 2 runs); confirmed on Project "All Work" (#4) via apply.sh --verify in step 13. Issues #37/#41/#43 untouched (unrelated).
