[![CI](https://github.com/iwase22334/dotfiles/actions/workflows/main.yml/badge.svg)](https://github.com/iwase22334/dotfiles/actions/workflows/main.yml)

Usage
-----

```
git clone https://github.com/iwase22334/dotfiles .dotfiles
(cd .dotfiles && chmod +x setup.sh && ./setup.sh)
```

Claude skills
-------------

`config/claude` パッケージが `~/.claude/` へ `settings.json` / `agents` /
`commands` / `skills` を配置する。`setup.sh` が自動で stow するので追加操作は不要。

**他のリポジトリが所有するスキル**(value-forge の `vf-*`、claude-tower の
`tower`、proactive-work)は `config/claude/.claude/skill-sources.yml` が台帳で、
`setup.sh` → `scripts/sync-skill-sources.sh` が clone と配置を行う。スキルが
どこにあるかはこの 1 ファイルで分かる。台帳に無い symlink は
`scripts/sync-skill-sources.sh --check` が警告する(散らかり検査)。
新しい外部スキルを作ったら台帳に 1 エントリ足す。

次のものは意図的に管理外なので、`setup.sh` では復元されない:

| 対象 | 理由 | 復元方法 |
|---|---|---|
| `skills/*-workspace/` | スキル作成時の作業スクラッチ | 復元不要 |
| `skills/**/.cache.json` | 実行時キャッシュ。セッション履歴を含むため公開しない | 初回実行時に再生成 |
| `skills/doc-coauthoring` | `~/.agents/` のスキルマネージャが管理(台帳の `unmanaged`) | 同マネージャで再取得 |

秘密情報の流出防止
------------------

この repo は公開されている。しかも stow の symlink 越しに、ツールが repo 内のファイルを
直接書き換える。そのため、秘密情報が気づかないうちに差分へ混ざりやすい。次の層で止める。

| 層 | 止めるもの | 実体 |
|---|---|---|
| コミット時 | トークンなどの値、`.env` や鍵のファイル、LAN の IP、メールアドレス | `.githooks/pre-commit`(gitleaks と `.gitleaks.toml`) |
| コミット時 | Claude Code が `settings.json` に書き込む `autoMode.environment` | `.gitattributes` の clean フィルタ(`jq` で削除する) |
| push 時 | 正規表現で拾えない内部情報(ホスト名、秘密の置き場所の一覧など) | `.githooks/pre-push`(gitleaks と `claude -p` によるレビュー) |
| PR・push 後 | フックを迂回した変更 | CI の gitleaks と、GitHub の secret scanning・push protection |
| repo 外 | 秘密ファイルを他のユーザーが読めること | `scripts/setup-secret-guard.sh` がパーミッションを直す |

フック・フィルタの登録とパーミッションの修正は `setup.sh` が
`scripts/setup-secret-guard.sh` を呼び出して実行する。clone しただけではフックが有効にならない。

運用上の注意:

- clean フィルタは手元の `settings.json` を変えない。`environment` は手元に残り、
  コミットされる版からだけ消える。
- gitleaks が誤検知したときは `.gitleaks.toml` の allowlist を直す。`--no-verify` で
  黙らせると、CI で止まる。
- AI レビューは push のたびに 20 秒前後かかる。止まった理由を確かめたうえで
  省略するときは `SKIP_AI_REVIEW=1 git push` とする。
- 公開済みの履歴にある検出(LAN の IP など)は、履歴を書き換えずに
  `.gitleaks.toml` の allowlist でコミット単位で許可している。
