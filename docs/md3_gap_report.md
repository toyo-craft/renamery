# Material Design 3 準拠ギャップレポート

**対象プロジェクト**: ReNamery (Flutter)

## 1. カラーシステム
- **現状**: `ColorScheme.fromSeed` で生成したが UI で `primaryContainer` 等未使用。
- **MD3 仕様**: Tonal Palette（Primary/Secondary/Tertiary/Neutral）を階層的に使用。
- **ギャップ**: 固定色 (`Colors.green`) に依存。
- **対策**: 各ウィジェットで `Theme.of(context).colorScheme.primaryContainer` 等を参照し、Surface Containers (`surfaceContainerLow/High`) を適切に割り当てる。

## 2. Typography
- **現状**: `Segoe UI` をハードコードし、サイズを直接指定。
- **MD3 仕様**: Roboto/Noto 系フォントと `TextTheme` の 15 種類（`displayLarge` 〜 `labelSmall`）を使用。
- **ギャップ**: フォントとサイズが統一されていない。
- **対策**: `GoogleFonts` で Roboto/Noto を導入し、`Theme.of(context).textTheme.bodyMedium` などを利用。必要なら `copyWith` で微調整。

## 3. コンポーネント
| コンポーネント          | 現状                         | MD3 期待                                                | ギャップ             | 対策                                  |
| ---------------- | -------------------------- | ----------------------------------------------------- | ---------------- | ----------------------------------- |
| Buttons          | `ElevatedButton` にカスタムスタイル | 角丸 20dp、Elevation が状態に連動                              | カスタムスタイルが残る      | `styleFrom` を削除しデフォルトに任せる           |
| TextField        | `OutlineInputBorder` 使用    | Filled スタイルが推奨                                        | スタイルは許容範囲        | 必要なら `filled: true` に変更             |
| NavigationDrawer | 独自ツリービュー実装                 | 標準 `NavigationDrawer` + `NavigationDrawerDestination` | 階層構造が MD3 に合わない  | 現状維持（MD3 ではフラットリスト）                 |
| Tabs             | `TabBar` 使用                | Primary/Secondary Tab の区別、Indicator カスタマイズ            | Indicator がデフォルト | `TabBarTheme` で `indicatorSize` 等設定 |
| Dialogs          | `AlertDialog` 使用           | 角丸 28dp、タイトル配置                                        | ほぼ準拠             | 追加調整不要                              |

## 4. レイアウト・スペーシング
- **現状**: `VisualDensity.compact`、固定マージン。
- **MD3**: 4dp グリッド、`compact` は -2dp、`-4dp` が最小。
- **ギャップ**: マージンが 8/12/16 の倍数でないケースあり。
- **対策**: パディング・マージンを 4 の倍数に統一し、ブレークポイントを公式 (600dp, 840dp) に合わせる。

## 5. モーション
- **現状**: デフォルト `Curves.ease`、Duration 150‑300ms。
- **MD3**: 4 種類のイージング（Emphasized, Standard, Accelerated, Decelerated）と推奨 Duration。
- **ギャップ**: 明示的なイージング指定がない。
- **対策**: `CurveTween` で公式カーブ (`cubic(0.2,0,0,1)` 等) を適用し、定数化。

## 6. 準拠が困難な部分
- **NavigationPanel（フォルダツリー）**: MD3 の `NavigationDrawer` は平坦リスト向けで階層表現が不適。
- **FileListPanel（データグリッド）**: MD3 に明確な DataTable 定義が無く、デスクトップ向けカスタム実装が必要。
- **SettingsPanel（多機能タブ）**: 情報密度が高く、MD3 の余白指針を厳守すると UI が過度に長くなるため、実用上は妥協が必要。

---
**結論**: 現在の準拠度は約 60‑70%。自動で対応できる部分はボタン・ダイアログ等の標準ウィジェット。カラー、タイポグラフィ、スペーシング、モーションは手動リファクタリングが必要。上記「準拠が困難」な領域は独自実装を維持しつつ、可能な範囲で MD3 のビジュアルガイドラインに合わせることを推奨します。
