import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
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
import 'package:package_info_plus/package_info_plus.dart';

enum HistoryType { find, replace, add, extension, remove, deleteTo }
enum AppThemeType { system, light, dark, darkGray }
enum MenuLabelType { standard, namery, english, chinese, spanish }

class DirectoryProvider extends ChangeNotifier {
  Directory? _currentDirectory;
  List<FileModel> _currentFiles = [];
  List<FileModel> _allFiles = [];
  bool _isLoading = false;
  bool _isInlineRenaming = false;
  bool _enableBetaFeatures = false;
  int _treeVersion = 0;
  final UndoManager _undoManager = UndoManager();
  final SettingsService _settings = SettingsService();
  StreamSubscription? _scanSubscription;
  Process? _currentProcess; 
  Isolate? _currentIsolate;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey<ScaffoldState> get scaffoldKey => _scaffoldKey;

  // アップデート情報
  bool _hasUpdate = false;
  String? _latestVersion;
  bool get hasUpdate => _hasUpdate;
  String? get latestVersion => _latestVersion;

  void setUpdateInfo(bool hasUpdate, String? version) {
    if (_hasUpdate != hasUpdate || _latestVersion != version) {
      _hasUpdate = hasUpdate;
      _latestVersion = version;
      notifyListeners();
    }
  }

  // GitHub Releases から最新バージョンをチェック
  Future<void> checkForUpdates() async {
    if (kIsWeb) return;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // GitHub API (Releases) から最新タグを取得
      final client = HttpClient();
      client.userAgent = 'ReNamery-App';
      final request = await client.getUrl(Uri.parse('https://api.github.com/repos/toyo-craft/renamery/releases/latest'));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final content = await response.transform(utf8.decoder).join();
        final json = jsonDecode(content);
        final String latestTagName = json['tag_name'] ?? '';
        final latestVer = latestTagName.replaceAll('v', '');

        // バージョン比較
        if (_isNewerVersion(currentVersion, latestVer)) {
          setUpdateInfo(true, latestVer);
        }
      }
      client.close();
    } catch (e) {
      if (kDebugMode) print('Update check failed: $e');
    }
  }

  bool _isNewerVersion(String current, String latest) {
    try {
      final curParts = current.split('.').map(int.parse).toList();
      final latParts = latest.split('.').map(int.parse).toList();
      for (var i = 0; i < 3; i++) {
        final cur = i < curParts.length ? curParts[i] : 0;
        final lat = i < latParts.length ? latParts[i] : 0;
        if (lat > cur) return true;
        if (lat < cur) return false;
      }
    } catch (_) {}
    return false;
  }

  bool _canPaste = false; bool get canPaste => _canPaste;
  bool _isCutMode = false; final Set<String> _cutFilePaths = {}; bool get isCutMode => _isCutMode;
  bool get isInlineRenaming => _isInlineRenaming; bool get enableBetaFeatures => _enableBetaFeatures; int get treeVersion => _treeVersion;

  void setInlineRenaming(bool isRenaming) { if (_isInlineRenaming != isRenaming) { _isInlineRenaming = isRenaming; notifyListeners(); } }

  bool _isLicenseAccepted = false; bool get isLicenseAccepted => _isLicenseAccepted;
  Future<void> acceptLicense() async { 
    _isLicenseAccepted = true; 
    _settings.set('isLicenseAccepted', true); 
    _saveState(); 
    notifyListeners(); 
  }

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
    else _seedColor = Colors.green; // デフォルト値の明示的なセット

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
    else if (_currentDirectory != null) await _applyFilters();
  }

  void _saveState() {
    final s = SettingsService();
    // 多数の設定を一度に保存するため、個別の自動保存を抑制し、最後に一括保存する
    if (_currentDirectory != null) s.set('lastDirectory', _currentDirectory!.path, saveImmediate: false);
    s.set('filterText', _filterText, saveImmediate: false);
    s.set('hideSystemFiles', _hideSystemFiles, saveImmediate: false);
    s.set('recursiveSearch', _recursiveSearch, saveImmediate: false);
    s.set('showPreview', _showPreview, saveImmediate: false);
    s.set('showFolders', _showFolders, saveImmediate: false);
    s.set('saveSequenceNumber', _saveSequenceNumber, saveImmediate: false);
    s.set('isCompactMode', _isCompactMode, saveImmediate: false);
    s.set('touchMode', _touchMode, saveImmediate: false);
    s.set('enableBetaFeatures', _enableBetaFeatures, saveImmediate: false);
    s.set('appTheme', _appTheme.name, saveImmediate: false);
    s.set('menuLabelType', _menuLabelType.name, saveImmediate: false);
    s.set('seedColor', _seedColor.toARGB32(), saveImmediate: false);
    s.set('navHistory', _navHistory, saveImmediate: false);
    s.set('navIndex', _navIndex, saveImmediate: false);
    s.set('renameMode', _renameMode.index, saveImmediate: false);
    s.set('numberingMode', _numberingMode.index, saveImmediate: false);
    s.set('isLicenseAccepted', _isLicenseAccepted, saveImmediate: false); // 明示的に保存対象に追加

    if (_findText != null) s.set('findText', _findText, saveImmediate: false);
    if (_replaceText != null) s.set('replaceText', _replaceText, saveImmediate: false);
    if (_appendText != null) s.set('appendText', _appendText, saveImmediate: false);
    if (_deleteToText != null) s.set('deleteToText', _deleteToText, saveImmediate: false);
    
    s.set('startNumber', _startNumber, saveImmediate: false);
    s.set('digits', _digits, saveImmediate: false);
    s.set('extensionToLowerCase', _extensionToLowerCase, saveImmediate: false);
    s.set('useRegex', _useRegex, saveImmediate: false);
    s.set('sortColumnIndex', _sortColumnIndex, saveImmediate: false);
    s.set('sortAscending', _sortAscending, saveImmediate: false);
    s.set('listRenameText', _listRenameText, saveImmediate: false);
    s.set('extensionChangeText', _extensionChangeText, saveImmediate: false);
    s.set('extensionAddText', _extensionAddText, saveImmediate: false);
    s.set('dateFormat', _dateFormat, saveImmediate: false);
    s.set('datePosition', _datePosition.index, saveImmediate: false);
    s.set('validationType', _validationType.index, saveImmediate: false);
    s.set('initialDirectoryMode', _initialDirectoryMode.index, saveImmediate: false);
    s.set('fixedInitialDirectory', _fixedInitialDirectory, saveImmediate: false);
    s.set('etcTimestamp', _etcTimestamp, saveImmediate: false);
    s.set('etcAttribReadOnly', _etcAttribReadOnly, saveImmediate: false);
    s.set('etcAttribHidden', _etcAttribHidden, saveImmediate: false);
    s.set('etcAttribArchive', _etcAttribArchive, saveImmediate: false);
    s.set('etcAttribSystem', _etcAttribSystem, saveImmediate: false);

    s.saveSettings(); // 最後に一括で書き込み
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

  RenameMode _lastMainMode = RenameMode.numbering; RenameMode _lastSubMode = RenameMode.extension;
  RenameMode _lastEtcMode = RenameMode.changeTimestamp; RenameMode _lastExtraMode = RenameMode.appendDate;
  RenameMode _lastStringMode = RenameMode.append;

  Directory? get currentDirectory => _currentDirectory;
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
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) {
        _canPaste = false;
        notifyListeners();
        return;
      }
      final reader = await clipboard.read();
      _canPaste = reader.canProvide(Formats.fileUri);
    } catch (e) {
      if (kDebugMode) print('Clipboard check failed: $e');
      _canPaste = false;
    }
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

  void setCompactMode(bool isCompact) { _isCompactMode = isCompact; _saveState(); notifyListeners(); }
  void setTouchMode(bool value) { _touchMode = value; _saveState(); notifyListeners(); }
  void setEnableBetaFeatures(bool enable) { _enableBetaFeatures = enable; _saveState(); notifyListeners(); }
  void setAppTheme(AppThemeType theme) { _appTheme = theme; _saveState(); notifyListeners(); }
  void setMenuLabelType(MenuLabelType type) { _menuLabelType = type; _saveState(); notifyListeners(); }
  void setSeedColor(Color color) { _seedColor = color; _saveState(); notifyListeners(); }

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
    else if (needRefilter) { _filterTimer?.cancel(); _filterTimer = Timer(Duration(milliseconds: filter != null ? 300 : 20), () => _applyFilters()); }
    _saveState();
  }

  int _filterVersion = 0;
  Future<void> _applyFilters() async {
    final currentVersion = ++_filterVersion; if (_allFiles.isEmpty) { _currentFiles = []; notifyListeners(); return; }
    final input = {'files': _allFiles.map((f) => {'originalName': f.originalName, 'isDirectory': f.entity is Directory, 'isHidden': f.originalName.startsWith('.')}).toList(), 'filterText': _filterText, 'isFilterRegex': _isFilterRegex, 'hideSystemFiles': _hideSystemFiles, 'showFolders': _showFolders};
    final visibility = await compute(_computeFilter, input); if (currentVersion != _filterVersion) return;
    final List<FileModel> filtered = []; for (int i = 0; i < _allFiles.length; i++) { if (visibility[i]) filtered.add(_allFiles[i]); }
    _currentFiles = filtered; for (var f in _allFiles) f.setCut(_cutFilePaths.contains(f.entity.path), notify: false); for (var f in _allFiles) f.notifyIfChanged();
    sortFiles(_sortColumnIndex, _sortAscending); notifyListeners();
  }

  static List<bool> _computeFilter(Map<String, dynamic> params) {
    final List<dynamic> files = params['files']; final String filterText = params['filterText']; final bool isFilterRegex = params['isFilterRegex']; final bool hideSystemFiles = params['hideSystemFiles']; final bool showFolders = params['showFolders'];
    RegExp? regex; if (filterText.isNotEmpty && isFilterRegex) { try { regex = RegExp(filterText, caseSensitive: false, unicode: true); } catch (_) {} }
    return files.map((f) {
      final String originalName = f['originalName']; final bool isDirectory = f['isDirectory']; final bool isHidden = f['isHidden'];
      if (hideSystemFiles && isHidden) return false; if (!showFolders && isDirectory) return false;
      if (filterText.isNotEmpty) { if (isFilterRegex) { if (regex == null) return true; return regex.hasMatch(originalName); } else return originalName.toLowerCase().contains(filterText.toLowerCase()); }
      return true;
    }).toList();
  }

  bool _shouldShowFile(FileModel file) {
    if (_hideSystemFiles && p.basename(file.originalName).startsWith('.')) return false;
    if (!_showFolders && file.entity is Directory) return false;
    if (_filterText.isNotEmpty) {
      if (_isFilterRegex) { try { return RegExp(_filterText, caseSensitive: false, unicode: true).hasMatch(file.originalName); } catch (_) { return true; } }
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
  bool _isProcessingPreview = false;
  bool _needsRetryPreview = false;

  int _visibleStartIndex = 0;
  int _visibleEndIndex = 100; 

  void updateVisibleRange(int start, int end) {
    if (_visibleStartIndex != start || _visibleEndIndex != end) {
      _visibleStartIndex = start;
      _visibleEndIndex = end;
      _updatePreviewsDebounced();
    }
  }

  Future<void> _updatePreviews() async {
    if (_currentFiles.isEmpty) return;
    if (_isProcessingPreview) { _needsRetryPreview = true; return; }
    _isProcessingPreview = true; _needsRetryPreview = false;
    try {
      final currentVersion = ++_previewVersion;
      final buffer = 20;
      final start = (_visibleStartIndex - buffer).clamp(0, _currentFiles.length);
      final end = (_visibleEndIndex + buffer).clamp(0, _currentFiles.length);
      List<FileModel> targets = [];
      for (int i = 0; i < _currentFiles.length; i++) {
        final f = _currentFiles[i];
        if (i >= start && i < end) { if (f.isSelected) targets.add(f); }
        else { f.setNewName(f.originalName, notify: false); f.setValidationError(null, notify: false); }
      }
      if (targets.isEmpty) { for (var f in _currentFiles) f.notifyIfChanged(); notifyListeners(); return; }
      String? curFind = (_renameMode == RenameMode.deleteFrontTo || _renameMode == RenameMode.deleteBackTo) ? _deleteToText : _findText;
      String? curReplace = (_renameMode == RenameMode.extension) ? _extensionChangeText : (_renameMode == RenameMode.extensionAdd ? _extensionAddText : _replaceText);
      String? baseDir = _currentDirectory != null ? p.basename(_currentDirectory!.path) : null;
      final input = {'mode': _renameMode, 'fileData': targets.map((f) => {'originalName': f.originalName, 'isDirectory': f.entity is Directory, 'modified': f.entity.statSync().modified}).toList(), 'findText': curFind, 'replaceText': curReplace, 'appendText': _appendText, 'startNumber': _startNumber, 'insertIndex': _insertIndex, 'digits': _digits, 'caseConversion': CaseConversion.none, 'extensionToLowerCase': _extensionToLowerCase, 'useRegex': _useRegex, 'numberingMode': _numberingMode, 'baseDirName': baseDir, 'listText': _listRenameText, 'dateFormat': _dateFormat, 'datePosition': _datePosition, 'validationType': _validationType, 'isWindows': !kIsWeb && Platform.isWindows, 'isMacOS': !kIsWeb && Platform.isMacOS};
      final results = await compute(RenameEngine.computeGeneratePreviews, input);
      if (currentVersion != _previewVersion) return;
      for (int i = 0; i < targets.length; i++) { final f = targets[i]; final res = results[i]; f.setNewName(res['newName']!, notify: false); f.setValidationError(res['error'], notify: false); }
      _hasValidationError = false; final nameCounts = <String, int>{};
      for (var f in _currentFiles) { if (f.validationErrorMessage != null && f.validationErrorMessage != 'ファイル名が重複しています') _hasValidationError = true; final fullPathKey = p.join(f.parentPath, f.newName).toLowerCase(); nameCounts[fullPathKey] = (nameCounts[fullPathKey] ?? 0) + 1; }
      for (var f in targets) { if (f.validationErrorMessage == null || f.validationErrorMessage == 'ファイル名が重複しています') { final fullPathKey = p.join(f.parentPath, f.newName).toLowerCase(); if ((nameCounts[fullPathKey] ?? 0) > 1) { f.setValidationError('ファイル名が重複しています', notify: false); _hasValidationError = true; } else f.setValidationError(null, notify: false); } }
      for (var f in _currentFiles) f.notifyIfChanged(); notifyListeners();
    } finally { _isProcessingPreview = false; if (_needsRetryPreview) { _needsRetryPreview = false; _updatePreviews(); } }
  }

  bool _hasValidationError = false; bool get hasValidationError => _hasValidationError;
  int _sortColumnIndex = 0; bool _sortAscending = true; int get sortColumnIndex => _sortColumnIndex; bool get sortAscending => _sortAscending;
  void toggleSelection(FileModel file) { file.isSelected = !file.isSelected; _updatePreviewsDebounced(); }
  void _updatePreviewsDebounced({bool immediate = false}) { _previewTimer?.cancel(); if (immediate) _updatePreviews(); else _previewTimer = Timer(const Duration(milliseconds: 50), () => _updatePreviews()); }

  void selectAll(bool select) { for (var f in _currentFiles) f.setSelected(select, notify: false); for (var f in _currentFiles) f.notifyIfChanged(); _updatePreviews(); notifyListeners(); }
  void selectRange(int start, int end, {bool exclusive = true, List<bool>? baseStates}) {
    final minIdx = start < end ? start : end; final maxIdx = start > end ? start : end;
    for (int i = 0; i < _currentFiles.length; i++) {
      final isInside = i >= minIdx && i <= maxIdx;
      if (baseStates != null && i < baseStates.length) _currentFiles[i].setSelected(isInside ? !baseStates[i] : baseStates[i], notify: false);
      else { if (isInside) _currentFiles[i].setSelected(true, notify: false); else if (exclusive) _currentFiles[i].setSelected(false, notify: false); }
    }
    for (var f in _currentFiles) f.notifyIfChanged(); _updatePreviews(); notifyListeners(); }

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

  int _selectionVersion = 0; int get selectionVersion => _selectionVersion;
  Future<void> setDirectory(Directory directory, {bool addToHistory = true, String? source, String? contextRoot}) async {
    _navigationSource = source; _navigationContextRoot = contextRoot;
    _selectionVersion++; await cancelScan();
    if (addToHistory && (_currentDirectory == null || _currentDirectory!.path != directory.path)) {
      if (_navIndex < _navHistory.length - 1) _navHistory = _navHistory.sublist(0, _navIndex + 1);
      _navHistory.remove(directory.path); _navHistory.add(directory.path); if (_navHistory.length > 20) _navHistory.removeAt(0);
      _navIndex = _navHistory.length - 1;
    }
    _currentDirectory = directory; _isLoading = true; _allFiles = []; _currentFiles = [];
    _saveState(); await checkClipboard(); notifyListeners();

    try {
      if (!kIsWeb && Platform.isWindows) {
        _currentProcess = await Process.start('cmd', ['/c', 'dir', '/b', _recursiveSearch ? '/s' : '', '/a'], workingDirectory: directory.path);
        final List<int> leftover = []; int count = 0; bool shouldStop = false;
        DateTime lastReportTime = DateTime.now(); DateTime lastDataTime = DateTime.now();

        _scanSubscription = _currentProcess!.stdout.listen((bytes) async {
          if (shouldStop) return; lastDataTime = DateTime.now(); leftover.addAll(bytes);
          final String output = systemEncoding.decode(leftover); final lines = output.split('\r\n');
          if (lines.length < 2) return; leftover.clear(); leftover.addAll(systemEncoding.encode(lines.removeLast()));
          final List<FileModel> increment = [];
          for (var line in lines) {
            if (line.isEmpty) continue;
            final fullPath = _recursiveSearch ? line : p.join(directory.path, line);
            final bool isDir = FileSystemEntity.isDirectorySync(fullPath);
            final f = FileModel(entity: isDir ? Directory(fullPath) : File(fullPath));
            increment.add(f); count++;

            final now = DateTime.now();
            final duration = now.difference(lastReportTime);
            final bool countTrigger = (count % 2500 == 0) && duration.inSeconds >= 3;
            final bool timeTrigger = duration.inSeconds >= 5;
            final bool stallTrigger = now.difference(lastDataTime).inSeconds >= 2;

            if (countTrigger || timeTrigger || stallTrigger) {
              _scanSubscription?.pause();
              final result = await _showLimitDialog(count, reason: countTrigger ? 'count' : (timeTrigger ? 'time' : 'stall'));
              if (result == 'stop') { shouldStop = true; _currentProcess?.kill(); break; }
              else if (result == 'cancel') { await cancelScan(); return; }
              lastReportTime = DateTime.now(); lastDataTime = DateTime.now();
              _scanSubscription?.resume();
            }
          }
          _allFiles.addAll(increment); _applyFiltersSync(); notifyListeners();
        }, onDone: () async { _isLoading = false; _currentProcess = null; _scanSubscription = null; await _applyFilters(); notifyListeners(); });
      } else {
        final receivePort = ReceivePort();
        final Map<String, dynamic> params = {'sendPort': receivePort.sendPort, 'rootPath': directory.path, 'recursive': _recursiveSearch};
        Timer? updateTimer = Timer.periodic(const Duration(milliseconds: 200), (_) => notifyListeners());
        Isolate.spawn(RenameEngine.computeScanStream, params).then((isolate) { _currentIsolate = isolate; });
        int count = 0; DateTime lastReportTime = DateTime.now(); DateTime lastDataTime = DateTime.now();
        Timer? stallTimer;
        stallTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
          if (!_isLoading) { t.cancel(); return; }
          final now = DateTime.now();
          if (now.difference(lastDataTime).inSeconds >= 2) {
            t.cancel();
            final result = await _showLimitDialog(count, reason: 'stall');
            if (result == 'stop') { _currentIsolate?.kill(); receivePort.close(); }
            else if (result == 'cancel') { await cancelScan(); receivePort.close(); }
            else { lastDataTime = DateTime.now(); if (_isLoading) stallTimer = Timer.periodic(const Duration(seconds: 1), (t2) { if (!_isLoading) t2.cancel(); }); }
          }
        });

        await for (final msg in receivePort) {
          lastDataTime = DateTime.now();
          if (msg == 'done' || msg is String && msg.startsWith('error')) { receivePort.close(); break; }
          final data = msg as Map<String, dynamic>;
          final f = FileModel(entity: data['isDir'] ? Directory(data['path']) : File(data['path']));
          f.setDisplayRelativePath(data['rel']); _allFiles.add(f); if (_shouldShowFile(f)) _currentFiles.add(f); count++;
          final now = DateTime.now();
          if (count % 2500 == 0 || now.difference(lastReportTime).inSeconds >= 5) {
            updateTimer?.cancel(); notifyListeners();
            final result = await _showLimitDialog(count, reason: count % 2500 == 0 ? 'count' : 'time');
            if (result == 'stop') { _currentIsolate?.kill(); receivePort.close(); break; }
            else if (result == 'cancel') { await cancelScan(); receivePort.close(); return; }
            lastReportTime = DateTime.now();
            updateTimer = Timer.periodic(const Duration(milliseconds: 200), (_) => notifyListeners());
          }
        }
        stallTimer?.cancel(); updateTimer?.cancel(); _isLoading = false; _currentIsolate = null; notifyListeners();
      }
    } catch (e) { _isLoading = false; _currentProcess = null; notifyListeners(); }
  }

  void _applyFiltersSync() {
    _currentFiles = _allFiles.where((f) => _shouldShowFile(f)).toList();
    // 現在のソート設定（デフォルトは名前順・フォルダ優先）を適用
    _currentFiles.sort((a, b) {
      final isDirA = a.entity is Directory;
      final isDirB = b.entity is Directory;
      if (isDirA && !isDirB) return -1;
      if (!isDirA && isDirB) return 1;
      
      int cmp = 0;
      switch (_sortColumnIndex) {
        case 0: cmp = a.originalName.toLowerCase().compareTo(b.originalName.toLowerCase()); break;
        case 1: cmp = a.newName.toLowerCase().compareTo(b.newName.toLowerCase()); break;
        case 2:
          if (a.entity is File && b.entity is File) {
            int sA = 0; int sB = 0;
            try { sA = (a.entity as File).lengthSync(); } catch (_) {}
            try { sB = (b.entity as File).lengthSync(); } catch (_) {}
            cmp = sA.compareTo(sB);
          }
          break;
        case 3: cmp = a.relativePath.compareTo(b.relativePath); break;
        case 4: cmp = a.fileType.compareTo(b.fileType); break;
        case 5: try { cmp = a.entity.statSync().modified.compareTo(b.entity.statSync().modified); } catch (e) { cmp = 0; } break;
        case 6: cmp = a.attributes.compareTo(b.attributes); break;
      }
      return _sortAscending ? cmp : -cmp;
    });
  }

  Future<String> _showLimitDialog(int currentCount, {String reason = 'count'}) async {
    final Completer<String> completer = Completer();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = _scaffoldKey.currentContext;
      if (context == null) { completer.complete('continue'); return; }
      String message = '$currentCount 件のファイルが見つかりました。\nスキャンを続行しますか？';
      if (reason == 'time') message = 'スキャン開始から5秒が経過しました（現在 $currentCount 件）。\nこのまま続行しますか？';
      if (reason == 'stall') message = '応答が一時的に途絶えています。スキャンを続行しますか？';
      final result = await showDialog<String>(context: context, barrierDismissible: false, builder: (context) => AlertDialog(title: const Text('スキャンの確認'), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(context, 'cancel'), child: const Text('中止 (クリア)')), TextButton(onPressed: () => Navigator.pop(context, 'stop'), child: const Text('ここで止めて表示')), FilledButton(onPressed: () => Navigator.pop(context, 'continue'), child: const Text('続行する'))]));
      completer.complete(result ?? 'continue');
    });
    return completer.future;
  }

  int _navTreeResetTick = 0; int get navTreeResetTick => _navTreeResetTick;
  void resetNavTree() { _navTreeResetTick++; notifyListeners(); }
  Future<void> cancelScan() async { await _scanSubscription?.cancel(); _scanSubscription = null; _currentProcess?.kill(); _currentProcess = null; _currentIsolate?.kill(); _currentIsolate = null; _isLoading = false; notifyListeners(); }

  Future<void> _loadAttributes(Directory dir) async {
    try {
      final res = await Process.run('attrib', ['*', '/D'], workingDirectory: dir.path, stdoutEncoding: systemEncoding);
      if (res.exitCode == 0) {
        final lines = (res.stdout as String).split('\n'); final Map<String, String> attrMap = {};
        for (var line in lines) { line = line.trim(); if (line.length > 21) { final ap = line.substring(0, 20).toUpperCase(); final pp = line.substring(20).trim(); final fp = p.isAbsolute(pp) ? p.canonicalize(pp) : p.canonicalize(p.join(dir.path, pp)); attrMap[fp] = ap; } }
        for (var f in _currentFiles) { final np = p.canonicalize(f.entity.path); if (attrMap.containsKey(np)) { final a = attrMap[np]!; f.setAttributes(readOnly: a.contains('R'), hidden: a.contains('H'), system: a.contains('S'), archive: a.contains('A')); } }
      }
    } catch (_) {}
  }

  Future<int> executeRename() async {
    final t = _currentFiles.where((f) => f.isSelected).toList(); if (t.isEmpty) return 0; _isLoading = true; notifyListeners(); List<FileModel> renamed = []; List<UndoAction> transaction = [];
    for (var file in t) { if (file.validationErrorMessage != null || file.originalName == file.newName) continue; try { final oldP = file.entity.path; final newP = p.join(file.parentPath, file.newName); await file.entity.rename(newP); file.markRenamed(); renamed.add(file); transaction.add(UndoAction(oldP, newP, type: UndoType.rename)); } catch (e) { file.markError(e.toString()); } }
    if (transaction.isNotEmpty) { _undoManager.addTransaction(transaction); if (_currentDirectory != null) await setDirectory(_currentDirectory!); if (_saveSequenceNumber) { _startNumber += renamed.length; _saveState(); notifyListeners(); } } else { _isLoading = false; notifyListeners(); }
    return renamed.length;
  }

  Future<void> renameOneFile(FileModel file, String newName) async { if (file.originalName == newName || newName.isEmpty) return; _isLoading = true; notifyListeners(); try { final oldP = file.entity.path; final newP = p.join(file.parentPath, newName); await file.entity.rename(newP); _undoManager.addTransaction([UndoAction(oldP, newP, type: UndoType.rename)]); if (_currentDirectory != null) await setDirectory(_currentDirectory!); } catch (_) { _isLoading = false; notifyListeners(); } }
  Future<Map<String, dynamic>> undo() async { if (!_undoManager.canUndo) return {'count': 0, 'errors': []}; _isLoading = true; notifyListeners(); final r = await _undoManager.undoLastTransaction(); if (_currentDirectory != null) await setDirectory(_currentDirectory!); return r; }
  Future<int> deleteSelectedFiles() async {
    final t = _currentFiles.where((f) => f.isSelected).toList(); if (t.isEmpty) return 0; int count = 0; _isLoading = true; notifyListeners();
    for (var f in t) { try { if (!kIsWeb && Platform.isWindows) { final isDir = f.entity is Directory; final ps = f.entity.path.replaceAll("'", "''"); final script = "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::Delete${isDir ? 'Directory' : 'File'}('$ps', 'OnlyErrorDialogs', 'SendToRecycleBin')"; final res = await Process.run('powershell', ['-Command', script]); if (res.exitCode == 0) count++; } else { await f.entity.delete(recursive: true); count++; } } catch (_) {} }
    if (count > 0 && _currentDirectory != null) await setDirectory(_currentDirectory!); else { _isLoading = false; notifyListeners(); }
    return count;
  }

  void clearInputHistory() { _findHistory.clear(); _replaceHistory.clear(); _appendHistory.clear(); _extensionHistory.clear(); _deleteFromHistory.clear(); _deleteToHistory.clear(); _saveState(); notifyListeners(); }
  Locale get currentLocale { switch (_menuLabelType) { case MenuLabelType.namery: return const Locale('ja', 'NM'); case MenuLabelType.english: return const Locale('en'); case MenuLabelType.chinese: return const Locale('zh'); case MenuLabelType.spanish: return const Locale('es'); default: return const Locale('ja'); } }

  static Future<List<Directory>> getQuickAccessDirectories() async {
    List<Directory> qa = []; if (kIsWeb) return qa;
    if (Platform.isAndroid) { const root = '/storage/emulated/0'; final folders = ['Download', 'DCIM', 'Pictures', 'Movies', 'Music', 'Documents']; for (var f in folders) { final d = Directory(p.join(root, f)); if (await d.exists()) qa.add(d); } return qa; }
    String? home = Platform.isWindows ? Platform.environment['USERPROFILE'] : Platform.environment['HOME'];
    if (home != null) { final hd = Directory(home); if (await hd.exists()) { qa.add(hd); for (var f in ['Desktop', 'Downloads', 'Documents', 'Pictures', 'Music', 'Videos']) { final d = Directory(p.join(home, f)); if (await d.exists()) qa.add(d); } final od = Directory(p.join(home, 'OneDrive')); if (await od.exists()) qa.add(od); } }
    return qa;
  }

  static Future<List<Directory>> getLogicalDrives() async {
    List<Directory> ds = []; if (kIsWeb) return ds;
    if (Platform.isWindows) { for (var c = 'A'.codeUnitAt(0); c <= 'Z'.codeUnitAt(0); c++) { final d = Directory('${String.fromCharCode(c)}:\\'); if (await d.exists()) ds.add(d); } }
    else if (Platform.isAndroid) { final d = Directory('/storage/emulated/0'); if (await d.exists()) ds.add(d); } else ds.add(Directory('/'));
    return ds;
  }

  Future<void> requestAndroidPermissions(BuildContext context) async {
    if (kIsWeb || !Platform.isAndroid) return; var status = await Permission.manageExternalStorage.status; if (status.isGranted) return; if (!context.mounted) return; final l10n = AppLocalizations.of(context)!;
    final bool? proceed = await showDialog<bool>(context: context, barrierDismissible: false, builder: (context) => AlertDialog(title: Row(children: [Icon(Icons.security, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 12), Expanded(child: Text(l10n.labelPermissionFileAccessTitle))]), content: Text(l10n.labelPermissionFileAccessMessage), actions: [FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.labelPermissionFileAccessButton))]));
    if (proceed == true) { status = await Permission.manageExternalStorage.request(); if (!status.isGranted) await openAppSettings(); }
  }

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
  void resetSettings() {
    _appTheme = AppThemeType.light; _menuLabelType = MenuLabelType.standard; _seedColor = Colors.green; _isCompactMode = false; _initialDirectoryMode = InitialDirectoryMode.lastUsed; _fixedInitialDirectory = ''; _renameMode = RenameMode.numbering; _numberingMode = NumberingMode.stringNumber; _startNumber = 1; _insertIndex = 1; _digits = 3; _findText = ''; _replaceText = ''; _appendText = ''; _deleteToText = ''; _extensionToLowerCase = true; _useRegex = false; _saveSequenceNumber = false; _dateFormat = 'yyyyMMdd_'; _datePosition = DatePosition.front;
    final now = DateTime.now(); _etcTimestamp = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'; _etcAttribReadOnly = false; _etcAttribHidden = false; _etcAttribArchive = false; _etcAttribSystem = false; _showFolders = true; _hideSystemFiles = true; _recursiveSearch = false; _showPreview = true; _validationType = ValidationType.auto; _resetCount++; _applyFilters(); _saveState(); notifyListeners();
  }

  void addHistory(HistoryType type, String value) { if (value.isEmpty) return; List<String> target; switch (type) { case HistoryType.find: target = _findHistory; break; case HistoryType.replace: target = _replaceHistory; break; case HistoryType.add: target = _appendHistory; break; case HistoryType.extension: target = _extensionHistory; break; case HistoryType.remove: target = _deleteFromHistory; break; case HistoryType.deleteTo: target = _deleteToHistory; break; } target.remove(value); target.insert(0, value); if (target.length > 20) target.removeRange(20, target.length); _saveState(); notifyListeners(); }
  List<UndoAction> getLastUndoTransaction() => _undoManager.peekLastTransaction();
}

enum InitialDirectoryMode { lastUsed, fixed }
