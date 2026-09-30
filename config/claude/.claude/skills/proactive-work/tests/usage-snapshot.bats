setup() {
  export CLAUDE_USAGE_DIR="$BATS_TEST_TMPDIR/usage"
  SCRIPT="$BATS_TEST_DIRNAME/../bin/usage-snapshot.sh"
  WITH='{"model":{"display_name":"Opus"},"rate_limits":{"five_hour":{"used_percentage":23.5,"resets_at":1},"seven_day":{"used_percentage":41.2,"resets_at":2}}}'
}

@test "records a snapshot and prints usage" {
  run bash -c "echo '$WITH' | '$SCRIPT'"
  [ "$status" -eq 0 ]
  [ "$output" = "Opus 5h:23.5% 7d:41.2%" ]
  [ "$(wc -l <"$CLAUDE_USAGE_DIR/snapshots.jsonl")" -eq 1 ]
  jq -e '.seven_day.used_percentage == 41.2 and (.ts > 0)' "$CLAUDE_USAGE_DIR/latest.json"
}

@test "throttles appends within 5 minutes but refreshes latest" {
  echo "$WITH" | "$SCRIPT" >/dev/null
  echo "${WITH/41.2/45}" | "$SCRIPT" >/dev/null
  [ "$(wc -l <"$CLAUDE_USAGE_DIR/snapshots.jsonl")" -eq 1 ]
  jq -e '.seven_day.used_percentage == 45' "$CLAUDE_USAGE_DIR/latest.json"
}

@test "writes nothing without rate_limits" {
  run bash -c "echo '{\"model\":{\"display_name\":\"Opus\"}}' | '$SCRIPT'"
  [ "$output" = "Opus" ]
  [ ! -e "$CLAUDE_USAGE_DIR/snapshots.jsonl" ]
}
