#!/usr/bin/env python3
"""スキル台帳を集める。skill-map が木を描くための素材を JSON で出す。

なぜスクリプトにするか: 供給源が3系統(自作 symlink / value-forge / plugin cache)
あり、plugin 名は frontmatter に無くパスと installed_plugins.json の
突き合わせでしか分からない。毎回 find を組み直すと取りこぼす。

使い方:
  collect_skills.py              # JSON を stdout へ
  collect_skills.py --summary    # 人が読む要約
  collect_skills.py --group <名> # そのグループだけ

出力の各スキル:
  name, source, origin, manifest, invocable, desc_head, path
"""
import argparse
import json
import os
import re
import sys
from pathlib import Path

HOME = Path.home()
SKILLS_DIR = HOME / ".claude" / "skills"
PLUGINS_CACHE = HOME / ".claude" / "plugins" / "cache"
INSTALLED = HOME / ".claude" / "plugins" / "installed_plugins.json"
GROUPS_FILE = Path(__file__).resolve().parent.parent / "references" / "groups.json"


def read_frontmatter(skill_md: Path) -> dict:
    """SKILL.md の YAML frontmatter を最小限パースする。

    pyyaml に依存しないのは、この環境に無いため。必要なキーだけ拾う。
    複数行の description (`>-` 記法) は先頭行のみを取り、
    木に載せる一行要約は別途 groups.json が持つ。
    """
    out = {}
    try:
        text = skill_md.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return out
    if not text.startswith("---"):
        return out
    end = text.find("\n---", 3)
    if end == -1:
        return out
    block = text[3:end]

    key = None
    for raw in block.splitlines():
        if not raw.strip():
            continue
        m = re.match(r"^([a-zA-Z][\w-]*)\s*:\s*(.*)$", raw)
        if m:
            key, val = m.group(1), m.group(2).strip()
            val = val.strip("\"'")
            # 複数行記法は後続行に本体が来る
            out[key] = "" if val in (">-", ">", "|", "|-") else val
        elif key and raw.startswith((" ", "\t")) and not out.get(key):
            # 複数行 description の最初の中身
            out[key] = raw.strip().strip("\"'")
    return out


def one_line(desc: str, limit: int = 78) -> str:
    """description を一行に圧縮する。

    自作スキルの description は中央値 172 字、最長 1349 字あり、
    そのまま木に載せると木が原文より長くなって俯瞰の役に立たない。
    最初の文だけ取り、トリガー語の列挙は落とす。
    """
    if not desc:
        return ""
    d = re.sub(r"\s+", " ", desc).strip()
    # トリガー語の列挙は俯瞰に不要なので切る
    for marker in ("トリガー:", "Trigger on", "Triggers:", "Use when", "Use this"):
        idx = d.find(marker)
        if idx > 20:
            d = d[:idx]
            break
    # 最初の文で切る
    m = re.search(r"^(.{20,}?[。.])\s", d + " ")
    if m:
        d = m.group(1)
    d = d.strip()
    if len(d) > limit:
        d = d[: limit - 1].rstrip() + "…"
    return d


def load_plugin_map() -> dict:
    """installPath → plugin@marketplace の対応を作る。

    frontmatter に plugin 名が無いので、これが唯一の正規の出所。
    """
    mapping = {}
    if not INSTALLED.is_file():
        return mapping
    try:
        data = json.loads(INSTALLED.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return mapping
    for key, entries in data.get("plugins", {}).items():
        for e in entries:
            p = e.get("installPath")
            if p:
                mapping[os.path.realpath(p)] = key
    return mapping


def classify(name: str, groups: dict) -> tuple:
    """分類表を引く。無ければ接頭辞で推定し、印を付ける。"""
    for gname, g in groups.get("groups", {}).items():
        if name in g.get("skills", {}):
            return gname, g["skills"][name], False
    # 表に無いものは接頭辞で推定する。黙って落とさず「未登録」と印を付ける
    for prefix, gname in groups.get("prefix_fallback", {}).items():
        if name.startswith(prefix):
            return gname, "", True
    return groups.get("unclassified_group", "未分類"), "", True


def collect_own(groups: dict) -> list:
    """~/.claude/skills/ 配下。symlink 先で供給源を判別する。"""
    out = []
    if not SKILLS_DIR.is_dir():
        return out
    for entry in sorted(SKILLS_DIR.iterdir()):
        skill_md = entry / "SKILL.md"
        if not skill_md.is_file():
            continue  # *-workspace 等はスキルではない
        if entry.is_symlink():
            target = os.readlink(entry)
            if ".dotfiles" in target:
                source, manifest = "自作", "dotfiles"
            elif "value-forge" in target:
                source, manifest = "自作", "value-forge"
            elif ".agents" in target:
                source, manifest = "公式配布", ".agents"
            else:
                source, manifest = "自作", "symlink"
        else:
            source, manifest = "自作", "未管理"

        fm = read_frontmatter(skill_md)
        name = fm.get("name") or entry.name
        group, summary, unlisted = classify(name, groups)
        out.append({
            "name": name,
            "source": source,
            "origin": "",
            "manifest": manifest,
            "invocable": fm.get("user-invocable", ""),
            "group": group,
            "summary": summary or one_line(fm.get("description", "")),
            "unlisted": unlisted,
            "path": str(entry).replace(str(HOME), "~"),
        })
    return out


def collect_plugins(groups: dict) -> list:
    """installed_plugins.json が指す版だけを見る。

    cache には旧版が残る (chrome-devtools-mcp は4版、多くは5版)。
    cache 全体を rglob すると同名スキルを何重にも数えてしまい、
    「保有スキル数」が実態の数倍に膨らむ。有効なのは installPath の版のみ。

    配置は plugin によって2通りある:
      <installPath>/skills/<name>/SKILL.md   (superpowers 等)
      <installPath>/<name>/SKILL.md          (academic-research-skills)
    """
    out = []
    if not INSTALLED.is_file():
        return out
    try:
        data = json.loads(INSTALLED.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as e:
        print(f"WARN: installed_plugins.json を読めない: {e}", file=sys.stderr)
        return out

    for key, entries in sorted(data.get("plugins", {}).items()):
        plugin = key.split("@")[0]
        marketplace = key.split("@")[-1]
        for e in entries:
            root = Path(e.get("installPath", ""))
            if not root.is_dir():
                continue
            # skills/ 配下を優先し、無ければ直下を見る
            for base in (root / "skills", root):
                if not base.is_dir():
                    continue
                found = sorted(base.glob("*/SKILL.md"))
                if not found:
                    continue
                for skill_md in found:
                    fm = read_frontmatter(skill_md)
                    name = fm.get("name") or skill_md.parent.name
                    group, summary, unlisted = classify(name, groups)
                    out.append({
                        "name": name,
                        "source": "plugin",
                        "origin": plugin,
                        "manifest": marketplace,
                        "invocable": fm.get("user-invocable", ""),
                        "group": group,
                        "summary": summary or one_line(fm.get("description", "")),
                        "unlisted": unlisted,
                        "path": str(skill_md.parent).replace(str(HOME), "~"),
                    })
                break  # 見つかった階層だけを採る
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--summary", action="store_true", help="人が読む要約を出す")
    ap.add_argument("--group", help="このグループだけに絞る")
    ap.add_argument("--source", choices=["自作", "plugin", "公式配布"], help="供給源で絞る")
    args = ap.parse_args()

    groups = {}
    if GROUPS_FILE.is_file():
        try:
            groups = json.loads(GROUPS_FILE.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            print(f"WARN: groups.json を読めない: {e}", file=sys.stderr)

    skills = collect_own(groups) + collect_plugins(groups)
    if args.group:
        skills = [s for s in skills if s["group"] == args.group]
    if args.source:
        skills = [s for s in skills if s["source"] == args.source]

    if not args.summary:
        order = groups.get("group_order", [])
        def sort_key(s):
            gi = order.index(s["group"]) if s["group"] in order else len(order)
            return (gi, s["source"] != "自作", s["origin"], s["name"])
        print(json.dumps({
            "total": len(skills),
            "skills": sorted(skills, key=sort_key),
        }, ensure_ascii=False, indent=2))
        return 0

    # 要約
    by_group = {}
    for s in skills:
        by_group.setdefault(s["group"], []).append(s)
    print(f"スキル {len(skills)} 件")
    print(f"  自作 {sum(1 for s in skills if s['source'] == '自作')}"
          f" / plugin {sum(1 for s in skills if s['source'] == 'plugin')}"
          f" / 公式配布 {sum(1 for s in skills if s['source'] == '公式配布')}")
    unlisted = [s for s in skills if s["unlisted"]]
    if unlisted:
        print(f"  分類表に未登録: {len(unlisted)} 件")
    print()
    order = groups.get("group_order", sorted(by_group))
    for g in order + [k for k in sorted(by_group) if k not in order]:
        if g not in by_group:
            continue
        items = by_group[g]
        print(f"{g} ({len(items)})")
        for s in items:
            mark = " *" if s["unlisted"] else ""
            src = s["origin"] or s["manifest"]
            print(f"  {s['name']:<28} {src:<22}{mark}")
        print()
    if unlisted:
        print("* = 分類表 (references/groups.json) に未登録。接頭辞または未分類へ仮置き")
    return 0


if __name__ == "__main__":
    sys.exit(main())
