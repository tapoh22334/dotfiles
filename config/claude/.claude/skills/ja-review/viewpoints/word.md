# 言葉の観点:場違いな言葉

Applies to every kind of text: repository documents, Issue and PR bodies,
notes. Used by the `ja-word-reviewer` agent through the `ja-review` skill, and
read before writing.

A word carries the impression of the place where it is usually used. 「知見が
設計に効いた」 reads as an ad, 「sudo を打つ」 as talk, 「司令塔」 as an image,
even when the meaning is clear. In a technical document each of these costs the
reader a small translation step. Find such words and rewrite them in written Japanese.

## What counts

Find the words that are out of place in a technical document:
spoken words, ad-like phrases, words only used when people in a trade talk to
each other, and figurative images. Rewrite each in plain written Japanese.
The rewrite touches only that word or phrase — structure, parentheses, facts, numbers and degree of
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

Strict does not reach the established terms of the text's own field. In a
marketing note, 流入・オーガニック投稿・ネットショップ・ニッチ are the field's
names for things, and replacing them (流入 → 訪問, オーガニック投稿 → 広告でない
通常の投稿) was judged wrong. The test: would the word head a section in that
field's guides or reference material? If so, keep it. Counters such as
「スキル6本」 also stay.

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
assumes the memo means a saddle point), propose the change and mark it as
resting on an assumed meaning, so the user can check it.
