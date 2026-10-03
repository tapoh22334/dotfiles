# proactive-work 設計(2026-09-27)

対象チケット: tapoh22334/dotfiles #6(Epic)/ #7・#8・#9(初回スライス)
先行調査: `docs/research/2026-09-23-proactive-agent-work.md`(判定: 部分自作)

## 目的

Claude Max サブスクリプションの**使わなければ消える枠**だけを使い、指示なしに
「採用される保守提案」を定期的に出す。希少なのはトークンではなく人のレビュー注意なので、
成果は行動回数ではなく**採用率**で測る。

## 決定事項

| 項目 | 決定 | 理由 |
|---|---|---|
| 実行ホスト | nuc11 のみ | 対象(`~/working/*` の未コミット変更等)がここにある。クラウド実行では見えない |
| 出力先 | 新設 private repo `tapoh22334/proactive-digest` の issue | private repo 名・ブランチ名を含む。スマホからチェックで採否を返せる |
| LLM の権限 | 読み取り専用。書き込み(issue 投稿・台帳)はラッパースクリプトだけが行う | gh-aw の safe outputs。LLM が書き込みを実行し得ない構造にする |
| 起動 | systemd user timer で3時間ごとに**ゲートを評価**し、通ったときだけ実行 | 固定曜日ではなく「週リセット直前の余り」に合わせる |
| 初回ジョブ | Git 後片付け(git-hygiene) | 判定が安く、正誤が事実で決まる |

## 課金の安全装置

2026-09 時点で `claude -p` はサブスクの利用上限から引かれる(従量課金への移行は 2026-06-15 に見送り。
https://support.claude.com/en/articles/15036540 )。自動で従量課金に落ちる経路を塞ぐ:

1. `ANTHROPIC_API_KEY` または `apiKeyHelper` が有効なら**中止**
2. `claude auth status` が `authMethod: claude.ai` かつ `subscriptionType: max` でなければ**中止**
3. usage credits(超過分の従量課金)は claude.ai 側で OFF にする(ユーザー操作。スクリプトからは確認不能なので README に明記)
4. `--max-budget-usd`(一覧価格換算)と `--max-turns` で1回の上限を切る
5. ポリシー再変更に備え、上記ヘルプ記事の確認を月1回ダイジェストの注意書きに出す(自動判定はしない)

## 「余り」の定義とゲート

### 使用率の取得

利用上限の使用率はサーバー集計の**アカウント全体**の値として statusline の入力 JSON にだけ渡される
(`rate_limits.five_hour|seven_day.used_percentage`, `.resets_at`。
https://code.claude.com/docs/en/statusline )。`claude -p` からは読めないので:

- **usage-snapshot**(statusline スクリプト): 描画ごとに受け取った `rate_limits` を
  `~/.local/state/claude-usage/snapshots.jsonl` に追記(前回から5分未満なら追記せず `latest.json` だけ更新)。
  画面にはモデル名と 5h/7d 使用率を1行で出す
- 他端末(Mac mini・claude.ai)の使用分もこの値に含まれる
- `rate_limits` はサブスク利用時かつセッションの最初の応答後にだけ現れる。無いときは何も書かない
- 副作用: カスタム statusline を設定すると footer の操作ヒント(`esc to interrupt` 等)が消える
  (現在 statusLine は未設定)

### 判定

```
pace      = max(直近24hの傾き, 今週窓内の平均傾き)        [%/h]   ※データ不足時は 1.0
staleness = now - 最新スナップショット時刻                   [h]
margin    = 15 + pace × staleness                            [%]
projected = seven_day.used + pace × 週リセットまでの時間
surplus   = 100 - projected - margin
```

次の**全て**を満たすときだけ実行する(1つでも欠けたら理由をログに残して終了):

- 週リセットまで **24時間以内**(消える枠だけを使う)
- `surplus ≥ 2 × job_cost`(`job_cost` の初期値 10%。較正は保留事項)
- `five_hour.used < 50%`
- 最新スナップショットが24時間以内で、その `seven_day.resets_at` が未来(窓が切り替わった後は不明扱い)
- 直近60分に対話セッションの活動がない(`~/.claude/projects` の jsonl 更新時刻。proactive-work 自身の実行ディレクトリは除外)
- 今週の窓でまだ実行していない(1窓1回)

迷ったら実行しない側に倒す。判定材料が欠けたら不実行。

## 構成

置き場: `config/claude/.claude/skills/proactive-work/`(dotfiles 経由で `~/.claude/skills/` へ)

```
proactive-work/
  SKILL.md                 手動起動の入口と判断規律
  bin/run.sh               ゲート → 課金検査 → 採否回収 → 収集 → 判断 → 投稿 → 記録
  bin/gate.py              上記「判定」。exit 0=実行可 / 1=不可(理由を stdout に JSON)
  bin/usage-snapshot.sh    statusline 用
  bin/reap.py              前回ダイジェストの採否を台帳へ
  jobs/git-hygiene/collect.sh   事実だけを JSON で出す(LLM なし)
  jobs/git-hygiene/prompt.md    判断基準と出力形式
  systemd/proactive-work.{service,timer}
```

状態: `~/.local/state/proactive-work/`(`ledger.jsonl`, `runs.jsonl`, `run/` = claude -p の作業ディレクトリ, `lock`)

## 1回の実行

1. `flock` で多重起動を防ぐ
2. `gate.py` が不可なら終了
3. 課金の安全装置 1・2
4. `reap.py`: `proactive-digest` の既存ダイジェスト issue を読み、台帳に採否を追記
   - close 済み: ☑ = 採用 / ☐ = 却下
   - open のまま14日経過: 未回答として記録し、コメントを付けて close
5. 各ジョブの `collect.sh` を実行し、事実 JSON を作る
6. `~/.local/bin/claude -p --model sonnet --max-turns 10 --max-budget-usd 3 --output-format json --tools "Read,Grep,Glob" --strict-mcp-config`
   に事実 JSON と `prompt.md` を渡す。出力はダイジェスト本文の Markdown のみ。
   - **`--tools` で道具そのものを3つに絞る**。`--allowedTools` は許可の追加でしかなく、ユーザー設定の
     `permissions.allow` に `Edit`/`Write` が入っているため読み取り専用にならない(2026-09-27 実測)。
     `--tools` 指定時は Edit/Write/Bash/Agent がコンテキストから消え、書き込みを試みることすらできない
   - `--strict-mcp-config`(`--mcp-config` なし)で claude.ai コネクタ(Notion/Gmail 等)も消える(実測)
   - **`--bare` は使わない**: 認証が `ANTHROPIC_API_KEY` のみになり従量課金経路に入る
   - `claude` は PATH に無い(systemd も同様)ので絶対パスで呼ぶ
   - 実測コスト(一覧価格換算): 最小呼び出しで $0.10(全ツール)→ $0.035(3ツール・MCP なし)。
     JSON に `total_cost_usd` と `modelUsage`(モデル名)が出る
7. 提案が0件なら投稿しない(沈黙も正解)
8. `gh issue create` で1本投稿。各提案は `- [ ] 本文 <!-- pw:<job>:<id> -->`。末尾に採用率・使ったモデル・一覧価格換算コスト・ゲート判定値
9. `runs.jsonl` に実行記録(モデル・コスト・ゲート値・提案数)

### git-hygiene の収集対象

`~/working/*`(シンボリックリンク先を含む git リポジトリ)と `~/.dotfiles`:
未コミット変更(最終更新時刻つき)、未 push コミット、main/master 上のローカル専用コミット、
マージ済みローカルブランチ、存在しないパスを指す worktree、stash。

### 判断規律(prompt.md / SKILL.md)

- 24時間以内に更新された変更は「作業中」として出さない
- 各提案に**根拠(観測事実)と推奨処置**を書く。削除系は「なぜ安全か」を必須
- 過去30日に却下された同一提案(`<job>:<id>` 一致)は出さない
- 水増ししない。該当なしは該当なし

## 失敗時

- どの段で失敗しても書き込みは起きない(投稿は最後の1手)
- 失敗は journald と `runs.jsonl` に残し、次回ダイジェスト冒頭に「前回の実行失敗」を1行出す
- `claude -p` がモデル指定と違うモデルで走った場合(JSON の `modelUsage` のキーに sonnet 以外が含まれる)は投稿せず失敗扱い
- `subtype` が `success` 以外(`error_max_turns` 等)は投稿せず失敗扱い

## テスト

- `gate.py`: スナップショット列の fixture で各条件(リセット24h外・余り不足・5h超過・古い・窓切替・活動中・今週実行済み)を単体テスト
- `collect.sh`: 一時ディレクトリに作ったダミーリポジトリ群で各検出項目を確認
- `reap.py`: issue 本文 fixture で採用/却下/未回答の判定
- `run.sh --dry-run`: ゲートを無視できる `--force-gate` と組み合わせ、投稿せずダイジェストを標準出力へ
- 本番: 無人実行1回の成功(#9 の完了条件)

## 保留(この spec の範囲外)

- `job_cost` の較正(実行前後のスナップショット差分から学習)— 実行記録が3回以上たまったら
- 採用率の低いジョブの自動停止、ジョブ追加(#11 保留判断チェック・#13 先回り調査)— Epic #6 の保留に従う

## 実装で変わった点(2026-09-27、レビュー反映)

- LLM は `--json-schema` の構造化出力で提案だけを返し、描画・キー・抑制・上限 10 件は `digest.py` が決める
- 提案キーは `<job>:sha1(repo|kind)`。モデルの言い回し(対象名の書き方)でキーが揺れて抑制が外れたため
- 抑制対象は「30 日以内に回答(採用/却下)済み」+「未回答で open のダイジェストに載っているもの」
- 判断(judge)・投稿(post)段で失敗した回は今週の窓を消費したとみなす(再実行による枠の浪費防止)。gate 自体の例外は exit 2 → 失敗として記録
- 24h 以内の活動は未コミット変更だけでなくブランチ・stash・default 直コミットも除外
- プロンプトは stdin 渡し(argv 128KiB 制限)。`--settings` で秘密パス(`~/.ssh` `~/.config` 等)の Read を deny(`//絶対パス` 形式で効くことを実測)
- collect: 他 worktree でチェックアウト中のブランチは「マージ済み」から除外、リモートの無いリポジトリは未 push を報告しない

## 週次 → 毎日(2026-10-03、利用者の判断)

週次ではジョブ 1 本(1 回 $0.03 程度)で週の余り(当時 82%)をほぼ使えないため、1 日 1 回までに変更。
- 「週リセット 24h 以内」「1 窓 1 回」を廃止し、「20h 以内に実行済み(判断以降の失敗を含む)なら不可」に置換
- 余りの条件を `surplus ≥ job_cost × (ceil(リセットまでの日数) + 1)` に変更。今日の分に加え残り日数分を予約するので、週の前半の実行が後半の利用者の分や実行を食わない
- 通知は増えない: 回答済み・掲載中の提案は抑制されるため、新しい提案が無い日は投稿しない
