# ReNamery 開発メモ

## バージョン管理
- **Semantic Versioning (MAJOR.MINOR.PATCH)** を採用
- バージョンは `pubspec.yaml` の `version:` で一元管理
- アプリ内表示は `package_info_plus` で動的に取得（ハードコード禁止）
- バンプは `.\scripts\bump_version.ps1 -Level <patch|minor|major>` で実行
- ワークフロー: `.agents/workflows/version-bump.md` 参照
- **MAJOR** バンプはユーザーの明示的な指示がある場合のみ

## リリースフロー（自動）
ユーザーが「リリースして」「ビルドして」「Windowsリリース」等のリリース系指示を出した場合、
以下を **自動で順番に実行** すること：

1. **変更規模の判定**: 直前のコード変更を評価し、PATCH / MINOR を自動判断
   - バグ修正、UI微調整、文言変更 → `patch`
   - 新機能、UX改善、設定項目の追加 → `minor`
   - ユーザーが「メジャーバージョンアップ」と明示 → `major`
2. **バージョンバンプ**: `.\scripts\bump_version.ps1 -Level <判断結果>` を実行
3. **リリースノート記載**: `CHANGELOG.md` の新バージョンエントリに変更内容を日本語で記載
   - 書式は [Keep a Changelog](https://keepachangelog.com/) に準拠
   - カテゴリ: `### 新機能` / `### 改善` / `### 修正` / `### 削除`
   - 各項目は簡潔な1行で記載
4. **ビルド**: `flutter build windows --release` を実行
5. **結果報告**: 新バージョン番号とビルドパスをユーザーに報告
