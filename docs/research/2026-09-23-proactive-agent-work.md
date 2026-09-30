# 指示なしで価値ある保守作業を自動実行する仕組みの先行調査(2026-09-23)

*一次資料・規範外(参考文献)。仕様や正典の裁定を上書きしない。*

調査対象(実装非依存の1文): コーディングエージェントが余剰計算資源を使い、人の指示なしに
コードベース/プロジェクトの保守作業(整理・検証・調査・監査)を能動的に行い、その成果が
人の注意コストを上回る価値を持つようにする。

使った検索語: トークン有効活用 / 自動実行スキル → Continuous AI, agentic workflows,
background agents, ambient agents, proactive agents, mixed-initiative interaction,
safe outputs, effective false positive, bot noise / alert fatigue, hotspot (churn×complexity),
Large-Scale Change

## 判定

**部分自作** — トリガー(スケジュール実行)と各作業の中身(レビュー・エントロピー低減・
バックログ監査等)は既存物を採用し、自作は「価値ゲート」の薄い層だけにする。
すなわち (1) 出力を1本のダイジェストに束ねる、(2) 対象をホットスポットに絞る、
(3) 作業種別ごとの採用率を記録し低いものを止める、(4) 実行上限。
**常駐指揮官は作らない**(aquarium で実現不能と確定済み)。

根本的な再定義: 希少資源はトークンではなく**人のレビュー注意**。文献・事例とも一致して
「行動の回数」ではなく「採用された成果」で測れと言っている。

## 既存物の一覧

| 名前(出典) | 何をする物か | 生死 | 採否と理由 |
|---|---|---|---|
| Claude Code GitHub Action(https://code.claude.com/docs/en/github-actions) | cron/イベントで無人実行、PR・コメント出力。`--max-turns`/`--allowedTools` | 生 | **採用候補(トリガー層)**。GitHub 上のリポジトリならこれが最短 |
| Claude Code 組込み `schedule` スキル / `/loop`(ローカル環境のスキル一覧) | cron でクラウドエージェント実行 / 間隔実行 | 生 | **採用候補(トリガー層)**。ローカル完結ならこちら。Routines の一次資料は未確認(3rd-party: https://www.mindstudio.ai/blog/claude-code-routines-scheduled-agents) |
| Claude Code Code Review(https://code.claude.com/docs/en/code-review) | PR 自動レビュー | 生 | 採用候補(「ダブルチェック」をdiff時に載せる) |
| GitHub Agentic Workflows / gh-aw(https://githubnext.com/projects/agentic-workflows/) | Markdown で AI ワークフロー定義。既定 read-only、書込みは "safe outputs" 経由 | technical preview | **設計を借りる**(safe outputs)。Copilot 前提で Claude Code 主体の運用と合うかは未検証 |
| GitHub Next Continuous AI(https://githubnext.com/projects/continuous-ai/) | 概念枠: Continuous Documentation/Code Improvement/Triage/Quality 等 | WIP | 語彙を借りる。ユーザーの挙げた項目はほぼこの分類に収まる |
| Copilot coding agent(https://docs.github.com/copilot/concepts/agents/coding-agent/about-coding-agent) | スケジュール/イベントで PR 作成 | 生 | 見送り(Claude Code 主体の方針) |
| OpenAI Codex Automations(https://learn.chatgpt.com/docs/automations?surface=app) | 定期/イベントで triage・CI 失敗要約・リリース要約 | 生 | 見送り。ただし「最初の数回はレビュー」運用は借りる |
| Google Jules proactive(https://blog.google/innovation-and-ai/technology/developers-tools/jules-proactive-updates/) | 依存更新・lint・cleanup の定期ジョブ | 生 | 見送り(別エコシステム) |
| Devin scheduled(https://cognition.com/blog/devin-can-now-schedule-devins) | 自己スケジュールの定期 QA 等 | 生 | 見送り(有償・別環境) |
| CodeRabbit(https://www.coderabbit.ai/blog/how-coderabbits-agentic-code-validation-helps-with-code-reviews) | PR レビュー+投稿前の検証エージェント | 生 | 設計を借りる(投稿前に検証を挟んで偽陽性を削る) |
| Renovate(https://docs.renovatebot.com/) | 依存更新 PR、`prHourlyLimit`・grouping・dashboard | 成熟 | 設計を借りる(量の上限・束ねる・ダッシュボード1枚) |
| Ralph Wiggum plugin(https://github.com/anthropics/claude-code/blob/main/plugins/ralph-wiggum/README.md) | Stop hook で同じ prompt を反復、完了文字列+max-iterations | 生 | 見送り(検証可能な完了条件のある単発タスク用。保守の常時運用ではない) |
| night-shift script(https://jeangalea.com/claude-code-overnight/) | 夜間ジョブキュー、ジョブ毎に成果物ファイル | 個人事例 | 設計を借りる(1ジョブ1成果物、朝レビュー必須、「一部は捨てる」) |
| RunVouch 事後分析(https://dev.to/runvouch/my-claude-code-cron-ran-up-1800-in-two-nights-the-watchdog-that-stops-it-at-2-3npb) | cron で `claude -p` が再試行ループし2晩で $1,818 | 失敗事例 | 教訓: `ANTHROPIC_API_KEY` 混入で従量課金化、実行毎上限必須 |
| shipshitdev tech-debt skill(https://www.claudepluginhub.com/plugins/shipshitdev-tech-debt-skills-tech-debt) | 技術負債棚卸し→issue化 | 低採用 | 見送り(手元 code-entropy-improver と同等、実績薄) |
| 手元: code-entropy-improver(~/.dotfiles/config/claude/.claude/commands/code-entropy-improver.md @5ca3281) | テスト→静的解析→多重レビュー→リファクタ | 生・呼出し型 | **採用(作業本体)** |
| 手元: review-and-fix(同 commands/, 5レビュアー並列) | コード/テスト/設計/ドキュメントのレビューと修正 | 生・呼出し型 | 採用(ダブルチェック・ドキュメント整備の本体) |
| 手元: backlog-steward(~/.dotfiles/config/claude/.claude/skills/backlog-steward) | ボード監査→close/re-parent 提案(人が承認) | **古い**(Backlog.md前提) | 改造: GitHub Issues 版に更新してから採用 |
| 手元: metalize / adversarial-review(同 skills/) | メタ批評 / 主張の反証 | 生・呼出し型 | 採用。metalize の Stop hook 化は未了のまま |
| 手元: 組込み security-review | ブランチ差分のセキュリティレビュー | 生 | 採用(diff 時に限定) |
| 手元: claude-aquarium 指揮層(~/working/claude-aquarium @98654b7) | HQ 指揮官+指令キュー+常設チームで自律運用 | **凍結**(2026-07-11) | 却下。常駐AI指揮官・失敗の自動requeue は実現不能と確定。incidents: 安価モデル指定が効かず高価モデルで数時間走行、無監視 fleet の静かな劣化 |

## この領域の定石(体系知識)

- **行動の期待効用 > 中断・レビューのコスト のときだけ行動する**。タイミングは注意の空き時間に寄せる — Horvitz 1999 https://erichorvitz.com/chi99horvitz.pdf
- **常時提案は「邪魔」。状態を見て遅延させると採用率 4.9%→18.6%、無駄推論 −75%** — CHI 2025 https://arxiv.org/pdf/2410.04596
- **「沈黙も正しい出力」**。頻度でなく、正しい時に証拠つきで出したかで評価 — https://arxiv.org/html/2605.06717v1
- **Bot の主な苦情は冗長・頻度・頼まれていない行動** — Wessel et al. CSCW 2021 https://arxiv.org/pdf/2103.13950 。Dependabot も利用者が通知を絞り、11.3% が離脱 — https://link.springer.com/article/10.1007/s10664-024-10523-y
- **有効偽陽性(人が行動しない指摘)10% 以下**、diff 時の提示は単独レポートより許容される — Sadowski et al. CACM 2018 https://cacm.acm.org/research/lessons-from-building-static-analysis-tools-at-google/
- **自動修正は提案として、最も文脈を持つ人へ** — SapFix https://engineering.fb.com/2018/09/13/developer-tools/finding-and-fixing-software-bugs-automatically-with-sapfix-and-sapienz/
- **大きな変更は所有者単位の小さな独立レビュー単位に分割** — Google LSC/Rosie https://abseil.io/resources/swe-book/html/ch22.html
- **ホットスポット(変更頻度×複雑度)に集中**。コードの1-2%が保守の大半 — Tornhill https://www.adamtornhill.com/articles/crimescene/codeascrimescene.htm
- **Goodhart**: 「削減したエントロピー量」「閉じたissue数」を目標にすると見せかけの編集が増える — https://jellyfish.co/blog/goodharts-law-in-software-engineering-and-how-to-avoid-gaming-your-metrics/
- **Chesterton's fence**: 削除系の自動作業は「なぜ安全か」の根拠(blame・テスト・参照)を添付 — https://josephwoodward.co.uk/2020/04/software-the-chestertons-fence-principle
- **作業種別ごとの採用/マージ率がKPI兼キルスイッチ** — https://arxiv.org/html/2602.08915v2

## 見送った候補と理由

- aquarium 指揮層型(常駐指揮官が次の仕事を決める): 手元で試して凍結済み。失敗点はタスク論理ではなく無人のディスパッチ(コスト漂流・静かな劣化・実行ポリシーの来歴が見えない)。
- Ralph ループ型: 検証可能な完了条件がある単一タスク向け。「価値あることを探す」は完了条件が無く、止まらないか偽の完了を宣言する。
- 他社エージェント(Copilot/Codex/Jules/Devin): 機能は近いが Claude Code 主体の運用から外れる。設計(safe outputs、初回レビュー、量の上限)だけ借りる。
- 「何でも屋」の自律改善プロンプト: 全事例で最も捨てられる出力。night-shift の成功例は狭い範囲のジョブのみ。

## 自作する場合に引き継ぐもの

- 出力は **1回の実行=1つのダイジェスト**(issue 1本 or ファイル1本)。PR や個別コメントを乱発しない(Renovate dashboard / gh-aw status report)
- 書き込みは **read-only 実行 → 提案 → 人が承認**(gh-aw safe outputs、backlog-steward の既存流儀)
- 対象選定は **git churn × 複雑度のホットスポット**、または直近の差分に限る
- 作業種別ごとに **採用/却下を台帳に記録**、採用率が低い種別は自動停止(Tricorder 10%)
- 投稿前に **adversarial-review 相当の検証を1段** 挟む(CodeRabbit)
- 実行上限: max-turns、実行毎の予算、**`ANTHROPIC_API_KEY` が無いことの確認**(RunVouch)、安価モデル指定が実際に効いているかの記録(aquarium incident)
- 削除系は根拠の添付を必須に(Chesterton)
- 語彙: Continuous Documentation / Code Improvement / Triage / Quality(GitHub Next)
