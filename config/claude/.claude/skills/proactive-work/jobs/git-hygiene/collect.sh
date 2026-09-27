#!/usr/bin/env bash
# git-hygiene collector: print a JSON array of repositories with leftovers.
# Facts only — no judgement, no LLM, no writes. Clean repositories are omitted.
# Usage: collect.sh [repo-dir ...]   (default: ~/working/* and ~/.dotfiles)
set -u

if [ $# -eq 0 ]; then
  set -- "$HOME"/working/* "$HOME/.dotfiles"
fi

default_branch() {
  local b
  b=$(git -C "$1" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null) && { echo "${b#origin/}"; return; }
  for b in main master; do
    git -C "$1" show-ref -q --verify "refs/heads/$b" && { echo "$b"; return; }
  done
}

newest_mtime() {
  # newest mtime among changed paths (deleted paths are skipped)
  local repo=$1 newest=0 entry path t skip=0
  while IFS= read -r -d '' entry; do
    if [ "$skip" -eq 1 ]; then skip=0; continue; fi   # rename source path
    case "$entry" in R*|C*) skip=1 ;; esac
    path=${entry:3}
    [ -e "$repo/$path" ] || continue
    t=$(stat -c %Y "$repo/$path" 2>/dev/null || echo 0)
    [ "$t" -gt "$newest" ] && newest=$t
  done < <(git -C "$repo" status --porcelain -z --untracked-files=all)
  echo "$newest"
}

collect_repo() {
  local repo=$1 def top uncommitted files local_commits unpushed merged stash_count stash_newest prunable
  top=$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null) || return 0
  [ "$top" = "$(cd "$repo" && pwd -P)" ] || return 0
  git -C "$repo" rev-parse -q --verify HEAD >/dev/null || return 0
  def=$(default_branch "$repo")
  # A linked worktree shares branches and stashes with its main checkout, which is
  # scanned on its own; report only what is local to this directory.
  local linked=false
  [ "$(git -C "$repo" rev-parse --git-dir)" != "$(git -C "$repo" rev-parse --git-common-dir)" ] && linked=true

  files=$(git -C "$repo" status --porcelain --untracked-files=all | wc -l)
  uncommitted=null
  [ "$files" -gt 0 ] && uncommitted=$(jq -n --argjson f "$files" --argjson m "$(newest_mtime "$repo")" \
    '{files: $f, newest_mtime: $m}')

  local_commits=null unpushed='[]' merged='[]' stash_count=0 stash_newest=0 prunable='[]'
  if [ "$linked" = false ]; then
    if [ -n "$def" ] && git -C "$repo" show-ref -q --verify "refs/remotes/origin/$def"; then
      local n
      n=$(git -C "$repo" rev-list --count "origin/$def..$def" 2>/dev/null || echo 0)
      [ "$n" -gt 0 ] && local_commits=$(jq -n --argjson c "$n" --arg b "$def" \
        --argjson t "$(git -C "$repo" log -1 --format=%ct "$def")" '{branch: $b, count: $c, newest_commit: $t}')
    fi

    # branches checked out in any worktree are someone's live work, never leftovers
    local checked_out
    checked_out=$(git -C "$repo" worktree list --porcelain | sed -n 's|^branch refs/heads/||p')

    # without a remote, "not on any remote" is true of every branch and says nothing
    if [ -n "$(git -C "$repo" remote)" ]; then
      unpushed=$(git -C "$repo" for-each-ref --format='%(refname:short)' refs/heads |
        while read -r b; do
          [ "$b" = "$def" ] && continue
          n=$(git -C "$repo" rev-list --count "$b" --not --remotes 2>/dev/null || echo 0)
          [ "$n" -gt 0 ] && jq -n --arg b "$b" --argjson c "$n" \
            --argjson t "$(git -C "$repo" log -1 --format=%ct "$b")" '{branch: $b, commits: $c, newest_commit: $t}'
        done | jq -s .)
    fi

    [ -n "$def" ] && merged=$(git -C "$repo" for-each-ref --format='%(refname:short)' --merged "$def" refs/heads |
      grep -vxF -f <(printf '%s\n' "$def" "$checked_out") | jq -R . | jq -s .)

    stash_count=$(git -C "$repo" stash list | wc -l)
    stash_newest=$(git -C "$repo" log -g -1 --format=%ct refs/stash 2>/dev/null || echo 0)

    prunable=$(git -C "$repo" worktree list --porcelain |
      awk '/^worktree /{p=substr($0,10)} /^prunable/{print p}' | jq -R . | jq -s .)
  fi

  jq -n --arg repo "$top" --arg def "$def" --argjson u "$uncommitted" --argjson l "$local_commits" \
    --argjson up "$unpushed" --argjson m "$merged" --argjson sc "$stash_count" --argjson sn "$stash_newest" \
    --argjson pw "$prunable" --argjson lw "$linked" '
    {repo: $repo, default_branch: $def, linked_worktree: $lw, uncommitted: $u, default_branch_local_commits: $l,
     unpushed_branches: $up, merged_branches: $m,
     stashes: (if $sc > 0 then {count: $sc, newest: $sn} else null end),
     prunable_worktrees: $pw}
    | select(.uncommitted or .default_branch_local_commits or .stashes
             or (.unpushed_branches | length > 0) or (.merged_branches | length > 0)
             or (.prunable_worktrees | length > 0))'
}

for repo in "$@"; do
  [ -d "$repo" ] && collect_repo "$repo"
done | jq -s .
