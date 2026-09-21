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

次のものは意図的に管理外なので、`setup.sh` では復元されない:

| 対象 | 理由 | 復元方法 |
|---|---|---|
| `skills/*-workspace/` | スキル作成時の作業スクラッチ | 復元不要 |
| `skills/**/.cache.json` | 実行時キャッシュ。セッション履歴を含むため公開しない | 初回実行時に再生成 |
| `skills/vf-*` | value-forge リポジトリが所有 | value-forge の `scripts/install.sh` |
| `skills/doc-coauthoring` | `~/.agents/` のスキルマネージャが管理 | 同マネージャで再取得 |
