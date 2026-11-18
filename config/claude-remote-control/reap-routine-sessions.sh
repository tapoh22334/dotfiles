#!/usr/bin/env bash
# claude remote-control (bridge) が routine の実行ごとに起動する子プロセスを片付ける。
#
#   reap-routine-sessions.sh [--dry-run]
#
# 子プロセスは実行が終わっても終了せずに残る(2.1.323 で確認)。bridge は同時に
# 32 セッションまでしか持てないので、毎時の routine が 31 回走ると新しい実行が
# 割り当てられなくなり、「Allocating sandbox」のまま止まる。
#
# 対象は、最初のプロンプトのハッシュ(CLAUDE_CODE_BRIDGE_PROMPT_SHA256)が
# routine-prompt-hashes に載っていて、起動から MAX_AGE 秒以上経った子だけである。
# claude.ai/code から開いた対話用のセッションは、ハッシュが載らないので残す。
# routine のプロンプトを変えるとハッシュも変わる。`--dry-run` で今のハッシュを
# 確かめ、routine-prompt-hashes に足す。
#
# 片付けが効かなくなったとき(ハッシュのずれなど)に気づけるよう、子プロセスが
# WARN_AT 個以上残っていたら notify-human で 1 日 1 回知らせる。
set -euo pipefail

dry_run=0
[ "${1:-}" = --dry-run ] && dry_run=1

here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
hashes_file="${REAP_HASHES_FILE:-$here/routine-prompt-hashes}"
max_age="${REAP_MAX_AGE:-1800}"
warn_at="${REAP_WARN_AT:-24}"
notify_url="${REAP_NOTIFY_URL:-https://github.com/tapoh22334/ops/issues/7}"
stamp="${XDG_STATE_HOME:-$HOME/.local/state}/reap-routine-sessions/notified"

allowed="$(grep -Ev '^[[:space:]]*(#|$)' "$hashes_file" | awk '{print $1}')"

total=0
reaped=0
for pid in $(pgrep -f -- '--sdk-url https://api.anthropic.com/v1/code/sessions/' || true); do
  env_file="/proc/$pid/environ"
  [ -r "$env_file" ] || continue
  envs="$(tr '\0' '\n' < "$env_file" 2>/dev/null || true)"
  grep -qx 'CLAUDE_CODE_ENVIRONMENT_KIND=bridge' <<<"$envs" || continue
  total=$((total + 1))

  hash="$(sed -n 's/^CLAUDE_CODE_BRIDGE_PROMPT_SHA256=//p' <<<"$envs")"
  age="$(ps -o etimes= -p "$pid" | tr -d ' ')"
  session="$(tr '\0' '\n' < "/proc/$pid/cmdline" | awk 'p { print; exit } $0 == "--session-id" { p = 1 }')"

  if [ -z "$hash" ] || ! grep -qx "$hash" <<<"$allowed"; then
    [ "$dry_run" = 1 ] && echo "keep  pid=$pid age=${age}s hash=${hash:-none} $session"
    continue
  fi
  if [ "${age:-0}" -lt "$max_age" ]; then
    [ "$dry_run" = 1 ] && echo "young pid=$pid age=${age}s hash=$hash $session"
    continue
  fi

  if [ "$dry_run" = 1 ]; then
    echo "reap  pid=$pid age=${age}s hash=$hash $session"
  else
    kill -TERM "$pid" 2>/dev/null && echo "reaped pid=$pid age=${age}s $session"
  fi
  reaped=$((reaped + 1))
done

left=$((total - reaped))
echo "bridge children: total=$total reaped=$reaped left=$left"

if [ "$dry_run" = 0 ] && [ "$left" -ge "$warn_at" ]; then
  today="$(date +%F)"
  if [ "$(cat "$stamp" 2>/dev/null || true)" != "$today" ]; then
    mkdir -p "$(dirname "$stamp")"
    if notify-human "$notify_url" "nuc11 の bridge に子プロセスが ${left} 個残っている(上限 32)。routine のプロンプトのハッシュが routine-prompt-hashes とずれていないか確かめる"; then
      echo "$today" > "$stamp"
    fi
  fi
fi
