import 'dart:io';
import 'package:path/path.dart' as p;

enum UndoType {
  rename,
  copy,
  create,
  delete,
}

class UndoAction {
  final UndoType type;
  final String originalPath;
  final String newPath;

  UndoAction(this.originalPath, this.newPath, {this.type = UndoType.rename});

  String get oldPath => originalPath;
}

class UndoManager {
  final List<List<UndoAction>> _history = [];

  bool get canUndo => _history.isNotEmpty;
  int get undoCount => _history.length;

  void addTransaction(List<UndoAction> actions) {
    if (actions.isNotEmpty) {
      _history.add(actions);
    }
  }

  List<UndoAction> peekLastTransaction() {
    if (_history.isEmpty) return [];
    return _history.last;
  }

  Future<Map<String, dynamic>> undoLastTransaction() async {
    if (_history.isEmpty) return {'count': 0, 'errors': <String>[]};

    List<UndoAction> lastTransaction = _history.removeLast();
    int successCount = 0;
    List<String> errors = [];

    for (var action in lastTransaction.reversed) {
      try {
        switch (action.type) {
          case UndoType.rename:
            if (await File(action.newPath).exists()) {
              await File(action.newPath).rename(action.originalPath);
              successCount++;
            } else if (await Directory(action.newPath).exists()) {
              await Directory(action.newPath).rename(action.originalPath);
              successCount++;
            } else {
              errors.add('${p.basename(action.newPath)}: Not found');
            }
            break;
          case UndoType.copy:
          case UndoType.create:
            // Undo copy or create by deleting the new item
            if (await File(action.newPath).exists()) {
              await File(action.newPath).delete();
              successCount++;
            } else if (await Directory(action.newPath).exists()) {
              await Directory(action.newPath).delete(recursive: true);
              successCount++;
            }
            break;
          case UndoType.delete:
            // Restoration of deleted files is not implemented yet
            errors.add('Undo delete not supported');
            break;
        }
      } catch (e) {
        errors.add('${p.basename(action.newPath)}: $e');
      }
    }
    return {'count': successCount, 'errors': errors};
  }
}
