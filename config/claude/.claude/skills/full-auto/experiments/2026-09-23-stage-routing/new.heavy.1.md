1. `gh issue list --state open --search "Tail"` then `gh issue list --state open --search "入れ子"` — check for an existing ticket before creating one.
2. Reuse #37 (Queue/Tail/Tile から戻ると Navigator が入れ子になる) — comment on it that work is starting, since this task both fixes its symptom and changes Tail's display mode.
3. github-tickets apply.sh — add a child Task under #37 (or a linked Task if no parent structure exists yet) for "Tail を別窓ではなく左ペイン表示モードにする", via manifest so it lands on Project #4 and is verified.
4. vf-pipeline (orient → articulate → requirements → userflows → harness → construct → acceptance → trace) — this changes a display mode (new pane-mode behavior for Tail, touches multiple tmux-plugin files, promises new behavior to the user), so it meets the "実装(重)" criteria; run the full gate sequence.
5. Within vf-pipeline's construct stage, apply superpowers:test-driven-development (RED → GREEN) for the pane-mode-switch logic and Navigator-state handling touched.
6. superpowers:systematic-debugging — apply while root-causing the current "別窓に飛ばされる" and "入れ子" behavior during orient/construct, since it's an existing bug being fixed, not just new code.
7. tower-reviewer — run against the diff before opening the PR; fix any CONFIRMED findings before proceeding.
8. Open PR against `main` with body explaining why (Tail should behave as an in-place pane mode, not spawn a nested client), referencing `Closes #37` and the new Task issue number; do not merge yet.
9. Wait for CI on the PR; if failing, measure baseline on `main` first (per tower-suite-preexisting-failures memory) to classify regression vs pre-existing before deciding to fix-forward or note as known-flaky.
10. Once CI is green (or failures classified as pre-existing and documented), merge PR via GitHub (squash/merge per repo norm), which auto-closes #37 and the child Task via `Closes #N`.
11. github-tickets apply.sh --verify (or item-list) — confirm #37 and the new Task are on Project #4 and now closed; comment on each with what was fixed and why.

Backlog after this task: reused #37 (closed via PR, comment added with fix rationale) and one new Task issue created via github-tickets manifest for the Tail pane-mode change (child of #37) — both verified on Project "All Work" #4 via apply.sh --verify.
