---
name: session-economics
description: Decide objectively, on token economics, whether an agent task should resume a persistent session or start fresh. Use when designing/tuning agent session reuse, when a session grows large, when "session limit" errors appear, when deciding rotation thresholds for formation roles / HQ / advisor sessions, or when the user asks whether context reuse is worth it (セッション使い回し, ローテーション, resume vs new).
---

# Session Economics — resume か新規かをトークン経済で決める

## モデル

毎回の resume は履歴全体をコンテキストとして再演する。判断は次の比較に還元される:

- **Resume コスト/タスク** ≈ 現在の文脈占有(peakContext または transcript サイズから推定)
  - JSONL バイト → トークン概算: `tokens ≈ bytes / 6`(オーバーヘッド込みの経験則)
- **新規プライミングコスト** ≈ mandate + 必読文書 + タスク文 ≈ **10〜15k tok**(実測: app-flood 探索ロール)
- 隠れコスト: 200k 窓超過での compaction スラッシュ、セッション上限の早期到達
  (上限エラー3件はすべて 300k 級セッションで発生 — 2026-07-04 実績)

## 判定規則

```
rotate if 推定文脈 > K × プライミング   (K=5 既定 → 閾値 ~75k tok ≈ 300KB jsonl)
ただし種別で K を変える:
  formation 実働ロール: K=5(タスクは異質・経験は mandate/ドクトリンへ外部化が正)
  formation 統括:      K=8(指令内の分解→統合の連続性に価値)
  HQ・顧問(監察/軍師/摂政): ローテーション対象外(蓄積文脈そのものが職能。
    ただし 150k tok 超で「要約引き継ぎ→新セッション」を提案せよ)
```

## 計測手順(aquarium)

1. `GET /api/session?project=<slug>&id=<sid>` → `summary.peakContext`(正確)
2. 速い代理: `stat -c %s ~/.claude/projects/<slug>/<sid>.jsonl` を 6 で割る
3. 判断例(2026-07-05 実測): 調査員A 315k / B 356k / 統括 213k tok
   → プライミング 15k の 14〜24 倍 → **全員 rotate が正**(継続は経済的に不合理)

## 原則との接続

憲法「経験は mandate に外部化してから個体を入れ替える」の機構化。
ローテーション時は引き継ぎをファイル(ドラフト・ドクトリン)に置く —
インライン文脈は資産ではなくコストである。
