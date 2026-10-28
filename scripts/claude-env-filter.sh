#!/usr/bin/env bash
# config/claude/.claude/settings.json 用の git フィルタ(.gitattributes から使う)。
#   clean : autoMode.environment を除いてコミットさせる。除いた値は .git/ に退避する
#   smudge: checkout・pull で上書きされたファイルに、退避した値を戻す
# environment は秘密の置き場所と本番名の一覧なので、公開 repo には入れない。
set -euo pipefail
umask 077  # 退避ファイルは秘密の置き場所の一覧なので本人だけが読めるようにする

stash="$(git rev-parse --git-dir)/claude-autoMode-environment.json"
input=$(cat)

case "${1:-}" in
  clean)
    if printf '%s' "$input" | jq -e '.autoMode.environment' >/dev/null 2>&1; then
      printf '%s' "$input" | jq '.autoMode.environment' >"$stash"
    fi
    printf '%s' "$input" | jq --indent 2 'del(.autoMode.environment)'
    ;;
  smudge)
    if [ -s "$stash" ] && printf '%s' "$input" | jq -e '.autoMode' >/dev/null 2>&1; then
      printf '%s' "$input" | jq --indent 2 --slurpfile env "$stash" '.autoMode.environment = $env[0]'
    else
      printf '%s\n' "$input"
    fi
    ;;
  *)
    echo "usage: $0 clean|smudge" >&2
    exit 2
    ;;
esac
