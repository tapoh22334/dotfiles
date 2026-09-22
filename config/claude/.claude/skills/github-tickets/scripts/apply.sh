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

MODE=apply
case "${1:-}" in
  --check)  MODE=check;  shift ;;
  --plan)   MODE=plan;   shift ;;
  --verify) MODE=verify; shift ;;
  -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
esac

MANIFEST="${1:?usage: apply.sh [--check|--plan|--verify] <manifest.yml>}"
[ -f "$MANIFEST" ] || { echo "manifest not found: $MANIFEST" >&2; exit 2; }

# ---- parse manifest into a flat TSV the shell can loop over -------------------
# python3 is used only as a YAML reader; all GitHub work stays in gh.
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
project = doc.get("project") or {}
rows, seen = [], set()

def walk(nodes, parent_key, level):
    for i, n in enumerate(nodes or []):
        if not isinstance(n, dict) or "title" not in n:
            sys.exit(f"every node needs a title (near parent {parent_key or 'root'})")
        # Top-level nodes of different sections (epics/stories/tasks) must not
        # share a prefix, or a manifest with two sections dies on "duplicate key".
        key = n.get("key") or f"{parent_key or level[0]}.{i}"
        if key in seen:
            sys.exit(f"duplicate key: {key}")
        seen.add(key)
        labels = list(n.get("labels") or [])
        default = {"epic": "type::epic", "story": "type::story"}.get(level)
        if default and default not in labels:
            labels.append(default)
        rows.append({
            "key": key, "parent": parent_key or "", "level": level,
            "title": n["title"], "body": n.get("body", "") or "",
            "labels": ",".join(labels),
            "assignees": ",".join(n.get("assignees") or []),
            "milestone": n.get("milestone", "") or "",
            "issue": str(n.get("issue", "") or ""),
            "fields": json.dumps(n.get("fields") or {}, ensure_ascii=False),
        })
        child_level = {"epic": "story", "story": "task"}.get(level, "task")
        walk(n.get("children"), key, child_level)

walk(doc.get("epics"),   None, "epic")
walk(doc.get("stories"), None, "story")
walk(doc.get("tasks"),   None, "task")
if not rows:
    sys.exit("manifest has no epics/stories/tasks")

print(json.dumps({
    "repo": repo,
    "project_number": str(project.get("number", "") or ""),
    "project_owner": project.get("owner", "") or "",
    "rows": rows,
}, ensure_ascii=False))
PY
}

PARSED="$(read_manifest)" || exit 1
jqp() { printf '%s' "$PARSED" | python3 -c "import json,sys;d=json.load(sys.stdin);print($1)"; }

REPO="$(jqp 'd["repo"]')"
PROJ_NUM="$(jqp 'd["project_number"]')"
PROJ_OWNER="$(jqp 'd["project_owner"]')"
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
    for k in ("key","parent","level","title","labels","assignees","milestone","issue","fields"):
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
       Run this yourself (interactive browser flow):  gh auth refresh -s project
       Or drop the 'project:' block from the manifest to file issues only."
    fi
  else
    note_ok "no project requested (issues only)"
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
  while IFS=$'\t' read -r key parent level title labels _a _m issue _f; do
    parent="$(unblank "$parent")"; labels="$(unblank "$labels")"; issue="$(unblank "$issue")"
    local indent="" ; case "$level" in story) indent="  ";; task) indent="    ";; esac
    printf '%s%s %s%s%s\n' "$indent" "$([ -n "$issue" ] && echo "#$issue" || echo "+")" \
      "$title" "${labels:+  [$labels]}" ""
  done <<<"$ROWS_TSV"
}
show_plan
[ "$MODE" = plan ] && exit 0

# ---- ensure labels -----------------------------------------------------------
if [ "$MODE" = apply ]; then
  while read -r l; do
    [ -z "$l" ] && continue
    gh label create "$l" --repo "$REPO" --color ededed >/dev/null 2>&1 || true
  done < <(cut -f5 <<<"$ROWS_TSV" | tr ',' '\n' | sort -u | grep -v '^$' | grep -vx -- '-')
fi

# ---- create ------------------------------------------------------------------
STATE="$(mktemp)"; trap 'rm -f "$STATE"' EXIT
node_id() { gh api "repos/$REPO/issues/$1" -q .node_id; }

if [ "$MODE" = apply ]; then
  echo; echo "creating:"
  while IFS=$'\t' read -r key parent level title labels assignees milestone issue _; do
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
  while IFS=$'\t' read -r key parent level title _l _a _m _i _f; do
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
while IFS=$'\t' read -r key parent level title labels _a _m issue _f; do
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
