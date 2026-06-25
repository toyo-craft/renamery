---
description: バージョンをバンプしてリリース準備を行う（SemVer準拠）
---

# バージョンバンプ / リリース ワークフロー

## バージョニングルール

| レベル | 形式例 | 条件 | 判断者 |
|---|---|---|---|
| **PATCH** | `0.1.0` → `0.1.1` | バグ修正、UI微調整、文言修正 | AIエージェントが自動判断 |
| **MINOR** | `0.1.1` → `0.2.0` | 新機能追加、UX改善、設定追加 | AIエージェントが自動判断 |
| **MAJOR** | `0.2.0` → `1.0.0` | 大規模刷新、互換性のない変更 | ユーザーの明示的な指示のみ |

## `リリースしてください` の処理

ユーザーが `リリースしてください` と明示した場合のみ、リリースコミット、タグ作成、push を行う。

1. 変更内容から SemVer のバンプ種別を判断する。曖昧な場合は確認する。
2. `pubspec.yaml` の `version:` を更新する。
3. `CHANGELOG.md` の最新エントリを同じバージョンに更新する。
4. 外部ホームページファイルの `<span id="renamery-version">` を `vX.X.X` に更新する。
5. `dart scripts/release_validator.dart --validate-version` を実行する。
6. 可能な範囲で `flutter analyze`、対象テスト、対象ビルドを実行する。
7. `git status`、`git diff`、`git log --oneline -10` を確認する。
8. 意図したファイルのみをコミットする。
9. `v<version>` 形式のタグを作成する。
10. ブランチとタグを push する。

## ホームページ更新

- 対象ファイル: `C:\Users\s.kodatai\OneDrive - 株式会社セラフ\source\toyo-craft\apps.html`
- 対象要素: `id="renamery-version"` を持つ `<span>`
- 更新値: `pubspec.yaml` のバージョンを `vX.X.X` 形式にした値
- UTF-8 を維持し、文字化けを避ける。

## GitHub Actions

- 通常のブランチ push だけではリリースされない。
- `.github/workflows/release.yml` は `v*` タグの push で起動する。
- `pubspec.yaml`、`CHANGELOG.md`、タグ名は同一バージョンにそろえる。

## Windows成果物命名

Windows版のリリースファイル名は、OS識別子を `windows` ではなく `win` とする。

- `ReNamery-vX.X.X-win-x64.msi`
- `ReNamery-vX.X.X-win-x64.msix`
- `ReNamery-vX.X.X-win-x64.zip`
