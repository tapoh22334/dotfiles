# テストシナリオ: ui-catalog の残件 4 件を GitHub Issues の階層に切る

あなたはリポジトリ ui-dirction-catalog(UI 方向性カタログ。AI にアプリを作らせるとき、承認済みの
デザイン方向性を選んで従わせるための Web カタログ。Storybook でレビュー、注文書→取り込み→採否→
選定のスクリプトが揃い、手製 3 エントリで一周済み)の残件を GitHub Issues に登録する準備をしている。
GitHub Project「All Work」には Epic(type::epic)/ Story(type::story)/ Task(ラベルなし)の 3 階層で
載せる運用。

残件(前のトラッカーからの移行分):
1. 方針文書 docs/STRATEGY.md を提督が承認する(現在 PR #1 でレビュー中)
2. 暫定仕様を、手製 3 エントリの一周で見つかった穴 8 件(急ぎの引き金と静かな画面の反転、Web フォントが
   オフラインで撮れない、似すぎ判定の閾値が未校正 など)で改訂する
3. 注文書の固定部を GEPA(プロンプト最適化器)で最適化する。前提: 人の採否記録が 5〜10 件たまってから
4. 選ぶ側(app-flood 側で使う ui-direction-select)と育てる側(ui-direction-order)の 2 スキルを
   skill-creator で作る。select 側は app-flood リポジトリの裁定が必要

次にやること: 外部生成器(Figma Make / v0)の出力を 1 本流して取り込み手順の穴を直す、も控えている。

これらを Epic / Story / Task の木にして提案せよ。木と、各ノードの 1 行の意図を出すこと。
