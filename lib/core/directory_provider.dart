import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:super_clipboard/super_clipboard.dart';
import 'file_model.dart';
import 'rename_engine.dart';
import 'undo_manager.dart';
import 'settings_service.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

enum HistoryType { find, replace, add, extension, remove, deleteTo }
enum AppThemeType { system, light, dark, darkGray }
enum MenuLabelType { standard, namery, english, chinese, spanish }

class DirectoryProvider extends ChangeNotifier {
  Directory? _currentDirectory;
  List<FileModel> _currentFiles = [];
  bool _isLoading = false;
  bool _isInlineRenaming = false;
  bool _enableBetaFeatures = false;
  int _treeVersion = 0;
  final UndoManager _undoManager = UndoManager();
  final SettingsService _settings = SettingsService();
  StreamSubscription? _scanSubscription;

  bool _canPaste = false; bool get canPaste => _canPaste;
  bool _isCutMode = false; final Set<String> _cutFilePaths = {}; bool get isCutMode => _isCutMode;
  bool get isInlineRenaming => _isInlineRenaming; bool get enableBetaFeatures => _enableBetaFeatures; int get treeVersion => _treeVersion;

  void setInlineRenaming(bool isRenaming) { if (_isInlineRenaming != isRenaming) { _isInlineRenaming = isRenaming; notifyListeners(); } }

  bool _isLicenseAccepted = false; bool get isLicenseAccepted => _isLicenseAccepted;
  Future<void> acceptLicense() async { _isLicenseAccepted = true; _settings.set('isLicenseAccepted', true); notifyListeners(); }

  Future<void> init() async {
    final s = _settings;
    _isLicenseAccepted = s.getBool('isLicenseAccepted') ?? false;
    _filterText = s.getString('filterText') ?? '';
    _hideSystemFiles = s.getBool('hideSystemFiles') ?? false;
    _recursiveSearch = s.getBool('recursiveSearch') ?? false;
    _showPreview = s.getBool('showPreview') ?? true;
    _showFolders = s.getBool('showFolders') ?? true;
    _saveSequenceNumber = s.getBool('saveSequenceNumber') ?? false;
    _isCompactMode = s.getBool('isCompactMode') ?? true;
    _isFilterSpecific = _filterText.isNotEmpty;
    _enableBetaFeatures = s.getBool('enableBetaFeatures') ?? false;
    _touchMode = s.getBool('touchMode') ?? (!kIsWeb && (Platform.isAndroid || Platform.isIOS));

    final appThemeStr = s.getString('appTheme') ?? 'light';
    _appTheme = AppThemeType.values.firstWhere((e) => e.name == appThemeStr, orElse: () => AppThemeType.light);
    final seedColorVal = s.getInt('seedColor');
    if (seedColorVal != null) _seedColor = Color(seedColorVal);

    final menuLabelStr = s.getString('menuLabelType') ?? 'namery';
    _menuLabelType = MenuLabelType.values.firstWhere((e) => e.name == menuLabelStr, orElse: () => MenuLabelType.standard);

    _navHistory = s.getList<String>('navHistory') ?? [];
    _navIndex = s.getInt('navIndex') ?? -1;
    if (_navIndex >= _navHistory.length) _navIndex = _navHistory.isNotEmpty ? _navHistory.length - 1 : -1;

    final rModeIndex = s.getInt('renameMode');
    if (rModeIndex != null && rModeIndex < RenameMode.values.length) _renameMode = RenameMode.values[rModeIndex];
    final nModeIndex = s.getInt('numberingMode');
    if (nModeIndex != null && nModeIndex < NumberingMode.values.length) _numberingMode = NumberingMode.values[nModeIndex];

    _findText = ''; _replaceText = ''; _appendText = ''; _deleteToText = '';
    _startNumber = s.getInt('startNumber') ?? 1;
    _digits = s.getInt('digits') ?? 3;
    _extensionToLowerCase = s.getBool('extensionToLowerCase') ?? true;
    _useRegex = s.getBool('useRegex') ?? false;

    _listRenameText = s.getString('listRenameText') ?? '01_chapter_intro.mp4\n02_chapter_main.mp4\n03_chapter_end.mp4';
    _extensionChangeText = s.getString('extensionChangeText') ?? '';
    _extensionAddText = s.getString('extensionAddText') ?? '';

    final lMainIndex = s.getInt('lastMainMode');
    if (lMainIndex != null && lMainIndex < RenameMode.values.length) _lastMainMode = RenameMode.values[lMainIndex];
    final lSubIndex = s.getInt('lastSubMode');
    if (lSubIndex != null && lSubIndex < RenameMode.values.length) _lastSubMode = RenameMode.values[lSubIndex];
    final lEtcIndex = s.getInt('lastEtcMode');
    if (lEtcIndex != null && lEtcIndex < RenameMode.values.length) _lastEtcMode = RenameMode.values[lEtcIndex];
    final lExtraIndex = s.getInt('lastExtraMode');
    if (lExtraIndex != null && lExtraIndex < RenameMode.values.length) _lastExtraMode = RenameMode.values[lExtraIndex];

    _dateFormat = s.getString('dateFormat') ?? 'yyyymmdd_';
    final dPosIndex = s.getInt('datePosition');
    if (dPosIndex != null && dPosIndex < DatePosition.values.length) _datePosition = DatePosition.values[dPosIndex];

    final vTypeIndex = s.getInt('validationType');
    if (vTypeIndex != null && vTypeIndex < ValidationType.values.length) _validationType = ValidationType.values[vTypeIndex];

    final initModeIndex = s.getInt('initialDirectoryMode');
    if (initModeIndex != null && initModeIndex < InitialDirectoryMode.values.length) _initialDirectoryMode = InitialDirectoryMode.values[initModeIndex];
    _fixedInitialDirectory = s.getString('fixedInitialDirectory') ?? '';

    _etcTimestamp = s.getString('etcTimestamp') ?? '';
    if (_etcTimestamp.isEmpty) {
      final now = DateTime.now();
      _etcTimestamp = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    }
    _etcAttribReadOnly = s.getBool('etcAttribReadOnly') ?? false;
    _etcAttribHidden = s.getBool('etcAttribHidden') ?? false;
    _etcAttribArchive = s.getBool('etcAttribArchive') ?? false;
    _etcAttribSystem = s.getBool('etcAttribSystem') ?? false;

    _appendHistory = s.getStringList('appendHistory');
    _deleteFromHistory = s.getStringList('deleteFromHistory');
    _deleteToHistory = s.getStringList('deleteToHistory');
    _findHistory = s.getStringList('findHistory');
    _replaceHistory = s.getStringList('replaceHistory');
    _extensionHistory = s.getStringList('extensionHistory');

    _sortColumnIndex = s.getInt('sortColumnIndex') ?? 0;
    _sortAscending = s.getBool('sortAscending') ?? true;

    await checkClipboard();
    notifyListeners();

    Directory? targetDir;
    if (_initialDirectoryMode == InitialDirectoryMode.fixed && _fixedInitialDirectory.isNotEmpty) {
      targetDir = Directory(_fixedInitialDirectory);
    } else {
      final lastDir = s.getString('lastDirectory');
      if (lastDir != null) targetDir = Directory(lastDir);
    }

    if (targetDir != null && await targetDir.exists()) await setDirectory(targetDir);
    else if (_currentDirectory != null) _applyFilters();
  }

  void _saveState() {
    final s = SettingsService();
    if (_currentDirectory != null) s.set('lastDirectory', _currentDirectory!.path);
    s.set('filterText', _filterText); s.set('hideSystemFiles', _hideSystemFiles);
    s.set('recursiveSearch', _recursiveSearch); s.set('showPreview', _showPreview);
    s.set('showFolders', _showFolders); s.set('saveSequenceNumber', _saveSequenceNumber);
    s.set('isCompactMode', _isCompactMode); s.set('touchMode', _touchMode);
    s.set('enableBetaFeatures', _enableBetaFeatures); s.set('appTheme', _appTheme.name);
    s.set('menuLabelType', _menuLabelType.name); s.set('seedColor', _seedColor.toARGB32());
    s.set('navHistory', _navHistory); s.set('navIndex', _navIndex);
    s.set('renameMode', _renameMode.index); s.set('numberingMode', _numberingMode.index);
    if (_findText != null) s.set('findText', _findText);
    if (_replaceText != null) s.set('replaceText', _replaceText);
    if (_appendText != null) s.set('appendText', _appendText);
    if (_deleteToText != null) s.set('deleteToText', _deleteToText);
    s.set('startNumber', _startNumber); s.set('digits', _digits);
    s.set('extensionToLowerCase', _extensionToLowerCase); s.set('useRegex', _useRegex);
    s.set('appendHistory', _appendHistory); s.set('deleteFromHistory', _deleteFromHistory);
    s.set('deleteToHistory', _deleteToHistory); s.set('findHistory', _findHistory);
    s.set('replaceHistory', _replaceHistory); s.set('extensionHistory', _extensionHistory);
    s.set('sortColumnIndex', _sortColumnIndex); s.set('sortAscending', _sortAscending);
    s.set('listRenameText', _listRenameText); s.set('extensionChangeText', _extensionChangeText);
    s.set('extensionAddText', _extensionAddText); s.set('lastMainMode', _lastMainMode.index);
    s.set('lastSubMode', _lastSubMode.index); s.set('lastEtcMode', _lastEtcMode.index);
    s.set('lastExtraMode', _lastExtraMode.index); s.set('dateFormat', _dateFormat);
    s.set('datePosition', _datePosition.index); s.set('validationType', _validationType.index);
    s.set('initialDirectoryMode', _initialDirectoryMode.index); s.set('fixedInitialDirectory', _fixedInitialDirectory);
    s.set('etcTimestamp', _etcTimestamp); s.set('etcAttribReadOnly', _etcAttribReadOnly);
    s.set('etcAttribHidden', _etcAttribHidden); s.set('etcAttribArchive', _etcAttribArchive);
    s.set('etcAttribSystem', _etcAttribSystem);
  }

  RenameMode _renameMode = RenameMode.numbering; NumberingMode _numberingMode = NumberingMode.stringNumber;
  ValidationType _validationType = ValidationType.auto; InitialDirectoryMode _initialDirectoryMode = InitialDirectoryMode.lastUsed;
  String _fixedInitialDirectory = ''; int _resetCount = 0; int get resetCount => _resetCount;
  String? _findText; String? _replaceText; String? _appendText; String? _deleteToText;
  int _startNumber = 1; int _insertIndex = 1; int _digits = 3;
  bool _extensionToLowerCase = true; bool _useRegex = false;
  String? _navigationSource; String? get navigationSource => _navigationSource;
  String? _navigationContextRoot; String? get navigationContextRoot => _navigationContextRoot;
  List<String> _appendHistory = []; List<String> _deleteFromHistory = []; List<String> _deleteToHistory = [];
  List<String> _findHistory = []; List<String> _replaceHistory = []; List<String> _extensionHistory = [];
  String _filterText = ''; bool _isFilterSpecific = false; bool _hideSystemFiles = false; bool _isFilterRegex = false;
  bool _recursiveSearch = false; bool _showPreview = true; bool _showFolders = true;
  bool _saveSequenceNumber = false; bool _isCompactMode = false; bool _touchMode = false;
  bool _isEnlargedPreviewOpen = false; int _enlargedPreviewIndex = -1;
  double _textPreviewFontSize = 13.0; double get textPreviewFontSize => _textPreviewFontSize;
  bool get isFilterRegex => _isFilterRegex;

  void setTextPreviewFontSize(double size) { _textPreviewFontSize = size.clamp(8.0, 40.0); notifyListeners(); }
  AppThemeType _appTheme = AppThemeType.light; MenuLabelType _menuLabelType = MenuLabelType.standard;
  Color _seedColor = Colors.green; String _dateFormat = 'yyyyMMdd_'; DatePosition _datePosition = DatePosition.front;
  String _etcTimestamp = ''; bool _etcAttribReadOnly = false; bool _etcAttribHidden = false;
  bool _etcAttribArchive = false; bool _etcAttribSystem = false;
  List<FileModel> _allFiles = []; Directory? get currentDirectory => _currentDirectory;
  List<FileModel> get currentFiles => _currentFiles; int get allFilesCount => _allFiles.length;
  bool get isLoading => _isLoading; bool get canUndo => _undoManager.canUndo; int get undoCount => _undoManager.undoCount;
  RenameMode get renameMode => _renameMode; NumberingMode get numberingMode => _numberingMode;
  ValidationType get validationType => _validationType; InitialDirectoryMode get initialDirectoryMode => _initialDirectoryMode;
  String get fixedInitialDirectory => _fixedInitialDirectory; bool get touchMode => _touchMode;
  bool get isEnlargedPreviewOpen => _isEnlargedPreviewOpen; int get enlargedPreviewIndex => _enlargedPreviewIndex;
  FileModel? get enlargedPreviewFile => (_enlargedPreviewIndex >= 0 && _enlargedPreviewIndex < _currentFiles.length) ? _currentFiles[_enlargedPreviewIndex] : null;

  int get enlargedPreviewSelectedListIndex {
    final file = enlargedPreviewFile; if (file == null) return -1;
    final selectedFiles = _currentFiles.where((f) => f.isSelected).toList();
    return selectedFiles.indexOf(file);
  }
  int get selectedFilesCount => _currentFiles.where((f) => f.isSelected).length;

  void openEnlargedPreview(FileModel file) { _enlargedPreviewIndex = _currentFiles.indexOf(file); if (_enlargedPreviewIndex != -1) { _isEnlargedPreviewOpen = true; notifyListeners(); } }
  void closeEnlargedPreview() { _isEnlargedPreviewOpen = false; notifyListeners(); }
  void nextEnlargedPreview() {
    final selectedFiles = _currentFiles.where((f) => f.isSelected).toList(); if (selectedFiles.isEmpty) return;
    final currentFile = enlargedPreviewFile; int selectedIdx = selectedFiles.indexOf(currentFile!);
    selectedIdx = (selectedIdx + 1) % selectedFiles.length; _enlargedPreviewIndex = _currentFiles.indexOf(selectedFiles[selectedIdx]); notifyListeners();
  }
  void prevEnlargedPreview() {
    final selectedFiles = _currentFiles.where((f) => f.isSelected).toList(); if (selectedFiles.isEmpty) return;
    final currentFile = enlargedPreviewFile; int selectedIdx = selectedFiles.indexOf(currentFile!);
    selectedIdx = (selectedIdx - 1 + selectedFiles.length) % selectedFiles.length; _enlargedPreviewIndex = _currentFiles.indexOf(selectedFiles[selectedIdx]); notifyListeners();
  }

  void updateInitialDirectorySettings(InitialDirectoryMode mode, String path) { _initialDirectoryMode = mode; _fixedInitialDirectory = path; _saveState(); notifyListeners(); }
  String? get findText => _findText; String? get replaceText => _replaceText; String? get appendText => _appendText; String? get deleteToText => _deleteToText;
  int get startNumber => _startNumber; int get insertIndex => _insertIndex; int get digits => _digits;
  bool get extensionToLowerCase => _extensionToLowerCase; bool get useRegex => _useRegex;
  List<String> get appendHistory => _appendHistory; List<String> get deleteFromHistory => _deleteFromHistory;
  List<String> get deleteToHistory => _deleteToHistory; List<String> get findHistory => _findHistory;
  List<String> get replaceHistory => _replaceHistory; List<String> get extensionHistory => _extensionHistory;

  RenameMode _lastMainMode = RenameMode.numbering; RenameMode _lastSubMode = RenameMode.extension;
  RenameMode _lastEtcMode = RenameMode.changeTimestamp; RenameMode _lastExtraMode = RenameMode.appendDate;
  RenameMode _lastStringMode = RenameMode.append;
  RenameMode get lastMainMode => _lastMainMode; RenameMode get lastSubMode => _lastSubMode;
  RenameMode get lastEtcMode => _lastEtcMode; RenameMode get lastExtraMode => _lastExtraMode;
  RenameMode get lastStringMode => _lastStringMode; String get dateFormat => _dateFormat; DatePosition get datePosition => _datePosition;
  String get etcTimestamp => _etcTimestamp; bool get etcAttribReadOnly => _etcAttribReadOnly; bool get etcAttribHidden => _etcAttribHidden;
  bool get etcAttribArchive => _etcAttribArchive; bool get etcAttribSystem => _etcAttribSystem;

  bool isMainMode(RenameMode mode) => !isSubMode(mode) && !isExtraMode(mode) && !isEtcMode(mode);
  bool isSubMode(RenameMode mode) => [RenameMode.extensionRemove, RenameMode.extensionAdd, RenameMode.extensionUpper, RenameMode.extensionLower, RenameMode.formatProperCase, RenameMode.listRename].contains(mode);
  bool isExtraMode(RenameMode mode) => [RenameMode.appendDate, RenameMode.convHalfToFull, RenameMode.convFullToHalf, RenameMode.convFullKataToHira, RenameMode.convHiraToFullKata, RenameMode.convFullAlphaToHalfAlpha, RenameMode.convNumToHalf].contains(mode);
  bool isEtcMode(RenameMode mode) => [RenameMode.changeTimestamp, RenameMode.changeAttributes].contains(mode);

  String _listRenameText = '01_chapter_intro.mp4\n02_chapter_main.mp4\n03_chapter_end.mp4';
  String _extensionChangeText = ''; String _extensionAddText = ''; Timer? _previewTimer;
  String get listRenameText => _listRenameText; String get extensionChangeText => _extensionChangeText; String get extensionAddText => _extensionAddText;

  String get filterText => _filterText; bool get hideSystemFiles => _hideSystemFiles;
  bool get recursiveSearch => _recursiveSearch; bool get showPreview => _showPreview;
  bool get showFolders => _showFolders; bool get saveSequenceNumber => _saveSequenceNumber;
  bool get isCompactMode => _isCompactMode; bool get isFilterSpecific => _isFilterSpecific;
  AppThemeType get appTheme => _appTheme; MenuLabelType get menuLabelType => _menuLabelType;

  ThemeMode get themeMode {
    switch (_appTheme) {
      case AppThemeType.light: return ThemeMode.light;
      case AppThemeType.dark: case AppThemeType.darkGray: return ThemeMode.dark;
      case AppThemeType.system: return ThemeMode.system;
    }
  }
  Color get seedColor => _seedColor;

  Future<void> checkClipboard() async {
    try {
      final clipboard = SystemClipboard.instance; if (clipboard == null) { _canPaste = false; notifyListeners(); return; }
      final reader = await clipboard.read(); _canPaste = reader.canProvide(Formats.fileUri);
    } catch (e) { debugPrint('Clipboard check failed: $e'); _canPaste = false; }
    notifyListeners();
  }

  Future<void> copySelection() async {
    final targets = _currentFiles.where((f) => f.isSelected).toList(); if (targets.isEmpty) return;
    _isCutMode = false; _cutFilePaths.clear(); for (var f in _allFiles) f.setCut(false, notify: false); for (var f in _allFiles) f.notifyIfChanged();
    final cb = SystemClipboard.instance; if (cb != null) {
      final items = targets.map((f) { final item = DataWriterItem(); item.add(Formats.fileUri(f.entity.uri)); return item; }).toList();
      await cb.write(items);
    }
    await checkClipboard(); notifyListeners();
  }

  Future<void> cutSelection() async {
    final targets = _currentFiles.where((f) => f.isSelected).toList(); if (targets.isEmpty) return;
    _isCutMode = true; _cutFilePaths.clear(); _cutFilePaths.addAll(targets.map((f) => f.entity.path));
    for (var f in _allFiles) f.setCut(_cutFilePaths.contains(f.entity.path), notify: false); for (var f in _allFiles) f.notifyIfChanged();
    final cb = SystemClipboard.instance; if (cb != null) {
      final items = targets.map((f) { final item = DataWriterItem(); item.add(Formats.fileUri(f.entity.uri)); return item; }).toList();
      await cb.write(items);
    }
    await checkClipboard(); notifyListeners();
  }

  void clearCutState() { _isCutMode = false; _cutFilePaths.clear(); for (var f in _allFiles) f.setCut(false, notify: false); for (var f in _allFiles) f.notifyIfChanged(); notifyListeners(); }

  Future<void> pasteFromClipboard() async {
    if (_currentDirectory == null) return;
    final clipboard = SystemClipboard.instance; if (clipboard == null) return;
    final reader = await clipboard.read();
    if (reader.canProvide(Formats.fileUri)) {
      _isLoading = true; notifyListeners(); List<UndoAction> transaction = [];
      for (final item in reader.items) {
        if (item.canProvide(Formats.fileUri)) {
          final uri = await item.readValue(Formats.fileUri); if (uri == null) continue;
          try {
            final srcP = uri.toFilePath(); final name = p.basename(srcP);
            final destP = _getUniquePath(p.join(_currentDirectory!.path, name));
            final ent = FileSystemEntity.typeSync(srcP) == FileSystemEntityType.file ? File(srcP) : Directory(srcP);
            if (_isCutMode) { await ent.rename(destP); transaction.add(UndoAction(srcP, destP, type: UndoType.rename)); }
            else { if (ent is File) await ent.copy(destP); else await _copyDirectory(ent as Directory, Directory(destP)); transaction.add(UndoAction(srcP, destP, type: UndoType.copy)); }
          } catch (e) { if (kDebugMode) print('Paste error: $e'); }
        }
      }
      if (transaction.isNotEmpty) _undoManager.addTransaction(transaction); if (_isCutMode) { _isCutMode = false; _cutFilePaths.clear(); }
      await refresh();
    }
  }

  String _getUniquePath(String path) {
    if (!File(path).existsSync() && !Directory(path).existsSync()) return path;
    final dir = p.dirname(path); final name = p.basenameWithoutExtension(path); final ext = p.extension(path); int counter = 2;
    while (true) { final newPath = p.join(dir, '$name ($counter)$ext'); if (!File(newPath).existsSync() && !Directory(newPath).existsSync()) return newPath; counter++; }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (var entity in source.list(recursive: false)) {
      final newP = p.join(destination.path, p.basename(entity.path));
      if (entity is Directory) await _copyDirectory(entity, Directory(newP)); else if (entity is File) await entity.copy(newP);
    }
  }

  Future<void> createNewFolder() async {
    if (_currentDirectory == null) return;
    String folderName = '新しいフォルダー'; int index = 1;
    while (await Directory(p.join(_currentDirectory!.path, folderName)).exists()) { index++; folderName = '新しいフォルダー ($index)'; }
    try {
      final destP = p.join(_currentDirectory!.path, folderName); await Directory(destP).create();
      _undoManager.addTransaction([UndoAction('', destP, type: UndoType.create)]); await refresh();
    } catch (e) { if (kDebugMode) print('Create Folder error: $e'); }
  }

  Timer? _filterTimer;
  void updateFilterSettings({String? filter, bool? hideSystem, bool? recursive, bool? preview, bool? showFolders, bool? isSpecific, bool? isRegex}) {
    bool needRescan = false; bool needRefilter = false;
    if (isSpecific != null) { if (_isFilterSpecific != isSpecific) { _isFilterSpecific = isSpecific; if (!isSpecific) _filterText = ''; needRefilter = true; } }
    if (filter != null) { _filterText = filter; if (filter.isNotEmpty) _isFilterSpecific = true; needRefilter = true; }
    if (isRegex != null) { _isFilterRegex = isRegex; needRefilter = true; notifyListeners(); }
    if (hideSystem != null) { _hideSystemFiles = hideSystem; needRefilter = true; }
    if (recursive != null) { if (_recursiveSearch != recursive) { _recursiveSearch = recursive; needRescan = true; } }
    if (preview != null) { _showPreview = preview; notifyListeners(); }
    if (showFolders != null) { _showFolders = showFolders; needRefilter = true; }
    if (needRescan) { if (_currentDirectory != null) setDirectory(_currentDirectory!); }
    else if (needRefilter) { _filterTimer?.cancel(); _filterTimer = Timer(const Duration(milliseconds: 300), () => _applyFilters()); }
    _saveState();
  }

  void setCompactMode(bool isCompact) { _isCompactMode = isCompact; _saveState(); notifyListeners(); }
  void setTouchMode(bool value) { _touchMode = value; _saveState(); notifyListeners(); }
  void setEnableBetaFeatures(bool enable) { _enableBetaFeatures = enable; _saveState(); notifyListeners(); }
  void setAppTheme(AppThemeType theme) { _appTheme = theme; _saveState(); notifyListeners(); }
  void setMenuLabelType(MenuLabelType type) { _menuLabelType = type; _saveState(); notifyListeners(); }
  void setSeedColor(Color color) { _seedColor = color; _saveState(); notifyListeners(); }

  int _filterVersion = 0;
  Future<void> _applyFilters() async {
    final currentVersion = ++_filterVersion; if (_allFiles.isEmpty) { _currentFiles = []; notifyListeners(); return; }
    final input = {'files': _allFiles.map((f) => {'originalName': f.originalName, 'isDirectory': f.entity is Directory}).toList(), 'filterText': _filterText, 'isFilterRegex': _isFilterRegex, 'hideSystemFiles': _hideSystemFiles, 'showFolders': _showFolders};
    final visibility = await compute(_computeFilter, input); if (currentVersion != _filterVersion) return;
    final List<FileModel> filtered = []; for (int i = 0; i < _allFiles.length; i++) { if (visibility[i]) filtered.add(_allFiles[i]); }
    _currentFiles = filtered; for (var f in _allFiles) f.setCut(_cutFilePaths.contains(f.entity.path), notify: false); for (var f in _allFiles) f.notifyIfChanged();
    sortFiles(_sortColumnIndex, _sortAscending); notifyListeners();
  }

  static List<bool> _computeFilter(Map<String, dynamic> params) {
    final List<dynamic> files = params['files']; final String filterText = params['filterText']; final bool isFilterRegex = params['isFilterRegex'];
    final bool hideSystemFiles = params['hideSystemFiles']; final bool showFolders = params['showFolders'];
    RegExp? regex; if (filterText.isNotEmpty && isFilterRegex) { try { regex = RegExp(filterText, caseSensitive: false, unicode: true); } catch (_) {} }
    return files.map((f) {
      final String originalName = f['originalName']; final bool isDirectory = f['isDirectory'];
      if (hideSystemFiles && originalName.startsWith('.')) return false; if (!showFolders && isDirectory) return false;
      if (filterText.isNotEmpty) { if (isFilterRegex) { if (regex == null) return true; return regex.hasMatch(originalName); } else return originalName.toLowerCase().contains(filterText.toLowerCase()); }
      return true;
    }).toList();
  }

  bool _shouldShowFile(FileModel file) {
    if (_hideSystemFiles && p.basename(file.originalName).startsWith('.')) return false;
    if (!_showFolders && file.entity is Directory) return false;
    if (_filterText.isNotEmpty) {
      if (_isFilterRegex) { try { return RegExp(_filterText, caseSensitive: false, unicode: true).hasMatch(file.originalName); } catch (e) { return true; } }
      else return file.originalName.toLowerCase().contains(_filterText.toLowerCase());
    }
    return true;
  }

  void updateRenameSettings({RenameMode? mode, NumberingMode? numberingMode, String? find, String? replace, String? append, String? deleteTo, int? start, int? digit, String? findText, String? replaceText, String? appendText, String? deleteToText, int? startNumber, int? insertIndex, int? digits, bool? extensionToLowerCase, bool? useRegex, bool? saveSequenceNumber, String? listText, String? extensionChangeText, String? extensionAddText, String? dateFormat, DatePosition? datePosition, ValidationType? validationType, String? etcTimestamp, bool? etcAttribReadOnly, bool? etcAttribHidden, bool? etcAttribArchive, bool? etcAttribSystem, bool immediate = false}) {
    if (mode != null) _renameMode = mode; if (numberingMode != null) _numberingMode = numberingMode;
    if (find != null || findText != null) _findText = find ?? findText; if (replace != null || replaceText != null) _replaceText = replace ?? replaceText;
    if (append != null || appendText != null) _appendText = append ?? appendText; if (deleteTo != null || deleteToText != null) _deleteToText = deleteTo ?? deleteToText;
    if (start != null || startNumber != null) _startNumber = (start ?? startNumber)!; if (insertIndex != null) _insertIndex = insertIndex;
    if (digit != null || digits != null) _digits = (digit ?? digits)!; if (extensionToLowerCase != null) _extensionToLowerCase = extensionToLowerCase;
    if (useRegex != null) _useRegex = useRegex; if (dateFormat != null) _dateFormat = dateFormat; if (datePosition != null) _datePosition = datePosition;
    if (validationType != null) _validationType = validationType; if (etcTimestamp != null) _etcTimestamp = etcTimestamp;
    if (etcAttribReadOnly != null) _etcAttribReadOnly = etcAttribReadOnly; if (etcAttribHidden != null) _etcAttribHidden = etcAttribHidden;
    if (etcAttribArchive != null) _etcAttribArchive = etcAttribArchive; if (etcAttribSystem != null) _etcAttribSystem = etcAttribSystem;
    if (listText != null) _listRenameText = listText; if (extensionChangeText != null) _extensionChangeText = extensionChangeText;
    if (extensionAddText != null) _extensionAddText = extensionAddText; if (saveSequenceNumber != null) _saveSequenceNumber = saveSequenceNumber;
    if (mode != null) {
      if (isSubMode(mode)) _lastSubMode = mode; else if (isMainMode(mode)) _lastMainMode = mode; else if (isExtraMode(mode)) _lastExtraMode = mode; else if (isEtcMode(mode)) _lastEtcMode = mode;
      if (mode == RenameMode.append || mode == RenameMode.prepend || mode == RenameMode.insert || mode == RenameMode.numbering) _lastStringMode = mode;
    }
    _previewTimer?.cancel(); if (immediate) _updatePreviews(); else _previewTimer = Timer(const Duration(milliseconds: 200), () => _updatePreviews());
    _saveState(); notifyListeners();
  }

  int _previewVersion = 0;
  Future<void> _updatePreviews() async {
    if (_currentFiles.isEmpty) return; final currentVersion = ++_previewVersion; List<FileModel> targets = [];
    for (var f in _currentFiles) { if (f.isSelected) targets.add(f); f.setNewName(f.originalName, notify: false); f.setValidationError(null, notify: false); }
    if (targets.isEmpty) { for (var f in _currentFiles) f.notifyIfChanged(); notifyListeners(); return; }
    String? curFind = (_renameMode == RenameMode.deleteFrontTo || _renameMode == RenameMode.deleteBackTo) ? _deleteToText : _findText;
    String? curReplace = (_renameMode == RenameMode.extension) ? _extensionChangeText : (_renameMode == RenameMode.extensionAdd ? _extensionAddText : _replaceText);
    String? baseDir = _currentDirectory != null ? p.basename(_currentDirectory!.path) : null;
    final input = {'mode': _renameMode, 'fileData': targets.map((f) => {'originalName': f.originalName, 'isDirectory': f.entity is Directory, 'modified': f.entity.statSync().modified}).toList(), 'findText': curFind, 'replaceText': curReplace, 'appendText': _appendText, 'startNumber': _startNumber, 'insertIndex': _insertIndex, 'digits': _digits, 'caseConversion': CaseConversion.none, 'extensionToLowerCase': _extensionToLowerCase, 'useRegex': _useRegex, 'numberingMode': _numberingMode, 'baseDirName': baseDir, 'listText': _listRenameText, 'dateFormat': _dateFormat, 'datePosition': _datePosition, 'validationType': _validationType, 'isWindows': !kIsWeb && Platform.isWindows, 'isMacOS': !kIsWeb && Platform.isMacOS};
    final results = await compute(RenameEngine.computeGeneratePreviews, input); if (currentVersion != _previewVersion) return;
    for (int i = 0; i < targets.length; i++) { final f = targets[i]; final res = results[i]; f.setNewName(res['newName']!, notify: false); f.setValidationError(res['error'], notify: false); }
    _hasValidationError = false; final nameCounts = <String, int>{};
    for (var f in _currentFiles) { if (f.validationErrorMessage != null && f.validationErrorMessage != 'ファイル名が重複しています') _hasValidationError = true; final fullPathKey = p.join(f.parentPath, f.newName).toLowerCase(); nameCounts[fullPathKey] = (nameCounts[fullPathKey] ?? 0) + 1; }
    for (var f in targets) {
      if (f.validationErrorMessage == null || f.validationErrorMessage == 'ファイル名が重複しています') { final fullPathKey = p.join(f.parentPath, f.newName).toLowerCase(); if ((nameCounts[fullPathKey] ?? 0) > 1) { f.setValidationError('ファイル名が重複しています', notify: false); _hasValidationError = true; } else f.setValidationError(null, notify: false); }
    }
    for (var f in _currentFiles) f.notifyIfChanged(); notifyListeners();
  }

  bool _hasValidationError = false; bool get hasValidationError => _hasValidationError;
  int _sortColumnIndex = 0; bool _sortAscending = true; int get sortColumnIndex => _sortColumnIndex; bool get sortAscending => _sortAscending;
  void toggleSelection(FileModel file) { file.isSelected = !file.isSelected; _updatePreviewsDebounced(); }
  void _updatePreviewsDebounced({bool immediate = false}) { _previewTimer?.cancel(); if (immediate) _updatePreviews(); else _previewTimer = Timer(const Duration(milliseconds: 50), () => _updatePreviews()); }

  void resetSettings() {
    _appTheme = AppThemeType.light; _menuLabelType = MenuLabelType.standard; _seedColor = Colors.green; _isCompactMode = false; _initialDirectoryMode = InitialDirectoryMode.lastUsed; _fixedInitialDirectory = ''; _renameMode = RenameMode.numbering; _numberingMode = NumberingMode.stringNumber; _startNumber = 1; _insertIndex = 1; _digits = 3; _findText = ''; _replaceText = ''; _appendText = ''; _deleteToText = ''; _extensionToLowerCase = true; _useRegex = false; _saveSequenceNumber = false; _lastMainMode = RenameMode.numbering; _lastSubMode = RenameMode.extension; _lastExtraMode = RenameMode.appendDate; _lastEtcMode = RenameMode.changeTimestamp; _lastStringMode = RenameMode.append; _listRenameText = '01_chapter_intro.mp4\n02_chapter_main.mp4\n03_chapter_end.mp4'; _extensionChangeText = ''; _extensionAddText = ''; _dateFormat = 'yyyyMMdd_'; _datePosition = DatePosition.front;
    final now = DateTime.now(); _etcTimestamp = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'; _etcAttribReadOnly = false; _etcAttribHidden = false; _etcAttribArchive = false; _etcAttribSystem = false; _showFolders = true; _hideSystemFiles = true; _recursiveSearch = false; _showPreview = true; _validationType = ValidationType.auto; _resetCount++; _applyFilters(); _saveState(); notifyListeners();
  }

  void selectAll(bool select) { for (var f in _currentFiles) f.setSelected(select, notify: false); for (var f in _currentFiles) f.notifyIfChanged(); _updatePreviews(); notifyListeners(); }
  void selectRange(int start, int end, {bool exclusive = true, List<bool>? baseStates}) {
    final minIdx = start < end ? start : end; final maxIdx = start > end ? start : end;
    for (int i = 0; i < _currentFiles.length; i++) {
      final isInside = i >= minIdx && i <= maxIdx;
      if (baseStates != null && i < baseStates.length) _currentFiles[i].setSelected(isInside ? !baseStates[i] : baseStates[i], notify: false);
      else { if (isInside) _currentFiles[i].setSelected(true, notify: false); else if (exclusive) _currentFiles[i].setSelected(false, notify: false); }
    }
    for (var f in _currentFiles) f.notifyIfChanged(); _updatePreviews(); notifyListeners();
  }

  void sortFiles(int columnIndex, bool ascending) {
    _sortColumnIndex = columnIndex; _sortAscending = ascending;
    _currentFiles.sort((a, b) {
      final isDirA = a.entity is Directory; final isDirB = b.entity is Directory; if (isDirA && !isDirB) return -1; if (!isDirA && isDirB) return 1; int cmp = 0;
      switch (columnIndex) { case 0: cmp = a.originalName.toLowerCase().compareTo(b.originalName.toLowerCase()); break; case 1: cmp = a.newName.toLowerCase().compareTo(b.newName.toLowerCase()); break; case 2: if (a.entity is File && b.entity is File) { int sA = 0; int sB = 0; try { sA = (a.entity as File).lengthSync(); } catch (_) {} try { sB = (b.entity as File).lengthSync(); } catch (_) {} cmp = sA.compareTo(sB); } break; case 3: cmp = a.relativePath.compareTo(b.relativePath); break; case 4: cmp = a.fileType.compareTo(b.fileType); break; case 5: try { cmp = a.entity.statSync().modified.compareTo(b.entity.statSync().modified); } catch (e) { cmp = 0; } break; case 6: cmp = a.attributes.compareTo(b.attributes); break; }
      return ascending ? cmp : -cmp;
    });
    _updatePreviews(); _saveState(); notifyListeners();
  }

  List<String> _navHistory = []; int _navIndex = -1;
  bool get canGoBack => _navIndex > 0; bool get canGoForward => _navIndex < _navHistory.length - 1;
  Future<void> goBack() async { if (canGoBack) { _navIndex--; await _navigateInternal(Directory(_navHistory[_navIndex])); } }
  Future<void> goForward() async { if (canGoForward) { _navIndex++; await _navigateInternal(Directory(_navHistory[_navIndex])); } }
  List<String> get backHistory => _navIndex <= 0 ? [] : _navHistory.sublist(0, _navIndex).reversed.toSet().toList();
  List<String> get forwardHistory => _navIndex >= _navHistory.length - 1 ? [] : _navHistory.sublist(_navIndex + 1).toSet().toList();
  Future<void> jumpBack(int steps) async { final ni = _navIndex - steps; if (ni >= 0) { _navIndex = ni; await _navigateInternal(Directory(_navHistory[_navIndex])); } }
  Future<void> jumpForward(int steps) async { final ni = _navIndex + steps; if (ni < _navHistory.length) { _navIndex = ni; await _navigateInternal(Directory(_navHistory[_navIndex])); } }
  Future<void> refresh() async { if (_currentDirectory != null) await setDirectory(_currentDirectory!, addToHistory: false); }
  Future<void> _navigateInternal(Directory dir) async => await setDirectory(dir, addToHistory: false);

  bool get canExecute { final s = _currentFiles.where((f) => f.isSelected); return s.isNotEmpty && s.any((f) => f.validationErrorMessage == null && f.originalName != f.newName); }
  bool get hasInvalidFilenamesSelected => _currentFiles.any((f) => f.isSelected && f.validationErrorMessage != null);
  int get validFileCount => _currentFiles.where((f) => f.isSelected && f.validationErrorMessage == null).length;
  int get invalidFileCount => _currentFiles.where((f) => f.isSelected && f.validationErrorMessage != null).length;

  bool get canMoveUp { if (_currentFiles.isEmpty) return false; for (int i = 0; i < _currentFiles.length; i++) { if (_currentFiles[i].isSelected && i > 0 && !_currentFiles[i - 1].isSelected) return true; } return false; }
  bool get canMoveDown { if (_currentFiles.isEmpty) return false; for (int i = 0; i < _currentFiles.length; i++) { if (_currentFiles[i].isSelected && i < _currentFiles.length - 1 && !_currentFiles[i + 1].isSelected) return true; } return false; }

  void moveSelection(bool up) {
    var si = _currentFiles.asMap().entries.where((e) => e.value.isSelected).map((e) => e.key).toList(); if (si.isEmpty) return; si.sort(); if (!up) si = si.reversed.toList();
    bool changed = false; final List<FileModel> newFiles = List.from(_currentFiles);
    for (var index in si) { if (up && index > 0 && !newFiles[index - 1].isSelected) { final t = newFiles[index - 1]; newFiles[index - 1] = newFiles[index]; newFiles[index] = t; changed = true; } else if (!up && index < newFiles.length - 1 && !newFiles[index + 1].isSelected) { final t = newFiles[index + 1]; newFiles[index + 1] = newFiles[index]; newFiles[index] = t; changed = true; } }
    if (changed) { _currentFiles = newFiles; _updatePreviews(); notifyListeners(); }
  }

  void reorderFiles(int oldIndex, int newIndex) {
    final draggedFile = _currentFiles[oldIndex];
    if (draggedFile.isSelected) {
      final selectedFiles = _currentFiles.where((f) => f.isSelected).toList(); final leaderOffset = selectedFiles.indexOf(draggedFile); _currentFiles.removeWhere((f) => f.isSelected);
      int insertBase = (oldIndex < newIndex) ? newIndex - 1 : newIndex; int finalStartIdx = (insertBase - leaderOffset).clamp(0, _currentFiles.length); _currentFiles.insertAll(finalStartIdx, selectedFiles);
    } else { if (oldIndex < newIndex) newIndex -= 1; final item = _currentFiles.removeAt(oldIndex); _currentFiles.insert(newIndex.clamp(0, _currentFiles.length), item); }
    _updatePreviews(); notifyListeners();
  }

  void moveSelectedToTop() { final s = _currentFiles.where((f) => f.isSelected).toList(); final u = _currentFiles.where((f) => !f.isSelected).toList(); if (s.isNotEmpty) { _currentFiles = [...s, ...u]; _updatePreviews(); notifyListeners(); } }
  void moveSelectedToBottom() { final s = _currentFiles.where((f) => f.isSelected).toList(); final u = _currentFiles.where((f) => !f.isSelected).toList(); if (s.isNotEmpty) { _currentFiles = [...u, ...s]; _updatePreviews(); notifyListeners(); } }
  Future<void> goUp() async { if (_currentDirectory != null) { final p = _currentDirectory!.parent; if (p.path != _currentDirectory!.path) await setDirectory(p); } }

  Future<int> executeRename() async {
    final t = _currentFiles.where((f) => f.isSelected).toList(); if (t.isEmpty) return 0; _isLoading = true; notifyListeners(); List<FileModel> renamed = []; List<UndoAction> transaction = [];
    for (var file in t) { if (file.validationErrorMessage != null || file.originalName == file.newName) continue; try { final oldP = file.entity.path; final newP = p.join(file.parentPath, file.newName); await file.entity.rename(newP); file.markRenamed(); renamed.add(file); transaction.add(UndoAction(oldP, newP, type: UndoType.rename)); } catch (e) { file.markError(e.toString()); } }
    if (transaction.isNotEmpty) { _undoManager.addTransaction(transaction); _saveInputHistory(); if (_currentDirectory != null) await setDirectory(_currentDirectory!); if (_saveSequenceNumber) { _startNumber += renamed.length; _saveState(); notifyListeners(); } } else { _isLoading = false; notifyListeners(); }
    return renamed.length;
  }

  Future<void> renameOneFile(FileModel file, String newName) async {
    if (file.originalName == newName || newName.isEmpty) return; _isLoading = true; notifyListeners();
    try { final oldP = file.entity.path; final newP = p.join(file.parentPath, newName); await file.entity.rename(newP); _undoManager.addTransaction([UndoAction(oldP, newP, type: UndoType.rename)]); if (_currentDirectory != null) await setDirectory(_currentDirectory!); } catch (e) { _isLoading = false; notifyListeners(); }
  }

  Future<Map<String, dynamic>> undo() async { if (!_undoManager.canUndo) return {'count': 0, 'errors': []}; _isLoading = true; notifyListeners(); final r = await _undoManager.undoLastTransaction(); if (_currentDirectory != null) await setDirectory(_currentDirectory!); return r; }
  List<UndoAction> getLastUndoTransaction() => _undoManager.peekLastTransaction();

  void addHistory(HistoryType type, String value) {
    if (value.isEmpty) return; List<String> target;
    switch (type) { case HistoryType.find: target = _findHistory; break; case HistoryType.replace: target = _replaceHistory; break; case HistoryType.add: target = _appendHistory; break; case HistoryType.extension: target = _extensionHistory; break; case HistoryType.remove: target = _deleteFromHistory; break; case HistoryType.deleteTo: target = _deleteToHistory; break; }
    target.remove(value); target.insert(0, value); if (target.length > 20) target.removeRange(20, target.length); _saveState(); notifyListeners();
  }

  void _saveInputHistory() {
    switch (_renameMode) { case RenameMode.replace: if (_findText != null) addHistory(HistoryType.find, _findText!); if (_replaceText != null) addHistory(HistoryType.replace, _replaceText!); break; case RenameMode.append: if (_appendText != null) addHistory(HistoryType.add, _appendText!); break; case RenameMode.deleteFrontTo: case RenameMode.deleteBackTo: case RenameMode.deleteFrom: if (_deleteToText != null) addHistory(HistoryType.remove, _deleteToText!); break; case RenameMode.extension: if (_extensionChangeText.isNotEmpty) addHistory(HistoryType.extension, _extensionChangeText); break; case RenameMode.extensionAdd: if (_extensionAddText.isNotEmpty) addHistory(HistoryType.extension, _extensionAddText); break; default: break; }
  }

  int _selectionVersion = 0; int get selectionVersion => _selectionVersion;
  
  Future<void> setDirectory(Directory directory, {bool addToHistory = true, String? source, String? contextRoot}) async {
    _navigationSource = source; _navigationContextRoot = contextRoot;
    _selectionVersion++; await _scanSubscription?.cancel(); _scanSubscription = null;

    if (addToHistory && (_currentDirectory == null || _currentDirectory!.path != directory.path)) {
      if (_navIndex < _navHistory.length - 1) _navHistory = _navHistory.sublist(0, _navIndex + 1);
      _navHistory.remove(directory.path); _navHistory.add(directory.path); if (_navHistory.length > 20) _navHistory.removeAt(0);
      _navIndex = _navHistory.length - 1;
    }
    
    _currentDirectory = directory; _isLoading = true; _allFiles = []; _currentFiles = [];
    _saveState(); await checkClipboard(); notifyListeners();

    try {
      if (!kIsWeb && Platform.isWindows) {
        // 真・究極の高速化: バイト列スキャン & Isolate デコード
        // これが feature/performance-debug ブランチの「魔法」の正体
        final List<int> allBytes = [];
        final process = await Process.start('cmd', ['/c', 'dir', '/b', _recursiveSearch ? '/s' : '', '/a'], workingDirectory: directory.path);
        
        _scanSubscription = process.stdout.listen((bytes) {
          allBytes.addAll(bytes);
          // 読み込み中も「進行中」であることを示すために、少しずつ処理して表示
          if (allBytes.length > 1024 * 50) { // 50KBごとに中間処理
            _processBytesIncremental(allBytes, directory.path);
          }
        }, onDone: () async {
          // 最後に一括で Isolate へ投げる (究極の整合性)
          final results = await compute(RenameEngine.computeScanBytes, {
            'bytes': allBytes,
            'rootPath': directory.path,
            'recursive': _recursiveSearch,
          });
          
          _allFiles = results.map((data) {
            final f = FileModel(entity: File(data['path'])); // Type は表示時に Lazy 判別
            f.setDisplayRelativePath(data['rel']); return f;
          }).toList();

          _applyFilters();
          _isLoading = false;
          _scanSubscription = null;
          notifyListeners();
        });
      } else {
        // Fallback for non-windows
        final results = await compute(RenameEngine.computeScan, {'rootPath': directory.path, 'recursive': _recursiveSearch});
        _allFiles = results.map((data) {
          final f = FileModel(entity: data['isDir'] ? Directory(data['path']) : File(data['path']));
          f.setDisplayRelativePath(data['rel']); return f;
        }).toList();
        _applyFilters(); _isLoading = false; notifyListeners();
      }
    } catch (e) { _allFiles = []; _currentFiles = []; _isLoading = false; notifyListeners(); }
  }

  void _processBytesIncremental(List<int> bytes, String rootPath) {
    // 中間表示用: メインスレッドで軽くデコードしてフィルタを通す
    try {
      final String partial = systemEncoding.decode(bytes);
      final lines = partial.split('\r\n');
      if (lines.length < 2) return;
      
      final List<FileModel> increment = [];
      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i]; if (line.isEmpty) continue;
        final fullPath = _recursiveSearch ? line : p.join(rootPath, line);
        final f = FileModel(entity: File(fullPath));
        if (_shouldShowFile(f)) increment.add(f);
      }
      
      // 重複を避けつつ追加
      final Set<String> existing = _currentFiles.map((f) => f.entity.path).toSet();
      _currentFiles.addAll(increment.where((f) => !existing.contains(f.entity.path)));
      notifyListeners();
    } catch (_) {}
  }

  int _navTreeResetTick = 0; int get navTreeResetTick => _navTreeResetTick;
  void resetNavTree() { _navTreeResetTick++; notifyListeners(); }
  void cancelScan() { _scanSubscription?.cancel(); _scanSubscription = null; _isLoading = false; notifyListeners(); }

  Future<void> _loadAttributes(Directory dir) async {
    try {
      final res = await Process.run('attrib', ['*', '/D'], workingDirectory: dir.path, stdoutEncoding: systemEncoding);
      if (res.exitCode == 0) {
        final lines = (res.stdout as String).split('\n'); final Map<String, String> attrMap = {};
        for (var line in lines) {
          line = line.trim(); if (line.length > 21) { final ap = line.substring(0, 20).toUpperCase(); final pp = line.substring(20).trim(); final fp = p.isAbsolute(pp) ? p.canonicalize(pp) : p.canonicalize(p.join(dir.path, pp)); attrMap[fp] = ap; }
        }
        for (var f in _currentFiles) { final np = p.canonicalize(f.entity.path); if (attrMap.containsKey(np)) { final a = attrMap[np]!; f.setAttributes(readOnly: a.contains('R'), hidden: a.contains('H'), system: a.contains('S'), archive: a.contains('A')); } }
      }
    } catch (e) { if (kDebugMode) print('Attrib Error: $e'); }
  }

  static Future<List<Directory>> getQuickAccessDirectories() async {
    List<Directory> qa = []; if (kIsWeb) return qa; String? home = Platform.isWindows ? Platform.environment['USERPROFILE'] : Platform.environment['HOME'];
    if (home != null) { final hd = Directory(home); if (await hd.exists()) { qa.add(hd); for (var f in ['Desktop', 'Downloads', 'Documents', 'Pictures', 'Music', 'Videos']) { final d = Directory(p.join(home, f)); if (await d.exists()) qa.add(d); } final od = Directory(p.join(home, 'OneDrive')); if (await od.exists()) qa.add(od); } }
    return qa;
  }

  Future<int> deleteSelectedFiles() async {
    final t = _currentFiles.where((f) => f.isSelected).toList(); if (t.isEmpty) return 0; int count = 0; _isLoading = true; notifyListeners();
    for (var f in t) { try { if (!kIsWeb && Platform.isWindows) { final isDir = f.entity is Directory; final ps = f.entity.path.replaceAll("'", "''"); final script = "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::Delete${isDir ? 'Directory' : 'File'}('$ps', 'OnlyErrorDialogs', 'SendToRecycleBin')"; final res = await Process.run('powershell', ['-Command', script]); if (res.exitCode == 0) count++; } else { await f.entity.delete(recursive: true); count++; } } catch (e) { if (kDebugMode) print('Delete error: $e'); } }
    if (count > 0 && _currentDirectory != null) { _treeVersion++; await setDirectory(_currentDirectory!); } else { _isLoading = false; notifyListeners(); }
    return count;
  }

  bool get hasInvalidFilenames => _hasValidationError;
  static Future<List<Directory>> getLogicalDrives() async {
    List<Directory> ds = []; if (kIsWeb) return ds;
    if (Platform.isWindows) { for (var c = 'A'.codeUnitAt(0); c <= 'Z'.codeUnitAt(0); c++) { final d = Directory('${String.fromCharCode(c)}:\\\\'); if (await d.exists()) ds.add(d); } }
    else if (Platform.isAndroid) { final d = Directory('/storage/emulated/0'); if (await d.exists()) ds.add(d); } else ds.add(Directory('/'));
    return ds;
  }

  String get termFolder { switch (_validationType) { case ValidationType.windows: case ValidationType.mac: case ValidationType.ios: return 'フォルダ'; case ValidationType.linux: case ValidationType.android: return 'ディレクトリ'; default: return (Platform.isWindows || Platform.isMacOS || Platform.isIOS) ? 'フォルダ' : 'ディレクトリ'; } }
  void clearInputHistory() { _findHistory.clear(); _replaceHistory.clear(); _appendHistory.clear(); _extensionHistory.clear(); _deleteFromHistory.clear(); _deleteToHistory.clear(); _saveState(); notifyListeners(); }
  Locale get currentLocale { switch (_menuLabelType) { case MenuLabelType.standard: return const Locale('ja'); case MenuLabelType.namery: return const Locale('ja', 'NM'); case MenuLabelType.english: return const Locale('en'); case MenuLabelType.chinese: return const Locale('zh'); case MenuLabelType.spanish: return const Locale('es'); } }

  Future<void> requestAndroidPermissions(BuildContext context) async {
    if (kIsWeb || !Platform.isAndroid) return; var status = await Permission.manageExternalStorage.status; if (status.isGranted) return; if (!context.mounted) return; final l10n = AppLocalizations.of(context)!;
    final bool? proceed = await showDialog<bool>(context: context, barrierDismissible: false, builder: (context) => AlertDialog(title: Row(children: [Icon(Icons.security, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 12), Expanded(child: Text(l10n.labelPermissionFileAccessTitle))]), content: Text(l10n.labelPermissionFileAccessMessage), actions: [FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.labelPermissionFileAccessButton))]));
    if (proceed == true) { status = await Permission.manageExternalStorage.request(); if (!status.isGranted) await openAppSettings(); }
  }
}

enum InitialDirectoryMode { lastUsed, fixed }
