#!/usr/bin/env bash
# Claude Code statusline: record subscription rate-limit usage for proactive-work's gate.
# rate_limits reaches only the interactive statusline, never `claude -p`, so this is
# the sole source of the usage numbers. Prints "<model> 5h:<n>% 7d:<n>%".
set -u
dir="${CLAUDE_USAGE_DIR:-$HOME/.local/state/claude-usage}"
input=$(cat)

model=$(jq -r '.model.display_name // "?"' <<<"$input" 2>/dev/null)
limits=$(jq -c --argjson ts "$(date +%s)" \
  'select(.rate_limits.seven_day != null)
   | {ts: $ts, five_hour: .rate_limits.five_hour, seven_day: .rate_limits.seven_day}' \
  <<<"$input" 2>/dev/null)

if [ -n "$limits" ]; then
  mkdir -p "$dir"
  printf '%s\n' "$limits" >"$dir/latest.json"
  last=$(tail -n 1 "$dir/snapshots.jsonl" 2>/dev/null | jq -r '.ts // 0' 2>/dev/null)
  now=$(date +%s)
  if [ $((now - ${last:-0})) -ge 300 ]; then
    printf '%s\n' "$limits" >>"$dir/snapshots.jsonl"
  fi
  printf '%s %s\n' "$model" "$(jq -r '"5h:\(.five_hour.used_percentage // "-" | tostring | .[0:4])% 7d:\(.seven_day.used_percentage | tostring | .[0:4])%"' <<<"$limits")"
else
  printf '%s\n' "$model"
fi
