# 単体テスト実行計画

## 目的

ReNamery の実装整合性を、AI 主導で単体テスト化して確認する。

対象は、既存コードで確認できる以下を優先する。

- `RenameEngine`（リネーム処理）
- `DirectoryProvider.selectRange`（範囲選択処理）
- `FileModel`（ファイル状態モデル）
- `FileListPanel`（ファイル一覧 UI）における Shift 範囲選択の入口
- `SettingsService`（設定永続化サービス）

実装計画にある `isCtrlFixedMode`（Ctrl固定モード設定）は、現コード上では未確認のため、単体テスト対象ではなく「仕様差分」として扱う。

## ドキュメント管理方針

通常の開発ドキュメントとは分け、単体テスト計画関連は `docs/unit_test_plan`（単体テスト計画用フォルダ）配下で管理する。

| 物理名 | 役割 |
|---|---|
| `docs/unit_test_plan/README.md`（単体テスト実行計画） | 実行計画の本体 |
| `docs/unit_test_plan/cases/README.md`（AI生成テストケース管理） | AIが作成・更新するテスト観点、ケース表、期待値の管理 |
| `docs/unit_test_plan/mcp/README.md`（MCP運用メモ） | Dart/Flutter MCP の使い方、実行ログ、失敗分析メモの管理 |

## 実行方針

### フェーズ 0: ベースライン確認

目的は、テスト追加前の状態を把握すること。

実施内容:

- `flutter --version`（Flutter SDKバージョン確認）を確認する。
- `flutter pub get`（依存関係取得）を実行する。
- `flutter analyze`（静的解析）を実行し、既存警告やエラーを記録する。
- `flutter test`（Flutterテスト実行）を実行し、既存の失敗状態を確認する。
- 既存の `test/widget_test.dart`（既存ウィジェットテスト）はCounterテンプレート由来の可能性があるため、維持するか置き換えるか判断する。

成果物:

- `docs/unit_test_plan/mcp/README.md`（MCP運用メモ）または同フォルダ内のログに、初回実行結果を記録する。

### フェーズ 1: テスト対象の分離

目的は、UI と I/O に依存しないロジックから先に単体テスト化すること。

優先順位:

1. `RenameEngine.computeGeneratePreviews`（リネームプレビュー生成処理）
2. `DirectoryProvider.selectRange`（範囲選択処理）
3. `FileModel`（ファイル状態モデル）
4. `SettingsService`（設定永続化サービス）
5. `FileListPanel`（ファイル一覧 UI）

判断基準:

- 純粋関数または副作用が小さい処理を先にテストする。
- ファイルシステム、キーボード入力、Flutter UI に依存する処理は後段に回す。
- `DirectoryProvider`（ディレクトリ状態管理）は内部状態が大きいため、必要ならテスト用初期化方法を最小追加する。

### フェーズ 2: AI生成テストケースの作成

目的は、AIに仕様と実装からテスト観点を抽出させ、人間が確認できる形で残すこと。

管理場所:

- `docs/unit_test_plan/cases/README.md`（AI生成テストケース管理）

作成する観点:

- 正常系
- 境界値
- 逆順指定
- 空入力
- 重複名
- 無効なファイル名
- Windows、macOS、Linux で差が出る命名規則
- 選択状態の維持、反転、解除

AIに依頼する内容:

- 実装計画と現コードの差分を抽出する。
- `given / when / then`（前提 / 操作 / 期待結果）の形式でケース化する。
- 仕様未確定または実装未確認の項目を、テスト対象から分離する。

### フェーズ 3: 最小単体テストの実装

目的は、壊れやすい箇所を小さいテストで固定すること。

作成候補:

- `test/core/rename_engine_test.dart`（リネーム処理テスト）
- `test/core/directory_provider_selection_test.dart`（範囲選択テスト）
- `test/core/file_model_test.dart`（ファイル状態モデルテスト）
- `test/ui/file_list_panel_selection_test.dart`（ファイル一覧選択UIテスト）

最初に作るべきテスト:

- `RenameEngine.computeGeneratePreviews`（リネームプレビュー生成処理）の代表ケース
- `DirectoryProvider.selectRange`（範囲選択処理）の排他選択、逆順指定、基準状態ありの反転

実装ルール:

- 追加依存は最小にする。
- まずは `flutter_test`（Flutter標準テストライブラリ）だけで始める。
- モックが必要になった段階で `mocktail`（Dart向けモックライブラリ）などを検討する。
- 実装をテストしやすくするための変更は、公開APIの追加ではなく最小の内部整理を優先する。

### フェーズ 4: MCPによるAI主導実行

目的は、AIがテスト作成、実行、失敗分析、修正提案のループを回せるようにすること。

利用候補:

- `dart mcp-server`（Dart/Flutter公式MCPサーバー）

MCPで行うこと:

- Dart/Flutterシンボルの確認
- `flutter analyze`（静的解析）の実行
- `flutter test`（Flutterテスト実行）の実行
- 失敗ログの要約
- 失敗原因の分類

失敗原因の分類:

- 実装バグ
- テスト期待値の誤り
- 仕様未確定
- 環境依存
- 既存テストの陳腐化

### フェーズ 5: UI選択動作の検証

目的は、`FileListPanel`（ファイル一覧 UI）から `DirectoryProvider.selectRange`（範囲選択処理）への接続を確認すること。

対象:

- 通常クリック時にトグル選択されること。
- Shiftクリック時に範囲選択されること。
- 起点未設定のShiftクリックで例外にならないこと。
- ドラッグ範囲選択で選択状態が意図どおり反転または維持されること。

注意点:

- Flutter のキーボード状態とポインターイベントは単体テストよりウィジェットテスト向き。
- 最初から完全なE2Eにはせず、`DirectoryProvider`（ディレクトリ状態管理）側のロジックテストを先に安定させる。

### フェーズ 6: 仕様差分の扱い

目的は、実装計画と現コードのズレをテスト失敗として混ぜないこと。

現時点の差分:

- `isCtrlFixedMode`（Ctrl固定モード設定）は現コードから確認できない。
- `CategoryAdvanced`（高度設定カテゴリ）にも Ctrl 固定モードの設定UIは確認できない。
- 現在の `FileListPanel`（ファイル一覧 UI）は、Shift範囲選択を常にトグル系の挙動として扱っている。

対応:

- 未実装仕様は `pending`（保留）扱いにする。
- 実装済み挙動のテストと、将来仕様のテストを分ける。
- 将来 `isCtrlFixedMode`（Ctrl固定モード設定）を実装する場合は、別フェーズで設定永続化、UI、選択分岐のテストを追加する。

## 完了条件

最初の完了条件:

- `RenameEngine.computeGeneratePreviews`（リネームプレビュー生成処理）の主要ケースがテストされている。
- `DirectoryProvider.selectRange`（範囲選択処理）の主要ケースがテストされている。
- `flutter test`（Flutterテスト実行）が通る、または既存失敗と新規失敗が分離されている。
- `flutter analyze`（静的解析）の結果が記録されている。
- AI生成テストケースとMCPメモが、通常ドキュメントとは別フォルダで管理されている。

拡張完了条件:

- `FileListPanel`（ファイル一覧 UI）のクリック、Shiftクリック、ドラッグ選択がウィジェットテストで確認されている。
- `SettingsService`（設定永続化サービス）の対象設定がテストされている。
- `isCtrlFixedMode`（Ctrl固定モード設定）が実装された場合、そのON/OFF分岐がテストされている。

## 推奨順序

1. `docs/unit_test_plan/cases/README.md`（AI生成テストケース管理）にテストケース表を作る。
2. `test/core/rename_engine_test.dart`（リネーム処理テスト）を追加する。
3. `test/core/directory_provider_selection_test.dart`（範囲選択テスト）を追加する。
4. `flutter test`（Flutterテスト実行）を実行する。
5. `flutter analyze`（静的解析）を実行する。
6. 失敗結果を `docs/unit_test_plan/mcp/README.md`（MCP運用メモ）へ記録する。
7. UIテストと設定テストを追加する。

## 進捗

2026-06-30 時点で、以下を完了した。

- `docs/unit_test_plan/cases/README.md`（AI生成テストケース管理）に初期テストケースを作成。
- `test/core/rename_engine_test.dart`（リネーム処理テスト）を追加。
- `test/core/directory_provider_selection_test.dart`（範囲選択テスト）を追加。
- `test/widget_test.dart`（既存ウィジェットテスト）をCounterテンプレート前提からReNamery向けスモークテストへ置換。
- `test/ui/file_list_panel_selection_test.dart`（ファイル一覧UI選択テスト）を追加。
- `flutter test`（Flutterテスト実行）で全11件の通過を確認。
- `flutter analyze`（静的解析）で既存コード由来の125件を確認し、`docs/unit_test_plan/mcp/README.md`（MCP運用メモ）へ記録。
- 通常クリックとShiftクリックは自動検証できたため、現時点で手動テスト依頼は不要と判断。

次に実施する候補:

1. `flutter analyze`（静的解析）のwarningを優先して整理する。
2. `FileListPanel`（ファイル一覧UI）のShiftクリックとドラッグ選択をウィジェットテスト化する。
3. `SettingsService`（設定永続化サービス）をテストしやすい形へ分離する。
