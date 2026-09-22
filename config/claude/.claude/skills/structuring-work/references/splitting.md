# 分割パターン(大きすぎるノードを縦に切る)

判定は「観測されたら適用」。どれにも当たらなければ、そのノードは大きくない(切らない)。

## SPIDR(Cohn)— 先にこの 5 軸

| 軸 | 観測されたら | 切り方 |
|---|---|---|
| Spike | 見積もれない・技術的に成立するか不明 | 時間箱つきの調査を別ノードに。調査の完了条件は「判断材料が揃う」 |
| Paths | 同じ目的への経路が複数(手段 A / 手段 B) | 経路ごと。最も単純な経路を先に |
| Interfaces | 入口が複数(Web / CLI / 簡易 UI / リッチ UI) | 入口ごと。簡易版を先に |
| Data | 扱うデータの種類・範囲が列挙できる | 種類ごと。最小の集合を先に |
| Rules | 業務規則・分岐条件が列挙できる | 規則ごと。緩い版を先に |

## Lawrence の 9 パターン — SPIDR で切れないとき

| パターン | 観測されたら |
|---|---|
| Workflow Steps | 逐次の工程が複数ある(申請→承認→通知) → 一部工程だけ先行 |
| Business Rule Variations | 「〜の場合」が複数 → 分岐ごと |
| Major Effort | 選択肢のうち 1 つだけ実装コストが大きい → 大きい方を後回し |
| Simple / Complex | 「基本 + 追加要件」の形 → 基本と追加を分離 |
| Variations in Data | 言語・地域・形式が列挙できる → 種類ごと |
| Data Entry Methods | 入力手段が複数 → 簡易な手段を先に |
| Defer Performance | 性能・SLA の数値要件がある → 機能と性能達成を分離 |
| Operations (CRUD) | 「管理できる」など複数操作を含む動詞 → 操作ごと |
| Break Out a Spike | 実現性が未検証 → 調査を切り出す |

## 縦切りの検査

切った 1 切片について: 単独でデモでき、利用者(または呼び手)が価値を観測できるか。
題名に層の名前(バックエンド、DB、API、UI)が出ていたら横切りの疑い。

## 出典

INVEST (Wake, xp123.com) / 3C (Jeffries) / SPIDR (Cohn, mountaingoatsoftware.com) /
Story Splitting Cheat Sheet (Lawrence, agileforall.com) / Shape Up (scopes = 縦切り) /
SAFe (Feature の完了 = 子の総和が仮説を満たす) / Atlassian (Epic は 1 スプリントに収まらない物)
