import 'dart:io';
import 'file_model.dart';
import 'package:path/path.dart' as p;

class UndoAction {
  final String originalPath;
  final String newPath;

  UndoAction(this.originalPath, this.newPath);
}

class UndoManager {
  final List<List<UndoAction>> _history = [];

  bool get canUndo => _history.isNotEmpty;

  void addTransaction(List<FileModel> renamedFiles) {
    List<UndoAction> transaction = [];
    for (var file in renamedFiles) {
      if (file.status == FileStatus.renamed) {
        // 以下をキャプチャします:
        // 旧: c:/path/old.txt
        // 新: c:/path/new.txt
        // アンドゥするには、新 -> 旧 にリネームする必要があります
        String oldP = p.join(file.parentPath, file.originalName);
        String newP = p.join(file.parentPath, file.newName);
        transaction.add(UndoAction(oldP, newP));
      }
    }
    if (transaction.isNotEmpty) {
      _history.add(transaction);
    }
  }

  Future<void> undoLastTransaction() async {
    if (_history.isEmpty) return;

    List<UndoAction> lastTransaction = _history.removeLast();

    // 複雑な移動の場合は逆順の方が安全かもしれませんが、通常のリネームであれば並列でも問題ありません
    for (var action in lastTransaction.reversed) {
      try {
        final file = File(action.newPath);
        if (await file.exists()) {
          await file.rename(action.originalPath);
        }
      } catch (e) {
        // エラー処理（例：ファイルがロックされている、またはスキップされた場合）
        print('アンドゥエラー ${action.newPath} -> ${action.originalPath}: $e');
      }
    }
  }
}
