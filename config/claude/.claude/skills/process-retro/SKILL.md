---
name: process-retro
description: >-
  Run a retrospective on the app-flood PROCESS itself (not on a deliverable):
  collect friction since the last retro, ground every proposed process change
  in observed evidence, and route changes through the freeze/norm rules.
  Use after any pipeline phase completes for an app, after a ship (full
  retro), after an incident/five-whys concludes, when the Admiral catches a
  process defect, or when someone says プロセスの振り返り / retro / 工程を
  見直したい. Complements the formation reflector (which evolves the TEAM);
  this evolves the PIPELINE documents.
---

# process-retro — プロセス自体の振り返り

工程の欠陥が「提督の気づき待ち」になるのを止めるための定例機構。原則は
組織振り返り(reflector)と同じ: **観測された摩擦に接地しない変更は提案
しない**。整った案より、証拠のある小さな修正。

## 入力(この順に集める)

1. `docs/process/friction.jsonl` — 前回レトロ以降の摩擦メモ(下記様式)
2. `docs/incidents/`(claude-aquarium 側)と five-whys の帰結 — 根本原因が
   工程欠陥を指しているもの
3. `docs/process/pipeline.jsonl` — 各艦の滞留(あるフェーズに不自然に長く
   いる = ゲートか DoD の欠陥候補)
4. 監査レンズ(OPEN-CHALLENGES): **結線監査**(上流情報を白紙で聞き直して
   いないか)・**鏡像盲点**(証拠が構造的に見えない領域はどこか)を全工程に
   1 回ずつ当てる
5. 提督の直近の指摘(最も感度の高い検出器 — ただしこれに依存しない状態が
   本スキルの成功条件)

## 手順

1. **摩擦の棚卸し**: 入力 1-5 を工程(lifecycle のフェーズ行)ごとに束ねる。
   摩擦ゼロのフェーズは「未実走だから摩擦が無い」のか「健全」なのかを区別
   して記録(未実走の無風は健全の証拠ではない)
2. **変更提案**: 摩擦 1 件以上に接地した変更だけを起案。様式:
   `{変更 / 接地する摩擦(friction id or incident) / 影響文書 / 規範レベル}`
3. **凍結・規範ルールの尊重**:
   - プロセス凍結中は**起案のみ**(friction.jsonl に accumulate)。適用は
     凍結明けの一括改訂で
   - 承認物(rubric/taxonomy/patterns/憲章)に触る変更は提督専権 — 草案止まり
   - 工程の詳細(gates の文言・スキル手順)は摂政先例の範囲内で即適用可
4. **整流チェック**: 変更を適用したら、正典宣言(verification-gates §正典)
   に従い**正典だけを編集**し、lifecycle 表に行を足し忘れていないか確認
   (表に無い工程は存在しない)
5. **台帳**: 実施記録を `docs/process/retro-log.md` に追記(日付・入力件数・
   採択/見送り件数・見送り理由)。見送りも書く — 「提案が出ない」と「出たが
   証拠不足で見送った」を後から区別できるように

## 摩擦メモの様式(誰でも・いつでも 1 行)

```
{"date":"2026-07-06","phase":"5 実装","friction":"何に引っかかったか 1 文",
 "evidence":"どこで起きたか(ファイル/指令id/会話)","by":"統括|検証者|提督|..."}
```

摩擦メモは**書くのに 30 秒**を守る(重いと書かれなくなり、レトロが提督の
記憶頼みに戻る)。工程中に気づいた者がその場で追記してよい — 承認不要。

## 成功条件(このスキル自体の検証器)

次の四半期で「提督が最初に発見した工程欠陥」の割合が下がること。レトロが
先に見つけた欠陥数 vs 提督発の欠陥数を retro-log で数える。


## 再発クラスの計数(2026-07-11 追加)

レトロは docs/process/defect-classes.jsonl を必ず読み、**同一クラスの検証者捕獲が2回目に達した時点で**(凍結中でも)生成側不変条件の即時提案を必須とする。検証者の同型捕獲は『システムが機能した』ではなく『生成が同じ欠陥を繰り返した』と数える。
