---
name: brief
description: >-
  Re-orient a returning user who has forgotten recent context: where the work
  stands in the overall flow, what was just being done, and the next actions —
  especially decisions only the user can make. Use whenever the user comes
  back after a gap and asks 今何してたっけ / 現状は? / どこまで進んだ? /
  作業に戻る / 状況教えて / brief / catch me up, or opens a session with a
  vague "continue"-like prompt after days away. Differs from the summarize
  skill (which captures state when STEPPING AWAY, from live conversation):
  brief reconstructs state when RETURNING, from persisted traces.
---

# Brief — 復帰ブリーフィング

離席していた提督が艦橋に戻ってきた。頭の中の作業スタックは消えている。
このスキルの仕事は、**60 秒で読める再着艦シート**を出すこと。書く側の
記憶ではなく、**残っている痕跡から**再構成する(セッションが新しければ
会話履歴は無い前提で動く)。

## 情報源(この順に当たり、無いものは飛ばす)

1. **メモリ** — MEMORY.md の索引と関連メモリファイル(ミッション・進行中
   プロジェクト・保留中の裁定が書いてあるはず)
2. **会話履歴**(同一セッション内なら)— 直近の未完タスクと約束
3. **git log** — 関係リポジトリの直近コミット(何が「完了」したかの証拠。
   コミットメッセージは嘘をつきにくい)
4. **タスク・バックグラウンド実行の状態** — 走りっぱなしのもの、待ち状態の
   もの(プロジェクト固有のダッシュボード・API があればそれも)
5. 情報源同士が食い違ったら、**新しい痕跡を優先し、食い違い自体を一行報告**

## 出力様式(この順・全体で 20 行以内目安)

```
## 現在地
(ミッション全体の中でどのフェーズにいるか — 1-2 文)

## 前回までに終わったこと
(3-6 個。それぞれ証拠つきで — コミット・ファイル・記録の所在)

## いま動いているもの
(自動で進行中のもの。無ければ「なし」)

## あなた待ち
(ユーザにしか決められない決定。最重要 — 無ければ「なし」と明言)

## 次の一手(推奨)
(上の「あなた待ち」が空なら、こちらが着手すべきこと 1-2 個)
```

## 原則

- **「あなた待ち」を絶対に埋もれさせない** — 復帰ユーザの最頻の疑問は
  「私は何かを止めているか?」。保留中の裁定・承認・号令はここに集める
- **内部識別子は初出時に一行の平文説明を付す**(プロジェクト名・候補名・
  記号コードをそのまま並べない。仮想の概念はその旨明示)
- 完了主張には証拠を添える(コミットハッシュ、ファイルパス、台帳の行)。
  痕跡が見つからないものは「未確認」と書く — 記憶で補完しない
- 読み手は疲れて戻ってきている。時系列の物語ではなく**現在の状態**を書く。
  経緯の詳細は求められたら出す
- 60 秒で読めない長さになったら、削るのは経緯・残すのは「あなた待ち」
