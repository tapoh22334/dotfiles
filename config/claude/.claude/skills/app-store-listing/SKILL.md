---
name: app-store-listing
description: >-
  Take an app from "the build is on TestFlight" to "submitted for review" on
  the App Store: write the listing (subtitle, promotional text, description,
  keywords) in Japanese and English, write the App Review notes, prepare the
  screenshots and previews, and fill every App Store Connect screen with a
  reason for each value. Use whenever the user is preparing an App Store
  submission or update — App Store 提出 / 審査に出す / 掲載文 / 説明文を書いて /
  サブタイトル / プロモーションテキスト / キーワード / 審査メモ / Notes /
  スクリーンショットの寸法 / App Store Connect の設定 / 年齢制限 / DSA /
  著作権の欄 / app store listing / ASO / review notes / submit to App Store.
  Also use when a store field is being changed after launch (keywords from
  search-term data, promotional text swaps).
---

# app-store-listing — 掲載文から提出まで

Distilled from the first submission of MA: SplitFlap (2026-11). The worked
example lives in that repo: `docs/app-store-metadata.md` (final copy, review
notes, claim/evidence table) and `.agents/product-marketing.md` (the context
doc). Read them when you need a concrete instance of a step below.

App Store Connect changes its screens and size lists often. Values in
`references/asc-screens.md` are **as of 2026-11**. When the user pastes text
from the ASC screen, that text wins over this skill and over your memory.

## Order of work

Each step produces a file or a decision the next step depends on.

| # | Step | Output | Who decides |
|---|------|--------|-------------|
| 1 | Find what already exists | list of past drafts, decisions, brand docs | — |
| 2 | Context doc (`product-marketing` skill) | `.agents/product-marketing.md` | owner fills the judgment fields |
| 3 | Copy (`copywriting` skill, then the rules below) | subtitle, promo, description, ja + en | owner picks among 2–4 options per field |
| 4 | Fact check every line against the code | claim → file:line table in the metadata doc | — |
| 5 | Keywords | 100-char lists, ja + en | launch with an estimate, revise later |
| 6 | Review notes | Notes text | — |
| 7 | Media | screenshots + previews per required slot, one zip | owner uploads |
| 8 | ASC screens, one at a time | values + reasons | owner enters them |

### 1. Find what already exists

Before drafting, search past sessions, Notion and issues for an earlier
draft. On MA a full rewrite from two days earlier sat in an old session,
waiting for a decision nobody remembered, and never reached the repo. Also
find the brand or philosophy docs: copy written without them drifted from
the brand's own rules on wording.

### 2. Context doc

Run `product-marketing`. Ask the owner only what only they can answer:
who it is for, the voice, who it is not for, and **where the maker's
philosophy goes**. On MA the owner's answer set the whole tone:

> 私の言及はあくまでも哲学の話なので、ユーザに対してはビジネスとしてわかりやすく伝わるようにする。世界観を保ちつつほしいと思わせたい。

Default to that split unless told otherwise: philosophy stays on the
maker's own site and social posts. The store copy says what the app is and
what happens on screen, in plain words.

Ask for real user words ("what did people say when they tried it?"). One
phrase from a tester (落ち着く) ended up in the subtitle.

### 3. Copy

Run `copywriting`. An owner with opinions is situation **B**: keep their
words (パタパタ, モダン, 置時計), do not swap in yours. Then apply these
store-specific rules, each learned from a correction on MA:

**Give each field one job.** The product page shows subtitle → promotional
text → description stacked together, so a word repeated across them reads
as padding (MA had パタパタ ×3 and 置時計 ×3 before the fix).

| Field | Limit | Indexed for search | Changes need review | Job |
|---|---|---|---|---|
| Name | 30 | yes | yes | the brand |
| Subtitle | 30 | yes | yes | say what it is, with one search word |
| Promotional text | 170 | **no** | **no** | the first sentence people read; the main hook. Optional |
| Description | 4000 | no | yes | for people who tap "more": features, modes, facts |
| Keywords | 100 | yes | yes | hidden; words not already in name or subtitle |

**Write what happens, not what it is not.** 「時刻を出さない」 and
「録音した雨音ではありません」 were both rejected. State a real absence
once at most, at the end (広告とアカウント登録はありません).

**Break the AI rhythm.** Three sentences with the same length and ending,
paired phrases (小雨から強い雨まで), and aphorism-like closers
(時間の流れを知らせる) all read as machine-written. What survived was a
plain observed fact: 「たまに強く降ります」.

**Drop metaphors the reader has not lived.** 「空港や駅の案内板のように」
was cut: few people have seen one. Annotated wordplay (間(ま)) was cut from
the description; if the owner likes it, the promotional text is the place
to try it, since it can change without review.

**Check strict meaning.** The owner asked what a clock is. Rain mode only
shows that time passes, so 「秒針の代わりに」 overstates it. Decide such
cases with the owner instead of letting them through.

**Name features by what the code does.** The timer had 25/5/15-minute
presets but no automatic work/break cycle. "Pomodoro timer" would promise
the cycle; 「ポモドーロの 25 分と 5 分のプリセット」 / "handy for Pomodoro"
does not. ("Pomodoro Technique" is a registered trademark; describing a
timer with it is common, naming the app with it is not advised.)

**Do not write claims that bind the future or argue with others.**
「データを集めません」 was removed: if analytics is added later, the
description becomes false, and App Privacy already states it. Comparisons
with other apps, or with the app's own web version, were also removed.

**English is its own copy, not a translation.** Check US idioms ("drum
roll" means drums → "scroll wheel"), Apple's spelling ("Silent mode"), the
30-char subtitle, and bullets. `•` and plain section titles are normal in
English listings; use `・` and `■` in Japanese.

**Reviewer output tuned for technical docs hardens consumer copy.** When
`ja-review` proposes 「合成していて」「消灯せずに表示されたまま」, keep the
plain wording if the owner chose a close, spoken distance. Take only the
fixes that remove ambiguity.

**Format the doc for pasting.** Put each field, per locale, in its own
```` ```text ```` block in the metadata doc. The owner copies from there into
ASC; prose around the blocks is for reasons, never for content.

### 4. Fact check

Before the owner pastes anything, map every factual line to code:
`TimerControls.tsx:11` for the presets, `rain.rs:43-45` for segment
lengths, and so on. Keep the table in the metadata doc. On MA, the line
「サイレントモードのときに音を鳴らすかどうかも選べます」 went into the
draft with no such setting in the app; the owner caught it, not the review.
A line with no evidence is removed or marked `[要実機確認]`.

Lines that depend on an unfinished device test (e.g. "plays alongside your
music") stay out until the test passes.

### 5. Keywords

- Do not repeat words from the name or subtitle; ASC combines them.
- Add alternate spellings of the subtitle's word (置時計 → 置き時計) and
  near synonyms (卓上時計).
- Skip head terms the big apps own (デジタル時計, 集中 is Forest's).
- Launch with an estimate. Revise 2–4 weeks after launch from the search
  terms in App Store Connect analytics. Score candidates as
  **popularity (Apple Search Ads, 5–100) × chance to rank (rating counts of
  the current top results) × relevance (hand-scored 1–3)**. Multiply rather
  than add, so a word that is zero on any axis drops out. File the revision
  as an `idea` issue with the trigger "2 weeks after launch".

### 6. Review notes

The Notes box under App Review Information is the right field even though
its tooltip talks about China permits. Write for a reviewer who has two
minutes:

- one paragraph: what the app is
- HOW TO USE: account needed or not, what the first screen is, how to move
  around (gestures are invisible — say "swipe left or right"), where
  settings are, orientation per device
- any behavior that could look like a guideline problem, with the reason
  (MA: plays in Silent mode and mixes with other audio → state the audio
  session category and option, and that volume can be set to 0)

Do not argue why the app differs from other apps or from its web version;
it invites a 4.2 (minimum functionality) or 4.3 reading. Re-check every
number against the current code: the draft carried rain durations from an
older version.

### 7. Media

See `references/asc-screens.md` for slots and sizes. Points that cost time:

- The medium iPhone slot (6.1"/6.3") is now the required one, and its media
  is reused for every iPhone size and every locale.
- Resize from the largest capture: scale to cover, then center-crop to the
  exact size. Check that nothing important is cut.
- A landscape-only iPhone app may have screens that cannot be captured
  usefully (MA's settings sheet covers the board); say so instead of
  forcing a shot.
- Put every final file in **one zip** on a GitHub Release
  (`iphone/`, `ipad/`, `header/`). The owner should not download twenty
  files one by one.

### 8. ASC screens

Walk the owner through one screen at a time, in Japanese, with the value
and the reason for each field. `references/asc-screens.md` has the field
map: which screen holds which field, what can change without review, and
the answers that fit an offline single-purpose tool. Personal data (address,
phone, legal name) is entered by the owner; never write it into docs,
issues, or commits — write only the format.

## Before you report "ready to submit"

- [ ] Every pasteable field is in a code block, ja and en, within limits
- [ ] Every factual line has a file:line or a device-test reference
- [ ] Review notes re-checked against the current build
- [ ] Device test done **with other audio playing** if the app makes sound
      (on MA the flaps were too quiet next to music; found the day of
      submission)
- [ ] Support URL and privacy policy URL return 200 on the live site
- [ ] Media zip on the Release, all required slots filled
- [ ] Deferred items (DSA, Mac, keyword revision) are issues, not memory
