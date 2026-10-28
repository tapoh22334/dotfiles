#!/usr/bin/env bash
# Bring repositories' labels in line with labels.tsv (the canonical set).
#
#   labels.sh [--dry-run] owner/repo [owner/repo ...]
#
# GitHub's default `bug` is renamed to `kind::bug` rather than recreated:
# a rename keeps the label on every issue that already carries it, while
# delete-and-create would silently strip it.
set -uo pipefail

DRY=0
REPOS=()
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    -*) echo "unknown option: $a" >&2; exit 2 ;;
    *) REPOS+=("$a") ;;
  esac
done
[ ${#REPOS[@]} -gt 0 ] || { sed -n '2,8p' "$0"; exit 2; }

TSV="$(cd "$(dirname "$0")" && pwd)/labels.tsv"
# </dev/null: gh must never read the TSV that feeds the loop below.
run() { if [ "$DRY" -eq 1 ]; then echo "    (dry) $*"; else "$@" >/dev/null </dev/null; fi; }

FAIL=0
for repo in "${REPOS[@]}"; do
  echo "$repo:"
  have="$(gh label list --repo "$repo" --limit 200 --json name -q '.[].name' </dev/null)" || {
    echo "  ✗ cannot list labels"; FAIL=1; continue; }

  if grep -qxF bug <<<"$have"; then
    if grep -qxF 'kind::bug' <<<"$have"; then
      # Both exist: renaming would collide, and merging means relabeling issues.
      echo "  ✗ both bug and kind::bug exist — move issues to kind::bug, then delete bug"; FAIL=1
    elif run gh label edit bug --repo "$repo" --name 'kind::bug'; then
      echo "  ~ bug → kind::bug"
    else
      echo "  ✗ rename bug → kind::bug failed"; FAIL=1
    fi
  fi

  while IFS=$'\t' read -r name color desc; do
    [ -z "$name" ] && continue
    # --force updates color and description when the label already exists.
    if run gh label create "$name" --repo "$repo" --color "$color" --description "$desc" --force; then
      echo "  ✓ $name"
    else
      echo "  ✗ $name"; FAIL=1
    fi
  done <"$TSV"
done
exit "$FAIL"
