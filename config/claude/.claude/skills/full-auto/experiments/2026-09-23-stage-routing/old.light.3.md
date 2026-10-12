1. gh issue list search / grep — check whether truncate_display's width-0 bug matches #37/#41/#43 (it doesn't); no reuse
2. gh issue create — file a new Task-level issue in tapoh22334/claude-tower describing the truncate_display width-0 bug in navigator-list.sh
3. github-tickets apply.sh --verify — register the new issue on Project "All Work" (#4) and confirm placement
4. superpowers:systematic-debugging — reproduce the width-0 case and localize the exact faulty line in truncate_display (navigator-list.sh)
5. superpowers:test-driven-development — write a failing bats test for truncate_display at width 0 (and adjacent edge widths) before touching the fix
6. git checkout -b fix/truncate-display-zero-width — create branch off main (no direct main commits per CLAUDE.md)
7. Apply the minimal fix to truncate_display so width 0 yields empty output instead of a stray digit
8. make test — run bats suite; make lint — shellcheck; compare failures against known baseline (tower-suite-preexisting-failures memory) to separate regressions from pre-existing
9. tower-reviewer agent — run against the diff (touches tmux-plugin/) before opening PR
10. git commit + gh pr create — commit fix+test, open PR against main with rationale ("why", not diff summary) in body
11. Monitor PR CI checks (gh pr checks --watch or poll) — do not merge while red; if red, classify failure (transient/infra/regression) per skill §6 and act accordingly
12. gh pr merge (squash) once CI is green and reviewer pass is clean — merge via PR, not local merge+push
13. gh issue close <new issue#> — close with a comment stating what was wrong and why the fix works, per CLAUDE.md's "close with 何を・なぜ" requirement
14. git branch -d fix/truncate-display-zero-width (local + remote cleanup) — reversible tidy-up, no confirmation needed

Backlog after this task: one new issue created for the truncate_display bug (number known only after step 2 runs), added to Project "All Work" (#4) via apply.sh; #37, #41, #43 untouched and left open.
