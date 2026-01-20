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
| カテゴリ | 項目 | 状態 | 優先度 | 備考 |
|---|---|---|---|---|
| **Typography** | Type Scale | ✅ OK | 高 | `GoogleFonts.notoSansJpTextTheme` 適用済み。 |
| **Icon** | Menu Icon | ✅ OK | 高 | 戻るボタンは標準。メニューアイコンを `Icons.folder` (Primary Color) に統一。 |
| **Color** | Color Scheme | ✅ OK | 高 | `fromSeed` 使用。`primaryContainer`, `surfaceContainer` 等のロールを適用済み。 |
| **Color** | Dark Theme | ✅ OK | 高 | `ThemeMode` 設定 (System/Light/Dark) を実装済み。 |
| **Shape** | Corner Radius | ⚠️ N/A | 中 | デフォルトのM3形状を使用。特段のカスタマイズなし。 |
| **Layout** | Spacing | ✅ OK | 高 | 4dpグリッド (8dp/16dp/24dp) を適用済み。 |
| **Layout** | Breakpoints | ⚠️ 独自 | 高 | PC向け3ペイン維持のため、MD3標準 (840dp) より広い 1100dp を閾値として採用。 |
| **Motion** | Easing/Duration | 📝 Ready | 中 | `AppAnim` クラスに定数定義済み。実装時の標準として使用。 |
| **Component** | AppBar | ✅ OK | 中 | `SliverAppBar` ではないが、M3スタイルに準拠。 |
| **Component** | FAB | ⚠️ N/A | 低 | ReNameryではFAB未使用 (RunボタンはBottom Action)。 |
| **Component** | Navigation | ✅ OK | 高 | NavigationRail / Drawer 相当の機能を3ペインで実装。 |

## 4. レイアウト・スペーシング
- **現状**: `VisualDensity.compact`、固定マージン (4dp Grid)。
- **MD3 仕様**: 4dp グリッド、ブレークポイント (600, 840)。
- **対応**: 
    - マージン/パディングを 4dp/8dp に統一 (✅ 対応済み)。
    - ブレークポイント: 実用性優先のため独自設定 (1100/700) を維持 (⚠️ 独自仕様)。

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
