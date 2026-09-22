---
name: hypothesis-loop
description: >-
  Run the app-flood lifecycle-v1 convergence loop: a product hypothesis card
  with 6 orthogonal dimensions holding option SETS, iterated by risk-driven
  spins (parallel dimension agents + adversarial composition check) until a
  maturity-based commitment review admits it to build. Use when starting
  product definition for ANY new app-flood candidate, when a downstream
  discovery invalidates an upstream assumption (re-entry respin), when someone
  asks 仮説カード / スピンを回して / 収束ループ, or when reviewing whether a
  candidate is actually ready to build. Replaces the old linear phase-2
  transition gates.
---

# hypothesis-loop — 収束ループの運転手順

正典は app-flood `docs/process/lifecycle-v1.md`(次元定義・セット規律・忠実度帯・
成熟度出口)。**まず読む**。本スキルは運転手順だけを持つ。

## カードの作成(候補が選定されたら最初に)

`docs/build/<app>/card.md` を作る。次元 D1〜D6 それぞれに:
- **候補集合**(最大 3。一意化しない — 例 D2: 買い切り/解錠IAP/回数券)
- 既知の証拠(階級 1-4)と忠実度(L0/L1/L2)
- **除外基準を先に明文化**(尾>2 は即死、禁忌違反は即死、等)
- 未解決矛盾欄(空でよい — 埋まるのが正常)

既存資産(archive の採点・セル台帳・過去調査)から引ける値は引き写す(白紙化禁止)。

## スピン(1 スピン = 艦隊指令 1 本)

指令テンプレの骨子:
1. **スピン計画を冒頭に明記**: 重要度×エビデンスの 2×2 で「事業を殺しうる×根拠薄」
   の次元・候補を選ぶ(全次元を回さない)。何を検証し何は触らないか
2. **次元タスクを並列発注**(次元ごとに別担当): 各タスクは候補集合の検証・除外・
   忠実度引き上げのどれかを行い、**新発見の制約**(他次元に効くもの)を必ず報告
3. **整合検査(必須・非起草者)**: 次元間矛盾を敵対的に探す —
   「D1 の量 × D2 の境界」「D1 の要求データ × D3 の API 現実」「D5 の芯 × D1 の段」。
   発見は カードの未解決矛盾欄へ first-class 記録
4. **カード更新**(統括=カードオーナー): 除外の実行(証拠必須)・忠実度更新・
   次スピンの計画案

## 成熟度出口(コミットメントレビュー)

lifecycle-v1 §成熟度出口 のチェックリストを統括が判定し、**各項目に証拠の所在を
併記**(書けない項目=未達 — 儀式化ガード)。合格で命名・rubric 採点 → ビルドへ。
提督不在時は「暫定合格・veto 可」と記録して進む。

## 再入

下流(設計・実装・レビュー・計測)の新事実は、カード再オープン → 影響次元だけの
ミニスピン。差し戻しと呼ばない。カードの改版履歴に一行残す。

## 運転上の注意

- スピン 1 での収束禁止(最適収束は中盤)・セット上限 3(超えたら先に除外)
- ループ不変条件を毎スピン適用: usecase-review 証拠階級・結線監査・数字の由来・
  **代替品掃引**(D4/D5 の証拠には「このペルソナが今日この仕事をどう済ませて
  いるか」の網羅表が必須: ①無料アプリの巨人(高評価ゆえ不満採掘に写らないもの
  を名指しで探す)②公的・無料 web ③汎用流用(Excel・紙・LINE・OS標準)。
  各行に差別化芯の充足/非充足を記す。母集団が不満採掘だけの competition/gap
  採点は受理不可 — 再発クラス台帳 free-giant-missed(3例)による)
- 1 候補のループ全体で目安スピン 2〜4。5 に達したら要件が揺れている —
  選定自体を疑い統括が停止判断
