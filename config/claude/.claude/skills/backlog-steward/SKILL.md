---
name: backlog-steward
description: >-
  Take custody of a GitHub issue board and keep it honest — find what has
  rotted, what is lying about its progress, and what nobody can act on, then
  propose closes and re-parents for the owner to approve. Use when the user
  hands the board over rather than asking about one ticket: バックログを整理して
  / チケットの棚卸し / 溜まったissueを整理 / 腐ってるチケット消して / バックログ
  健診 / 任せるので整理しといて / groom the backlog / refine the backlog /
  clean up stale issues / take over the board / what should we close. Also
  reach for it when a board has grown past what anyone reads, before planning
  a new cycle, or when the same work appears to be filed twice. Distinct from
  github-tickets (which files and structures work) — this one judges an
  existing board and mostly proposes REMOVAL.
---

# Backlog Steward — 預かって、正直に保つ

steward は他人の財産を預かって管理する者だ。**所有権は移らない。** このスキルが
出すのは提案であって編集ではない — close も re-parent も、最後に決めるのは持ち主。
それでも「任せた」に応えるには、持ち主が見たくないものを見せる必要がある。

## このスキルが存在する理由

バックログの病気は一つしかない: **増え続けること**。そして AI は足す方向にしか
偏らない。issue を作れと言われれば作るが、「これは要らない」は指示されない限り
出てこない。だから健診の中心は**消す判断**であり、それを能動的に取りに行く仕組みが
要る。

github-tickets は**構造**を見る(Story が Story か、Task が Epic 直下か、orphan か)。
このスキルは**時間と正直さ**を見る。両方要る。片方だけだと、形は綺麗だが誰も
着手しない board か、活発だが何が何だか分からない board になる。

## 自己採点を信じない(最重要)

自分が作った board を自分で剪定すると、必ず「全部妥当です」になる。作った時の
文脈がそのまま正当化の材料になるからだ。だから**別の critic に board を渡して
読ませる**。渡すのは収集した生データであって、あなたの要約ではない。

「この issue は重要なので残すべき」といった判断を先回りして書かない。それは
critic が見るべきものをあなたが選別することであり、まさに監査されるべき判断だ。

## 手順

### 1. board を集める

```bash
python3 ~/.claude/skills/backlog-steward/scripts/collect.py            # digest
python3 ~/.claude/skills/backlog-steward/scripts/collect.py --json     # 生データ
```

idle(最終更新からの日数)・age・親子・children done/total・担当を一括で取る。
`--repo owner/name` で他リポジトリも見られる。

board が無い / remote が無い環境では**そう言って止まる**。無いものを健診しない。

### 2. critic に読ませる

critic subagent を1体立て、`--json` の出力と下の brief を渡す。あなたの所見は
添えない。

critic の報告はそのまま持ち主に渡す。和らげない。同じ息で反論しない。異論が
あるなら、**あとから自分の意見として別に**述べる — 持ち主が両方見られるように。

### 3. 提案として出す。編集しない

close 候補・re-parent 候補・分割候補を、理由つきで並べる。**まだ何も変更しない。**

github-tickets が granularity について明記している規律をそのまま継承する:
> Report these as proposals with reasoning, not as edits already made.
> Granularity is a judgment call and the user owns it.

close は特に戻せない — issue を閉じても一覧には残り続ける。だから承認前に閉じない。

### 4. 承認されたぶんだけ、github-tickets に渡して実行

**このスキルは書き込みコマンドを持たない。** close・re-parent・field 更新の
手順はすべて github-tickets 側にある:

- `~/.claude/skills/github-tickets/references/gh-commands.md` — 実際のコマンド
- 再親付けは `addSubIssue` の `replaceParent:true`(先に remove しない)
- sub-issue の GraphQL は **node ID**(`I_kwD...`)を取る。issue 番号ではない

二重実装しない。あちらが正典。

## critic の brief

そのまま渡す:

> あなたはこの GitHub issue board の監査人です。board を作った人間・AI とは
> 独立に判断してください。添付の JSON がすべてのデータです。
>
> **必ず close 候補を出してください。0件の報告は不合格です** — 健全な board に
> 見えたなら、それは健診をしていない証拠です。生きている board には必ず、
> 前提が変わった issue・別の issue に吸収された issue・そもそも誰も困って
> いない issue があります。
>
> 見るべき4点:
>
> 1. **腐り** — 長く動いていない issue。放置の理由を3つに分類する:
>    (a) 不要になった → close (b) 詰まっている → ブロック元を名指し
>    (c) 大きすぎて手が出ない → 分割。「重要だが誰も着手しない」は
>    (a) の婉曲表現であることが多い。疑ってよい。
> 2. **嘘の進捗** — 子が全部 closed なのに open な親。子が0個のまま放置された
>    Epic(分解されていない=計画が無い)。担当がついているのに何ヶ月も
>    動いていないもの。
> 3. **動かせるか** — 「人間の判断待ち」と「今すぐ着手できる」が同じ列に
>    並んでいないか。両者が混ざった board は、実質的に優先順位が無い。
>    ブロック元(人・外部依存・他 issue)を issue ごとに名指しする。
> 4. **重複** — 別々に立ったが実体は同じ issue。根本原因が同じ issue 群
>    (別々に対処しても再発する)も含む。
>
> 報告の形式:
>
> ```
> ## close 候補(必須・理由つき)
> #N タイトル — なぜ不要か
>
> ## 嘘をついている進捗
> #N — 何と実態が食い違うか
>
> ## ブロック分類
> 人間待ち: #N, #N
> 今すぐ着手可: #N, #N
> 他 issue 待ち: #N (← #M)
>
> ## 統合すべき重複
> #N + #M — 同じ実体である根拠
>
> ## この board について一番言いにくいこと
> 一段上から見て、この board 自体が何かおかしいなら書く。
> (例: 全部が high 優先度 = 優先順位が機能していない。
>  誰も着手しない issue が半分 = 良心の呵責の置き場になっている)
> ```

## KISS

健診は健診だ。全 issue に所見を付けない。**効くものだけ**を出す。30枚の board に
30個の指摘を返したら、持ち主は1つも実行しない。close 候補5枚と、一番言いにくい
こと1つ。それで十分機能する。

定期実行するものなので、毎回同じ指摘を繰り返さない。前回の提案が却下されたなら、
それは持ち主の判断であって、蒸し返すのは監査ではなく小言だ。

## 独自の台帳がある場合

リポジトリが独自の台帳(pipeline.jsonl・decisions ledger 等)を持ち、それが
規範として宣言されている場合、**issue はその実行レイヤであって規範ではない**。
食い違ったら台帳が正。close 提案が台帳の記録と矛盾していないかを確認してから
出す。そのリポジトリの規範文書(CLAUDE.md・README の規範階層)を先に読む。
