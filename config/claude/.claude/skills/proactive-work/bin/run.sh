#!/usr/bin/env bash
# proactive-work: spend expiring Claude quota on maintenance proposals nobody asked for.
# gate -> billing guard -> reap answers -> collect facts -> judge (read-only LLM) -> post one digest.
# Only this script writes (issue, ledger); the model gets Read/Grep/Glob and no MCP.
#
#   run.sh             normal run (gate decides)
#   run.sh --force     skip the gate (manual run)
#   run.sh --dry-run   print the digest instead of posting; no reap, no run record
set -euo pipefail

HERE=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
STATE="${PW_STATE_DIR:-$HOME/.local/state/proactive-work}"
RUNDIR="$STATE/proactive-work-run"      # name is gate.py's OWN_RUN_MARKER
CLAUDE="${PW_CLAUDE_BIN:-$HOME/.local/bin/claude}"
REPO="${PW_DIGEST_REPO:-tapoh22334/proactive-digest}"
MODEL=sonnet
JOB=git-hygiene

force=0 dry=0
for a in "$@"; do
  case "$a" in
    --force) force=1 ;;
    --dry-run) dry=1 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

mkdir -p "$RUNDIR"
exec 9>"$STATE/lock"
flock -n 9 || { echo "another run holds the lock" >&2; exit 0; }

log() { echo "[proactive-work] $*" >&2; }
tmp=$(mktemp -d)
stage=start window=0

record() {  # status [extra-json]
  [ "$dry" -eq 1 ] && return 0
  local extra=${2:-'{}'}
  jq -nc --arg s "$1" --arg st "$stage" --argjson w "$window" --argjson x "$extra" \
    '{ts: now|floor, status: $s, stage: $st, window_resets_at: $w} + $x' >>"$STATE/runs.jsonl"
}
on_exit() {
  local rc=$?
  [ "$rc" -ne 0 ] && record failed
  rm -rf "$tmp"
  exit "$rc"
}
trap on_exit EXIT

# 1. gate
stage=gate
gate_rc=0
gate_json=$(python3 "$HERE/bin/gate.py") || gate_rc=$?
window=$(jq '.metrics.window_resets_at // 0' <<<"$gate_json" 2>/dev/null || echo 0)
if [ "$gate_rc" -ge 2 ] || [ -z "$gate_json" ]; then
  log "gate crashed (rc=$gate_rc): $gate_json"; exit 1          # recorded as failed
fi
if [ "$gate_rc" -ne 0 ] && [ "$force" -eq 0 ]; then
  log "gate closed: $gate_json"
  exit 0
fi

# 2. billing guard: never fall through to metered API billing
stage=billing
[ -z "${ANTHROPIC_API_KEY:-}" ] || { log "ANTHROPIC_API_KEY is set; refusing (would bill the API)"; exit 1; }
[ "$(jq -r '.apiKeyHelper // empty' "$HOME/.claude/settings.json" 2>/dev/null)" = "" ] ||
  { log "apiKeyHelper is configured; refusing"; exit 1; }
auth=$("$CLAUDE" auth status)
jq -e '.authMethod == "claude.ai" and .subscriptionType == "max"' <<<"$auth" >/dev/null ||
  { log "not on the claude.ai Max subscription: $auth"; exit 1; }

# 3. reap last digests' answers into the ledger
stage=reap
: >"$tmp/reap.json"
if [ "$dry" -eq 0 ]; then
  gh issue list -R "$REPO" --label digest --state all --limit 50 --json number,state,createdAt,body |
    python3 "$HERE/bin/reap.py" reap "$STATE/ledger.jsonl" >"$tmp/reap.json"
  for n in $(jq -r '.to_close[]' "$tmp/reap.json"); do
    gh issue close -R "$REPO" "$n" -c "14 日間回答が無かったため未回答として閉じます。" >/dev/null
  done
fi
python3 "$HERE/bin/reap.py" suppressed "$STATE/ledger.jsonl" >"$tmp/suppressed.txt"
[ -s "$tmp/reap.json" ] && jq -r '.open_keys[]' "$tmp/reap.json" >>"$tmp/suppressed.txt"
python3 "$HERE/bin/reap.py" stats "$STATE/ledger.jsonl" >"$tmp/stats.json"

# 4. collect facts; anything touched in the last 24h is work in progress, not a leftover
stage=collect
"$HERE/jobs/$JOB/collect.sh" | jq --argjson cutoff "$(( $(date +%s) - 86400 ))" '
  map(if .uncommitted and .uncommitted.newest_mtime > $cutoff then .uncommitted = null else . end
      | if .default_branch_local_commits and .default_branch_local_commits.newest_commit > $cutoff
        then .default_branch_local_commits = null else . end
      | if .stashes and .stashes.newest > $cutoff then .stashes = null else . end
      | .unpushed_branches |= map(select(.newest_commit <= $cutoff)))
  | map(select(.uncommitted or .default_branch_local_commits or .stashes
               or (.unpushed_branches | length > 0) or (.merged_branches | length > 0)
               or (.prunable_worktrees | length > 0)))
  | walk(if type == "object" then with_entries(
      if (.key | startswith("newest")) and (.value | type == "number") and .value > 0
      then .value |= (todate | .[0:10]) else . end) else . end)' >"$tmp/facts.json"
if [ "$(jq length "$tmp/facts.json")" -eq 0 ]; then
  log "nothing to report"; record empty; exit 0
fi

# 5. judge: read-only tools, no MCP, subscription auth (never --bare: it forces API-key auth)
stage=judge
{ cat "$HERE/jobs/$JOB/prompt.md"; printf '\n## facts\n\n```json\n'; cat "$tmp/facts.json"; printf '```\n'; } >"$tmp/prompt.md"
# facts can outgrow a single argv entry (128 KiB), so the prompt goes through stdin
deny=$(jq -nc --arg h "$HOME" '{permissions: {deny: [
  "Read(/\($h)/.ssh/**)", "Read(/\($h)/.gnupg/**)", "Read(/\($h)/.config/**)", "Read(/\($h)/.aws/**)",
  "Read(/\($h)/.netrc)", "Read(/\($h)/.claude/.credentials.json)", "Read(/\($h)/.local/share/keyrings/**)",
  "Read(**/.env)", "Read(**/.env.*)"]}}')
(cd "$RUNDIR" && "$CLAUDE" -p \
  --model "$MODEL" --max-turns 10 --max-budget-usd 3 --output-format json \
  --tools "Read,Grep,Glob" --strict-mcp-config --settings "$deny" \
  --json-schema "$(cat "$HERE/jobs/$JOB/schema.json")" <"$tmp/prompt.md") >"$tmp/out.json"
jq -e '.subtype == "success" and (.structured_output.proposals | type == "array")' "$tmp/out.json" >/dev/null ||
  { log "judge failed: $(jq -c '{subtype, result}' "$tmp/out.json")"; exit 1; }
models=$(jq -r '.modelUsage | keys | join(",")' "$tmp/out.json")
[[ "$models" =~ ^(claude-sonnet[^,]*)(,claude-sonnet[^,]*)*$ ]] ||
  { log "unexpected model(s): $models"; exit 1; }
cost=$(jq '.total_cost_usd' "$tmp/out.json")
jq '.structured_output.proposals' "$tmp/out.json" >"$tmp/proposals.json"

# 6. render and post one digest (silence is a valid outcome)
stage=post
jq -n --arg m "$models" --argjson c "$cost" --argjson g "$gate_json" --argjson f "$force" \
  '{model: $m, cost_usd_list_price: $c, surplus: $g.metrics.surplus, forced: ($f == 1)}' >"$tmp/meta.json"
notices=()
last=$(tail -n 1 "$STATE/runs.jsonl" 2>/dev/null || true)
[ "$(jq -r '.status // empty' <<<"$last" 2>/dev/null)" = failed ] &&
  notices+=("前回の実行が失敗しました(段階: $(jq -r .stage <<<"$last"))。journalctl --user -u proactive-work を確認してください。")
[ "$(date +%d)" -le 7 ] &&
  notices+=("月初の確認: claude -p の課金ポリシーに変更が無いか https://support.claude.com/en/articles/15036540 を確認してください。")
python3 "$HERE/bin/digest.py" "$JOB" "$tmp/proposals.json" "$tmp/suppressed.txt" "$tmp/stats.json" \
  "$tmp/meta.json" "${notices[@]}" >"$tmp/body.md"

if [ ! -s "$tmp/body.md" ]; then
  log "no proposals survived"; record empty "$(jq -c '{cost_usd: .cost_usd_list_price, model}' "$tmp/meta.json")"; exit 0
fi
if [ "$dry" -eq 1 ]; then cat "$tmp/body.md"; exit 0; fi

url=$(gh issue create -R "$REPO" --label digest \
  --title "proactive-work ダイジェスト $(date +%F)" --body-file "$tmp/body.md")
log "posted $url"
record posted "$(jq -c --arg u "$url" '{url: $u, cost_usd: .cost_usd_list_price, model}' "$tmp/meta.json")"
