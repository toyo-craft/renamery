import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
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

    // Navigation History (Restored from settings)
    final savedNavHistory = s.getList<String>('navHistory');
    if (savedNavHistory != null) {
      _navHistory = savedNavHistory;
    } else {
      _navHistory.clear();
    }
    _navIndex = s.getInt('navIndex') ?? -1;

    // Safety check for index bounds
    if (_navIndex >= _navHistory.length) {
      _navIndex = _navHistory.isNotEmpty ? _navHistory.length - 1 : -1;
    }

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

    // Sub Tab / New States
    _listRenameText = s.getString('listRenameText') ?? '';
    _subTabExtensionText = s.getString('subTabExtensionText') ?? '';

    final lMainIndex = s.getInt('lastMainMode');
    if (lMainIndex != null && lMainIndex < RenameMode.values.length) {
      _lastMainMode = RenameMode.values[lMainIndex];
    }
    final lSubIndex = s.getInt('lastSubMode');
    if (lSubIndex != null && lSubIndex < RenameMode.values.length) {
      _lastSubMode = RenameMode.values[lSubIndex];
    }
    final lEtcIndex = s.getInt('lastEtcMode');
    if (lEtcIndex != null && lEtcIndex < RenameMode.values.length) {
      _lastEtcMode = RenameMode.values[lEtcIndex];
    } else {
      _lastEtcMode = RenameMode.changeTimestamp; // Default
    }
    final lExtraIndex = s.getInt('lastExtraMode');
    if (lExtraIndex != null && lExtraIndex < RenameMode.values.length) {
      _lastExtraMode = RenameMode.values[lExtraIndex];
    } else {
      _lastExtraMode = RenameMode.appendDate; // Default
    }

    // Extra Tab
    _dateFormat = s.getString('dateFormat') ?? 'yyyymmdd_';
    final dPosIndex = s.getInt('datePosition');
    if (dPosIndex != null && dPosIndex < DatePosition.values.length) {
      _datePosition = DatePosition.values[dPosIndex];
    }

    // Validation
    final vTypeIndex = s.getInt('validationType');
    if (vTypeIndex != null && vTypeIndex < ValidationType.values.length) {
      _validationType = ValidationType.values[vTypeIndex];
    }

    // Initial Directory Settings
    final initModeIndex = s.getInt('initialDirectoryMode');
    if (initModeIndex != null &&
        initModeIndex < InitialDirectoryMode.values.length) {
      _initialDirectoryMode = InitialDirectoryMode.values[initModeIndex];
    }
    _fixedInitialDirectory = s.getString('fixedInitialDirectory') ?? '';

    // Etc Tab
    _etcTimestamp = s.getString('etcTimestamp') ?? '';
    // If empty, set default to now? Or keep empty? User Manual: "Ex 2002/03/30 17:30".
    if (_etcTimestamp.isEmpty) {
      final now = DateTime.now();
      _etcTimestamp =
          '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    }
    _etcAttribReadOnly = s.getBool('etcAttribReadOnly') ?? false;
    _etcAttribHidden = s.getBool('etcAttribHidden') ?? false;
    _etcAttribArchive = s.getBool('etcAttribArchive') ?? false;
    _etcAttribSystem = s.getBool('etcAttribSystem') ?? false;

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
    Directory? targetDir;

    if (_initialDirectoryMode == InitialDirectoryMode.fixed &&
        _fixedInitialDirectory.isNotEmpty) {
      targetDir = Directory(_fixedInitialDirectory);
    } else {
      // Last Used
      final lastDir = s.getString('lastDirectory');
      if (lastDir != null) {
        targetDir = Directory(lastDir);
      }
    }

    if (targetDir != null && await targetDir.exists()) {
      await setDirectory(targetDir);
    } else {
      // Fallback or empty state
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

    s.set('navHistory', _navHistory);
    s.set('navIndex', _navIndex);

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

    // New Fields
    s.set('listRenameText', _listRenameText);
    s.set('subTabExtensionText', _subTabExtensionText);
    s.set('lastMainMode', _lastMainMode.index);
    s.set('lastSubMode', _lastSubMode.index);
    s.set('lastEtcMode', _lastEtcMode.index);
    s.set('lastExtraMode', _lastExtraMode.index);
    s.set('lastEtcMode', _lastEtcMode.index);
    s.set('lastExtraMode', _lastExtraMode.index);

    // Extra Tab
    s.set('dateFormat', _dateFormat);
    s.set('datePosition', _datePosition.index);

    // Validation
    s.set('validationType', _validationType.index);

    // Initial Directory
    s.set('initialDirectoryMode', _initialDirectoryMode.index);
    s.set('fixedInitialDirectory', _fixedInitialDirectory);

    // Etc Tab
    s.set('etcTimestamp', _etcTimestamp);
    s.set('etcAttribReadOnly', _etcAttribReadOnly);
    s.set('etcAttribHidden', _etcAttribHidden);
    s.set('etcAttribArchive', _etcAttribArchive);
    s.set('etcAttribSystem', _etcAttribSystem);
  }

  // Rename State
  RenameMode _renameMode = RenameMode.upper;
  NumberingMode _numberingMode = NumberingMode.stringNumber;
  ValidationType _validationType = ValidationType.auto;

  // Initial Directory State
  InitialDirectoryMode _initialDirectoryMode = InitialDirectoryMode.lastUsed;
  String _fixedInitialDirectory = '';

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

  // Extra Tab State
  String _dateFormat = 'yyyymmdd_';
  DatePosition _datePosition = DatePosition.front;

  // Etc Tab State
  String _etcTimestamp = ''; // "yyyy/MM/dd HH:mm"
  bool _etcAttribReadOnly = false;
  bool _etcAttribHidden = false;
  bool _etcAttribArchive = false;
  bool _etcAttribSystem = false;

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
  ValidationType get validationType => _validationType;
  InitialDirectoryMode get initialDirectoryMode => _initialDirectoryMode;
  String get fixedInitialDirectory => _fixedInitialDirectory;

  void updateInitialDirectorySettings(InitialDirectoryMode mode, String path) {
    _initialDirectoryMode = mode;
    _fixedInitialDirectory = path;
    _saveState();
    notifyListeners();
  }

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

  // Mode Memory
  RenameMode _lastMainMode = RenameMode.upper;
  RenameMode _lastSubMode = RenameMode.extensionRemove;
  RenameMode _lastEtcMode = RenameMode.changeTimestamp;
  RenameMode _lastExtraMode = RenameMode.appendDate;

  RenameMode get lastMainMode => _lastMainMode;
  RenameMode get lastSubMode => _lastSubMode;
  RenameMode get lastEtcMode => _lastEtcMode;
  RenameMode get lastExtraMode => _lastExtraMode;

  String get dateFormat => _dateFormat;
  DatePosition get datePosition => _datePosition;

  String get etcTimestamp => _etcTimestamp;
  bool get etcAttribReadOnly => _etcAttribReadOnly;
  bool get etcAttribHidden => _etcAttribHidden;
  bool get etcAttribArchive => _etcAttribArchive;
  bool get etcAttribSystem => _etcAttribSystem;

  bool isMainMode(RenameMode mode) {
    return !isSubMode(mode) && !isExtraMode(mode) && !isEtcMode(mode);
  }

  bool isSubMode(RenameMode mode) {
    return [
      RenameMode.extensionRemove,
      RenameMode.extensionAdd,
      RenameMode.extensionUpper,
      RenameMode.extensionLower,
      RenameMode.formatProperCase,
      RenameMode.listRename,
    ].contains(mode);
  }

  bool isExtraMode(RenameMode mode) {
    return [
      RenameMode.appendDate,
      RenameMode.convHalfToFull,
      RenameMode.convFullToHalf,
      RenameMode.convFullKataToHira,
      RenameMode.convHiraToFullKata,
      RenameMode.convFullAlphaToHalfAlpha,
      RenameMode.convNumToHalf,
    ].contains(mode);
  }

  bool isEtcMode(RenameMode mode) {
    return [
      RenameMode.changeTimestamp,
      RenameMode.changeAttributes,
    ].contains(mode);
  }

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

  // Helper to distinguish modes (Same logic as SettingsPanel, arguably should be static or shared)

  void updateRenameSettings({
    RenameMode? mode,
    NumberingMode? numberingMode,
    String? find,
    String? replace,
    String? append,
    String? deleteTo,
    int? start,
    int? digit,
    String? findText,
    String? replaceText,
    String? appendText,
    String? deleteToText,
    int? startNumber,
    int? digits,
    bool? extensionToLowerCase,
    bool? useRegex,
    bool? saveSequenceNumber,
    String? listText,
    String? extensionText,
    String? dateFormat,
    DatePosition? datePosition,
    ValidationType? validationType,
    String? etcTimestamp,
    bool? etcAttribReadOnly,
    bool? etcAttribHidden,
    bool? etcAttribArchive,
    bool? etcAttribSystem,
    bool immediate = false, // false = debounce, true = immediate
  }) {
    if (mode != null) _renameMode = mode;
    if (numberingMode != null) _numberingMode = numberingMode;
    if (findText != null) _findText = findText;
    if (replaceText != null) _replaceText = replaceText;
    if (appendText != null) _appendText = appendText;
    if (deleteToText != null) _deleteToText = deleteToText;
    if (startNumber != null) _startNumber = startNumber;
    if (digits != null) _digits = digits;
    if (extensionToLowerCase != null)
      _extensionToLowerCase = extensionToLowerCase;
    if (useRegex != null) _useRegex = useRegex;

    // Extra Tab
    if (dateFormat != null) _dateFormat = dateFormat;
    if (datePosition != null) _datePosition = datePosition;

    // Validation
    if (validationType != null) _validationType = validationType;

    // Etc Tab
    if (etcTimestamp != null) _etcTimestamp = etcTimestamp;
    if (etcAttribReadOnly != null) _etcAttribReadOnly = etcAttribReadOnly;
    if (etcAttribHidden != null) _etcAttribHidden = etcAttribHidden;
    if (etcAttribArchive != null) _etcAttribArchive = etcAttribArchive;
    if (etcAttribSystem != null) _etcAttribSystem = etcAttribSystem;

    // Sub Tab
    if (listText != null) _listRenameText = listText;
    if (extensionText != null) _subTabExtensionText = extensionText;

    if (saveSequenceNumber != null) {
      _saveSequenceNumber = saveSequenceNumber;
    }

    // Track Last Active Modes per Tab
    if (mode != null) {
      if (isSubMode(mode)) {
        _lastSubMode = mode;
      } else if (isMainMode(mode)) {
        _lastMainMode = mode;
      } else if (isExtraMode(mode)) {
        _lastExtraMode = mode;
      } else if (isEtcMode(mode)) {
        _lastEtcMode = mode;
      }
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
    _saveState();
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
      f.setValidationError(null);
    }

    if (targets.isEmpty) return; // Nothing to rename

    // Use deleteToText as findText for deleteFrontTo/BackTo modes
    String? currentFindText = _findText;
    if (_renameMode == RenameMode.deleteFrontTo ||
        _renameMode == RenameMode.deleteBackTo) {
      currentFindText = _deleteToText;
    }

    String? currentReplaceText = _replaceText;
    if (_renameMode == RenameMode.extension ||
        _renameMode == RenameMode.extensionAdd) {
      currentReplaceText = _subTabExtensionText;
    }

    String? baseDirName;
    if (_currentDirectory != null) {
      baseDirName = p.basename(_currentDirectory!.path);
    }

    RenameEngine.generatePreviews(
      targets,
      _renameMode,
      findText: currentFindText,
      replaceText: currentReplaceText,
      appendText: _appendText,
      startNumber: _startNumber,
      digits: _digits,
      extensionToLowerCase: _extensionToLowerCase,
      useRegex: _useRegex,
      numberingMode: _numberingMode,
      baseDirName: baseDirName,
      listText: _listRenameText,
      dateFormat: _dateFormat,
      datePosition: _datePosition,
      validationType: _validationType,
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

  // --- Navigation History ---
  List<String> _navHistory = [];
  int _navIndex = -1;

  bool get canGoBack => _navIndex > 0;
  bool get canGoForward => _navIndex < _navHistory.length - 1;

  Future<void> goBack() async {
    if (canGoBack) {
      _navIndex--;
      final path = _navHistory[_navIndex];
      await _navigateInternal(Directory(path));
    }
  }

  Future<void> goForward() async {
    if (canGoForward) {
      _navIndex++;
      final path = _navHistory[_navIndex];
      await _navigateInternal(Directory(path));
    }
  }

  // History access for UI
  // Back history: Items BEFORE _navIndex, reversed (closest first)
  List<String> get backHistory {
    if (_navIndex <= 0) return [];
    return _navHistory.sublist(0, _navIndex).reversed.toList();
  }

  // Forward history: Items AFTER _navIndex
  List<String> get forwardHistory {
    if (_navIndex >= _navHistory.length - 1) return [];
    return _navHistory.sublist(_navIndex + 1);
  }

  Future<void> jumpToHistory(String path) async {
    // Find the index of this path.
    // Note: Duplicates might exist. We should probably target simple linear scan
    // that prefers "closest" or "most logical" target?
    // Or, since the UI will likely pick from one of the lists above,
    // we can infer the target index based on which list it came from?
    // Actually, passing the absolute index would be safer if we exposed it.
    // But string is easier for now if unique enough.
    // Let's modify logic to accept an index if possible, or just scan.
    // Simple scan: find LAST occurrence <= index (for back) or FIRST >= index?
    // Actually, let's just find the first match in the whole history that isn't current?
    // Ideally we should pass the index from the UI.

    final index = _navHistory.indexOf(path);
    if (index != -1 && index != _navIndex) {
      _navIndex = index;
      await _navigateInternal(Directory(path));
    }
  }

  // Better Jump Method: Jump by offset (relative) logic or absolute index?
  // Let's rely on the UI calling jumpToHistory(path).
  // Wait, if I have A -> B -> A -> C.
  // Current C. Back history: A, B, A.
  // If I click the first A (the one before B), I expect to go to index 0.
  // If I click the second A (the recent one), I expect index 2.
  // `indexOf` will always return 0.
  // So I MUST use index.
  // Let's refactor: exposing `List<Map<String, dynamic>>` or similar?
  // Or just helper for "Jump back N steps".

  Future<void> jumpBack(int steps) async {
    final newIndex = _navIndex - steps;
    if (newIndex >= 0) {
      _navIndex = newIndex;
      await _navigateInternal(Directory(_navHistory[_navIndex]));
    }
  }

  Future<void> jumpForward(int steps) async {
    final newIndex = _navIndex + steps;
    if (newIndex < _navHistory.length) {
      _navIndex = newIndex;
      await _navigateInternal(Directory(_navHistory[_navIndex]));
    }
  }

  Future<void> refresh() async {
    if (_currentDirectory != null) {
      // Force reload
      await setDirectory(_currentDirectory!, addToHistory: false);
    }
  }

  // Internal nav that doesn't add to history again (or handles it)
  Future<void> _navigateInternal(Directory dir) async {
    // Similar to setDirectory but doesn't modify history stack
    // Actually setDirectory logic is heavy.
    // Let's refactor setDirectory to accept an option?
    // Or just call setDirectory with addToHistory: false
    await setDirectory(dir, addToHistory: false);
  }

  // --- List Manipulation ---

  bool get canExecute {
    // Current Logic enforces selection for execution (in ToolbarPanel)
    // So we check if ANY selected file has a change.
    // If we later support "Execute All if None Selected", we would check that here too.

    final selected = _currentFiles.where((f) => f.isSelected);
    if (selected.isEmpty) return false;

    return selected.any((f) => f.originalName != f.newName);
  }

  bool get canMoveUp {
    if (_currentFiles.isEmpty) return false;
    // Check if any selected item has a non-selected item above it
    for (int i = 0; i < _currentFiles.length; i++) {
      if (_currentFiles[i].isSelected) {
        if (i > 0 && !_currentFiles[i - 1].isSelected) {
          return true; // Found an item that can move up (swap with unselected above)
        }
      }
    }
    return false;
  }

  bool get canMoveDown {
    if (_currentFiles.isEmpty) return false;
    // Check if any selected item has a non-selected item below it
    for (int i = 0; i < _currentFiles.length; i++) {
      if (_currentFiles[i].isSelected) {
        if (i < _currentFiles.length - 1 && !_currentFiles[i + 1].isSelected) {
          return true; // Found an item that can move down (swap with unselected below)
        }
      }
    }
    return false;
  }

  void moveSelection(bool up) {
    // Only move if we have a selection
    var selectedIndices = _currentFiles
        .asMap()
        .entries
        .where((e) => e.value.isSelected)
        .map((e) => e.key)
        .toList();

    if (selectedIndices.isEmpty) return;

    // Sort indices to handle movement correctly
    selectedIndices.sort();
    if (!up) {
      selectedIndices = selectedIndices.reversed.toList();
    }

    bool changed = false;
    final List<FileModel> newFiles = List.from(_currentFiles);

    for (var index in selectedIndices) {
      if (up) {
        if (index > 0) {
          final prevIndex = index - 1;
          // Only swap if the previous item is NOT selected (to move the whole block)
          if (!newFiles[prevIndex].isSelected) {
            final temp = newFiles[prevIndex];
            newFiles[prevIndex] = newFiles[index];
            newFiles[index] = temp;
            changed = true;
          }
        }
      } else {
        if (index < newFiles.length - 1) {
          final nextIndex = index + 1;
          // Only swap if the next item is NOT selected
          if (!newFiles[nextIndex].isSelected) {
            final temp = newFiles[nextIndex];
            newFiles[nextIndex] = newFiles[index];
            newFiles[index] = temp;
            changed = true;
          }
        }
      }
    }

    if (changed) {
      _currentFiles = newFiles;
      // If we move manually, we might be breaking the sort order.
      // Should we set sort to 'Manual'?
      // For now, let's just update the list.
      _updatePreviews(); // Re-calculate previews (e.g. sequence numbers might change)
      notifyListeners();
    }
  }

  // Manual Sort (Renamed for consistency if needed, checking existing reorderFiles)
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
    List<UndoAction> transaction = [];

    for (var file in targets) {
      // Logic branching
      if (_renameMode == RenameMode.changeTimestamp) {
        try {
          final fullPath = p.join(file.parentPath, file.originalName);
          final DateFormat format = DateFormat('yyyy/MM/dd HH:mm');
          final DateTime dt = format.parse(_etcTimestamp);

          final f = File(fullPath);
          await f.setLastModified(dt);
          // Metadata update doesn't change name, but effectively "done"
          // Maybe refresh file info?
        } catch (e) {
          file.markError(e.toString());
        }
      } else if (_renameMode == RenameMode.changeAttributes) {
        try {
          final fullPath = p.join(file.parentPath, file.originalName);

          List<String> args = [];
          args.add(_etcAttribReadOnly ? '+R' : '-R');
          args.add(_etcAttribHidden ? '+H' : '-H');
          args.add(_etcAttribSystem ? '+S' : '-S');
          args.add(_etcAttribArchive ? '+A' : '-A');
          args.add(fullPath);

          await Process.run('attrib', args);
        } catch (e) {
          file.markError(e.toString());
        }
      } else {
        // Normal Rename
        if (file.originalName == file.newName) continue;

        try {
          final oldPath = p.join(file.parentPath, file.originalName);
          final newPath = p.join(file.parentPath, file.newName);

          final fsEntity = File(oldPath);
          if (await fsEntity.exists()) {
            await fsEntity.rename(newPath);
            file.markRenamed();
            transaction.add(UndoAction(oldPath, newPath));
            renamaedFiles.add(file);
          }
        } catch (e) {
          file.markError(e.toString());
        }
      }
    }

    if (transaction.isNotEmpty) {
      _undoManager.addTransaction(transaction);
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

  Future<void> setDirectory(Directory directory,
      {bool addToHistory = true}) async {
    // History Logic
    if (addToHistory &&
        (_currentDirectory == null ||
            _currentDirectory!.path != directory.path)) {
      // If we are in the middle of history, truncate forward history
      if (_navIndex < _navHistory.length - 1) {
        _navHistory = _navHistory.sublist(0, _navIndex + 1);
      }
      _navHistory.add(directory.path);

      // Limit History Size
      const int maxHistory = 20;
      if (_navHistory.length > maxHistory) {
        _navHistory.removeAt(0);
        // No need to adjust index here because we are about to set it to length-1 anyway?
        // Wait. _navHistory.add -> length is now 21. index will be 20.
        // removeAt(0) -> length becomes 20. index should be 19.
        // So effectively index is length - 1 always when adding new.
      }

      _navIndex = _navHistory.length - 1;
    }

    _currentDirectory = directory;
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

  Future<int> deleteSelectedFiles() async {
    final targets = _currentFiles.where((f) => f.isSelected).toList();
    if (targets.isEmpty) return 0;

    int count = 0;
    _isLoading = true;
    notifyListeners();

    for (var f in targets) {
      try {
        // Use try-catch per file to avoid stopping everything
        await f.entity.delete(recursive: true);
        count++;
      } catch (e) {
        if (kDebugMode) {
          print('Delete error: $e');
        }
      }
    }

    if (count > 0 && _currentDirectory != null) {
      setDirectory(_currentDirectory!);
    } else {
      _isLoading = false;
      notifyListeners();
    }
    return count;
  }

  // Validation State Getter
  bool get hasInvalidFilenames =>
      _currentFiles.any((f) => f.hasValidationError);

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

  // Terminology Getter
  String get termFolder {
    switch (_validationType) {
      case ValidationType.windows:
      case ValidationType.mac:
      case ValidationType.ios:
        return 'フォルダ';
      case ValidationType.linux:
      case ValidationType.android:
        return 'ディレクトリ';
      case ValidationType.auto:
        if (Platform.isWindows || Platform.isMacOS || Platform.isIOS) {
          return 'フォルダ';
        } else {
          return 'ディレクトリ';
        }
    }
  }
}

enum InitialDirectoryMode {
  lastUsed,
  fixed,
}
