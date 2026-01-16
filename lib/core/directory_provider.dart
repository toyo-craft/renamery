import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'file_model.dart';
import 'rename_engine.dart';
import 'undo_manager.dart';

class DirectoryProvider extends ChangeNotifier {
  Directory? _currentDirectory;
  List<FileModel> _currentFiles = [];
  bool _isLoading = false;
  final UndoManager _undoManager = UndoManager();

  // Rename State
  RenameMode _renameMode = RenameMode.upper; // Default to something safe
  NumberingMode _numberingMode = NumberingMode.stringNumber;

  String? _findText;
  String? _replaceText;
  String? _appendText;
  int _startNumber = 1;
  int _digits = 3;
  bool _extensionToLowerCase = false;
  bool _useRegex = false;

  // History State
  List<String> _appendHistory = [];
  List<String> _deleteFromHistory = [];

  // Insert Index (Shared with startNumber for now, but UI shows it explicitly)
  // Logic: startNumber is used as index in Insert Mode.

  Directory? get currentDirectory => _currentDirectory;
  List<FileModel> get currentFiles => _currentFiles;
  bool get isLoading => _isLoading;
  bool get canUndo => _undoManager.canUndo;

  // Getters for UI
  RenameMode get renameMode => _renameMode;
  NumberingMode get numberingMode => _numberingMode;
  String? get findText => _findText;
  String? get replaceText => _replaceText;
  String? get appendText => _appendText;
  int get startNumber => _startNumber;
  int get digits => _digits;
  bool get extensionToLowerCase => _extensionToLowerCase;
  bool get useRegex => _useRegex;
  List<String> get appendHistory => _appendHistory;
  List<String> get deleteFromHistory => _deleteFromHistory;

  // Sort State
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  int get sortColumnIndex => _sortColumnIndex;
  bool get sortAscending => _sortAscending;

  // Selection Methods
  void toggleSelection(FileModel file) {
    file.isSelected = !file.isSelected;
    _updatePreviews(); // Re-calc previews based on new selection
    notifyListeners();
  }

  void selectAll(bool select) {
    for (var f in _currentFiles) {
      f.isSelected = select;
    }
    _updatePreviews();
    notifyListeners();
  }

  // Sort Methods
  void sortFiles(int columnIndex, bool ascending) {
    _sortColumnIndex = columnIndex;
    _sortAscending = ascending;

    _currentFiles.sort((a, b) {
      int cmp = 0;
      switch (columnIndex) {
        case 0: // Original Name
          if ((a.entity is Directory) && (b.entity is! Directory)) return -1;
          if ((a.entity is! Directory) && (b.entity is Directory)) return 1;
          cmp = a.originalName.toLowerCase().compareTo(
                b.originalName.toLowerCase(),
              );
          break;
        case 1: // New Name
          cmp = a.newName.toLowerCase().compareTo(b.newName.toLowerCase());
          break;
        default:
          cmp = 0;
      }
      return ascending ? cmp : -cmp;
    });
    notifyListeners();
  }

  // Manual Sort
  void reorderFiles(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final FileModel item = _currentFiles.removeAt(oldIndex);
    _currentFiles.insert(newIndex, item);
    notifyListeners();
  }

  Future<void> executeRename() async {
    if (_currentFiles.isEmpty) return;

    final hasSelection = _currentFiles.any((f) => f.isSelected);
    final targets = hasSelection
        ? _currentFiles.where((f) => f.isSelected).toList()
        : _currentFiles;

    if (targets.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    List<FileModel> renamaedFiles = [];

    for (var file in targets) {
      if (file.originalName == file.newName) continue;

      try {
        final oldPath = p.join(file.parentPath, file.originalName);
        final newPath = p.join(file.parentPath, file.newName);

        final fsEntity = File(oldPath);
        if (await fsEntity.exists()) {
          await fsEntity.rename(newPath);
          file.markRenamed();
          renamaedFiles.add(file);
        }
      } catch (e) {
        file.markError(e.toString());
      }
    }

    if (renamaedFiles.isNotEmpty) {
      _undoManager.addTransaction(renamaedFiles);
      if (_currentDirectory != null) {
        await setDirectory(_currentDirectory!);
      }
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> undo() async {
    if (!_undoManager.canUndo) return;
    _isLoading = true;
    notifyListeners();

    await _undoManager.undoLastTransaction();

    if (_currentDirectory != null) {
      await setDirectory(_currentDirectory!);
    }
  }

  void addToHistory(String value, bool isAppend) {
    if (value.isEmpty) return;
    List<String> target = isAppend ? _appendHistory : _deleteFromHistory;

    // Remove if exists to move to top
    target.remove(value);
    target.insert(0, value);

    if (target.length > 10) {
      target = target.sublist(0, 10);
    }

    // Re-assign to trigger check (List reference check might need new instance or just notify)
    if (isAppend) {
      _appendHistory = List.from(target);
    } else {
      _deleteFromHistory = List.from(target);
    }
    notifyListeners();
  }

  // Update Settings
  void updateRenameSettings({
    RenameMode? mode,
    NumberingMode? numberingMode,
    String? find,
    String? replace,
    String? append,
    int? start,
    int? digit,
    bool? extensionToLowerCase,
    bool? useRegex,
  }) {
    if (mode != null) _renameMode = mode;
    if (numberingMode != null) _numberingMode = numberingMode;
    if (find != null) _findText = find;
    if (replace != null) _replaceText = replace;
    if (append != null) _appendText = append;
    if (start != null) _startNumber = start;
    if (digit != null) _digits = digit;
    if (extensionToLowerCase != null) {
      _extensionToLowerCase = extensionToLowerCase;
    }
    if (useRegex != null) _useRegex = useRegex;

    _updatePreviews();
    notifyListeners();
  }

  void _updatePreviews() {
    if (_currentFiles.isEmpty) return;

    final hasSelection = _currentFiles.any((f) => f.isSelected);

    if (hasSelection) {
      // 1. Reset unselected
      for (var f in _currentFiles.where((f) => !f.isSelected)) {
        f.setNewName(f.originalName);
      }
      // 2. Apply to selected
      RenameEngine.generatePreviews(
        _currentFiles.where((f) => f.isSelected).toList(),
        _renameMode,
        numberingMode: _numberingMode,
        findText: _findText,
        replaceText: _replaceText,
        appendText: _appendText,
        startNumber: _startNumber,
        digits: _digits,
        extensionToLowerCase: _extensionToLowerCase,
        useRegex: _useRegex,
      );
    } else {
      // Apply to all
      RenameEngine.generatePreviews(
        _currentFiles,
        _renameMode,
        numberingMode: _numberingMode,
        findText: _findText,
        replaceText: _replaceText,
        appendText: _appendText,
        startNumber: _startNumber,
        digits: _digits,
        extensionToLowerCase: _extensionToLowerCase,
        useRegex: _useRegex,
      );
    }
  }

  Future<void> setDirectory(Directory directory) async {
    _currentDirectory = directory;
    _isLoading = true;
    notifyListeners();

    try {
      final List<FileSystemEntity> entities = await directory.list().toList();

      _currentFiles = entities.map((e) => FileModel(entity: e)).toList();

      // Apply default sort
      sortFiles(_sortColumnIndex, _sortAscending);

      // Initial Preview Calculation (defaults to all since no selection)
      _updatePreviews();
    } catch (e) {
      if (kDebugMode) {
        print('Error listing directory: $e');
      }
      _currentFiles = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Quick Access Directories
  static Future<List<Directory>> getQuickAccessDirectories() async {
    List<Directory> quickAccess = [];

    String? home;
    if (Platform.isWindows) {
      home = Platform.environment['USERPROFILE'];
    } else {
      home = Platform.environment['HOME'];
    }

    if (home != null) {
      final homeDir = Directory(home);
      if (await homeDir.exists()) {
        quickAccess.add(homeDir); // Home

        // Common folders
        final folders = [
          'Desktop',
          'Downloads',
          'Documents',
          'Pictures',
          'Music',
          'Videos',
        ];
        for (var folder in folders) {
          final dir = Directory(p.join(home, folder));
          if (await dir.exists()) {
            quickAccess.add(dir);
          }
        }

        // OneDrive Check
        final oneDrive = Directory(p.join(home, 'OneDrive'));
        if (await oneDrive.exists()) {
          quickAccess.add(oneDrive);
        }
      }
    }
    return quickAccess;
  }

  // Helper to list Windows drives (Physical Drives)
  static Future<List<Directory>> getLogicalDrives() async {
    List<Directory> drives = [];

    if (Platform.isWindows) {
      for (var code = 'A'.codeUnitAt(0); code <= 'Z'.codeUnitAt(0); code++) {
        final driveLetter = String.fromCharCode(code);
        final dir = Directory('$driveLetter:\\');
        if (await dir.exists()) {
          drives.add(dir);
        }
      }
    } else {
      drives.add(Directory('/'));
    }
    return drives;
  }
}
