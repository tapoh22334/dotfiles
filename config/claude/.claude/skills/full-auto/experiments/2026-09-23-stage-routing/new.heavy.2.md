1. Reuse #37 — comment "着手: Tail を左ペイン表示モード化として対応" on the existing issue (symptom already tracked: Navigator nesting after Queue/Tail/Tile).
2. github-tickets apply.sh — verify #37 is on Project "All Work" #4; if not, add it via manifest (not a new issue).
3. vf-pipeline (orient → articulate → requirements → userflows → harness → construct → acceptance → trace) — this is new user-facing behavior (Tail becomes an in-pane display mode instead of a separate window) touching multiple files (navigator display logic, pane-switch handling, state files per [[tower-nav-shared-state-files]]) and eliminates the nesting bug as a side effect: qualifies as "実装(重)".
4. superpowers:systematic-debugging — before construct, root-cause why returning from the separate Tail window re-enters Navigator/nests attach ([[tower-nav-shared-state-files]] and [[tmux-window-target-by-index]] memories flag stale client/window-target issues as the likely mechanism).
5. TDD (superpowers:test-driven-development) inside vf-pipeline's harness/construct stages — RED test reproducing the nesting on branch, then GREEN implementing Tail as in-pane mode.
6. Run `make test` and `make lint` — capture actual output as evidence per full-auto self-verification (no trusting subagent "DONE").
7. tower-reviewer — run against the diff before opening PR, per project CLAUDE.md.
8. Fix any CONFIRMED findings from tower-reviewer, re-run `make test`/`make lint`.
9. Open PR from current branch `fix/settle-not-in-subshell`... — wait, this work is unrelated to that branch's fix; create a new branch (e.g. `fix/tail-inpane-mode`) off `main`, commit there instead (per CLAUDE.md: no direct main commits, work happens on a branch per topic).
10. PR body states why (nesting bug + separate-window UX problem), includes `Closes #37`; do not merge — wait for CI, check baseline vs current failures per [[tower-suite-preexisting-failures]] before judging any red CI as regression or pre-existing.
11. Do not close #37 manually — closes via PR merge per `Closes #37`.

Backlog after this task: issue #37 reused (existing, on Project "All Work" #4 — verified via apply.sh in step 2); no new issues created.
