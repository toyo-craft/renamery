import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'file_model.dart';
import 'rename_engine.dart';
import 'undo_manager.dart';
import 'settings_service.dart';

enum AppThemeType {
  system,
  light,
  dark,
  darkGray, // New Custom Theme
}

enum MenuLabelType {
  standard, // 日本語
  namery, // Namery互換
  english, // English
  chinese, // 中国語
}

class DirectoryProvider extends ChangeNotifier {
  Directory? _currentDirectory;
  List<FileModel> _currentFiles = [];
  bool _isLoading = false;
  bool _isInlineRenaming = false;
  final UndoManager _undoManager = UndoManager();

  bool get isInlineRenaming => _isInlineRenaming;

  void setInlineRenaming(bool isRenaming) {
    if (_isInlineRenaming != isRenaming) {
      _isInlineRenaming = isRenaming;
      notifyListeners();
    }
  }

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

    // Theme (SYNC)
    final appThemeStr = s.getString('appTheme') ?? 'light';
    _appTheme = AppThemeType.values.firstWhere((e) => e.name == appThemeStr,
        orElse: () => AppThemeType.light);
    final seedColorVal = s.getInt('seedColor');
    if (seedColorVal != null) {
      _seedColor = Color(seedColorVal);
    }

    // Menu Label (SYNC)
    final menuLabelStr = s.getString('menuLabelType') ??
        'namery'; // Default to Namery for existing users? Or Standard? User asked to change from current. Current is Namery. So Default Namery or Standard?
    // "各種メニューを現行のものからより一般的でわかりやすい名称にしてください" -> Implies Standard should be NEW default?
    // Let's set Standard as default for new, but keep Namery if explicitly set?
    // Actually, explicit request "Make it more general... but allow changing to Namery". Defaults to Standard seems appropriate for "Make it...".
    _menuLabelType = MenuLabelType.values.firstWhere(
        (e) => e.name == menuLabelStr,
        orElse: () => MenuLabelType.standard);

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
    _extensionToLowerCase = s.getBool('extensionToLowerCase') ?? true;
    _useRegex = s.getBool('useRegex') ?? false;

    // Sub Tab / New States
    _listRenameText = s.getString('listRenameText') ??
        '01_chapter_intro.mp4\n02_chapter_main.mp4\n03_chapter_end.mp4';
    _extensionChangeText = s.getString('extensionChangeText') ?? '';
    _extensionAddText = s.getString('extensionAddText') ?? '';

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
    if (s.getList('findHistory') != null) {
      _findHistory = s.getList<String>('findHistory')!;
    }
    if (s.getList('replaceHistory') != null) {
      _replaceHistory = s.getList<String>('replaceHistory')!;
    }
    if (s.getList('extensionHistory') != null) {
      _extensionHistory = s.getList<String>('extensionHistory')!;
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
    s.set('appTheme', _appTheme.name);
    s.set('menuLabelType', _menuLabelType.name);
    s.set('seedColor', _seedColor.value);
    s.set('seedColor', _seedColor.value);

    s.set('navHistory', _navHistory);
    s.set('navIndex', _navIndex);

    s.set('renameMode', _renameMode.index);
    s.set('numberingMode', _numberingMode.index);
    if (_findText != null) s.set('findText', _findText);
    if (_replaceText != null) s.set('replaceText', _replaceText);
    if (_appendText != null) s.set('appendText', _appendText);
    if (_deleteToText != null) s.set('deleteToText', _deleteToText);

    s.set('startNumber', _startNumber);
    s.set('insertIndex', _insertIndex);
    s.set('digits', _digits);
    s.set('extensionToLowerCase', _extensionToLowerCase);
    s.set('useRegex', _useRegex);

    s.set('appendHistory', _appendHistory);
    s.set('deleteFromHistory', _deleteFromHistory);
    s.set('deleteToHistory', _deleteToHistory);
    s.set('findHistory', _findHistory);
    s.set('replaceHistory', _replaceHistory);
    s.set('extensionHistory', _extensionHistory);

    s.set('sortColumnIndex', _sortColumnIndex);
    s.set('sortAscending', _sortAscending);

    // New Fields
    s.set('listRenameText', _listRenameText);
    s.set('extensionChangeText', _extensionChangeText);
    s.set('extensionAddText', _extensionAddText);
    s.set('lastMainMode', _lastMainMode.index);
    s.set('lastSubMode', _lastSubMode.index);
    s.set('lastEtcMode', _lastEtcMode.index);
    s.set('lastExtraMode', _lastExtraMode.index);
    s.set('lastEtcMode', _lastEtcMode.index);
    s.set('lastExtraMode', _lastExtraMode.index);
    s.set('lastStringMode', _lastStringMode.index);

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
  RenameMode _renameMode = RenameMode.numbering; // Default: Numbering (Main)
  NumberingMode _numberingMode = NumberingMode.stringNumber;
  ValidationType _validationType = ValidationType.auto;

  // Initial Directory State
  InitialDirectoryMode _initialDirectoryMode = InitialDirectoryMode.lastUsed;
  String _fixedInitialDirectory = '';

  // Reset Signal for Sidebar
  int _resetCount = 0;
  int get resetCount => _resetCount;

  String? _findText;
  String? _replaceText;
  String? _appendText;
  String? _deleteToText; // 専用の入力欄
  int _startNumber = 1;
  int _insertIndex = 1;
  int _digits = 3;
  bool _extensionToLowerCase = true;
  bool _useRegex = false;

  // Navigation Source
  String? _navigationSource;
  String? get navigationSource => _navigationSource;

  // Navigation Context Root (for differentiating QA trees)
  String? _navigationContextRoot;
  String? get navigationContextRoot => _navigationContextRoot;

  // History State
  List<String> _appendHistory = [];
  List<String> _deleteFromHistory = [];
  List<String> _deleteToHistory = [];
  List<String> _findHistory = [];
  List<String> _replaceHistory = [];
  List<String> _extensionHistory = [];

  // Filter State
  String _filterText = '';
  bool _hideSystemFiles = true;
  bool _recursiveSearch = false;
  bool _showPreview = true;
  bool _showFolders = true;
  bool _saveSequenceNumber = false;
  bool _isCompactMode = false; // Default: OFF (Standard)

  // Theme State
  AppThemeType _appTheme = AppThemeType.light; // Default: Light
  MenuLabelType _menuLabelType = MenuLabelType.standard; // Default: Standard
  Color _seedColor = Colors.green;

  // Extra Tab State
  String _dateFormat = 'yyyyMMdd_'; // Default: yyyyMMdd_
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
  int get insertIndex => _insertIndex;
  int get digits => _digits;
  bool get extensionToLowerCase => _extensionToLowerCase;
  bool get useRegex => _useRegex;
  List<String> get appendHistory => _appendHistory;
  List<String> get deleteFromHistory => _deleteFromHistory;
  List<String> get deleteToHistory => _deleteToHistory;
  List<String> get findHistory => _findHistory;
  List<String> get replaceHistory => _replaceHistory;
  List<String> get extensionHistory => _extensionHistory;

  // Mode Memory
  RenameMode _lastMainMode = RenameMode.numbering; // Default: Numbering
  RenameMode _lastSubMode = RenameMode.extension; // Default: Change Extension
  RenameMode _lastEtcMode = RenameMode.changeTimestamp;
  RenameMode _lastExtraMode = RenameMode.appendDate;
  RenameMode _lastStringMode = RenameMode.append; // Default Suffix

  RenameMode get lastMainMode => _lastMainMode;
  RenameMode get lastSubMode => _lastSubMode;
  RenameMode get lastEtcMode => _lastEtcMode;
  RenameMode get lastExtraMode => _lastExtraMode;
  RenameMode get lastStringMode => _lastStringMode;

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
  String _listRenameText =
      '01_chapter_intro.mp4\n02_chapter_main.mp4\n03_chapter_end.mp4';
  String _extensionChangeText = '';
  String _extensionAddText = '';
  Timer? _previewTimer;

  String get listRenameText => _listRenameText;
  String get extensionChangeText => _extensionChangeText;
  String get extensionAddText => _extensionAddText;

  // Getters for Filter UI
  String get filterText => _filterText;
  bool get hideSystemFiles => _hideSystemFiles;
  bool get recursiveSearch => _recursiveSearch;
  bool get showPreview => _showPreview;
  bool get showFolders => _showFolders;
  bool get saveSequenceNumber => _saveSequenceNumber;
  bool get isCompactMode => _isCompactMode;

  AppThemeType get appTheme => _appTheme;
  MenuLabelType get menuLabelType => _menuLabelType;

  // Dynamic Label Getters

  // Helper for MaterialApp to consume (Mapping)
  ThemeMode get themeMode {
    switch (_appTheme) {
      case AppThemeType.light:
        return ThemeMode.light;
      case AppThemeType.dark:
      case AppThemeType.darkGray:
        return ThemeMode.dark;
      case AppThemeType.system:
        return ThemeMode.system;
    }
  }

  Color get seedColor => _seedColor;

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

  void setAppTheme(AppThemeType theme) {
    _appTheme = theme;
    _saveState();
    notifyListeners();
  }

  void setMenuLabelType(MenuLabelType type) {
    _menuLabelType = type;
    _saveState();
    notifyListeners();
  }

  void setSeedColor(Color color) {
    _seedColor = color;
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
    int? insertIndex,
    int? digits,
    bool? extensionToLowerCase,
    bool? useRegex,
    bool? saveSequenceNumber,
    String? listText,
    String? extensionChangeText,
    String? extensionAddText,
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

    if (find != null) _findText = find;
    if (findText != null) _findText = findText;

    if (replace != null) _replaceText = replace;
    if (replaceText != null) _replaceText = replaceText;

    if (append != null) _appendText = append;
    if (appendText != null) _appendText = appendText;

    if (deleteTo != null) _deleteToText = deleteTo;
    if (deleteToText != null) _deleteToText = deleteToText;

    if (start != null) _startNumber = start;
    if (startNumber != null) _startNumber = startNumber;

    if (insertIndex != null) _insertIndex = insertIndex;

    if (digit != null) _digits = digit;
    if (digits != null) _digits = digits;

    if (extensionToLowerCase != null) {
      _extensionToLowerCase = extensionToLowerCase;
    }
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
    if (extensionChangeText != null) _extensionChangeText = extensionChangeText;
    if (extensionAddText != null) _extensionAddText = extensionAddText;

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

      // Update Last String Mode
      if (mode == RenameMode.append ||
          mode == RenameMode.prepend ||
          mode == RenameMode.insert ||
          mode == RenameMode.numbering) {
        _lastStringMode = mode;
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
    if (_renameMode == RenameMode.extension) {
      currentReplaceText = _extensionChangeText;
    } else if (_renameMode == RenameMode.extensionAdd) {
      currentReplaceText = _extensionAddText;
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
      insertIndex: _insertIndex,
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
    // 1. Theme
    _appTheme = AppThemeType.light;
    _menuLabelType = MenuLabelType.standard;
    _seedColor = Colors.green;
    _isCompactMode = false;

    // 2. Initial Directory
    _initialDirectoryMode = InitialDirectoryMode.lastUsed;
    _fixedInitialDirectory = '';

    // 3. Rename Settings
    _renameMode = RenameMode.numbering;
    _numberingMode = NumberingMode.stringNumber;
    _startNumber = 1;
    _insertIndex = 1;
    _digits = 3;
    _findText = '';
    _replaceText = '';
    _appendText = '';
    _deleteToText = '';
    _extensionToLowerCase = true;
    _useRegex = false;
    _saveSequenceNumber = false;

    // Mode Memory defaults
    _lastMainMode = RenameMode.numbering;
    _lastSubMode = RenameMode.extension;
    _lastExtraMode = RenameMode.appendDate;
    _lastEtcMode = RenameMode.changeTimestamp;
    _lastStringMode = RenameMode.append;

    // Sub Tab
    _listRenameText =
        '01_chapter_intro.mp4\n02_chapter_main.mp4\n03_chapter_end.mp4';
    _extensionChangeText = '';
    _extensionAddText = '';

    // Extra Tab
    _dateFormat = 'yyyyMMdd_';
    _datePosition = DatePosition.front;

    // Etc Tab
    _etcTimestamp =
        ''; // Will default to now on next read if needed, or clear it
    final now = DateTime.now();
    _etcTimestamp =
        '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _etcAttribReadOnly = false;
    _etcAttribHidden = false;
    _etcAttribArchive = false;
    _etcAttribSystem = false;

    // 4. View Settings (Left Pane)
    _showFolders = true;
    _hideSystemFiles = true;
    _recursiveSearch = false;
    _showPreview = true;
    _validationType = ValidationType.auto;

    // 5. Reset Signal (Collapse Tree)
    _resetCount++;

    _applyFilters(); // Re-apply view settings
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
      _saveInputHistory();
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

    // Remove if exists to move to top (prevent duplicates)
    target.remove(value);
    target.insert(0, value);

    if (target.length > 20) {
      // Increased limit slightly or keep logic
      target.removeRange(20, target.length);
    }
    // Limit was 10, keeping 10 or increasing? User didn't specify size, just duplicates.
    // Existing code had 10. Let's stick to 10 but ensure removal works.
    if (target.length > 10) {
      target.removeRange(10, target.length);
    }

    notifyListeners();
    _saveState();
  }

  void clearInputHistory() {
    _appendHistory.clear();
    _deleteFromHistory.clear();
    _deleteToHistory.clear();
    _saveState();
    notifyListeners();
  }

  Future<void> setDirectory(Directory directory,
      {bool addToHistory = true, String? source, String? contextRoot}) async {
    _navigationSource = source;
    _navigationContextRoot = contextRoot;
    // History Logic
    if (addToHistory &&
        (_currentDirectory == null ||
            _currentDirectory!.path != directory.path)) {
      // If we are in the middle of history, truncate forward history
      if (_navIndex < _navHistory.length - 1) {
        _navHistory = _navHistory.sublist(0, _navIndex + 1);
      }

      // Remove duplicate if exists (User Request)
      _navHistory.remove(directory.path);

      _navHistory.add(directory.path);

      // Limit History Size
      const int maxHistory = 20;
      if (_navHistory.length > maxHistory) {
        _navHistory.removeAt(0);
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

      // Fetch Attributes in bulk (Windows Only)
      if (Platform.isWindows) {
        await _loadAttributes(_currentDirectory!);
      }
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

  Future<void> _loadAttributes(Directory dir) async {
    try {
      // Run attrib *
      // Note: attributes might be localized? No, A S H R are standard.
      // Output format: A   H  R    C:\Path\To\File.txt
      final result =
          await Process.run('attrib', ['*'], workingDirectory: dir.path);
      if (result.exitCode == 0) {
        final lines = (result.stdout as String).split('\n');
        final Map<String, String> attrMap = {};

        // Parse
        // Using fixed width parsing for performance and reliability with 'attrib' output format.
        // Format: 'A   H        C:\Path' (First 20 chars are attributes)
        // Let's assume absolute if working dir is set, but output might vary.
        // Attrib output usually matches input. attrib * -> relative paths if in dir.
        // Wait, Process.run workingDirectory set.
        // Output will be: "A      file.txt" (Relative) or "A      C:\path\file.txt"?
        // Let's check my test output: "A                    R:\renamery\.gitignore"
        // It returned ABSOLUTE path.

        for (var line in lines) {
          line = line.trim();
          if (line.isEmpty) continue;
          // Split by first large gap? Or use regex.
          // Attribs are fixed width (approx 20 chars).
          if (line.length > 21) {
            final attrPart = line.substring(0, 20).toUpperCase();
            final pathPart = line.substring(20).trim();
            // Path might be absolute.
            // Normalize path for matching.
            String normalizedPath = pathPart;
            // If absolute, key should be absolute.
            // If relative, key should be join(dir.path, relative).
            // Since our FileModels have absolute paths.
            // Let's try to match.
            // If path start with drive letter, it's absolute.
            // FileModel entity.path is absolute.

            attrMap[normalizedPath.toLowerCase()] = attrPart;
            // Also try absolute if raw path is relative
            if (!pathPart.contains(':')) {
              attrMap['${dir.path}\\$pathPart'
                  .toLowerCase()
                  .replaceAll('/', '\\')] = attrPart;
            }
          }
        }

        // Apply to FileModels
        for (var f in _currentFiles) {
          final key = f.entity.path.toLowerCase().replaceAll('/', '\\');
          if (attrMap.containsKey(key)) {
            final attrs = attrMap[key]!;
            f.setAttributes(
              readOnly: attrs.contains('R'),
              hidden: attrs.contains('H'),
              system: attrs.contains('S'),
              archive: attrs.contains('A'),
            );
          }
        }
      }
    } catch (e) {
      // Ignore attribute errors
      print('Attrib Error: $e');
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

  void _saveInputHistory() {
    switch (_renameMode) {
      case RenameMode.append:
      case RenameMode.prepend:
      case RenameMode.insert:
      case RenameMode.numbering:
        if (_appendText != null) addToHistory(_appendHistory, _appendText!);
        break;
      case RenameMode.replace:
        if (_findText != null) addToHistory(_findHistory, _findText!);
        if (_replaceText != null) addToHistory(_replaceHistory, _replaceText!);
        break;
      case RenameMode.deleteFrontTo:
      case RenameMode.deleteBackTo:
      case RenameMode.deleteFrom: // Maybe?
        if (_deleteToText != null) {
          addToHistory(_deleteToHistory, _deleteToText!);
        }
        break;
      case RenameMode.extension:
        if (_extensionChangeText.isNotEmpty) {
          addToHistory(_extensionHistory, _extensionChangeText);
        }
        break;
      case RenameMode.extensionAdd:
        if (_extensionAddText.isNotEmpty) {
          addToHistory(_extensionHistory,
              _extensionAddText); // Using same history list? Or split history?
          // User asked for split *items* (fields), history might be shared or split.
          // Conventionally, extension history is shared.
          // Let's keep history shared for now unless requested otherwise.
          addToHistory(_extensionHistory, _extensionAddText);
        }
        break;
      case RenameMode.extensionRemove:
        // No input usually, or maybe removed extension?
        break;
      default:
        break;
    }
  }

  // --- Terminology Helper ---
  String _l({
    required String jp,
    required String namery,
    required String en,
    required String cn,
  }) {
    switch (_menuLabelType) {
      case MenuLabelType.standard:
        return jp;
      case MenuLabelType.namery:
        return namery;
      case MenuLabelType.english:
        return en;
      case MenuLabelType.chinese:
        return cn;
    }
  }

  // --- Terminology Getters ---

  // Tabs
  String get labelMainTab => _l(jp: '基本', namery: 'Main', en: 'Main', cn: '基本');
  String get labelSubTab => _l(jp: '拡張', namery: 'Sub', en: 'Sub', cn: '扩展');
  String get labelExtraTab =>
      _l(jp: '高度', namery: 'Extra', en: 'Extra', cn: '高级');
  String get labelEtcTab =>
      _l(jp: '属性', namery: 'etc...', en: 'Attributes', cn: '属性');

  String get labelStringInput =>
      _l(jp: '文字列', namery: '文字列', en: 'String', cn: '文本');

  // Columns (Central Panel)
  String get labelColName =>
      _l(jp: '現在のファイル名', namery: '名前', en: 'Name', cn: '文件名');
  String get labelColNewName =>
      _l(jp: '新しいファイル名', namery: '変更後ファイル名', en: 'New Name', cn: '新文件名');
  String get labelColSize => _l(jp: 'サイズ', namery: 'サイズ', en: 'Size', cn: '大小');
  String get labelColPath => _l(jp: 'パス', namery: '相対パス', en: 'Path', cn: '路径');
  String get labelColType =>
      _l(jp: '種別', namery: 'ファイルの種類', en: 'Type', cn: '类型');
  String get labelColDate =>
      _l(jp: '更新日時', namery: '更新日時', en: 'Date Modified', cn: '修改日期');
  String get labelColAttr =>
      _l(jp: '属性', namery: '属性', en: 'Attributes', cn: '属性');

  // Operations (Main Tab)
  String get labelOpPrefix =>
      _l(jp: '先頭に追加', namery: 'Prefix(前方追加)', en: 'Add Prefix', cn: '添加前缀');
  String get labelOpSuffix =>
      _l(jp: '末尾に追加', namery: 'Suffix(後方追加)', en: 'Add Suffix', cn: '添加后缀');
  String get labelOpInsert =>
      _l(jp: '指定位置に挿入', namery: '文字列挿入', en: 'Insert at', cn: '插入字符');
  String get labelOpDeleteStart => _l(
      jp: '先頭から削除', namery: '先頭から桁数分削除', en: 'Delete from Start', cn: '删除头部');
  String get labelOpDeleteEnd =>
      _l(jp: '末尾から削除', namery: '後ろから桁数分削除', en: 'Delete from End', cn: '删除尾部');
  String get labelOpDeleteFrom => _l(
      jp: '指定位置から削除',
      namery: '開始数字から桁数削除',
      en: 'Delete from Pos',
      cn: '删除指定位置');
  String get labelOpCapitalize =>
      _l(jp: '先頭を大文字化', namery: '先頭文字を大文字化', en: 'Capitalize', cn: '首字母大写');
  String get labelOpUpper =>
      _l(jp: 'すべて大文字化', namery: '大文字化', en: 'To Upper Case', cn: '全部大写');
  String get labelOpLower =>
      _l(jp: 'すべて小文字化', namery: '小文字化', en: 'To Lower Case', cn: '全部小写');

  // Operations (Sub Tab)
  String get labelOpExtChange =>
      _l(jp: '拡張子を変更', namery: '拡張子を変更', en: 'Change Ext', cn: '修改后缀');
  String get labelOpExtAdd =>
      _l(jp: '拡張子を追加', namery: '拡張子を追加', en: 'Add Extension', cn: '添加后缀');
  String get labelOpExtRemove =>
      _l(jp: '拡張子を削除', namery: '拡張子を削除', en: 'Remove Ext', cn: '删除后缀');
  String get labelOpExtUpper =>
      _l(jp: '拡張子を大文字化', namery: '拡張子を大文字化', en: 'Ext to Upper', cn: '后缀大写');
  String get labelOpExtLower =>
      _l(jp: '拡張子を小文字化', namery: '拡張子を小文字化', en: 'Ext to Lower', cn: '后缀小写');
  String get labelSubExtChangeTitle =>
      _l(jp: '拡張子変更', namery: 'Extension', en: 'Extension', cn: '后缀修改');
  String get labelSubFormatTitle =>
      _l(jp: '英単語整形', namery: '英単語を区切って整形', en: 'Format', cn: '格式化');
  String get labelSubFormatProperCase => _l(
      jp: '単語の先頭を大文字化 (Space/Hyphen/Underscore)',
      namery: '単語の先頭を大文字化 (Space/Hyphen/Underscore)',
      en: 'Capitalize Words',
      cn: '首字母大写');
  String get labelSubListTitle =>
      _l(jp: 'リストリネーム', namery: 'リストリネーム', en: 'List Rename', cn: '列表重命名');
  String get labelSubListModeText => _l(
      jp: 'テキスト入力 (Original[TAB]New)',
      namery: 'テキスト入力 (Original[TAB]New)',
      en: 'Text Input',
      cn: '文本输入');
  String get labelSubListSample1 => _l(
      jp: 'サンプル: 連番ファイル',
      namery: 'サンプル: 連番ファイル',
      en: 'Sample: Sequential',
      cn: '示例: 序号');
  String get labelSubListSample2 => _l(
      jp: 'サンプル: 拡張子一括置換',
      namery: 'サンプル: 拡張子一括置換',
      en: 'Sample: Ext Replace',
      cn: '示例: 后缀替换');
  String get labelSubListSample3 => _l(
      jp: 'サンプル: 特定文字の置換',
      namery: 'Sample: Char Replace',
      en: 'サンプル: 特定文字の置換',
      cn: '示例: 字符替换');
  String get labelSubListHint => _l(
      jp: 'old_name.txt\tnew_name.txt\nfile01.png\timage01.png',
      namery: 'old.txt\tnew.txt',
      en: 'old.txt\tnew.txt',
      cn: 'old.txt\tnew.txt');

  // Operations (Extra Tab)
  String get labelExtraAppendDate =>
      _l(jp: 'ファイルの日付を付加', namery: 'ファイルの日付を付加', en: 'Append Date', cn: '添加日期');
  String get labelExtraDateFormatHint => _l(
      jp: '日付フォーマット (例: yyyymmdd_)',
      namery: '日付フォーマット (例: yyyymmdd_)',
      en: 'Date Format',
      cn: '日期格式');
  String get labelExtraPosition =>
      _l(jp: '位置', namery: '位置', en: 'Position', cn: '位置');
  String get labelExtraFront =>
      _l(jp: '前方', namery: '前方', en: 'Front', cn: '前');
  String get labelExtraBack => _l(jp: '後方', namery: '後方', en: 'Back', cn: '后');
  String get labelExtraConvHalfToFull =>
      _l(jp: '半角を全角にする', namery: '半角を全角にする', en: 'Half to Full', cn: '半角转全角');
  String get labelExtraConvFullToHalf =>
      _l(jp: '全角を半角にする', namery: '全角を半角にする', en: 'Full to Half', cn: '全角转半角');
  String get labelExtraConvKataToHira => _l(
      jp: '全角カナをひらがなにする',
      namery: '全角カナをひらがなにする',
      en: 'Katakana to Hiragana',
      cn: '片假名转平假名');
  String get labelExtraConvHiraToKata => _l(
      jp: 'ひらがなを全角カナにする',
      namery: 'ひらがなを全角カナにする',
      en: 'Hiragana to Katakana',
      cn: '平假名转片假名');
  String get labelExtraConvFullAlphaToHalf => _l(
      jp: '全角英字を半角にする',
      namery: '全角英字を半角にする',
      en: 'Full Alpha to Half',
      cn: '全角英转半角');
  String get labelExtraConvNumToHalf =>
      _l(jp: '数字を半角にする', namery: '数字を半角にする', en: 'Num to Half', cn: '数字转半角');

  // Operations (Etc Tab)
  String get labelEtcAttribReadOnly =>
      _l(jp: '読み取り専用', namery: 'ReadOnly', en: 'Read Only', cn: '只读');
  String get labelEtcAttribHidden =>
      _l(jp: '隠しファイル', namery: 'Hidden', en: 'Hidden', cn: '隐藏');
  String get labelEtcAttribArchive =>
      _l(jp: 'アーカイブ', namery: 'Archive', en: 'Archive', cn: '存档');
  String get labelEtcAttribSystem =>
      _l(jp: 'システムファイル', namery: 'System', en: 'System', cn: '系统');

  String get labelEtcTimestampChange => _l(
      jp: 'タイムスタンプを変更する',
      namery: 'タイムスタンプを変更する',
      en: 'Change Timestamp',
      cn: '修改时间戳');
  String get labelEtcPickTime =>
      _l(jp: '時刻を選択してください', namery: '時刻を選択してください', en: 'Pick Time', cn: '选择时间');
  String get labelEtcPickDateTooltip => _l(
      jp: '日付と時刻を選択',
      namery: '日付と時刻を選択',
      en: 'Pick Date & Time',
      cn: '选择日期和时间');
  String get labelEtcTimestampNote => _l(
      jp: '(Ex 2002/03/30 17:30 のように指定します。)',
      namery: '(Ex 2002/03/30 17:30 のように指定します。)',
      en: '(Ex 2002/03/30 17:30)',
      cn: '(例如 2002/03/30 17:30)');
  String get labelEtcAttributeChange =>
      _l(jp: '属性を変更する', namery: '属性を変更する', en: 'Change Attributes', cn: '修改属性');
  String get labelEtcCautionTitle =>
      _l(jp: '取り消し操作不能', namery: '取り消し操作不能', en: 'No Undo', cn: '无法撤销');
  String get labelEtcCautionMessage => _l(
      jp: 'このカテゴリ（タイムスタンプ・属性）の変更は、アンドゥ機能で元に戻すことができません。慎重に操作してください。',
      namery: 'このカテゴリ（タイムスタンプ・属性）の変更は、アンドゥ機能で元に戻すことができません。慎重に操作してください。',
      en: 'Timestamp/Attribute changes cannot be undone.',
      cn: '时间戳和属性的修改无法撤销。');

  // Toolbar & Menu
  String get labelUndo => _l(jp: '戻す', namery: '戻す', en: 'Undo', cn: '撤销');
  String get labelExecute =>
      _l(jp: '実行', namery: '実行', en: 'Execute', cn: '执行');
  String get labelErrorInvalidFilename => _l(
      jp: 'エラー：ファイル名に禁止文字が含まれています',
      namery: 'エラー：ファイル名に禁止文字が含まれています',
      en: 'Error: Invalid Filename',
      cn: '错误: 文件名包含非法字符');
  String get labelCopyName =>
      _l(jp: 'コピー (現在名)', namery: 'コピー (現在名)', en: 'Copy Name', cn: '复制文件名');
  String get labelCopyPath =>
      _l(jp: 'コピー (パス)', namery: 'コピー (パス)', en: 'Copy Path', cn: '复制路径');
  String get labelCopyFullPath => _l(
      jp: 'コピー (フルパス)',
      namery: 'コピー (フルパス)',
      en: 'Copy Full Path',
      cn: '复制完整路径');
  String get labelCopyOptions =>
      _l(jp: 'コピーオプション', namery: 'コピーオプション', en: 'Copy Options', cn: '复制选项');
  String get labelCopyUndo =>
      _l(jp: '変更記録をコピー', namery: '変更記録をコピー', en: 'Copy Undo Log', cn: '复制撤销记录');
  String get labelCopyListClipboard => _l(
      jp: 'クリップボードへ現在のリストをコピー',
      namery: 'クリップボードへ現在のリストをコピー',
      en: 'Copy List to Clipboard',
      cn: '复制列表到剪贴板');
  String get labelMoveUp =>
      _l(jp: '上に移動', namery: '上に移動', en: 'Move Up', cn: '上移');
  String get labelMoveDown =>
      _l(jp: '下に移動', namery: '下に移動', en: 'Move Down', cn: '下移');
  String get labelRefresh =>
      _l(jp: '全て更新', namery: '全て更新', en: 'Refresh All', cn: '刷新所有');
  String get labelMenuMore =>
      _l(jp: 'その他の操作', namery: 'その他の操作', en: 'More Actions', cn: '更多操作');
  String get labelMenuSettings =>
      _l(jp: 'アプリ設定', namery: 'アプリ設定', en: 'Settings', cn: '设置');
  String get labelMenuFolder =>
      _l(jp: 'メニュー (フォルダ)', namery: 'メニュー (フォルダ)', en: 'Menu', cn: '菜单');

  // Numbering Modes (Main Tab)
  String get labelNumStringNumber =>
      _l(jp: '文字列 + 連番', namery: '文字列 + 連番', en: 'Str + Num', cn: '字符 + 序号');
  String get labelNumOriginalNumber => _l(
      jp: '現在名 + 連番', namery: '現在名 + 連番', en: 'Original + Num', cn: '原名 + 序号');
  String get labelNumNumberString =>
      _l(jp: '連番 + 文字列', namery: '連番 + 文字列', en: 'Num + Str', cn: '序号 + 字符');
  String get labelNumNumberOriginal => _l(
      jp: '連番 + 現在名', namery: '連番 + 現在名', en: 'Num + Original', cn: '序号 + 原名');

  // Complex Numbering Modes
  String get labelNumBaseStringNumber => _l(
      jp: '基本名 + 文字列 + 連番',
      namery: '基本名 + 文字列 + 連番',
      en: 'Base + Str + Num',
      cn: '基本名 + 字符 + 序号');
  String get labelNumBaseStringOriginal => _l(
      jp: '基本名 + 文字列 + 現在名',
      namery: '基本名 + 文字列 + 現在名',
      en: 'Base + Str + Original',
      cn: '基本名 + 字符 + 原名');
  String get labelNumRelativeStringNumber => _l(
      jp: '相対名 + 文字列 + 連番',
      namery: '相対名 + 文字列 + 連番',
      en: 'Relative + Str + Num',
      cn: '相对名 + 字符 + 序号');
  String get labelNumRelativeStringOriginal => _l(
      jp: '相対名 + 文字列 + 現在名',
      namery: '相対名 + 文字列 + 現在名',
      en: 'Relative + Str + Original',
      cn: '相对名 + 字符 + 原名');
  String get labelNumNumberStringBase => _l(
      jp: '連番 + 文字列 + 基本名',
      namery: '連番 + 文字列 + 基本名',
      en: 'Num + Str + Base',
      cn: '序号 + 字符 + 基本名');
  String get labelNumNumberStringRelative => _l(
      jp: '連番 + 文字列 + 相対名',
      namery: '連番 + 文字列 + 相対名',
      en: 'Num + Str + Relative',
      cn: '序号 + 字符 + 相对名');

  // Replace Labels (Main Tab)
  String get labelReplaceFrom =>
      _l(jp: 'を', namery: 'を', en: 'Replace', cn: '将');
  String get labelReplaceTo =>
      _l(jp: 'に置換', namery: 'に置換', en: 'With', cn: '替换为');

  // Address Bar (File List Panel)
  String get labelFullPath =>
      _l(jp: '現在の場所 > ', namery: 'フルパス > ', en: 'Location > ', cn: '当前位置 > ');
  String get labelSelectAll =>
      _l(jp: 'すべて選択', namery: '全選択', en: 'Select All', cn: '全选');

  // Settings & Filter
  String get labelSettingsFilterTitle => _l(
      jp: '表示設定 (フィルタ)',
      namery: '表示設定 (フィルタ)',
      en: 'Filter Settings',
      cn: '筛选设置');
  String get labelFilterAll =>
      _l(jp: '全てのファイル', namery: '全てのファイル', en: 'All Files', cn: '所有文件');
  String get labelFilterSpecific =>
      _l(jp: '指定', namery: '指定', en: 'Specific', cn: '指定');
  String get labelFilterHideSystem => _l(
      jp: 'システムファイルを非表示',
      namery: 'システムファイルを非表示',
      en: 'Hide System Files',
      cn: '隐藏系统文件');
  String get labelFilterRecursive => _l(
      jp: '下位フォルダ検索', namery: '下位フォルダ検索', en: 'Recursive Search', cn: '递归搜索');
  String get labelFilterPreview =>
      _l(jp: 'プレビュー表示', namery: 'プレビュー表示', en: 'Show Preview', cn: '显示预览');
  String get labelExtensionLower => _l(
      jp: '拡張子は小文字化',
      namery: '拡張子は小文字化',
      en: 'Lowercase Extension',
      cn: '后缀小写');

  // Navigation
  String get labelNavBack => _l(jp: '戻る', namery: '戻る', en: 'Back', cn: '后退');
  String get labelNavForward =>
      _l(jp: '進む', namery: '進む', en: 'Forward', cn: '前进');
  String get labelHistoryBack =>
      _l(jp: '履歴 (戻る)', namery: '履歴 (戻る)', en: 'History (Back)', cn: '历史 (后退)');
  String get labelHistoryForward => _l(
      jp: '履歴 (進む)', namery: '履歴 (進む)', en: 'History (Forward)', cn: '历史 (前进)');

  // Navigation
  String get labelNavQuickAccess =>
      _l(jp: 'クイックアクセス', namery: 'クイックアクセス', en: 'Quick Access', cn: '快速访问');

  String get labelGoRenamery => "Go ReNamery!!!";

  // Main Tab (Delete / Find / Numbering)
  String get labelDeleteFront =>
      _l(jp: '前から', namery: '前から', en: 'From Front', cn: '从前');
  String get labelDeleteBack =>
      _l(jp: '後から', namery: '後から', en: 'From Back', cn: '从后');
  String get labelDeleteUntil =>
      _l(jp: 'まで削除', namery: 'まで削除', en: 'Delete Until', cn: '删除至');
  String get labelFindHint =>
      _l(jp: '検索 (Find)', namery: '検索 (Find)', en: 'Find', cn: '查找');
  String get labelReplaceHint =>
      _l(jp: '置換 (Replace)', namery: '置換 (Replace)', en: 'Replace', cn: '替换');
  String get labelRegex =>
      _l(jp: '正規表現', namery: '正規表現', en: 'Regex', cn: '正则表达式');
  // Numbering
  String get labelString =>
      _l(jp: '文字列', namery: '文字列', en: 'String', cn: '字符');
  String get labelStartDigit =>
      _l(jp: '開始/桁', namery: '開始/桁', en: 'Start/Digits', cn: '开始/位数');
}

enum InitialDirectoryMode {
  lastUsed,
  fixed,
}
