#!/usr/bin/env bash
# Wire proactive-work into this machine: statusline snapshot, digest label, systemd timer.
# Idempotent. Expects the skill at ~/.claude/skills/proactive-work (stow from ~/.dotfiles).
set -euo pipefail

SKILL="$HOME/.claude/skills/proactive-work"
SETTINGS="$HOME/.claude/settings.json"
REPO="${PW_DIGEST_REPO:-tapoh22334/proactive-digest}"
UNITS="$HOME/.config/systemd/user"

[ -x "$SKILL/bin/run.sh" ] || { echo "skill not found at $SKILL (run stow first)" >&2; exit 1; }

# statusline: the only place rate-limit usage is exposed
current=$(jq -r '.statusLine.command // empty' "$SETTINGS")
if [ -z "$current" ]; then
  tmp=$(mktemp)
  jq --arg c "$SKILL/bin/usage-snapshot.sh" '.statusLine = {type: "command", command: $c}' "$SETTINGS" >"$tmp"
  cat "$tmp" >"$SETTINGS"   # write through the stow symlink
  rm -f "$tmp"
  echo "statusLine -> usage-snapshot.sh"
elif [ "$current" != "$SKILL/bin/usage-snapshot.sh" ]; then
  echo "statusLine already set to '$current'; make it also call usage-snapshot.sh" >&2
fi

gh label create digest -R "$REPO" --color 0E8A16 --description "proactive-work digest" 2>/dev/null || true

mkdir -p "$UNITS"
install -m 644 "$SKILL/systemd/proactive-work.service" "$SKILL/systemd/proactive-work.timer" "$UNITS/"
systemctl --user daemon-reload
systemctl --user enable --now proactive-work.timer
systemctl --user list-timers proactive-work.timer --no-pager
