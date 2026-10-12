1. gh issue create — file a small bug ticket for `truncate_display` (width-0 → emits digits), body notes it's a 1-function fix; no Epic (per [[no-epic-for-small-trees]] precedent).
2. github-tickets apply.sh — register the new issue on Project "All Work" (#4) and verify placement.
3. superpowers:systematic-debugging — reproduce the width-0 case for `truncate_display` in `tmux-plugin/scripts/navigator-list.sh` and confirm root cause before touching code.
4. superpowers:test-driven-development — write/extend a bats test asserting empty output (not digits) when width is 0, watch it fail, then fix the function.
5. `make lint` — shellcheck the change.
6. `make format` — verify shfmt formatting (fix in-place via `make format-fix` if needed).
7. `make test` — run full bats suite; compare failures against pre-existing baseline (per [[tower-suite-preexisting-failures]]) so no false regression is claimed.
8. tower-reviewer — run the project review agent on the diff before opening the PR.
9. Create branch, commit fix + test — never commit to `main` directly.
10. `gh pr create` — open PR against `main`, body explains why (width-0 truncation bug), referencing the issue for the "why" narrative.
11. Monitor CI (`gh pr checks --watch` or poll) — do not merge until green; if red, classify failure (transient/infra/pre-existing/real regression) before acting.
12. `gh pr merge` — once CI is green and diff reviewed, merge via PR (no direct push/merge to main).
13. `gh issue close` — close the ticket with a comment stating what was wrong and why the fix is correct.

Backlog after this task: one new issue created (for the `truncate_display` width-0 bug), placed on Project "All Work" (#4) via apply.sh; closed by the end of this run. Issues #37, #41, #43 remain open/untouched.
