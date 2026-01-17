import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'file_model.dart';
import 'rename_engine.dart';
import 'undo_manager.dart';
import 'settings_service.dart';

class DirectoryProvider extends ChangeNotifier {
  Directory? _currentDirectory;
  List<FileModel> _currentFiles = [];
  bool _isLoading = false;
  final UndoManager _undoManager = UndoManager();

  Future<void> init() async {
    final s = SettingsService();

    // 1. Restore Filter Settings (SYNC)
    _filterText = s.getString('filterText') ?? '';
    _hideSystemFiles = s.getBool('hideSystemFiles') ?? true;
    _recursiveSearch = s.getBool('recursiveSearch') ?? false;
    _showPreview = s.getBool('showPreview') ?? true;
    _showFolders = s.getBool('showFolders') ?? true;
    _saveSequenceNumber = s.getBool('saveSequenceNumber') ?? false;
    _isCompactMode = s.getBool('isCompactMode') ?? true; // Default to Compact

    // 2. Restore Rename Settings (SYNC)
    final rModeIndex = s.getInt('renameMode');
    if (rModeIndex != null && rModeIndex < RenameMode.values.length) {
      _renameMode = RenameMode.values[rModeIndex];
    }
    final nModeIndex = s.getInt('numberingMode');
    if (nModeIndex != null && nModeIndex < NumberingMode.values.length) {
      _numberingMode = NumberingMode.values[nModeIndex];
    }

    _findText = s.getString('findText');
    _replaceText = s.getString('replaceText');
    _appendText = s.getString('appendText');
    _deleteToText = s.getString('deleteToText');
    _startNumber = s.getInt('startNumber') ?? 1;
    _digits = s.getInt('digits') ?? 3;
    _extensionToLowerCase = s.getBool('extensionToLowerCase') ?? false;
    _useRegex = s.getBool('useRegex') ?? false;

    // 3. Restore History (SYNC)
    if (s.getList('appendHistory') != null) {
      _appendHistory = s.getList<String>('appendHistory')!;
    }
    if (s.getList('deleteFromHistory') != null) {
      _deleteFromHistory = s.getList<String>('deleteFromHistory')!;
    }
    if (s.getList('deleteToHistory') != null) {
      _deleteToHistory = s.getList<String>('deleteToHistory')!;
    }

    // 4. Restore Sort (SYNC)
    _sortColumnIndex = s.getInt('sortColumnIndex') ?? 0;
    _sortAscending = s.getBool('sortAscending') ?? true;

    // Notify listeners so UI updates with restored settings immediately
    notifyListeners();

    // 5. Restore Directory (ASYNC - might take time)
    final lastDir = s.getString('lastDirectory');
    if (lastDir != null) {
      final dir = Directory(lastDir);
      if (await dir.exists()) {
        await setDirectory(dir);
      }
    } else {
      // If no directory, we are effectively ready with empty state
      if (_currentDirectory != null) {
        _applyFilters();
      }
      notifyListeners();
    }
  }

  void _saveState() {
    final s = SettingsService();
    if (_currentDirectory != null) {
      s.set('lastDirectory', _currentDirectory!.path);
    }
    s.set('filterText', _filterText);
    s.set('hideSystemFiles', _hideSystemFiles);
    s.set('recursiveSearch', _recursiveSearch);
    s.set('showPreview', _showPreview);
    s.set('showFolders', _showFolders);
    s.set('saveSequenceNumber', _saveSequenceNumber);
    s.set('isCompactMode', _isCompactMode);

    s.set('renameMode', _renameMode.index);
    s.set('numberingMode', _numberingMode.index);
    if (_findText != null) s.set('findText', _findText);
    if (_replaceText != null) s.set('replaceText', _replaceText);
    if (_appendText != null) s.set('appendText', _appendText);
    if (_deleteToText != null) s.set('deleteToText', _deleteToText);

    s.set('startNumber', _startNumber);
    s.set('digits', _digits);
    s.set('extensionToLowerCase', _extensionToLowerCase);
    s.set('useRegex', _useRegex);

    s.set('appendHistory', _appendHistory);
    s.set('deleteFromHistory', _deleteFromHistory);
    s.set('deleteToHistory', _deleteToHistory);

    s.set('sortColumnIndex', _sortColumnIndex);
    s.set('sortAscending', _sortAscending);
  }

  // Rename State
  RenameMode _renameMode = RenameMode.upper;
  NumberingMode _numberingMode = NumberingMode.stringNumber;

  String? _findText;
  String? _replaceText;
  String? _appendText;
  String? _deleteToText; // 専用の入力欄
  int _startNumber = 1;
  int _digits = 3;
  bool _extensionToLowerCase = false;
  bool _useRegex = false;

  // History State
  List<String> _appendHistory = [];
  List<String> _deleteFromHistory = [];
  List<String> _deleteToHistory = [];

  // Filter State
  String _filterText = '';
  bool _hideSystemFiles = true;
  bool _recursiveSearch = false;
  bool _showPreview = true;
  bool _showFolders = true;
  bool _saveSequenceNumber = false;
  bool _isCompactMode = true;

  // Cache for in-memory filtering
  List<FileModel> _allFiles = [];

  // Getters
  Directory? get currentDirectory => _currentDirectory;
  List<FileModel> get currentFiles => _currentFiles;
  int get allFilesCount => _allFiles.length; // For Status Bar
  bool get isLoading => _isLoading;
  bool get canUndo => _undoManager.canUndo;
  int get undoCount => _undoManager.undoCount;

  // Getters for Rename UI
  RenameMode get renameMode => _renameMode;
  NumberingMode get numberingMode => _numberingMode;
  String? get findText => _findText;
  String? get replaceText => _replaceText;
  String? get appendText => _appendText;
  String? get deleteToText => _deleteToText;
  int get startNumber => _startNumber;
  int get digits => _digits;
  bool get extensionToLowerCase => _extensionToLowerCase;
  bool get useRegex => _useRegex;
  List<String> get appendHistory => _appendHistory;
  List<String> get deleteFromHistory => _deleteFromHistory;
  List<String> get deleteToHistory => _deleteToHistory;

  // Sub Tab State
  String _listRenameText = '';
  String _subTabExtensionText = '';
  Timer? _previewTimer;

  String get listRenameText => _listRenameText;
  String get subTabExtensionText => _subTabExtensionText;

  // Getters for Filter UI
  String get filterText => _filterText;
  bool get hideSystemFiles => _hideSystemFiles;
  bool get recursiveSearch => _recursiveSearch;
  bool get showPreview => _showPreview;
  bool get showFolders => _showFolders;
  bool get saveSequenceNumber => _saveSequenceNumber;
  bool get isCompactMode => _isCompactMode;

  // Filter Logic
  void updateFilterSettings({
    String? filter,
    bool? hideSystem,
    bool? recursive,
    bool? preview,
    bool? showFolders,
  }) {
    bool needRescan = false;
    bool needRefilter = false;

    if (filter != null) {
      _filterText = filter;
      needRefilter = true;
    }
    if (hideSystem != null) {
      _hideSystemFiles = hideSystem;
      needRefilter = true;
    }
    if (recursive != null) {
      if (_recursiveSearch != recursive) {
        _recursiveSearch = recursive;
        needRescan = true; // Recursion change requires disk re-scan
      }
    }
    if (preview != null) {
      _showPreview = preview;
      notifyListeners();
    }
    if (showFolders != null) {
      _showFolders = showFolders;
      needRefilter = true;
    }

    if (needRescan) {
      if (_currentDirectory != null) {
        setDirectory(_currentDirectory!);
      }
    } else if (needRefilter) {
      _applyFilters();
    }
    _saveState();
  }

  void setCompactMode(bool isCompact) {
    _isCompactMode = isCompact;
    _saveState();
    notifyListeners();
  }

  void _applyFilters() {
    _currentFiles = _allFiles.where((file) {
      // 1. System/Hidden Files
      if (_hideSystemFiles) {
        final name = p.basename(file.originalName);
        if (name.startsWith('.')) return false;
      }

      // 1.5 Show/Hide Folders
      // If NOT showFolders, and entity IS Directory -> hide
      if (!_showFolders && file.entity is Directory) {
        return false;
      }

      // 2. Filter Text
      if (_filterText.isNotEmpty) {
        // Contains check (case insensitive)
        if (!file.originalName
            .toLowerCase()
            .contains(_filterText.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();

    // Re-sort and Re-preview
    sortFiles(_sortColumnIndex, _sortAscending);
    // _updatePreviews() is called inside sortFiles at the end
    // But sortFiles notifies listeners. Doing it again might be redundant but safe.
    // Actually sortFiles calls _updatePreviews().
  }

  void updateRenameSettings({
    RenameMode? mode,
    NumberingMode? numberingMode,
    String? find,
    String? replace,
    String? append,
    String? deleteTo,
    int? start,
    int? digit,
    bool? extensionToLowerCase,
    bool? useRegex,
    bool? saveSequenceNumber,
    String? listText,
    String? extensionText,
    bool immediate = false, // If true, skip debounce
  }) {
    if (mode != null) _renameMode = mode;
    if (numberingMode != null) _numberingMode = numberingMode;
    if (find != null) _findText = find;
    if (replace != null) _replaceText = replace;
    if (append != null) _appendText = append;
    if (deleteTo != null) _deleteToText = deleteTo;
    if (start != null) _startNumber = start;
    if (digit != null) _digits = digit;
    if (extensionToLowerCase != null) {
      _extensionToLowerCase = extensionToLowerCase;
    }
    if (useRegex != null) _useRegex = useRegex;

    // Sub Tab
    if (listText != null) _listRenameText = listText;
    if (extensionText != null) _subTabExtensionText = extensionText;

    if (saveSequenceNumber != null) {
      _saveSequenceNumber = saveSequenceNumber;
    }

    // Debounce preview update
    _previewTimer?.cancel();
    if (immediate) {
      _updatePreviews();
    } else {
      _previewTimer = Timer(const Duration(milliseconds: 200), () {
        _updatePreviews();
      });
    }
    notifyListeners();
  }

  void _updatePreviews() {
    if (_currentFiles.isEmpty) return;

    final hasSelection = _currentFiles.any((f) => f.isSelected);
    List<FileModel> targets = [];

    // User Requirement: If no selection, NO files are targets.
    // So distinct from previous behavior (all).
    if (hasSelection) {
      targets = _currentFiles.where((f) => f.isSelected).toList();
    }

    // Reset ALL files to original name first (cleans up unselected or previous states)
    for (var f in _currentFiles) {
      f.setNewName(f.originalName);
    }

    if (targets.isEmpty) return; // Nothing to rename

    // Use deleteToText as findText for deleteFrontTo/BackTo modes
    String? currentFindText = _findText;
    if (_renameMode == RenameMode.deleteFrontTo ||
        _renameMode == RenameMode.deleteBackTo) {
      currentFindText = _deleteToText;
    }

    String? baseDirName;
    if (_currentDirectory != null) {
      baseDirName = p.basename(_currentDirectory!.path);
    }

    RenameEngine.generatePreviews(
      targets,
      _renameMode,
      findText: currentFindText,
      replaceText: _replaceText,
      appendText: _appendText,
      startNumber: _startNumber,
      digits: _digits,
      extensionToLowerCase: _extensionToLowerCase,
      useRegex: _useRegex,
      numberingMode: _numberingMode,
      baseDirName: baseDirName,
      listText: _listRenameText,
    );
  }

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

  void resetSettings() {
    _renameMode = RenameMode.replace;
    _findText = '';
    _replaceText = '';
    _appendText = '';
    _startNumber = 1;
    _digits = 3;
    _numberingMode = NumberingMode.stringNumber;
    // _deleteModeString = 'start'; // Default radio selection - This is not a state variable
    _extensionToLowerCase = false;
    _useRegex = false;
    // _caseConversion = CaseConversion.none; // This is not a state variable
    _saveState();
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
        case 2: // Size
          // Directories don't have size in this simple model, treat as 0 or last
          if ((a.entity is Directory) && (b.entity is! Directory)) return -1;
          if ((a.entity is! Directory) && (b.entity is Directory)) return 1;
          if (a.entity is File && b.entity is File) {
            int sizeA = 0;
            int sizeB = 0;
            try {
              sizeA = (a.entity as File).lengthSync();
            } catch (_) {}
            try {
              sizeB = (b.entity as File).lengthSync();
            } catch (_) {}
            cmp = sizeA.compareTo(sizeB);
          }
          break;
        case 3: // Relative Path
          cmp = a.relativePath.compareTo(b.relativePath);
          break;
        case 4: // Type
          cmp = a.fileType.compareTo(b.fileType);
          break;
        case 5: // Date Modified
          try {
            cmp = a.entity
                .statSync()
                .modified
                .compareTo(b.entity.statSync().modified);
          } catch (e) {
            cmp = 0;
          }
          break;
        case 6: // Attributes
          cmp = a.attributes.compareTo(b.attributes);
          break;
        default:
          cmp = 0;
      }
      return ascending ? cmp : -cmp;
    });

    _updatePreviews();
    _saveState();
    notifyListeners();
  }

  // Manual Sort
  void reorderFiles(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final FileModel item = _currentFiles.removeAt(oldIndex);
    _currentFiles.insert(newIndex, item);

    // User Requirement: Update previews on reorder (numbering changes)
    _updatePreviews();
    notifyListeners();
  }

  Future<int> executeRename() async {
    if (_currentFiles.isEmpty) return 0;

    // Strict selection requirement
    final targets = _currentFiles.where((f) => f.isSelected).toList();
    if (targets.isEmpty) return 0;

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

      // Auto-Increment Logic
      if (_saveSequenceNumber) {
        // e.g. Start 1, Processed 5 -> Next Start = 1 + 5 = 6
        _startNumber += renamaedFiles.length;
        _saveState();
        notifyListeners(); // Will update UI controller via watcher
      }
    } else {
      _isLoading = false;
      notifyListeners();
    }
    return renamaedFiles.length;
  }

  Future<void> renameOneFile(FileModel file, String newName) async {
    if (file.originalName == newName || newName.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      final oldPath = p.join(file.parentPath, file.originalName);
      final newPath = p.join(file.parentPath, newName);

      final fsEntity = File(oldPath);
      if (await fsEntity.exists()) {
        await fsEntity.rename(newPath);
        // We re-list directory to ensure state sync,
        // or effectively we could just update the model if we trust it.
        // For safety, let's re-list.
        if (_currentDirectory != null) {
          await setDirectory(_currentDirectory!);
        }
      }
    } catch (e) {
      // Handle error (maybe show toast/snackbar in UI, but here we just log or ignore)
      if (kDebugMode) {
        print('Rename One Error: $e');
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> undo() async {
    if (!_undoManager.canUndo) return {'count': 0, 'errors': []};
    _isLoading = true;
    notifyListeners();

    final result = await _undoManager.undoLastTransaction();

    if (_currentDirectory != null) {
      await setDirectory(_currentDirectory!);
    }
    return result;
  }

  // Undo Metadata
  List<UndoAction> getLastUndoTransaction() {
    return _undoManager.peekLastTransaction();
  }

  void addToHistory(List<String> target, String value) {
    if (value.isEmpty) return;
    // target is passed reference

    // Remove if exists to move to top
    target.remove(value);
    target.insert(0, value);

    if (target.length > 10) {
      target = target.sublist(0, 10);
    }

    notifyListeners();
    _saveState();
  }

  Future<void> setDirectory(Directory directory) async {
    _currentDirectory = directory;
    _isLoading = true;
    _isLoading = true;
    _saveState();
    notifyListeners();

    try {
      List<FileSystemEntity> entities = [];
      if (_recursiveSearch) {
        // Recursive Listing
        entities = await directory.list(recursive: true).toList();
      } else {
        entities = await directory.list(recursive: false).toList();
      }

      _allFiles = entities.map((e) => FileModel(entity: e)).toList();

      // Calculate Relative Path for Recursive Mode
      if (_recursiveSearch) {
        final rootPath = directory.path;
        for (var f in _allFiles) {
          try {
            // User Definition: Relative Folder = Immediate Parent Folder Name
            // e.g. Root: node_modules, File: node_modules/undici/docs/file
            // Relative: docs

            // 1. Display Path: Full Relative Path (e.g. "undici\docs")
            String displayRelPath = p.relative(f.parentPath, from: rootPath);
            if (displayRelPath == '.') displayRelPath = '';
            f.setDisplayRelativePath(displayRelPath);

            // 2. Rename Logic Path: Immediate Parent Name (e.g. "docs")
            // Check if file is directly in root?
            if (p.equals(f.parentPath, rootPath)) {
              // If directly in root, Parent Name is Base Dir Name?
              // Or empty relative?
              // Logic: Base = Root Name. Relative = Parent Name.
              // If file is at root, its parent IS the root.
              // So Relative = Root Name.
              // Let's use basename of parentPath.
              f.setRelativePath(p.basename(f.parentPath));
            } else {
              f.setRelativePath(p.basename(f.parentPath));
            }
          } catch (e) {
            f.setRelativePath('');
            f.setDisplayRelativePath('');
          }
        }
      } else {
        // Logic for Non-recursive
        for (var f in _allFiles) {
          f.setRelativePath('');
          f.setDisplayRelativePath('');
        }
      }

      _applyFilters();
    } catch (e) {
      if (kDebugMode) {
        print('Error listing directory: $e');
      }
      _allFiles = [];
      _currentFiles = [];
      notifyListeners();
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
