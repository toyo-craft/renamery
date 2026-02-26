import 'dart:io';

import 'package:path/path.dart' as p;

class UndoAction {
  final String originalPath;
  final String newPath;

  UndoAction(this.originalPath, this.newPath);

  // Compatibility Aliases for HomeScreen (if it uses oldPath/newPath)
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

    // Reverse order for safety
    for (var action in lastTransaction.reversed) {
      try {
        if (await File(action.newPath).exists()) {
          await File(action.newPath).rename(action.originalPath);
          successCount++;
        } else if (await Directory(action.newPath).exists()) {
          await Directory(action.newPath).rename(action.originalPath);
          successCount++;
        } else {
          errors.add('${p.basename(action.newPath)}: File/Directory not found');
        }
      } catch (e) {
        errors.add('${p.basename(action.newPath)}: $e');
      }
    }
    return {'count': successCount, 'errors': errors};
  }
}
