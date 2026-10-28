#!/usr/bin/env bash
# Apply a ticket manifest (YAML) to GitHub: issues, labels, sub-issue links, project.
#
# Why a manifest instead of ad-hoc gh calls: the manifest is a declaration of
# intended end state, so it can be diffed against reality afterwards. That diff
# is what catches a step that failed while earlier steps succeeded -- the exact
# way a tree once landed with every issue created but none on the project board.
#
#   apply.sh --check   tickets.yml   # preflight only: auth, scopes, labels, project
#   apply.sh --plan    tickets.yml   # print what would be created, touch nothing
#   apply.sh           tickets.yml   # create, then verify and report the diff
#   apply.sh --verify  tickets.yml   # verify an existing tree against the manifest
#
# Requires: gh, python3. Manifest schema: see references/manifest.md
set -uo pipefail

# Options are accepted anywhere: `apply.sh tickets.yml --plan` once ran as a
# full apply, because only the first argument was checked for a mode.
MODE=apply
MANIFEST=
for a in "$@"; do
  case "$a" in
    --check)  MODE=check ;;
    --plan)   MODE=plan ;;
    --verify) MODE=verify ;;
    -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
    -*) echo "unknown option: $a" >&2; exit 2 ;;
    *) [ -z "$MANIFEST" ] || { echo "only one manifest, got: $MANIFEST $a" >&2; exit 2; }
       MANIFEST="$a" ;;
  esac
done

[ -n "$MANIFEST" ] || { echo "usage: apply.sh [--check|--plan|--verify] <manifest.yml>" >&2; exit 2; }
[ -f "$MANIFEST" ] || { echo "manifest not found: $MANIFEST" >&2; exit 2; }

# ---- parse manifest into a flat TSV the shell can loop over -------------------
# python3 is used only as a YAML reader; all GitHub work stays in gh.
# miniyaml.py sits next to this script; without this, running apply.sh from
# anywhere but its own directory fails to import it when PyYAML is absent.
export GT_SCRIPTS="${GT_SCRIPTS:-$(cd "$(dirname "$0")" && pwd)}"

read_manifest() {
  python3 - "$MANIFEST" <<'PY'
import sys, json, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(sys.argv[0])) or ".", "."))
try:
    import yaml
    doc = yaml.safe_load(open(sys.argv[1], encoding="utf-8")) or {}
except ImportError:
    # PyYAML is often absent on a bare system, and asking the user to pip
    # install to file a ticket is friction the skill should not impose.
    sys.path.insert(0, os.environ.get("GT_SCRIPTS", ""))
    from miniyaml import load
    doc = load(open(sys.argv[1], encoding="utf-8").read())
repo    = doc.get("repo", "")
# A missing block used to mean "issues only", so forgetting it filed issues
# that never reached the board. Opting out now has to be written: `project: none`.
project = doc.get("project", "missing")
if project == "none":
    project_state, project = "none", {}
elif project == "missing":
    project_state, project = "missing", {}
elif isinstance(project, dict) and project.get("number"):
    project_state = "set"
else:
    sys.exit(f"project must be a block with number (and owner), or 'none'; got {project!r}")
rows, seen, violations = [], set(), []

def as_list(n, field):
    v = n.get(field) or []
    # A string here is iterated character by character, which once created
    # twelve one-letter labels on a real repo. Refuse rather than guess.
    if not isinstance(v, list) or any(isinstance(x, (list, dict)) for x in v):
        sys.exit(f"{field} must be a list of names, got {v!r} (near {n.get('title')!r})")
    return [str(x) for x in v]

def walk(nodes, parent_key, level, depth):
    for i, n in enumerate(nodes or []):
        if not isinstance(n, dict) or "title" not in n:
            sys.exit(f"every node needs a title (near parent {parent_key or 'root'})")
        if not isinstance(n["title"], str):
            # YAML reads `title: [RFC] x` as a list. Quote such titles.
            sys.exit(f"title must be a string; quote it: {n['title']!r}")
        kids = n.get("children") or []
        # Under an Epic, a node that splits further is a Story; one that does
        # not is a Task, the Story's peer. Under a Story, it is a Subtask.
        # An adopted node may be listed without its children, so nesting
        # cannot tell its level; `level:` says it, or no type label is checked.
        if level == "child-of-epic":
            if n.get("level") in ("story", "task"):
                level_here = n["level"]
            elif n.get("issue") and not kids:
                level_here = "adopted"
            else:
                level_here = "story" if kids else "task"
        else:
            level_here = level
        # Top-level nodes of different sections (epics/stories/tasks) must not
        # share a prefix, or a manifest with two sections dies on "duplicate key".
        key = n.get("key") or f"{parent_key or level_here[0]}.{i}"
        if key in seen:
            sys.exit(f"duplicate key: {key}")
        seen.add(key)
        # Count rules apply to new nodes only: an adopted parent may list just
        # the children being added now.
        if not n.get("issue"):
            if level_here in ("epic", "story") and len(kids) < 2:
                fix = "make it a Task" if level_here == "story" else "drop the Epic"
                violations.append(f"{level_here} {n['title']!r} has {len(kids)} child(ren); needs 2+ ({fix})")
            if level_here in ("task", "subtask") and kids:
                violations.append(f"{level_here} {n['title']!r} has children; only Epic and Story split")
        labels = as_list(n, "labels")
        typed = [l for l in labels if l.startswith("type::")]
        if typed:
            sys.exit(f"type:: is set from the manifest's nesting; remove {typed} from {n['title']!r}")
        if level_here != "adopted":
            labels.append(f"type::{level_here}")
        rows.append({
            "key": key, "parent": parent_key or "", "level": level_here,
            "title": n["title"], "body": n.get("body", "") or "",
            "labels": ",".join(labels),
            "assignees": ",".join(as_list(n, "assignees")),
            "milestone": n.get("milestone", "") or "",
            "issue": str(n.get("issue", "") or ""),
            "fields": json.dumps(n.get("fields") or {}, ensure_ascii=False),
            "depth": depth,
        })
        child_level = {"epic": "child-of-epic", "story": "subtask"}.get(level_here, "subtask")
        walk(kids, key, child_level, depth + 1)

walk(doc.get("epics"),   None, "epic",  0)
walk(doc.get("stories"), None, "story", 0)
walk(doc.get("tasks"),   None, "task",  0)
if not rows:
    sys.exit("manifest has no epics/stories/tasks")

print(json.dumps({
    "repo": repo,
    "project_number": str(project.get("number", "") or ""),
    "project_owner": project.get("owner", "") or "",
    "project_state": project_state,
    "rows": rows,
    "violations": violations,
}, ensure_ascii=False))
PY
}

PARSED="$(read_manifest)" || exit 1
jqp() { printf '%s' "$PARSED" | python3 -c "import json,sys;d=json.load(sys.stdin);print($1)"; }

REPO="$(jqp 'd["repo"]')"
PROJ_NUM="$(jqp 'd["project_number"]')"
PROJ_OWNER="$(jqp 'd["project_owner"]')"
PROJ_STATE="$(jqp 'd["project_state"]')"
[ -n "$REPO" ] || REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
[ -n "$REPO" ] || { echo "repo not set in manifest and not inside a gh repo" >&2; exit 2; }

# Empty fields are written as "-" because bash collapses consecutive tabs when
# IFS is whitespace, which silently shifts every later column. A blank issue
# number reading as a title is how duplicate issues get created.
EMPTY='-'
ROWS_TSV="$(printf '%s' "$PARSED" | python3 -c '
import json,sys
d=json.load(sys.stdin)
for r in d["rows"]:
    vals=[]
    for k in ("key","parent","level","title","labels","assignees","milestone","issue","fields","depth"):
        v=str(r[k]).replace("\t"," ").replace("\n"," ").strip()
        vals.append(v if v else "-")
    print("\t".join(vals))
')"
unblank() { [ "$1" = "$EMPTY" ] && printf '' || printf '%s' "$1"; }

# ---- preflight ---------------------------------------------------------------
# Every prerequisite is checked BEFORE the first write. A tree half-created
# because a scope was missing is the failure this whole script exists to prevent.
PREFLIGHT_FAIL=0
note_fail() { echo "  ✗ $1"; PREFLIGHT_FAIL=1; }
note_ok()   { echo "  ✓ $1"; }

preflight() {
  echo "preflight:"
  if gh auth status >/dev/null 2>&1; then note_ok "gh authenticated"; else
    note_fail "gh not authenticated — run: gh auth login"; return; fi

  local scopes; scopes="$(gh auth status 2>&1 | grep -o "'[a-z:,_ ]*'" | tr -d "'" | tr ',' '\n' | tr -d ' ')"
  if grep -qx "repo" <<<"$scopes"; then
    note_ok "scope: repo"
  else
    note_fail "scope: repo missing"
  fi

  if [ -n "$PROJ_NUM" ]; then
    if grep -qx "project" <<<"$scopes"; then
      note_ok "scope: project"
      if gh project view "$PROJ_NUM" --owner "${PROJ_OWNER:-@me}" --format json >/dev/null 2>&1; then
        note_ok "project #$PROJ_NUM reachable"
      else
        note_fail "project #$PROJ_NUM not reachable as ${PROJ_OWNER:-@me}"
      fi
    else
      # This is the exact gap that let a tree land with zero project items.
      note_fail "scope: project missing — the board step WILL fail.
       Run this yourself (interactive browser flow):  gh auth refresh -s project"
    fi
  elif [ "$PROJ_STATE" = none ]; then
    note_ok "project: none (issues only, opted out explicitly)"
  else
    note_fail "no project: block — the issues would never reach a board.
       Add a project: block with number: and owner: under it, or write  project: none
       only when the user asked for issues without a board."
  fi

  # A one-child Story is a Task with extra ceremony, and its parent stays open
  # after the only child closes. Refuse before anything exists.
  while read -r v; do
    [ -n "$v" ] && note_fail "structure: $v"
  done < <(printf '%s' "$PARSED" | python3 -c 'import json,sys;print("\n".join(json.load(sys.stdin)["violations"]))')

  # Created numbers live only for one run, so a rerun would file the whole tree
  # again. An open issue with the same title means this node already exists.
  # Compared as plain strings in bash: awk -v rewrites backslashes and compares
  # number-like titles numerically. A failed listing must not pass as "no dups".
  local open_titles
  if open_titles="$(gh issue list --repo "$REPO" --state open --limit 1000 \
       --json number,title -q '.[]|"\(.number)\t\(.title)"' 2>/dev/null)"; then
    [ "$(grep -c . <<<"$open_titles")" -ge 1000 ] &&
      echo "  · 1000+ open issues: duplicate-title check saw only the first 1000"
    while IFS=$'\t' read -r _k _p _lv title _l _a _m issue _f; do
      [ "$issue" = "-" ] || continue
      while IFS=$'\t' read -r onum otitle; do
        [ "$otitle" = "$title" ] && {
          note_fail "already open as #$onum: $title — put  issue: $onum  on that node"; break; }
      done <<<"$open_titles"
    done <<<"$ROWS_TSV"
  else
    note_fail "cannot list open issues in $REPO — duplicate-title check did not run"
  fi

  # grep -vx '-' strips the placeholder; without it a label named "-" gets created.
  local want; want="$(cut -f5 <<<"$ROWS_TSV" | tr ',' '\n' | sort -u | grep -v '^$' | grep -vx -- '-' || true)"
  local have; have="$(gh label list --repo "$REPO" --limit 200 --json name -q '.[].name' 2>/dev/null || true)"
  while read -r l; do
    [ -z "$l" ] && continue
    grep -qxF "$l" <<<"$have" && note_ok "label: $l" || echo "  · label: $l (will be created)"
  done <<<"$want"
}

preflight
if [ "$MODE" = check ]; then
  [ "$PREFLIGHT_FAIL" -eq 0 ] && echo "preflight OK" || echo "preflight FAILED"
  exit "$PREFLIGHT_FAIL"
fi
# --verify never writes, so it must still run when preflight fails -- diagnosing
# an already-broken tree is exactly when you need it most.
if [ "$PREFLIGHT_FAIL" -ne 0 ] && [ "$MODE" != verify ]; then
  echo
  echo "Refusing to write: fix the above first. Nothing was created." >&2
  echo "(This guard exists because a partial run leaves issues on GitHub that" >&2
  echo " cannot be cleanly undone.)" >&2
  exit 1
fi

# ---- plan --------------------------------------------------------------------
show_plan() {
  echo; echo "plan ($REPO${PROJ_NUM:+, project #$PROJ_NUM}):"
  while IFS=$'\t' read -r _k _p _lv title labels _a _m issue _f depth; do
    labels="$(unblank "$labels")"; issue="$(unblank "$issue")"
    local indent; indent="$(printf '%*s' $((depth * 2 + 2)) '')"
    printf '%s%s %s%s\n' "$indent" "$([ -n "$issue" ] && echo "#$issue" || echo "+")" \
      "$title" "${labels:+  [$labels]}"
  done <<<"$ROWS_TSV"
}
show_plan
[ "$MODE" = plan ] && exit 0

# ---- ensure labels -----------------------------------------------------------
if [ "$MODE" = apply ]; then
  # Canonical labels get their color and description from labels.tsv, so a
  # repo's first ticket leaves the same labels every other repo has.
  LABELS_TSV="$GT_SCRIPTS/labels.tsv"
  while read -r l; do
    [ -z "$l" ] && continue
    spec="$(awk -F'\t' -v n="$l" '$1==n' "$LABELS_TSV")"
    if [ -n "$spec" ]; then
      gh label create "$l" --repo "$REPO" --color "$(cut -f2 <<<"$spec")" \
        --description "$(cut -f3 <<<"$spec")" >/dev/null 2>&1 || true
    else
      gh label create "$l" --repo "$REPO" --color ededed >/dev/null 2>&1 || true
    fi
  done < <(cut -f5 <<<"$ROWS_TSV" | tr ',' '\n' | sort -u | grep -v '^$' | grep -vx -- '-')
fi

# ---- create ------------------------------------------------------------------
STATE="$(mktemp)"; trap 'rm -f "$STATE"' EXIT
node_id() { gh api "repos/$REPO/issues/$1" -q .node_id; }

if [ "$MODE" = apply ]; then
  echo; echo "creating:"
  while IFS=$'\t' read -r key parent _lv title labels assignees milestone issue _; do
    parent="$(unblank "$parent")"; labels="$(unblank "$labels")"; issue="$(unblank "$issue")"
    assignees="$(unblank "$assignees")"; milestone="$(unblank "$milestone")"
    if [ -n "$issue" ]; then
      echo "  #$issue (existing) $title"; printf '%s\t%s\n' "$key" "$issue" >>"$STATE"; continue
    fi
    body="$(printf '%s' "$PARSED" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(next(r['body'] for r in d['rows'] if r['key']=='$key'))")"
    args=(--repo "$REPO" --title "$title" --body "$body")
    IFS=',' read -ra LS <<<"$labels";    for l in "${LS[@]}";  do [ -n "$l" ] && args+=(--label "$l"); done
    IFS=',' read -ra AS <<<"$assignees"; for a in "${AS[@]}";  do [ -n "$a" ] && args+=(--assignee "$a"); done
    [ -n "$milestone" ] && args+=(--milestone "$milestone")

    url="$(gh issue create "${args[@]}")" || { echo "  ✗ failed: $title" >&2; break; }
    num="${url##*/}"
    echo "  #$num $title"
    printf '%s\t%s\n' "$key" "$num" >>"$STATE"
  done <<<"$ROWS_TSV"

  # link children (needs both node IDs, so it runs after all issues exist)
  while IFS=$'\t' read -r key parent _lv title _l _a _m _i _f; do
    parent="$(unblank "$parent")"
    [ -z "$parent" ] && continue
    cnum="$(grep -P "^\Q$key\E\t" "$STATE" | cut -f2)"
    pnum="$(grep -P "^\Q$parent\E\t" "$STATE" | cut -f2)"
    if [ -z "$cnum" ] || [ -z "$pnum" ]; then continue; fi
    # shellcheck disable=SC2016  # $p/$c は GraphQL 変数。シェル展開させない
    link_err="$(gh api graphql -f query='
      mutation($p:ID!,$c:ID!){ addSubIssue(input:{issueId:$p, subIssueId:$c, replaceParent:true}){ clientMutationId } }' \
      -f p="$(node_id "$pnum")" -f c="$(node_id "$cnum")" 2>&1 >/dev/null)"
    if [ -z "$link_err" ]; then
      echo "  linked #$cnum → #$pnum"
    elif grep -qi "duplicate sub-issues" <<<"$link_err"; then
      # Already linked. Re-running a manifest is meant to be safe, so this is
      # not a failure -- reporting it as one trains people to ignore ✗ lines.
      echo "  linked #$cnum → #$pnum (already)"
    else
      echo "  ✗ link failed #$cnum → #$pnum: $link_err" >&2
    fi
  done <<<"$ROWS_TSV"

  # project
  if [ -n "$PROJ_NUM" ]; then
    while IFS=$'\t' read -r key _p _lv _t _l _a _m _i _f; do
      num="$(grep -P "^\Q$key\E\t" "$STATE" | cut -f2)"; [ -z "$num" ] && continue
      gh project item-add "$PROJ_NUM" --owner "${PROJ_OWNER:-@me}" \
        --url "https://github.com/$REPO/issues/$num" >/dev/null 2>&1 \
        && echo "  board += #$num" || echo "  ✗ board add failed #$num" >&2
    done <<<"$ROWS_TSV"
  fi
fi

# ---- verify: compare intended end state against what GitHub actually has -----
# This is the step whose absence let a whole tree sit off the board for a month.
echo; echo "verify:"
FAIL=0
while IFS=$'\t' read -r key parent _lv title labels _a _m issue _f; do
  parent="$(unblank "$parent")"; labels="$(unblank "$labels")"; issue="$(unblank "$issue")"
  num="$issue"
  [ -z "$num" ] && [ -f "$STATE" ] && num="$(grep -P "^\Q$key\E\t" "$STATE" 2>/dev/null | cut -f2 || true)"
  if [ -z "$num" ]; then echo "  ✗ $title — no issue"; FAIL=1; continue; fi

  info="$(gh issue view "$num" --repo "$REPO" --json number,labels,projectItems 2>/dev/null)" || {
    echo "  ✗ #$num unreadable"; FAIL=1; continue; }

  for l in $(tr ',' ' ' <<<"$labels"); do
    [ -z "$l" ] && continue
    grep -q "\"$l\"" <<<"$info" || { echo "  ✗ #$num missing label $l"; FAIL=1; }
  done

  if [ -n "$parent" ]; then
    pnum="$(grep -P "^\Q$parent\E\t" "$STATE" 2>/dev/null | cut -f2 || true)"
    [ -z "$pnum" ] && pnum="$(printf '%s' "$PARSED" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(next((r['issue'] for r in d['rows'] if r['key']=='$parent'), ''))")"
    if [ -n "$pnum" ]; then
      kids="$(gh api graphql -f query="{repository(owner:\"${REPO%%/*}\",name:\"${REPO##*/}\"){issue(number:$pnum){subIssues(first:100){nodes{number}}}}}" \
              -q '.data.repository.issue.subIssues.nodes[].number' 2>/dev/null || true)"
      grep -qx "$num" <<<"$kids" || { echo "  ✗ #$num not linked under #$pnum"; FAIL=1; }
    fi
  fi

  if [ -n "$PROJ_NUM" ]; then
    if grep -q '"projectItems":\[\]' <<<"$info"; then
      echo "  ✗ #$num NOT on project board"; FAIL=1
    fi
  fi
  if [ "$FAIL" -eq 0 ]; then
    echo "  ✓ #$num $title"
  else
    true
  fi
done <<<"$ROWS_TSV"

echo
if [ "$FAIL" -eq 0 ]; then
  echo "verified: manifest matches GitHub."
else
  echo "MISMATCH — the tree on GitHub does not match the manifest (see ✗ above)." >&2
  echo "Report this to the user rather than rerunning; issues already created are not undone by a rerun." >&2
fi
exit "$FAIL"
