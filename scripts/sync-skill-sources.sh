#!/usr/bin/env bash
# sync-skill-sources.sh — 台帳(config/claude/.claude/skill-sources.yml)どおりに
# 外部 repo のスキルを揃え、台帳に無いスキルを警告する。
#
#   scripts/sync-skill-sources.sh          # clone(無ければ)→ 配置 → 検査
#   scripts/sync-skill-sources.sh --check  # 検査だけ。警告があれば終了コード 1
#
# 台帳の読み取りは python3 の小さなパーサで行う(PyYAML 不要。台帳の形式は
# ファイル冒頭のコメントの範囲に限る)。
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="$DOTFILES/config/claude/.claude/skill-sources.yml"
SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
OWN_SKILLS="$DOTFILES/config/claude/.claude/skills"
CHECK_ONLY=0
[[ "${1:-}" == "--check" ]] && CHECK_ONLY=1

warn_count=0
warn() { echo "  ⚠️  $*"; warn_count=$((warn_count + 1)); }
ok() { echo "  ✅ $*"; }

# 台帳 → 行(区切りは US = \x1f。タブは IFS の空白扱いで空欄が潰れる):
#   "source<US>name<US>repo<US>path<US>install<US>link(k=v,...)<US>skills(a,b,...)"
#   "unmanaged<US>name"
_parse_registry() {
    python3 - "$REGISTRY" <<'PY'
import re, sys
src = {}
cur = None
section = None
for raw in open(sys.argv[1], encoding="utf-8"):
    line = raw.split("#", 1)[0].rstrip()
    if not line.strip():
        continue
    if re.match(r"^sources:\s*$", line):
        section = "sources"; continue
    if re.match(r"^unmanaged:\s*$", line):
        section = "unmanaged"; continue
    if section == "unmanaged":
        m = re.match(r"^\s*-\s*(\S+)", line)
        if m:
            print("unmanaged\x1f" + m.group(1))
        continue
    if section != "sources":
        continue
    m = re.match(r"^\s*-\s*name:\s*(\S+)", line)
    if m:
        cur = {"name": m.group(1), "repo": "", "path": "", "install": "", "link": {}, "skills": []}
        src[cur["name"]] = cur
        continue
    if cur is None:
        continue
    m = re.match(r"^\s*(repo|path|install):\s*(\S+)", line)
    if m:
        cur[m.group(1)] = m.group(2); continue
    m = re.match(r"^\s*skills:\s*\[(.*)\]", line)
    if m:
        cur["skills"] = [s.strip() for s in m.group(1).split(",") if s.strip()]; continue
    m = re.match(r"^\s{6,}(\S+):\s*(\S+)", line)
    if m:
        cur["link"][m.group(1)] = m.group(2); continue
for s in src.values():
    link = ",".join(f"{k}={v}" for k, v in s["link"].items())
    print("\x1f".join(["source", s["name"], s["repo"], s["path"], s["install"], link, ",".join(s["skills"])]))
PY
}

expand_home() { printf '%s' "${1/#\~/$HOME}"; }

echo "🧩 Claude skill sources ($REGISTRY)"
declare -a expected=()
declare -a unmanaged=()
while IFS=$'\x1f' read -r kind name repo path install link skills; do
    if [[ "$kind" == "unmanaged" ]]; then
        unmanaged+=("$name")
        continue
    fi
    [[ "$kind" == "source" ]] || continue
    path=$(expand_home "$path")
    IFS=',' read -r -a skill_names <<<"$skills"
    expected+=("${skill_names[@]}")

    if [[ ! -d "$path" ]]; then
        if ((CHECK_ONLY)); then
            warn "$name: $path が無い(clone されていない)"
            continue
        fi
        echo "  ⬇️  $name: git clone $repo → $path"
        if ! git clone -q "git@github.com:${repo}.git" "$path"; then
            warn "$name: clone に失敗 ($repo)"
            continue
        fi
    fi

    if ((!CHECK_ONLY)); then
        if [[ -n "$install" ]]; then
            if ! (cd "$path" && "./$install" >/dev/null); then
                warn "$name: $install が失敗"
            fi
        fi
        if [[ -n "$link" ]]; then
            IFS=',' read -r -a pairs <<<"$link"
            for kv in "${pairs[@]}"; do
                ln -sfn "$path/${kv#*=}" "$SKILLS_DIR/${kv%%=*}"
            done
        fi
    fi

    missing=()
    for s in "${skill_names[@]}"; do
        [[ -e "$SKILLS_DIR/$s/SKILL.md" ]] || missing+=("$s")
    done
    if ((${#missing[@]})); then
        warn "$name: 台帳にあるのに配置されていない: ${missing[*]}"
    else
        ok "$name: ${#skill_names[@]} skill(s)"
    fi
done < <(_parse_registry)

# 台帳に無いスキル: dotfiles 所有でも、台帳の repo 所有でもないもの。
stray=()
for entry in "$SKILLS_DIR"/*/; do
    [[ -d "$entry" ]] || continue
    name=$(basename "$entry")
    [[ "$name" == *-workspace ]] && continue
    [[ -e "$entry/SKILL.md" ]] || continue
    [[ -e "$OWN_SKILLS/$name" ]] && continue
    listed=0
    for s in "${expected[@]}" "${unmanaged[@]}"; do
        [[ "$s" == "$name" ]] && listed=1
    done
    ((listed)) || stray+=("$name → $(readlink -f "$entry" 2>/dev/null || echo '?')")
done
if ((${#stray[@]})); then
    for s in "${stray[@]}"; do
        warn "台帳に無いスキル: $s(skill-sources.yml に載せるか、dotfiles へ移す)"
    done
else
    ok "台帳に無いスキルは無い"
fi

if ((warn_count)); then
    echo "  → 警告 $warn_count 件"
    ((CHECK_ONLY)) && exit 1
fi
exit 0
