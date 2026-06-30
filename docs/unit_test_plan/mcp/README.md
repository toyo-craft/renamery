# MCP運用メモ

このフォルダでは、Dart/Flutter MCP を使ったテスト実行、静的解析、失敗分析の記録を管理する。

## 想定ツール

- `dart mcp-server`（Dart/Flutter公式MCPサーバー）
- `flutter test`（Flutterテスト実行）
- `flutter analyze`（静的解析）
- `flutter pub get`（依存関係取得）

## 記録テンプレート

| 日付 | 実行内容 | 結果 | 失敗分類 | メモ |
|---|---|---|---|---|
| 2026-06-30 | `dart format test/core/rename_engine_test.dart test/core/directory_provider_selection_test.dart`（追加テストの整形） | 成功 | なし | 2ファイル整形、変更なし |
| 2026-06-30 | `flutter test`（Flutterテスト実行） | 失敗 | obsolete_existing_test | 新規追加したロジックテスト9件は通過。既存の`test/widget_test.dart`（既存ウィジェットテスト）がCounterテンプレート前提で失敗 |
| 2026-06-30 | `dart format test/widget_test.dart`（既存テスト置換後の整形） | 成功 | なし | 1ファイル整形、変更なし |
| 2026-06-30 | `flutter test`（Flutterテスト実行） | 成功 | なし | 全10件通過。`DirectoryProvider`（ディレクトリ状態管理）テストでテスト環境のネイティブプラグイン未登録ログは出るが、内部捕捉されテスト失敗なし |
| 2026-06-30 | `flutter analyze`（静的解析） | 127件検出 | environment_issue | 既存コード由来のinfo/warningが中心。今回追加したテストファイル由来の指摘はなし |
| 2026-06-30 | `flutter test test/ui/file_list_panel_selection_test.dart`（ファイル一覧UI選択テスト） | 成功 | なし | 通常クリックとShiftクリックによる範囲反転を自動検証 |
| 2026-06-30 | `flutter test`（Flutterテスト実行） | 成功 | なし | 全11件通過。テスト環境のネイティブプラグイン未登録ログは継続するが、内部捕捉されテスト失敗なし |
| 2026-06-30 | `flutter analyze`（静的解析） | 125件検出 | environment_issue | 未使用警告を安全に削除し、残りは既存コード由来のinfoのみ |

## 失敗分類

| 分類 | 意味 |
|---|---|
| implementation_bug | 実装バグ |
| test_expectation_error | テスト期待値の誤り |
| spec_pending | 仕様未確定 |
| environment_issue | 環境依存 |
| obsolete_existing_test | 既存テストの陳腐化 |

## 初回実行メモ

- `test/widget_test.dart`（既存ウィジェットテスト）はCounterテンプレート由来だったため、`ReNameryApp`（アプリ本体）のスモークテストへ置き換えた。
- `DirectoryProvider.selectRange`（範囲選択処理）のテストは、一時ディレクトリに4件のファイルを作成し、`setDirectory`（ディレクトリ設定）で読み込ませる方式で実装した。
- `DirectoryProvider`（ディレクトリ状態管理）のテスト実行中、`path_provider`（パス取得プラグイン）と`super_clipboard`（クリップボードプラグイン）の未登録ログが出る。現状は内部で捕捉され、テスト結果には影響していない。
- `flutter analyze`（静的解析）の127件は、主に既存コードの`curly_braces_in_flow_control_structures`（if文の波括弧省略）、`deprecated_member_use`（非推奨API使用）、`unused_import`（未使用import）、`unused_field`（未使用フィールド）である。
- `flutter analyze`（静的解析）の最新結果は125件で、主に既存コードの`curly_braces_in_flow_control_structures`（if文の波括弧省略）、`deprecated_member_use`（非推奨API使用）である。
- 通常クリックとShiftクリックは自動テスト化できたため、現時点で手動テスト依頼は不要。
