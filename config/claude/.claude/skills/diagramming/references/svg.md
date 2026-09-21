# SVG 手書き

Mermaid で表現できないときだけ SVG に降りる。手書きは制御できる代わりに
ズレやすいので、グリッドに乗せることで精度を担保する。

## 目次

- [いつ SVG にするか](#いつ-svg-にするか)
- [グリッドに乗せる](#グリッドに乗せる)
- [基本の型](#基本の型)
- [形で種類を分ける](#形で種類を分ける)
- [矢印](#矢印)
- [テキストの配置](#テキストの配置)
- [グルーピング](#グルーピング)
- [テーマ対応](#テーマ対応)
- [点検](#点検)

## いつ SVG にするか

Mermaid を先に試すのが原則。以下に当てはまるときだけ SVG にする。

- 配置を厳密に決める必要がある（Mermaid の自動レイアウトが意図と合わない）
- Mermaid に対応する図種がない（物理配置図、独自の表現）
- 図そのものが主成果物で、細部まで作り込む価値がある

逆に、頻繁に更新する図や、他人が編集する図は Mermaid のほうが良い。
テキスト差分が読めることの価値は大きい。

## グリッドに乗せる

**座標を目分量で決めない。** 単位を決めて、その倍数だけを使う。

```
単位 U = 20
ノード幅   = 8U = 160
ノード高   = 3U = 60
横の間隔   = 4U = 80
縦の間隔   = 3U = 60
```

こうすると、ノードの左端は必ず 20 の倍数になり、中心線も自動的に揃う。
「なんとなく揃えた」図は必ず 1〜3px のズレが残り、それが雑な印象を作る。

実装では変数として持つ:

```xml
<!-- U=20 グリッド。全ての座標は 20 の倍数 -->
<svg viewBox="0 0 720 400" xmlns="http://www.w3.org/2000/svg">
```

`viewBox` も グリッドの倍数にすると、余白が均等になる。

## 基本の型

```xml
<svg viewBox="0 0 720 320" xmlns="http://www.w3.org/2000/svg"
     font-family="system-ui, sans-serif" font-size="13">

  <defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5"
            markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 0 L 10 5 L 0 10 z" fill="currentColor"/>
    </marker>
  </defs>

  <g stroke="currentColor" fill="none" stroke-width="1.5">
    <!-- ノード -->
    <rect x="40" y="40" width="160" height="60" rx="2"/>
    <rect x="280" y="40" width="160" height="60" rx="2"/>
    <!-- 接続 -->
    <line x1="200" y1="70" x2="280" y2="70" marker-end="url(#arrow)"/>
  </g>

  <g fill="currentColor" text-anchor="middle" dominant-baseline="central">
    <text x="120" y="70">取り込み</text>
    <text x="360" y="70">変換</text>
  </g>
</svg>
```

要点:
- `currentColor` を使うと、埋め込み先の文字色に追従する（テーマ対応が楽）
- 線と文字を `<g>` で分けると、共通属性の指定が1箇所で済む
- `marker` は `defs` に1つ定義して使い回す

## 形で種類を分ける

SKILL.md の原則通り、種類ごとに形を変える。

```xml
<!-- 処理: 四角 -->
<rect x="40" y="40" width="160" height="60" rx="2"/>

<!-- データ: 平行四辺形 -->
<path d="M 60 40 L 220 40 L 200 100 L 40 100 Z"/>

<!-- 判断: ひし形 -->
<path d="M 120 30 L 200 70 L 120 110 L 40 70 Z"/>

<!-- 始点・終点: 角丸 -->
<rect x="40" y="40" width="160" height="60" rx="30"/>

<!-- 外部システム: 二重枠 -->
<rect x="40" y="40" width="160" height="60" rx="2"/>
<rect x="45" y="45" width="150" height="50" rx="2"/>
```

## 矢印

**線種で意味を分ける。** 色ではなく。

```xml
<!-- 主たる関係 -->
<line x1="200" y1="70" x2="280" y2="70" marker-end="url(#arrow)"/>

<!-- 副次的・例外 -->
<line x1="200" y1="70" x2="280" y2="70"
      stroke-dasharray="4 3" marker-end="url(#arrow)"/>

<!-- 強調（1本だけ） -->
<line x1="200" y1="70" x2="280" y2="70"
      stroke-width="3" marker-end="url(#arrow)"/>
```

**折れ線は直角で。** 斜め線が混ざると、どこが意図的かが読めなくなる。

```xml
<polyline points="200,70 240,70 240,170 280,170"
          marker-end="url(#arrow)"/>
```

折れ点もグリッドに乗せる（上の例では 240 = 12U）。

## テキストの配置

中央揃えは `text-anchor` と `dominant-baseline` の両方を指定する。
片方だけだと縦か横がズレる。

```xml
<text x="120" y="70" text-anchor="middle" dominant-baseline="central">ラベル</text>
```

`dominant-baseline="central"` はブラウザによって解釈が違うことがある。
確実にしたいなら `y` を微調整せず、`dy="0.35em"` を使う:

```xml
<text x="120" y="70" text-anchor="middle" dy="0.35em">ラベル</text>
```

長いラベルは `<tspan>` で改行する。SVG は自動折り返ししない。

```xml
<text x="120" y="60" text-anchor="middle">
  <tspan x="120" dy="0">クラスタ分け</tspan>
  <tspan x="120" dy="1.3em">（時刻ベース）</tspan>
</text>
```

`x` を各 `tspan` で指定し直すのを忘れない。忘れると左に寄っていく。

## グルーピング

```xml
<g>
  <rect x="20" y="20" width="420" height="120" rx="2"
        stroke-dasharray="3 3" fill="none" opacity="0.5"/>
  <text x="32" y="38" font-size="11" opacity="0.7">パイプライン</text>
  <!-- 中身のノード -->
</g>
```

- 囲みは破線か細線にして、中身より弱く見せる
- ラベルは左上に小さく置く
- 囲みの余白も グリッドの倍数にする（上の例では内側に 20 = 1U の余白）

## テーマ対応

埋め込み先が light / dark どちらでも読めるようにする。

**最も簡単な方法**: `currentColor` を使い、自分では色を指定しない。
文字色に追従するので、どちらのテーマでも自動的に読める。

```xml
<g stroke="currentColor" fill="none">
```

**塗りが必要な場合**: 不透明度で階調を作る。色を使わなければテーマに依存しない。

```xml
<rect fill="currentColor" opacity="0.08"/>
```

`fill="#fff"` や `fill="#000"` を直接書くと、片方のテーマで消える。

## 点検

- 全ての座標がグリッドの倍数になっているか
- 線と線の交差が最小か（ノードの配置換えで消せないか）
- テキストがノードからはみ出していないか（長いラベルは要注意）
- `viewBox` に対して余白が均等か
- 色を全部消しても（`currentColor` だけにしても）意味が伝わるか
- 同じ種類のノードが同じ形・同じサイズか
