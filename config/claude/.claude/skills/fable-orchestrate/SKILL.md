---
name: fable-orchestrate
description: Run fable as a cost-efficient orchestrator — keep fable's expensive tokens on judgment, decisions, and reasoning while delegating cheap fan-out research to sonnet subagents and mechanical integration/coordination to opus subagents. Use this whenever fable is (or should be) driving a multi-step task and you want to control cost: when a task mixes "think hard" work with "just go read/collect/merge" work, when fable is about to do broad file-reading or log-grepping itself, when someone asks to "orchestrate with fable", "use fable but keep it cheap", "fableで指揮して", "fableのコストを抑えて", "調査はsonnet・判断はfable", or when a fable session is spending its budget on grunt work instead of decisions. Also trigger when planning which model does what in a delegation/subagent pipeline.
---

# Fable Orchestrate — 高価な fable を判断に集中させる

fable は最も高価なモデルなので、その1トークンは「余人には代えがたい判断」に使うのが経済合理的だ。ファイルを何十個も読む、ログを grep する、定型のマージをする——こうした作業に fable の思考を溶かすのは、外科医に検体のラベル貼りをさせるようなもの。**判断は fable、探索は sonnet、単純な統合・指揮は opus** に振り分けることで、質を落とさずコストを数分の一にできる。

このスキルは fable がオーケストレーターとして働くとき、あるいは他モデルが重要局面で fable を呼ぶときの、**振り分け規則と委譲の作法**を与える。

## モデル(なぜこの三層か)

各モデルには「得意 × 単価」の座標がある。振り分けの原則はひとつ——**そのサブタスクを一段安いモデルに落としても成果物の質が落ちないなら、必ず落とす**。落ちるのは「判断の分岐がある」「間違えると後段が全部やり直しになる」ところだけで、そこにだけ fable を使う。

| 層 | モデル | 担わせるもの | 理由 |
|---|---|---|---|
| **判断** | `fable` (self / claude-fable-5) | タスク分解、トレードオフの決定、矛盾する証拠の裁定、最終統合の設計、"次に何をするか" | 間違えると全体がやり直しになる一点。ここの質が成果を決める |
| **探索** | `sonnet` | ファイル横断読み、ログ/コード検索、事実収集、候補列挙、既知パターンの当てはめ | 発散的で並列化でき、正解が「見つかるか否か」で判断分岐が少ない。安く大量に投げる |
| **統合・指揮** | `opus` | 複数の調査結果のマージ、定型リファクタ、決まった手順の遂行、下位 fan-out の取りまとめ | 賢さは要るが新規の判断は要らない中量級。fable ほどの単価は不要 |

境界の勘所: **「考える」のか「見つける/まとめる」のか**で分ける。分岐を含む "which/whether/why" は判断(fable)。"find/collect/list" は探索(sonnet)。"merge/apply/run these steps" は統合(opus)。迷ったら [references/routing-examples.md](references/routing-examples.md) にシナリオ別の実例がある。

## 二つの使い方

### A. fable 主導(fable がこのスキルを読んで自分で振り分ける)

fable がメインループのとき、自分では grunt work をせず、探索と統合を subagent に出す。骨格:

1. **分解(fable 自身)** — タスクを「判断が要る核」と「作業」に割る。判断の核だけ自分の手元に残す。
2. **探索を sonnet に fan-out** — 事実収集は並列サブエージェントへ。`Agent` ツールに `model: "sonnet"` を渡す。結論だけ返させる(ファイルダンプを返させない)。
3. **統合を opus に** — 収集結果のマージや定型処理が重いなら `model: "opus"` の1エージェントに束ねさせる。軽ければ fable が直接畳んでよい。
4. **判断(fable 自身)** — 返ってきた結論の上で決める。矛盾の裁定・最終設計・次アクションはここでやる。
5. 必要なら 2〜4 を回す。

鉄則: **fable が自分でファイルを開き始めたら黄信号。** その読解が「判断のため」でなく「情報収集のため」なら、sonnet に投げるべきだったサイン。

### B. 呼び出し(opus/sonnet が起点で、重要局面だけ fable に上げる)

安いモデルが主導し、判断が要る一点でだけ fable を呼ぶ。用途: 大半は定型だが1箇所だけ質の高い裁定が要る作業。

- 主導モデルは探索・統合を自分と sonnet で進め、**分岐点に来たら `Agent` に `model: "fable"` で判断だけを委譲**する。
- fable への委譲プロンプトは「収集済みの事実」+「決めるべき問い」に絞る。fable に探索させない——それは高い。事実は主導側で揃えて渡す。
- fable の返答(決定+理由)を受けて、主導モデルが実行に戻る。

## 委譲の作法(Agent ツール)

`model` 引数で層を選ぶ。新しいエージェント定義は要らない——既存の `general-purpose`(または `Explore`)に model を載せるだけでいい。

```
探索:   Agent(subagent_type="Explore",         model="sonnet", prompt="<収集タスク。結論だけ返せ>")
統合:   Agent(subagent_type="general-purpose", model="opus",   prompt="<マージ/定型処理>")
判断:   Agent(subagent_type="general-purpose", model="fable",  prompt="<事実+決めるべき問い>")
```

委譲プロンプトの原則(質とコストの両方に効く):

- **探索(sonnet)には「結論だけ返せ」と明示する。** サブエージェントの最終テキストだけが親に返る。ファイルの中身を貼らせず、「どのファイルの何行目に何があったか」の要約と結論を返させる。これで親のコンテキストが汚れず、fable のトークンを節約できる。
- **判断(fable)には探索させない。** プロンプトに「調べるべきこと」ではなく「もう調べた事実」を書く。fable は与えられた事実の上で決めるだけにする。もし fable が「まず〜を確認する」と言い出したら、その確認は sonnet に前段で済ませておくべきだった。
- **並列可能な探索は同一ターンで複数投げる。** 独立した収集は1メッセージに複数の Agent 呼び出しをまとめると同時に走る。
- **統合(opus)には手順を渡す。** 「これらN件の結果を〜の基準でマージし、重複を除いて表にせよ」のように、判断の余地なく実行できる形にする。判断が混ざるなら、その判断部分は fable に切り出す。
- **探索(sonnet)には「読み取りだけで結論を出せ、副作用のある検証(ビルド・テスト・書き込み)はするな」と添える。** サブエージェントはビルドやテストの実行権限を持たないことが多く、`cargo check` 等を試みて権限エラーで足踏みする。探索の目的は事実収集であって検証ではないので、「コード/差分を読んで論理的に結論せよ、実行系は不要」と最初から枠をはめると無駄な往復が消える。実際に検証が要るなら、それは探索ではなく後段の別ステップとして切り出す。
- **探索(sonnet)が指示外の異常に気づいたら、総括に一言添えてよいと許す。** 「結論だけ返せ」と両立する。収集の過程で見つけた副次的な問題(消えた履歴、矛盾、想定外の状態)は、親が拾うべき判断材料になる。ただし本題の結論を薄めないよう、あくまで末尾に短く。

## コスト意識のチェック(自問)

作業中、次を折に触れて自問する。fable のトークンが grunt work に溶けていないかの検知器:

- いま自分(fable)がしているのは**判断**か、それとも**情報収集**か? 後者なら sonnet に出す。
- この subagent は sonnet で足りるのに opus/fable を指定していないか? 一段下げられないか常に問う。
- 探索結果を親にダンプさせて fable のコンテキストを膨らませていないか? 「結論だけ」を徹底する。
- 逆に、**ケチりすぎて判断を安いモデルに投げていないか?** 間違えると後段総崩れになる裁定は fable に上げる。ここだけは節約しない——安物買いの銭失いになる。

振り分けはコスト最適化であって品質妥協ではない。**質を保つ最小コストの配分**を狙う。
