#!/usr/bin/env bash
# 秘密情報の流出を防ぐ仕組みを、この clone と $HOME に適用する。何度実行してもよい。
#   - フック(.githooks/)を有効にする
#   - settings.json の clean フィルタを登録する(.gitattributes が参照する)
#   - repo 外の秘密ファイルを本人以外から読めないようにする
set -euo pipefail

cd "$(dirname "$0")/.."

git config core.hooksPath .githooks
git config filter.strip-claude-env.clean 'scripts/claude-env-filter.sh clean'
git config filter.strip-claude-env.smudge 'scripts/claude-env-filter.sh smudge'
# jq がないときにフィルタを素通りさせず、コミットを失敗させる
git config filter.strip-claude-env.required true

for cmd in gitleaks jq; do
  command -v "$cmd" >/dev/null 2>&1 || echo "⚠️  $cmd が見つからない。コミットがフックで止まる(brew bundle で入る)" >&2
done

secret_paths=(
  "$HOME/.env_file"
  "$HOME/.secrets"
  "$HOME/.ssh"
  "$HOME/.gnupg"
  "$HOME/.gitconfig.local"
  "$HOME/.claude/.credentials.json"
  "$HOME/.config/gh/hosts.yml"
)
for path in "${secret_paths[@]}"; do
  [ -e "$path" ] || continue
  # 公開鍵(*.pub)は読めてよい。-perm /077 は macOS の find が受け付けないので展開して書く。
  # 1 件の失敗で setup.sh 全体を止めず、警告にとどめる
  find -H "$path" ! -name '*.pub' \
    \( -perm -040 -o -perm -020 -o -perm -010 -o -perm -004 -o -perm -002 -o -perm -001 \) \
    -print -exec chmod go-rwx {} + | sed 's/^/🔒 本人以外の権限を外した: /' ||
    echo "⚠️  $path の権限を直せなかった" >&2
done
