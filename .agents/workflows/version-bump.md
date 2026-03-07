---
description: バージョンをバンプする（SemVer準拠）
---

# バージョンバンプ ワークフロー

## バージョニングルール（Semantic Versioning）

| レベル | 形式例 | 条件 | 判断者 |
|---|---|---|---|
| **PATCH** | `0.1.0` → `0.1.1` | バグ修正、UI微調整、文言修正 | AIエージェントが自動判断 |
| **MINOR** | `0.1.1` → `0.2.0` | 新機能追加、UX改善、設定追加 | AIエージェントが自動判断 |
| **MAJOR** | `0.2.0` → `1.0.0` | 大規模刷新、互換性のない変更 | ユーザーの明示的な指示のみ |

## 使い方

### スクリプトで実行
// turbo-all

1. PATCHバンプ（バグ修正・微調整後）:
```powershell
.\scripts\bump_version.ps1 -Level patch
```

2. MINORバンプ（新機能・UX改善後）:
```powershell
.\scripts\bump_version.ps1 -Level minor
```

3. MAJORバンプ（ユーザーからの明示的な指示があった場合のみ）:
```powershell
.\scripts\bump_version.ps1 -Level major
```

## スクリプトが更新するファイル
- `pubspec.yaml` の `version:` 行
- `pubspec.yaml` の `msix_version:` 行
- `CHANGELOG.md` に新エントリを追加

## バージョン表示の仕組み
- アプリ内のバージョン表示は `package_info_plus` で `pubspec.yaml` から動的に取得
- ハードコードされたバージョン文字列は存在しない

## リリース時の手順
1. コード変更を完了
2. `.\scripts\bump_version.ps1 -Level <patch|minor|major>` を実行
3. `CHANGELOG.md` に変更内容を記載
4. `flutter build windows --release` でビルド
5. `git commit -am "v<version>"` でコミット
6. `git tag v<version>` でタグ付け
