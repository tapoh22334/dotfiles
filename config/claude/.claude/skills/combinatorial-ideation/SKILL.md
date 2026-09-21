---
name: combinatorial-ideation
description: >-
  Mechanically enumerate the full combination space of ideation axes (atlas
  cell × pattern catalog × entry point) and fan out cheap agents to generate
  seed ideas for EVERY viable combo — exploiting AI's capacity to evaluate
  volumes no human team can. Use when exploration density is too low, when
  slates keep coming from the same few pattern/entry combos, when the user
  asks 探索密度を上げたい / アイディアを網羅的に出したい / 組み合わせで生成して,
  or periodically to refresh the app-flood seeds ledger. Complements (does not
  replace) the slate process — output feeds the normal critique/scoring funnel.
---

# Combinatorial Ideation — 組み合わせ空間の機械的網羅

人間のブレストは「思いつける範囲」しか探せない。AI は 864 通りを 1 つずつ
真面目に検討できる — それがこの生成軸の存在理由。**賢さより網羅**。個々の
シードの質は既存工程(批評・usecase-review・rubric)が後段で担保するので、
この段の美徳は (1) 空間を漏らさないこと (2) 死んだ組み合わせを死んだと
正直に記録すること。**死案も資産** — 「セル×パターン別の生存率地図」は
次回の探索資源配分を較正する組織学習データになる。

## 手順

### 1. 軸の抽出と機械列挙(トークン消費ゼロ)

カタログから軸を機械抽出する(手で暗記・創作しない):
- セル: docs/atlas/taxonomy-v0.md の M×D(必要なら I 層)
- パターン: docs/ideation/patterns.md の A/B 系
- 出発点: 同 E 系

列挙前に**ドクトリンの硬フィルタ**を適用し、生成対象から機械的に除外する
(先例・裁定に由来する除外は生成後でなく生成前に切る — トークンの節約と
禁忌の構造的遵守):
- 刺激層(I1/I2)・裁定で除外されたモード
- 買い切り艦隊トラックなら深さ D1/D2 優先(D3+ は尾 3-5 の実測)
- 基盤未整備の出発点(例: E5 はトレンド基盤が立つまで)

**枝狩り規則(2026-07-06 第1巡の実測 850 combo で較正 — 対象を約半分に削減、
期待損失ほぼゼロ)**:
- **E4(新API解禁)は通常回では列挙から除外**(212 combo で promising ゼロ、
  121 件が「時期未確認」の穴埋め)。実在の named API イベント一覧を入力に
  持てる回だけ生成する
- **M8 は B5(ローカル完結)との交点のみ**、**M4 は B1/B6/B7(逆転・面シフト・
  移植)との交点のみ**残す(他は全滅の実測)
- **健康・医療隣接と通知依存はプロンプト指示では防げない**(死案ゼロ報告
  = quota 埋めの実証)— 列挙段階で機械除外する
- **3 巡に 1 回、狩った枝から無作為 5〜10 combo を監査生成**し、死んだ海域の
  蘇生(新 OS 機能等)を見逃さない

### 2. 生成 fan-out(安価モデルの並列エージェント)

モード単位など一貫性のある塊で分割し、1 エージェント 1 塊。各エージェントは
カタログ原典を自分で読み、担当する全組み合わせを 1 つずつ検討して出力する:

- 1 シード = 1 行 JSON: `{"combo":"M3xD2/A4/E2","idea":"平文1-2文(誰が・
  いつ・何が一撃になるか)","user":"具体的な人+引き金状況","evidence_hook":
  "証拠が転がっていそうな場所","label":"[仮説]"}`
- **全シードは [仮説] ラベル固定**(証拠は後段。verification-gates の
  ラベル規則に従う)。命名は禁止(仮称も付けない — 命名は着工ゲート事項)
- **成立しない組み合わせは `{"combo":"...","dead":true,"why":"1行"}`** と
  正直に出す。無理に捻り出した案は後段の批評コストを盗む
- 市場範囲(日本で使える)・尾の設計(support_tail 1-2 見込み)を生成時の
  制約として明記する

### 3. 統合・淘汰(中量級モデル 1 体)

- 全シードをマージし、概念重複を除去(combo 座標は全て保持 — 同じ案が
  複数座標から出たこと自体が信号)
- 粗トリアージ 3 値: promising(既存工程のスレートへ)/ park(証拠待ち)/
  dead(理由つき)。**rubric 採点はしない** — ここは漏斗の最上流
- 台帳へ追記: docs/ideation/seeds.jsonl(1 行 1 シード、トリアージ結果と
  座標つき)。座標別生存率の集計を末尾に 1 表

### 4. 接続

promising 上位を通常のスレート工程(相互批評+usecase-review ゲート+
rubric)へ渡す。**シードは候補ではない** — 漏斗を飛ばして採点に直行させない。

## 運用原則

- 生成エージェントには「結論だけ返せ、ファイルへの書き込みは統合役だけ」
- 塊のサイズは 1 エージェント 100 組み合わせ程度まで(それ以上は quota
  埋めの駄作が混ざる)
- 2 回目以降の実行は seeds.jsonl を読み、既出 combo をスキップ(差分生成)
- 生存率地図が偏りを示したら(例: 特定パターンが全滅)、それはパターン
  定義の欠陥仮説として監察/較正文書に上げる
