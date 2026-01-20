# ReNamery 開発環境セットアップガイド

ReNamery（Flutter Windowsアプリ）を開発・実行するためには、以下の環境構築が必要です。

## 1. Flutter SDK のインストール

Flutterアプリをビルド・実行するために必要です。

1.  [Flutter公式サイト](https://docs.flutter.dev/get-started/install/windows) から Windows版の Flutter SDK zipファイルをダウンロードします。
2.  zipファイルを適切な場所（例: `C:\src\flutter` など）に解凍します。
    *   ※ `C:\Program Files` などの管理者権限が必要なフォルダは避けてください。
3.  環境変数 `Path` に、flutterフォルダ内の `bin` フォルダへのパスを追加します。
    *   例: `C:\src\flutter\bin`

## 2. Visual Studio のインストール (C++ コンパイラ)

Windowsデスクトップアプリとしてビルドするために、Microsoft Visual Studio（C++コンパイラ）が必要です。

1.  [Visual Studio Downloads](https://visualstudio.microsoft.com/downloads/) から **Visual Studio 2022 Community** (無料版) をダウンロードしてインストールします。
2.  インストーラーのワークロード選択画面で、**「C++ によるデスクトップ開発」 (Desktop development with C++)** にチェックを入れてインストールしてください。
    *   これには MSVC v143 ビルドツール、Windows SDK などが含まれます。

## 3. VS Code 拡張機能のセットアップ

1.  VS Code の拡張機能マーケットプレイスを開きます。
2.  **Flutter** 拡張機能 (dart-code.flutter) を検索してインストールします。
    *   これにより、Dart 言語のサポートも自動的にインストールされます。

## 4. セットアップ確認

VS Code のターミナルで以下のコマンドを実行し、全てチェックが付くか確認してください。

```powershell
flutter doctor
```

もし `X` や `!` が出ている項目があれば、その指示に従って修正を検討してください。
