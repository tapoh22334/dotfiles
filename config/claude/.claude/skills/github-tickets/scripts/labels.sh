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
[ "${1:-}" = --dry-run ] && { DRY=1; shift; }
[ $# -gt 0 ] || { sed -n '2,8p' "$0"; exit 2; }

TSV="$(dirname "$0")/labels.tsv"
run() { if [ "$DRY" -eq 1 ]; then echo "    (dry) $*"; else "$@" >/dev/null; fi; }

FAIL=0
for repo in "$@"; do
  echo "$repo:"
  have="$(gh label list --repo "$repo" --limit 200 --json name -q '.[].name')" || {
    echo "  ✗ cannot list labels"; FAIL=1; continue; }

  if grep -qxF bug <<<"$have" && ! grep -qxF 'kind::bug' <<<"$have"; then
    run gh label edit bug --repo "$repo" --name 'kind::bug' && echo "  ~ bug → kind::bug"
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
