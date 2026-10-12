1. Check open issues for overlap: reuse #37 (Tail/Queue/Tile→Navigator nesting) as the parent problem context, since this feature removes the separate-window jump that causes it.
2. `gh issue create` — new Story: "Tail ビューを左ペインの表示モードとして実装する（別窓ジャンプを廃止）", body notes it supersedes/relates to #37's nesting symptom.
3. github-tickets apply.sh — register the new issue manifest entry on Project "All Work" (#4), verify placement.
4. vf-pipeline (orient → articulate → requirements → userflows) — clarify current Tail-as-separate-window behavior vs. target left-pane display-mode behavior, and produce acceptance criteria before touching code.
5. superpowers:systematic-debugging — trace the existing "別窓に飛ばされて戻ると Navigator が入れ子になる" flow to find the exact call path that spawns the new window/client.
6. superpowers:test-driven-development — write failing bats test(s) in tests/integration/ asserting Tail renders in the left pane in-place (no new tmux window/client, no re-attach nesting) before implementation.
7. Implement the fix in tmux-plugin/scripts (and lib/ as needed) per vf-pipeline's construct stage, satisfying the new tests.
8. Run `make test` and `make lint` locally; fix failures.
9. tower-reviewer — run the project review agent on the diff per CLAUDE.md before opening the PR.
10. Address tower-reviewer findings (fix nesting/state-file/echo-cursor classes it flags).
11. Commit on feature branch, push, open PR via `gh pr create` referencing the new issue (and #37 if the nesting symptom is resolved by this change).
12. Monitor CI (background poll, not a blocking wait-and-stop); on green, report status — do not merge myself since PR merge is an outward-facing action requiring confirmation.
13. Comment on and close the new issue (and comment on #37 noting whether this change resolves its nesting symptom, without closing #37 unless the fix fully covers it) once PR is confirmed mergeable.

Backlog after this task: 1 new issue created for the Tail-left-pane Story (registered on Project "All Work" #4 via github-tickets apply.sh); #37 referenced/commented but left open pending confirmation it's fully resolved; #41 and #43 untouched.
