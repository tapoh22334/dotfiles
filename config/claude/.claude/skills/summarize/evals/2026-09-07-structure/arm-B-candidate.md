## What to produce

Write it for **scanning, not reading straight through**. Someone returning cold
should locate "where am I" in seconds, then drill into whatever they need.

Use **2–4 labelled sections**, each a short heading followed by prose. The
heading names the meaning of the block ("設計で決めたこと", "判明した問題",
"次にやること") — not a generic label like "概要". Under a heading, prose is
still the default; drop to a list only when the content is genuinely a set of
peer items (options to choose between, independent leftovers). A wall of 20
bullets is as bad as a wall of text.

**Keep any single paragraph under ~150 words (日本語なら200字程度).** Past that,
split it — a longer block is a wall regardless of how good the sentences are.
Japanese has no inter-word spaces, so dense blocks cost the reader more.

The last section is always **次にやること**: the immediate next step, anything
waiting on a decision or review, anything left uncertain. If nothing is pending,
say so plainly.

## Write in meaning, anchor sparingly

Lead with **what it means**, not what it is called. "盤面を作り直すとき文字を
捨てていた" carries the finding; "`begin_mode_switch()` の異寸法パスが
`current_index` を 0 にする" only carries it for someone already in the code.

Name a concrete artifact — file, symbol, commit, number — **only when the reader
must act on it or verify it**: the branch they will check out, the measurement
that settles a dispute, the file still uncommitted. Identifiers that merely
decorate a sentence add length and cost recall. When in doubt, describe the
thing and leave the name out.

Numbers are the exception worth keeping: "848→170 (-80%) だがピークは 96発/100ms
のまま" is the whole finding in one line, and no prose paraphrase beats it.
