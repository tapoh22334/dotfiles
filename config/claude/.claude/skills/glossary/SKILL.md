---
name: glossary
description: Define a project's domain terms in a glossary and keep documents from drifting between several names for one thing. Picks each term from the field's established vocabulary, writes a one-sentence definition and the expressions to avoid, records it in the project glossary (or the user-level one for terms shared by every project), makes sure CLAUDE.md links to the glossary, and finds avoided expressions in documents. Use whenever the user says 用語集 / 用語を定義して / 用語を統一して / 用語の揺れ / 表記揺れ(言葉の) / 呼び方がバラバラ / この概念を何と呼ぶか / ドメイン用語 / glossary / terminology / define this term, when a new concept needs a name in a design doc, or when you notice one concept written two ways while writing or reviewing a document.
---

# glossary

A reader who meets 「按分」 in one file and 「家事按分」 in the next has to stop
and ask whether these are two things. One concept, one term, written the same
way everywhere — that is what the glossary is for. It also lets you write a
term once with care and then reuse it instead of re-deciding it each time.

## Where glossaries live

| Level | File | Holds |
|---|---|---|
| Project | the project's existing glossary if it has one, else `docs/glossary.md` | terms of this project's domain |
| User | `~/.claude/glossary.md` | terms the user uses with the same meaning in every project |

A term goes in exactly one of them. Put it at user level only when it means the
same thing across projects (the user's own working vocabulary, for example the
ticket levels); a domain term — tax, audio, a product's own concepts — stays in
its project even if two projects happen to share it today.

If `~/.claude` is managed from a dotfiles repository (`~/.claude/doc-style.md`
or `~/.claude/skills/*` are symlinks into it), create the user glossary in that
repository beside them and link it the same way, so it is versioned with the
rest.

## Steps

1. **Read both glossaries.** Find the project glossary: a link in the project's
   CLAUDE.md, else a file named like `glossary` / `用語集`. Read it and the
   user glossary, so you neither duplicate a term nor contradict one.

2. **Create what is missing.** If the project has no glossary and you are about
   to add a term, create it from `assets/glossary-template.md`. Then make sure
   the CLAUDE.md at the same level links to it; add this section if no link
   exists (project glossary → the project's CLAUDE.md, user glossary →
   `~/CLAUDE.md` or `~/.claude/CLAUDE.md`, whichever the user has):

   ```markdown
   ## 用語

   用語は [docs/glossary.md](docs/glossary.md) で定義している。文書・Issue・
   コメントを書く前に読み、定義された用語を使う。用語を足すときは glossary
   スキルに従う。
   ```

   A link, not an `@` import: the glossary grows, and loading it into every
   session costs context even when nothing is being written.

3. **Collect the concepts.** From the user's request, or by reading the
   project's documents for concepts that appear under more than one name.
   Running the check script (below) on existing entries also shows where drift
   already happened.

4. **Choose the term** for each concept with the criteria in the next section.
   When the field has primary sources (laws, official guidance, standards, the
   vendor's own documentation), look up how they write it — including kanji vs
   kana and 送り仮名 — and note the source.

5. **Write the entry.** One row per term (format below). The definition is one
   sentence: what kind of thing it is, and what sets it apart from its
   neighbours. Don't define a term with itself or with one of its avoided
   expressions.

6. **Unify the documents.** Run the check script on the project's documents and
   replace avoided expressions with the term in files that may be rewritten.
   Leave alone what the project says not to rewrite (append-only records, past
   decisions, frozen years — the project's CLAUDE.md says which); new text in
   those places uses the term. Report what you replaced and what you left.

## Choosing a term

- **Take the field's established term.** The test: would the word head a
  section or an index entry in that field's guides or reference material? If
  so, use it as written there. Don't coin a word where the field already has
  one; readers from the field will look for it.
- **Coin only for the project's own concepts**, and then name what the thing is
  (`週次レビュー`, `判定シート`), not a metaphor for it.
- **Not too short.** A bare generic word (処理・対応・データ・管理・情報) or a
  team-only abbreviation does not pick out one concept. Add the qualifier that
  does: 「経費」 is fine in a tax repository where nothing else competes, but
  「按分」 alone is ambiguous where 家事按分 is meant.
- **Not too long.** A descriptive phrase or a clause is a definition, not a
  term. The term must fit naturally into a sentence many times over; as a rough
  guide, two to eight characters of Japanese or one to three English words.
  Shorten from the end of a phrase toward its head noun, as the field does
  (自宅兼事務所の費用の事業分 → 家事按分).
- **One concept, one term; one term, one concept.** If the field uses one word
  for two concepts, define which one this project means and name the other
  explicitly.
- **Keep the field's own language.** If the field uses an English or katakana
  term (`インボイス`, `Story`), keep it; don't translate it into a Japanese
  phrase nobody in the field uses.

## Entry format

```markdown
| 用語 | 定義 | 避ける表現 |
|---|---|---|
| 家事按分 | 自宅と事業で共用する費用のうち、事業に使った割合だけを必要経費にすること。根拠:所得税法施行令第96条 | 按分、経費按分、家事分割 |
```

- **避ける表現**: the other names actually seen for this concept, separated by
  「、」. These are what the check script looks for, so list only expressions
  that should never mean this concept. A substring of the term is fine (「按分」
  above): occurrences inside the term itself are not reported.
- A source goes at the end of the definition as `根拠:...` when the term was
  taken from a primary source.
- Keep rows in 五十音順 / alphabetical order so a reader can scan.
- A table may be split under `##` headings by area once it passes a few dozen
  rows; the script reads every table whose header starts with `用語`.

## Check script

```bash
python3 ~/.claude/skills/glossary/scripts/check_terms.py [--glossary FILE ...] PATH...
```

Without `--glossary` it reads `docs/glossary.md` (if present) and
`~/.claude/glossary.md`. It prints `<file>:<line> 「避ける表現」→「用語」` for
each hit in Markdown and text files under PATH, skipping code blocks, inline
code and the glossary files themselves, and exits 1 when anything is found.
Hits are candidates: read each in context before replacing, since a word can be
an avoided expression in one sentence and an ordinary word in another.
