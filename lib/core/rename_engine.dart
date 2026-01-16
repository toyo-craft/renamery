import 'package:path/path.dart' as p;
import 'file_model.dart';

enum RenameMode {
  replace,
  append,
  prepend,
  numbering,
  extension
}

class RenameEngine {
  /// パラメータに基づいてファイルのプレビュー名を生成します。
  static List<FileModel> generatePreviews(
    List<FileModel> files,
    RenameMode mode, {
    String? findText,
    String? replaceText,
    String? appendText,
    int startNumber = 1,
    int digits = 3,
  }) {
    // リストを複製するか、その場で処理するか？ プレビューの場合、通常は 'newName' プロパティを変更します。
    // ここでは明確にするために変更されたリストを返します。
    
    int counter = startNumber;

    for (var file in files) {
      String originalBaseName = p.basenameWithoutExtension(file.originalName);
      String extension = p.extension(file.originalName);
      String newBaseName = originalBaseName;

      switch (mode) {
        case RenameMode.replace:
          if (findText != null && findText.isNotEmpty) {
            newBaseName = originalBaseName.replaceAll(findText, replaceText ?? '');
          }
          break;
        case RenameMode.append:
          if (appendText != null) {
            newBaseName = '$originalBaseName$appendText';
          }
          break;
        case RenameMode.prepend:
          if (appendText != null) {
            newBaseName = '$appendText$originalBaseName';
          }
          break;
        case RenameMode.numbering:
          String numberStr = counter.toString().padLeft(digits, '0');
          newBaseName = '$originalBaseName$numberStr'; // 単純化されたロジック、通常は部分置換または追加
          counter++;
          break;
        case RenameMode.extension:
          if (replaceText != null) {
             // 拡張子の変更を処理（replaceTextが新しい拡張子として機能）
             // 注意: ここではextension変数を変更するだけなので、まだ再構築しません。
             if (replaceText.startsWith('.')) {
               extension = replaceText;
             } else {
               extension = '.$replaceText';
             }
          }
          break;
      }
      
      file.setNewName('$newBaseName$extension');
    }
    
    return files;
  }
}
