---
name: usecase-review
description: >-
  Audit whether a claimed use case actually exists before it drives a build or
  scoring decision. Use whenever a product candidate, feature, or app idea is
  being scored, pitched, or approved — especially when a differentiator is
  justified by "competitors don't have it", when a go/no-go hinges on one
  scenario, when the user asks そのユースケース本当にあるの?/ニーズがわからない,
  or before Phase-2/build approval of any app-flood candidate. Also use to
  review ideation slates: every 案 with a 想定ユーザー deserves this audit.
---

# Use-Case Review — 需要主張の実在性監査

アイディエーションは「もっともらしい利用シーン」を無から生成できてしまう。
このスキルの仕事は、**そのシーンが世界に実在する証拠の種類を特定し、
「検証済み」と「仮説」と「創作」を峻別する**こと。今日の教訓
(app-flood RuleRename の CSV 照合機能): 「競合 10 本に無い」を網羅確認しても、
「欲しい人がいる」の証拠はゼロだった — 不在の証明は需要の証明ではない。

## 証拠の 4 階級(強い順)

| 階級 | 内容 | 例 |
|---|---|---|
| **1. 要望証拠** | 誰かがそれを明示的に求めた | レビューの要望、知恵袋/フォーラムの質問、feature request |
| **2. 行動証拠** | 人々が既に苦痛な回避行動をしている | 自作スプレッドシート、PC への往復、手作業 N 回 |
| **3. 前例証拠** | 別プラットフォームで同機能が実在し使われている | PC 定番ソフトの機能が実際に使われている → モバイル移植仮説 |
| **4. 不在証拠** | 競合がやっていない | 説明文に機能が無い |

**階級 4 は単独では需要の証拠にならない**。1〜3 のどれかと組んで初めて
「空いている機会」になる。単独なら、それは「誰も欲しがらないから無い」
可能性と区別がつかない。

## 各ユースケースへの尋問(5 問)

1. **WHO** — 具体的に誰か。ペルソナ名でなく「その人は入力データを既に持って
   いるか」を問う(**データ所在テスト**: アプリが動く場所に、必要な入力は
   自然に存在するか。例: iOS アプリに Excel は自然に居るか?)
2. **WHEN** — 引き金となる状況と頻度。年 1 回なら課金は成立しない
3. **INSTEAD** — 今日それをどうやっているか。回避策のコストが低いなら
   購入動機はない(OS 標準・無料手段で足りるかを必ず確認)
4. **WHERE'S THE CROWD** — その人たちが集まって話している場所を指させるか。
   指させない群衆は創作の疑いあり
5. **LOAD-BEARING** — このユースケースが創作だったとき、どの判定が覆るか。
   go/no-go・課金設計・スコアの軸を名指しする。**覆るものが大きいほど
   要求する証拠階級を上げる**(go を支えるなら階級 1-2 を要求)

## 判定と出力形式

ユースケースごとに次の表で判定する:

| UC | 内容 | 証拠階級 | データ所在 | 回避策コスト | 判定 | load-bearing |
|---|---|---|---|---|---|---|

判定は 3 値:
- **validated** — 階級 1 or 2 の証拠を原典つきで持つ
- **hypothesis** — 階級 3-4 のみ。**昇格条件(何の証拠が取れれば validated か)
  を必ず併記**する。取れる見込みのない昇格条件しか書けないなら fiction に落とす
- **fiction** — 証拠なし・データ所在テスト不合格・群衆を指させない

最後に **load-bearing hypotheses の一覧**(= 意思決定が仮説に寄りかかっている
箇所)を明示する。これが空でない go 判定は「条件付き go」と呼び替えること。

## 適用のコツ

- スコアリング済み候補に対しては、**各スコア軸がどのユースケースに依存して
  いるか**を逆引きすると load-bearing が機械的に見つかる
- 「あったら便利」は全部 hypothesis。人は「あったら便利」に金を払わない —
  払うのは「今日の苦痛が消える」ものだけ
- レビュー 0 件・質問 0 件は「証拠が取れなかった」ではなく**それ自体が観測**
  (需要が薄いか、別の場所に流れている)。どちらの解釈かは行動証拠で決める
