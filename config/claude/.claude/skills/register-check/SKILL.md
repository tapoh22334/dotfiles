---
name: register-check
description: Find words in a Japanese technical text that belong somewhere else — chat, sales copy, trade talk, net slang, figurative images — and rewrite them in plain written Japanese, changing nothing else. Catches 「設計に効く」「ユーザーに刺さる」「解像度が上がる」「うっかり」「逃げ道」「sudo を打つ」「サーバーが落ちる」「4K に縛られる」. Use when the user says 位相 / レジスター / 言葉の場違い / 広告っぽい / 雑談っぽい / 話し言葉を直して / 書き言葉にして / 「〜に効く」みたいな言い回しを直して / register check, or when an Issue, PR body, README, design doc or Notion memo reads as if someone said it aloud. Not for structure, parentheses or list nesting (doc-style), and not for writing from scratch.
---

# register-check

A word carries the impression of the place where it is usually used. 「知見が
設計に効いた」 reads as an ad, 「sudo を打つ」 as talk, 「司令塔」 as an image,
even when the meaning is clear. In a technical document each of these costs the
reader a small translation step. This skill finds such words and rewrites them
in written Japanese.

## What to do

Read the text and find the words that are out of place in a technical document:
spoken words, ad-like phrases, words only used when people in a trade talk to
each other, and figurative images. Rewrite each in plain written Japanese.
Change nothing else — structure, parentheses, facts, numbers and degree of
certainty stay as they are.

## How strict

Strict. Change a word if a plainer written word exists for the same thing, even
when engineers use the word all the time. These were all judged as needing a
fix in real Claude-written texts:

| 原文 | 直し |
|---|---|
| sudo を打つ | sudo を実行する |
| UM560 が落ちたら | UM560 が停止したら |
| 動画の上限に縛られる | 動画の上限に制限される |
| ナイトモードが効かない | ナイトモードが適用されない |
| ノイズ低減はよく効く | ノイズ低減の効果は大きい |
| 正規表現で拾えない | 正規表現で検出できない |
| 見張り続ける / 見張るだけの役 | 監視し続ける / 監視するだけの役 |
| 構成の第一歩 | 構成の最初の段階 |
| 巻き戻し用に残す | 切り戻し用に残す |
| 思いつき / 手入れ | 未確約の案 / 保守作業 |
| 指摘されるかも | 指摘される可能性がある |

Words that only look technical are not exempt: 峠・壁・道 used for a saddle
point, a limit and a path are images, not names.

## Name the thing, don't shrink it

Rewrite to what the word actually points at. A shorter, vaguer word that
"fits every reading" loses the meaning and was judged worse every time:

| 原文 | 良い | 悪い |
|---|---|---|
| 逃げ道を削る | 例外の手順を削る | 例外を削る |
| 基本許可でよい | 原則として許可してよい | 原則として許可でよい |
| 司令塔から振り分ける | 管理用のマシンから振り分ける | 一か所から振り分ける |
| U が真上の世界と横倒しの世界 | U が鉛直に近い群と水平に近い群 | U が真上の群と横倒しの群 |
| 規則の取りこぼし | 規則の検出漏れ | 規則の違反を見落とすこと |

When the specific word rests on a reading the text does not state (峠 → 鞍点
assumes the memo means a saddle point), make the change and say so in the
report, so the user can check it.

## Output

1. The revised text. Apply it to a file, issue or page only on the user's say-so.
2. Each change as 「原文」→「直し」.
3. The changes that rest on an assumed meaning, with the assumption.
