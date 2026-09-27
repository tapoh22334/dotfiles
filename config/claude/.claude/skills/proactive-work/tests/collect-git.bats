setup() {
  COLLECT="$BATS_TEST_DIRNAME/../jobs/git-hygiene/collect.sh"
  R="$BATS_TEST_TMPDIR"
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  git init -q --bare -b main "$R/origin.git"
  git clone -q "$R/origin.git" "$R/repo" 2>/dev/null
  git -C "$R/repo" commit -q --allow-empty -m init
  git -C "$R/repo" push -q origin main
}

finding() { jq -r --arg k "$1" '.[] | select(.repo | endswith("/repo")) | .[$k]' <<<"$output"; }

@test "clean repo reports nothing" {
  run "$COLLECT" "$R/repo"
  [ "$status" -eq 0 ]
  [ "$(jq length <<<"$output")" -eq 0 ]
}

@test "detects uncommitted changes with age" {
  echo x >"$R/repo/a.txt"
  run "$COLLECT" "$R/repo"
  [ "$(finding uncommitted | jq .files)" -eq 1 ]
  [ "$(finding uncommitted | jq '.newest_mtime > 0')" = true ]
}

@test "detects local-only commits on the default branch" {
  git -C "$R/repo" commit -q --allow-empty -m direct
  run "$COLLECT" "$R/repo"
  [ "$(finding default_branch_local_commits | jq .count)" -eq 1 ]
}

@test "detects unpushed feature branch and merged branch" {
  git -C "$R/repo" switch -q -c feat
  git -C "$R/repo" commit -q --allow-empty -m wip
  git -C "$R/repo" switch -q main
  git -C "$R/repo" branch merged-one
  run "$COLLECT" "$R/repo"
  [ "$(finding unpushed_branches | jq -r '.[0].branch')" = feat ]
  [ "$(finding merged_branches | jq -r '.[0]')" = merged-one ]
}

@test "detects stash and prunable worktree" {
  echo x >"$R/repo/b.txt"; git -C "$R/repo" add b.txt; git -C "$R/repo" stash -q
  git -C "$R/repo" worktree add -q "$R/wt" -b wtb
  rm -rf "$R/wt"
  run "$COLLECT" "$R/repo"
  [ "$(finding stashes | jq .count)" -eq 1 ]
  [ "$(finding prunable_worktrees | jq length)" -eq 1 ]
}

@test "skips non-repositories" {
  mkdir "$R/plain"
  run "$COLLECT" "$R/plain"
  [ "$status" -eq 0 ]
  [ "$(jq length <<<"$output")" -eq 0 ]
}

@test "linked worktree reports only its own uncommitted changes" {
  git -C "$R/repo" commit -q --allow-empty -m direct
  git -C "$R/repo" worktree add -q "$R/wt2" -b wt2b
  echo x >"$R/wt2/c.txt"
  run "$COLLECT" "$R/wt2"
  [ "$(jq '.[0].uncommitted.files' <<<"$output")" -eq 1 ]
  [ "$(jq '.[0].default_branch_local_commits' <<<"$output")" = null ]
  [ "$(jq '.[0].unpushed_branches | length' <<<"$output")" -eq 0 ]
  [ "$(jq -r '.[0].linked_worktree' <<<"$output")" = true ]
}

@test "detached HEAD is not reported as a merged branch" {
  git -C "$R/repo" checkout -q --detach
  run "$COLLECT" "$R/repo"
  [ "$(jq length <<<"$output")" -eq 0 ]
}

@test "branch checked out in a live worktree is not proposed as merged" {
  git -C "$R/repo" worktree add -q "$R/live" -b live-branch
  run "$COLLECT" "$R/repo"
  [ "$(jq length <<<"$output")" -eq 0 ]
}

@test "repo without a remote reports no unpushed branches" {
  git init -q -b main "$R/local"
  git -C "$R/local" commit -q --allow-empty -m init
  git -C "$R/local" switch -q -c topic
  git -C "$R/local" commit -q --allow-empty -m wip
  run "$COLLECT" "$R/local"
  [ "$(jq length <<<"$output")" -eq 0 ]
}
