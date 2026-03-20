import 'dart:io';
import 'package:path/path.dart' as p;

enum UndoType {
  rename, // 既存ファイルの名前変更
  move,   // 切り取り・貼り付け（移動）
  copy,   // コピー・貼り付け（複製）
  create, // 新規フォルダ作成
}

class UndoAction {
  final UndoType type;
  final String? originalPath; // source or old path
  final String newPath;      // destination or created path

  UndoAction({
    required this.type,
    this.originalPath,
    required this.newPath,
  });

  // Compatibility getter
  String get oldPath => originalPath ?? '';
}

class UndoManager {
  final List<List<UndoAction>> _undoStack = [];
  final List<List<UndoAction>> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  int get undoCount => _undoStack.length;
  int get redoCount => _redoStack.length;

  void addTransaction(List<UndoAction> actions) {
    if (actions.isNotEmpty) {
      _undoStack.add(actions);
      _redoStack.clear(); // 新しい操作が行われたらRedoスタックをクリア
      if (_undoStack.length > 50) {
        _undoStack.removeAt(0); // 最大50件保持
      }
    }
  }

  List<UndoAction> peekLastTransaction() {
    if (_undoStack.isEmpty) return [];
    return _undoStack.last;
  }

  Future<Map<String, dynamic>> undoLastTransaction() async {
    if (_undoStack.isEmpty) return {'count': 0, 'errors': <String>[]};

    List<UndoAction> transaction = _undoStack.removeLast();
    int successCount = 0;
    List<String> errors = [];
    List<UndoAction> redoActions = [];

    // Undoは実行時の逆順で行う
    for (var action in transaction.reversed) {
      try {
        switch (action.type) {
          case UndoType.rename:
          case UndoType.move:
            // 元に戻す（リネーム・移動）
            if (await _exists(action.newPath)) {
              await _rename(action.newPath, action.originalPath!);
              redoActions.add(action);
              successCount++;
            } else {
              errors.add('${p.basename(action.newPath)}: Not found');
            }
            break;
          case UndoType.create:
          case UndoType.copy:
            // 作成したものを削除する
            if (await _exists(action.newPath)) {
              await _delete(action.newPath);
              redoActions.add(action);
              successCount++;
            } else {
              errors.add('${p.basename(action.newPath)}: Already removed');
            }
            break;
        }
      } catch (e) {
        errors.add('${p.basename(action.newPath)}: $e');
      }
    }

    if (redoActions.isNotEmpty) {
      _redoStack.add(redoActions.reversed.toList());
    }

    return {'count': successCount, 'errors': errors};
  }

  Future<Map<String, dynamic>> redoLastTransaction() async {
    if (_redoStack.isEmpty) return {'count': 0, 'errors': <String>[]};

    List<UndoAction> transaction = _redoStack.removeLast();
    int successCount = 0;
    List<String> errors = [];
    List<UndoAction> undoActions = [];

    for (var action in transaction) {
      try {
        switch (action.type) {
          case UndoType.rename:
          case UndoType.move:
            if (await _exists(action.originalPath!)) {
              await _rename(action.originalPath!, action.newPath);
              undoActions.add(action);
              successCount++;
            } else {
              errors.add('${p.basename(action.originalPath!)}: Not found');
            }
            break;
          case UndoType.create:
            await Directory(action.newPath).create(recursive: true);
            undoActions.add(action);
            successCount++;
            break;
          case UndoType.copy:
            if (await _exists(action.originalPath!)) {
              await _copy(action.originalPath!, action.newPath);
              undoActions.add(action);
              successCount++;
            } else {
              errors.add('${p.basename(action.originalPath!)}: Source not found');
            }
            break;
        }
      } catch (e) {
        errors.add('${p.basename(action.newPath)}: $e');
      }
    }

    if (undoActions.isNotEmpty) {
      _undoStack.add(undoActions);
    }

    return {'count': successCount, 'errors': errors};
  }

  // Helpers
  Future<bool> _exists(String path) async {
    return (await File(path).exists()) || (await Directory(path).exists());
  }

  Future<void> _rename(String src, String dest) async {
    if (await File(src).exists()) {
      await File(src).rename(dest);
    } else {
      await Directory(src).rename(dest);
    }
  }

  Future<void> _delete(String path) async {
    if (await File(path).exists()) {
      await File(path).delete();
    } else {
      await Directory(path).delete(recursive: true);
    }
  }

  Future<void> _copy(String src, String dest) async {
    if (await File(src).exists()) {
      await File(src).copy(dest);
    } else {
      await _copyDirectory(Directory(src), Directory(dest));
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (var entity in source.list(recursive: false)) {
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(p.join(destination.path, p.basename(entity.path))));
      } else if (entity is File) {
        await entity.copy(p.join(destination.path, p.basename(entity.path)));
      }
    }
  }
}
