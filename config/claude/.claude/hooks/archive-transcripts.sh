#!/usr/bin/env bash
# Archive Claude Code transcripts as zstd-compressed tarballs.
#
# Claude Code deletes ~/.claude/projects/*/<session>.jsonl after
# cleanupPeriodDays (default 30). This keeps a compressed copy of every
# session: <session>.jsonl plus its sidecar directory (subagents, tool results).
#
#   archive-transcripts.sh           SessionEnd hook: start a sweep detached
#                                    and return at once (hook stdin is ignored)
#   archive-transcripts.sh --sweep   archive every transcript that is new or
#                                    changed since its archive, in the foreground
#
# The hook runs on every session end, including tmux kill-session (claude-tower
# D). Each run sweeps all transcripts, so a session missed by a power loss or
# kill -9 is picked up the next time any session ends.
#
# Read an archive:  zstd -dc <id>.tar.zst | tar -xO <id>.jsonl | less
set -euo pipefail

SRC="${CLAUDE_TRANSCRIPT_SRC:-$HOME/.claude/projects}"
DST="${CLAUDE_TRANSCRIPT_ARCHIVE:-$HOME/.claude/transcript-archive}"

if [[ "${1:-}" != "--sweep" ]]; then
  cat >/dev/null || true
  mkdir -p "$DST"
  setsid nohup "$0" --sweep >>"$DST/archive.log" 2>&1 </dev/null &
  exit 0
fi

mkdir -p "$DST"
exec 9>"$DST/.lock"
flock 9   # one sweep at a time; a waiting sweep still sees the newest files

shopt -s nullglob
for jsonl in "$SRC"/*/*.jsonl; do
  proj_dir=$(dirname "$jsonl")
  proj=$(basename "$proj_dir")
  id=$(basename "$jsonl" .jsonl)

  # Keep one archive per session even if it is resumed in a later month.
  existing=("$DST/$proj"/*/"$id.tar.zst")
  if (( ${#existing[@]} )); then
    out=${existing[0]}
  else
    out="$DST/$proj/$(date -r "$jsonl" +%Y-%m)/$id.tar.zst"
  fi

  members=("$id.jsonl")
  [[ -d "$proj_dir/$id" ]] && members+=("$id")

  if [[ -e "$out" ]] && [[ -z "$(find "$jsonl" "${members[@]/#/$proj_dir/}" \
        -newer "$out" -print -quit 2>/dev/null)" ]]; then
    continue
  fi

  mkdir -p "$(dirname "$out")"
  tmp="$out.tmp.$$"
  # A live session may append while tar reads; tar exits 1 for that and the
  # snapshot is still valid (the next sweep refreshes it).
  set +e
  tar --warning=no-file-changed -C "$proj_dir" -cf - "${members[@]}" \
    | zstd -q -19 -T0 -o "$tmp"
  st=("${PIPESTATUS[@]}")
  set -e
  if (( st[0] <= 1 && st[1] == 0 )); then
    mv -f "$tmp" "$out"
    echo "$(date -Is) archived $proj/$id"
  else
    rm -f "$tmp"
    echo "$(date -Is) FAILED $proj/$id" >&2
  fi
done
