# gh command reference

Verified against `gh` 2.96.0 and live GraphQL introspection. Copy these rather than improvising — several shapes fail silently when guessed.

## Contents

- [Preflight](#preflight)
- [Labels](#labels)
- [Creating issues](#creating-issues)
- [Sub-issues (parent/child)](#sub-issues-parentchild)
- [Reading the tree](#reading-the-tree)
- [Projects](#projects)
- [Batch creation script](#batch-creation-script)

## Preflight

```bash
gh auth status                       # who am I, what scopes
gh --version | head -1               # gates the item-edit path below
gh repo view --json nameWithOwner -q .nameWithOwner
```

Scopes:

| Operation | Needs |
|---|---|
| Issue create/edit, sub-issues | `repo` |
| `gh project` read (`view`, `field-list`, `item-list`) | `read:project` |
| `gh project` write (`item-add`, `item-edit`) | `project` |

`gh auth refresh -s project` is an interactive browser flow — the **user** must run it. Suggest they type `! gh auth refresh -s project`.

## Labels

Create once per repo; harmless to re-run with `|| true`.

```bash
gh label create "type::epic"  --color 6F42C1 --description "Epic: 事業/プロダクト上の成果単位" 2>/dev/null || true
gh label create "type::story" --color 0E8A16 --description "Story: 独立して価値のある振る舞い" 2>/dev/null || true
```

Check what exists: `gh label list --search "type::"`

## Creating issues

Use a heredoc for the body — it keeps markdown and Japanese intact and avoids quoting bugs.

```bash
EPIC_NUM=$(gh issue create \
  --title "予約キャンセルをセルフサービス化する" \
  --label "type::epic" \
  --body "$(cat <<'EOF'
## 解決する課題
キャンセル依頼が問い合わせの4割を占め、対応が営業時間に縛られている。

## 成功指標
キャンセル関連の問い合わせ件数が50%以上減る。

## スコープ外
返金処理そのもののフロー変更。
EOF
)" --json number -q .number)
```

If `--json` is unsupported on the installed version, `gh issue create` prints the URL — take the trailing number:

```bash
URL=$(gh issue create --title "..." --label "type::story" --body "...")
NUM=${URL##*/}
```

Other useful flags: `--assignee @me`, `--milestone <name>`, `--repo <owner>/<repo>` (required when not inside the repo).

## Sub-issues (parent/child)

**GraphQL mutations take node IDs (`I_kwD...`), never issue numbers.** This is the most common failure.

```bash
node_id() { gh issue view "$1" --json id -q .id; }   # add --repo O/R if needed
```

### Add / re-parent

`replaceParent:true` moves a child that already has a parent — no need to remove first. Safe to include always.

```bash
add_sub() {  # add_sub <parent_num> <child_num>
  gh api graphql -f query='
    mutation($parent:ID!, $child:ID!){
      addSubIssue(input:{issueId:$parent, subIssueId:$child, replaceParent:true}){
        issue{ number subIssuesSummary{ total completed } }
        subIssue{ number }
      }
    }' -f parent="$(node_id "$1")" -f child="$(node_id "$2")"
}
```

### Remove (make top-level)

Both IDs required; there is no URL variant.

```bash
gh api graphql -f query='
  mutation($parent:ID!, $child:ID!){
    removeSubIssue(input:{issueId:$parent, subIssueId:$child}){ issue{ number } }
  }' -f parent="$(node_id PARENT)" -f child="$(node_id CHILD)"
```

### Reorder

Pass exactly one of `afterId` / `beforeId`.

```bash
gh api graphql -f query='
  mutation($parent:ID!, $child:ID!, $after:ID){
    reprioritizeSubIssue(input:{issueId:$parent, subIssueId:$child, afterId:$after}){ issue{ number } }
  }' -f parent="$P" -f child="$C" -f after="$SIBLING"
```

### Limits

100 sub-issues per parent, 8 nesting levels. Epic→Story→Task uses 2 — ample headroom.

### REST alternative

Only if you must. REST takes **database IDs** (integers), not node IDs, and the DELETE path is singular `sub_issue`.

```bash
CHILD_DB=$(gh api /repos/O/R/issues/CHILD --jq .id)
gh api --method POST /repos/O/R/issues/PARENT/sub_issues -F sub_issue_id=$CHILD_DB -F replace_parent=true
gh api --method DELETE /repos/O/R/issues/PARENT/sub_issue -F sub_issue_id=$CHILD_DB
```

Use `-F` (typed) not `-f` for integer ids — `-f` sends them as JSON strings.

## Reading the tree

Summary + children + parent in one round trip:

```bash
gh api graphql -f query='
  query($o:String!,$r:String!,$n:Int!){
    repository(owner:$o,name:$r){ issue(number:$n){
      number title state
      parent{ number title }
      subIssuesSummary{ total completed percentCompleted }
      subIssues(first:100){ nodes{ number title state
        labels(first:10){ nodes{ name } }
        subIssuesSummary{ total completed }
      }}
    }}}' -f o=OWNER -f r=REPO -F n=NUM
```

`subIssuesSummary` fields are exactly `total`, `completed`, `percentCompleted` (all Int).

Cheap parent check: `gh issue view N --json parent`

Find Epics: `gh issue list --label "type::epic" --state all --json number,title,state`

Find orphan issues (no parent, not an Epic):

```bash
gh issue list --state open --json number,title,parent,labels \
  -q '.[] | select(.parent == null) | select([.labels[].name] | index("type::epic") | not) | "\(.number)\t\(.title)"'
```

## Projects

Project identity is always `<number>` positional + `--owner <login>`. `--owner` accepts a user login, an org login, or `@me` — the CLI resolves which; you don't need to know.

```bash
gh project list --owner @me
gh project view NUM --owner OWNER --format json
gh project field-list NUM --owner OWNER --format json
```

### Add an issue

`--url` takes the **issue** URL. Returns the project item id. Re-adding an existing issue returns the existing item id rather than erroring, so it doubles as a lookup.

```bash
ITEM_ID=$(gh project item-add NUM --owner OWNER \
  --url "https://github.com/O/R/issues/123" --format json -q .id)
```

### Set a field — two paths

**gh ≥ 2.97.0 — by name.** Prefer this; it skips all ID resolution.

```bash
gh project item-edit NUM --owner OWNER \
  --url "https://github.com/O/R/issues/123" \
  --field "Status" --value "Done"
```

Constraints: the project number positional is required with `--url`/`--field`/`--value`; `--value` requires `--field`; iteration fields cannot be set by name (use `--iteration-id`).

**gh ≤ 2.96.0 — by node ID.** Unavoidable on this version. All four are node IDs, not names.

```bash
OWNER=myorg; NUM=1; ISSUE_URL="https://github.com/O/R/issues/123"

PROJECT_ID=$(gh project view $NUM --owner "$OWNER" --format json -q .id)
FIELD_ID=$(gh project field-list $NUM --owner "$OWNER" --format json \
  -q '.fields[] | select(.name=="Status") | .id')
OPTION_ID=$(gh project field-list $NUM --owner "$OWNER" --format json \
  -q '.fields[] | select(.name=="Status") | .options[] | select(.name=="Done") | .id')
ITEM_ID=$(gh project item-list $NUM --owner "$OWNER" --limit 500 --format json \
  -q ".items[] | select(.content.url==\"$ISSUE_URL\") | .id")

gh project item-edit --id "$ITEM_ID" --field-id "$FIELD_ID" \
  --project-id "$PROJECT_ID" --single-select-option-id "$OPTION_ID"
```

Gate on version:

```bash
ver=$(gh --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
[ "$(printf '%s\n2.97.0\n' "$ver" | sort -V | head -1)" = "2.97.0" ] && BY_NAME=1 || BY_NAME=0
```

### Gotchas

- `item-list` defaults to `--limit 30`. **Always pass `--limit`** on real projects or your lookup silently misses the item.
- `options` is omitted entirely for non-single-select fields — always `select(.name==...)` before touching `.options`.
- `content.url` is absent for draft issues; `content` may be `null`.
- Custom field values appear camelCased at item top level: `Status` → `.status`, so `select(.status=="Done")` filters.
- `item-edit` does **not** add the issue to the project. `item-add` first (safe to re-run).
- Server-side filter (github.com / GHES ≥ 3.20): `--query "is:issue -status:Done"`.

## Batch creation script

Pattern for creating an approved tree. Write it to the scratchpad and run it, rather than issuing dozens of interactive calls.

```bash
#!/usr/bin/env bash
set -euo pipefail          # stop at the first failure — a half-built tree
                           # must not be reported as complete
REPO="owner/repo"
PROJ_NUM=1; PROJ_OWNER="@me"

node_id(){ gh issue view "$1" --repo "$REPO" --json id -q .id; }
add_sub(){ gh api graphql -f query='mutation($p:ID!,$c:ID!){addSubIssue(input:{issueId:$p,subIssueId:$c,replaceParent:true}){subIssue{number}}}' \
             -f p="$(node_id "$1")" -f c="$(node_id "$2")" >/dev/null; }
mkissue(){ # mkissue <title> <label-or-empty> <body>
  local args=(--repo "$REPO" --title "$1" --body "$3")
  # `if`, not `[ ] &&` — a bare test that fails is a nonzero return under
  # `set -e`, which would abort on every unlabeled Task.
  if [ -n "$2" ]; then args+=(--label "$2"); fi
  gh issue create "${args[@]}" | sed 's#.*/##'
}

EPIC=$(mkissue "予約キャンセルをセルフサービス化する" "type::epic" "$(cat <<'EOF'
## 解決する課題
...
## 成功指標
...
EOF
)")
echo "Epic #$EPIC"

S1=$(mkissue "ユーザーが自分の予約をキャンセルできる" "type::story" "$(cat <<'EOF'
## ユーザーストーリー
予約者として、自分の予約をキャンセルしたい。営業時間を待ちたくないから。
## 受入条件
- [ ] 予約一覧からキャンセルでき、在庫が即時戻る
- [ ] キャンセル済みの予約は再キャンセルできない
EOF
)")
add_sub "$EPIC" "$S1"

T1=$(mkissue "キャンセルAPIエンドポイントを追加する" "" "$(cat <<'EOF'
## やること
予約をキャンセルし在庫を解放するエンドポイントを追加する。
## 完了条件
- [ ] 本人の予約のみキャンセルでき、二重キャンセルが拒否される
EOF
)")
add_sub "$S1" "$T1"

for n in "$EPIC" "$S1" "$T1"; do
  gh project item-add "$PROJ_NUM" --owner "$PROJ_OWNER" \
    --url "https://github.com/$REPO/issues/$n" >/dev/null
done

echo "done: epic=$EPIC story=$S1 task=$T1"
```

If the script dies partway, `set -e` stops it — report which issues exist and what's unlinked rather than rerunning from the top, which would duplicate everything already created.
