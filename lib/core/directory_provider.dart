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
    _isFilterSpecific = _filterText.isNotEmpty; // Init specific if text exists

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
  bool _isFilterSpecific = false;
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
  bool get isFilterSpecific => _isFilterSpecific;

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
    bool? isSpecific,
  }) {
    bool needRescan = false;
    bool needRefilter = false;

    if (isSpecific != null) {
      if (_isFilterSpecific != isSpecific) {
        _isFilterSpecific = isSpecific;
        if (!isSpecific) {
          _filterText = ''; // Clear text if switching to All Files?
          // Or keep it? If we keep it, we need _applyFilters to check _isFilterSpecific.
          // Let's clear it for simplicity and standard behavior (All Files usually means resetting filter).
        }
        needRefilter = true;
      }
    }

    if (filter != null) {
      _filterText = filter;
      if (filter.isNotEmpty) {
        _isFilterSpecific = true; // Auto-enable specific mode on input
      }
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

  // --- Localization Integration ---

  Locale get currentLocale {
    switch (_menuLabelType) {
      case MenuLabelType.standard:
        return const Locale('ja');
      case MenuLabelType.namery:
        return const Locale('ja', 'NM');
      case MenuLabelType.english:
        return const Locale('en');
      case MenuLabelType.chinese:
        return const Locale('zh');
    }
  }
}

enum InitialDirectoryMode {
  lastUsed,
  fixed,
}
