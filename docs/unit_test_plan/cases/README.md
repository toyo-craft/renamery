# AI生成テストケース管理

このフォルダでは、AI が作成・更新する単体テスト観点とケース表を管理する。

## 管理対象

- `RenameEngine`（リネーム処理）の入力と期待結果
- `DirectoryProvider.selectRange`（範囲選択処理）の選択状態遷移
- `FileModel`（ファイル状態モデル）の状態変更
- `FileListPanel`（ファイル一覧 UI）のクリック、Shiftクリック、ドラッグ選択
- `SettingsService`（設定永続化サービス）の設定読み書き

## ケース記述形式

| ID | 対象 | 前提 | 操作 | 期待結果 | 状態 |
|---|---|---|---|---|---|
| UT-001 | `RenameEngine.computeGeneratePreviews`（リネームプレビュー生成処理） | `report_final.txt`（対象ファイル名） | `final`（検索文字）を`draft`（置換文字）へ通常置換 | `report_draft.txt`（新ファイル名）になり、エラーなし | implemented |
| UT-002 | `RenameEngine.computeGeneratePreviews`（リネームプレビュー生成処理） | `chapter_12.mp4`（対象ファイル名） | 正規表現`chapter_(\d+)`（検索パターン）を`episode_$1`（置換文字）へ置換 | `episode_12.mp4`（新ファイル名）になり、エラーなし | implemented |
| UT-003 | `RenameEngine.computeGeneratePreviews`（リネームプレビュー生成処理） | `photo.JPG`（対象ファイル名） | 拡張子を`png`（変更後拡張子）へ変更 | `photo.png`（新ファイル名）になり、エラーなし | implemented |
| UT-004 | `RenameEngine.computeGeneratePreviews`（リネームプレビュー生成処理） | `report.txt`（対象ファイル名） | 先頭に`20260630_`（追加文字）を付与 | `20260630_report.txt`（新ファイル名）になり、エラーなし | implemented |
| UT-005 | `RenameEngine.computeGeneratePreviews`（リネームプレビュー生成処理） | `report.txt`（対象ファイル名） | Windows検証で`:bad`（使用不可文字を含む追加文字）を末尾に付与 | エラー`ファイル名に使用できない文字が含まれています`（無効文字エラー）が設定される | implemented |
| UT-006 | `RenameEngine.computeGeneratePreviews`（リネームプレビュー生成処理） | `abc`（対象ファイル名） | 先頭から3文字を削除 | エラー`ファイル名が空です`（空ファイル名エラー）が設定される | implemented |
| UT-007 | `DirectoryProvider.selectRange`（範囲選択処理） | 4件すべて未選択 | `selectRange(1, 2)`（排他範囲選択）を実行 | 選択状態が`[false, true, true, false]`（2件選択）になる | implemented |
| UT-008 | `DirectoryProvider.selectRange`（範囲選択処理） | 4件すべて未選択 | `selectRange(3, 1)`（逆順範囲選択）を実行 | 選択状態が`[false, true, true, true]`（3件選択）になる | implemented |
| UT-009 | `DirectoryProvider.selectRange`（範囲選択処理） | 選択状態`[true, false, true, false]`（初期選択） | `baseStates`（基準選択状態）ありで範囲選択 | 範囲内だけ反転し、範囲外は維持される | implemented |
| UT-010 | `FileListPanel`（ファイル一覧UI） | 起点未設定 | Shiftクリック | 例外なく通常クリック相当または未処理として扱われる | pending |
| UT-011 | `SettingsService`（設定永続化サービス） | `isCtrlFixedMode`（Ctrl固定モード設定）が存在する | ON/OFFを保存して再読込 | 保存値が復元される | pending |
| UT-012 | `FileListPanel`（ファイル一覧UI） | `isCtrlFixedMode`（Ctrl固定モード設定）がOFF | 通常クリック | Windows標準の排他選択になる | pending |
| UT-013 | `FileListPanel`（ファイル一覧UI） | 4件表示、2件目を通常クリック済み | Shiftを押しながら4件目をクリック | 選択状態が`[false, false, true, true]`（範囲内反転）になる | implemented |

## 状態定義

| 状態 | 意味 |
|---|---|
| draft | AI生成直後で未確認 |
| reviewed | 人間またはAIレビュー済み |
| implemented | テスト実装済み |
| pending | 仕様未確定または実装未確認 |

## 現時点の扱い

- UT-001 から UT-006 は、`RenameEngine.computeGeneratePreviews`（リネームプレビュー生成処理）だけで完結するため、最初に実装する。
- UT-007 から UT-009 は、`DirectoryProvider.setDirectory`（ディレクトリ設定）で一時ディレクトリを読み込ませる形で実装済み。
- UT-010 から UT-012 は、起点未設定UIイベントまたは未実装仕様に依存するため、現時点では `pending`（保留）にする。
- UT-013 は、`FileListPanel`（ファイル一覧UI）を単体描画し、通常クリックとShiftクリックをウィジェットテストで実装済み。
