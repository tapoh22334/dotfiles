# Ticket manifest schema

A manifest declares the **intended end state** of a ticket tree. `scripts/apply.sh`
creates it and then diffs the manifest against GitHub, so a step that fails while
earlier steps succeed is caught rather than assumed.

## Minimal

```yaml
repo: owner/name          # optional inside a gh repo

epics:
  - title: iPad版をApp Storeで公開リリースする
    body: |
      ## 解決する課題
      iPad向けに動作するが、一般ユーザーが正規に入手できる状態にない。

      ## 成功指標
      App Storeで公開され、一般ユーザーが入手・利用できる。
    children:
      - title: 初見ユーザーが公開に耐えるモードだけを見られる状態にする
        body: |
          ## ユーザーストーリー
          初見ユーザーとして、完成度の低いモードを見せられたくない。
        children:
          - title: 全モードをリリース基準で評価し公開/据え置きを判定する
```

Nesting sets the level: `epics:` → epic, its children → story, theirs → task.
`type::epic` / `type::story` labels are added automatically; tasks get none, which
is the convention (absence of a type label *is* the signal).

## Fields

| Field | Applies to | Meaning |
|---|---|---|
| `title` | all | Required. Ends in a verb; reads standalone in a list of eighty. |
| `body` | all | Markdown. Use `\|` block scalars. Follow the level's template. |
| `children` | all | Nested nodes, one level down. |
| `key` | all | Stable id for cross-references. Auto-generated if omitted. |
| `issue` | all | An **existing** issue number. That node is not re-created — it is adopted and verified. This is how you retrofit a manifest onto tickets that already exist. |
| `labels` | all | Extra labels beyond the automatic type label. |
| `assignees` | all | GitHub logins. |
| `milestone` | all | Milestone title. |

Top-level `stories:` and `tasks:` also exist, for work that genuinely has no
parent. Prefer `epics:` with nesting — a task with no story usually means the
*why* was never articulated.

## Project block

```yaml
project:
  number: 1
  owner: tapoh22334      # defaults to @me
```

Omit this block entirely to file issues without touching a board. That is the
right choice when the `project` scope is unavailable — issues still land, and the
manifest records that no board was intended, so verify won't report a false gap.

## Running it

```bash
export GT_SCRIPTS=~/.claude/skills/github-tickets/scripts

apply.sh --check   tickets.yml   # prerequisites only. Nothing is written.
apply.sh --plan    tickets.yml   # the tree that would be created.
apply.sh           tickets.yml   # create, then verify.
apply.sh --verify  tickets.yml   # diff an existing tree against the manifest.
```

`--check` runs automatically before any write, and a failure **refuses to write
anything**. This matters because a half-created tree cannot be cleanly undone —
closing an issue leaves it visible forever.

`--verify` deliberately still runs when preflight fails, since diagnosing an
already-broken tree is when it is most needed.

## Adopting an existing tree

Put the real issue numbers in `issue:` and run `--verify`. This answers "did that
actually land?" for trees created before the manifest existed:

```yaml
epics:
  - issue: 184
    title: iPad版をApp Storeで公開リリースする
    children:
      - issue: 185
        title: 初見ユーザーが公開に耐えるモードだけを見られる状態にする
```

## Notes

- YAML is read with PyYAML when installed, otherwise a bundled reader
  (`miniyaml.py`) that covers this schema. There is no install step.
- Re-running `apply.sh` on a manifest whose nodes all carry `issue:` numbers is
  safe — existing nodes are adopted, not duplicated. Nodes **without** `issue:`
  are created every run, so add the numbers back after the first apply if you
  intend to re-run.
