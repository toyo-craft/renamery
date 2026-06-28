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

## 失敗したリリースをまたぐ場合のCHANGELOG

- `v*` タグを push しても GitHub Actions が失敗し、利用可能な成果物が公開されなかった場合、そのバージョンは利用者が実質的に認知できない前提で扱う。
- 次に成功させるリリースの `CHANGELOG.md` には、直近の成功リリース以降に入った利用者向けの変更をまとめて含める。
- CI修正や依存更新だけで終わらせず、「何が速くなったか」「何が安定したか」「どの操作が改善されたか」を先に書く。
- 技術詳細は必要な範囲に絞り、利用者が読んで理解しやすい説明にする。
- GitHub Release の本文を作る場合も、同じ方針で「前回成功リリースから今回成功リリースまで」の内容を要約する。

## ホームページ更新

- 対象ファイル: このリポジトリ外にあるローカルの外部ホームページファイル
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
