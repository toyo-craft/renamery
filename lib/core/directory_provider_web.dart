import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:renamery/l10n/generated/app_localizations.dart';

import 'file_model_web.dart';
import 'rename_options.dart';
import 'settings_service.dart';
import 'web_file_system_service.dart';
import 'web_locale_service.dart';

enum HistoryType { find, replace, add, extension, remove, deleteTo }

enum AppThemeType { system, light, dark, darkGray }

enum MenuLabelType { standard, namery, english, chinese, spanish }

enum InitialDirectoryMode { lastUsed, fixed }

MenuLabelType? _menuLabelTypeForLocale(Locale? locale) {
  switch (locale?.languageCode.toLowerCase()) {
    case 'ja':
      return MenuLabelType.standard;
    case 'en':
      return MenuLabelType.english;
    case 'zh':
      return MenuLabelType.chinese;
    case 'es':
      return MenuLabelType.spanish;
    default:
      return null;
  }
}

MenuLabelType _defaultMenuLabelTypeForLocales(List<Locale> locales) {
  for (final locale in locales) {
    final type = _menuLabelTypeForLocale(locale);
    if (type != null) return type;
  }
  return MenuLabelType.english;
}

MenuLabelType? _pageMenuLabelType() {
  final tag = _readPageInitialLocale();
  if (tag == null || tag.isEmpty || tag.toLowerCase() == 'auto') return null;
  return _menuLabelTypeForLocale(_localeFromTag(tag));
}

String? _readPageInitialLocale() {
  return readPageInitialLocale();
}

List<Locale> _readPreferredLocales() {
  final locales = readPreferredLocaleTags()
      .map(_localeFromTag)
      .whereType<Locale>()
      .toList(growable: false);
  if (locales.isNotEmpty) return locales;
  final platformLocales = WidgetsBinding.instance.platformDispatcher.locales;
  if (platformLocales.isNotEmpty) return platformLocales;
  return [WidgetsBinding.instance.platformDispatcher.locale];
}

Locale? _localeFromTag(String tag) {
  final parts = tag.trim().replaceAll('_', '-').split('-');
  if (parts.isEmpty || parts.first.isEmpty) return null;
  final languageCode = parts.first.toLowerCase();
  String? scriptCode;
  String? countryCode;
  for (final part in parts.skip(1)) {
    if (part.length == 4 && scriptCode == null) {
      scriptCode = part[0].toUpperCase() + part.substring(1).toLowerCase();
    } else if ((part.length == 2 || part.length == 3) && countryCode == null) {
      countryCode = part.toUpperCase();
    }
  }
  return Locale.fromSubtags(
    languageCode: languageCode,
    scriptCode: scriptCode,
    countryCode: countryCode,
  );
}

class WebDirectory {
  WebDirectory({
    required this.name,
    required this.path,
    required this.relativePath,
    required this.handle,
  });

  final String name;
  final String path;
  final String relativePath;
  final Object? handle;

  WebDirectory? get parent {
    if (path.isEmpty) return null;
    final parentPath = p.posix.dirname(path);
    if (parentPath == path || parentPath == '.') return null;
    return WebDirectory(
      name: p.posix.basename(parentPath),
      path: parentPath,
      relativePath: p.posix.dirname(relativePath) == '.'
          ? ''
          : p.posix.dirname(relativePath),
      handle: null,
    );
  }
}

class WebUndoAction {
  WebUndoAction(this.oldPath, this.newPath, {this.parentHandle});

  final String oldPath;
  final String newPath;
  final Object? parentHandle;
}

class DirectoryProvider extends ChangeNotifier {
  DirectoryProvider({
    WebFileSystemClient? fileSystem,
    SettingsService? settings,
  })  : _fs = fileSystem ?? WebFileSystemService(),
        _settings = settings ?? SettingsService();

  final WebFileSystemClient _fs;
  final SettingsService _settings;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey<ScaffoldState> get scaffoldKey => _scaffoldKey;

  AppLocalizations? get _l10n {
    final context = _scaffoldKey.currentContext;
    return context == null ? null : AppLocalizations.of(context);
  }

  String _localized(
      String Function(AppLocalizations l10n) text, String fallback) {
    final l10n = _l10n;
    return l10n == null ? fallback : text(l10n);
  }

  WebDirectory? _currentDirectory;
  List<FileModel> _currentFiles = [];
  List<FileModel> _allFiles = [];
  List<FileModel> _directoryEntries = [];
  List<WebSavedDirectory> _savedDirectories = [];
  final List<WebDirectory> _breadcrumbs = [];
  bool _isLoading = false;
  bool _isInlineRenaming = false;
  bool _isCutMode = false;
  bool _canPaste = false;
  bool _enableBetaFeatures = false;
  bool _isLicenseAccepted = false;
  bool _hasUpdate = false;
  String? _latestVersion;
  String? _errorMessage;

  RenameMode _renameMode = RenameMode.numbering;
  NumberingMode _numberingMode = NumberingMode.stringNumber;
  ValidationType _validationType = ValidationType.auto;
  InitialDirectoryMode _initialDirectoryMode = InitialDirectoryMode.lastUsed;
  String _fixedInitialDirectory = '';
  String? _findText;
  String? _replaceText;
  String? _appendText;
  String? _deleteToText;
  int _startNumber = 1;
  int _insertIndex = 1;
  int _digits = 3;
  bool _extensionToLowerCase = true;
  bool _useRegex = false;
  bool _saveSequenceNumber = false;
  String _listRenameText =
      '01_chapter_intro.mp4\n02_chapter_main.mp4\n03_chapter_end.mp4';
  String _extensionChangeText = '';
  String _extensionAddText = '';
  String _dateFormat = 'yyyyMMdd_';
  DatePosition _datePosition = DatePosition.front;
  String _etcTimestamp = '';
  bool _etcAttribReadOnly = false;
  bool _etcAttribHidden = false;
  bool _etcAttribArchive = false;
  bool _etcAttribSystem = false;

  RenameMode _lastMainMode = RenameMode.numbering;
  RenameMode _lastSubMode = RenameMode.extension;
  RenameMode _lastEtcMode = RenameMode.changeTimestamp;
  RenameMode _lastExtraMode = RenameMode.appendDate;
  RenameMode _lastStringMode = RenameMode.append;

  String _filterText = '';
  bool _isFilterSpecific = false;
  bool _hideSystemFiles = false;
  bool _isFilterRegex = false;
  bool _recursiveSearch = false;
  bool _showPreview = true;
  bool _showFolders = true;
  bool _isCompactMode = true;
  bool _touchMode = false;
  AppThemeType _appTheme = AppThemeType.light;
  MenuLabelType _menuLabelType = MenuLabelType.standard;
  Color _seedColor = Colors.green;

  int _resetCount = 0;
  int _selectionVersion = 0;
  int _navTreeResetTick = 0;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  String? _navigationSource;
  String? _navigationContextRoot;
  final List<String> _navHistory = [];
  int _navIndex = -1;
  final List<WebUndoAction> _lastUndoTransaction = [];

  bool _isEnlargedPreviewOpen = false;
  int _enlargedPreviewIndex = -1;
  double _textPreviewFontSize = 13.0;

  List<String> _appendHistory = [];
  List<String> _deleteFromHistory = [];
  List<String> _deleteToHistory = [];
  List<String> _findHistory = [];
  List<String> _replaceHistory = [];
  List<String> _extensionHistory = [];

  WebDirectory? get currentDirectory => _currentDirectory;
  List<FileModel> get currentFiles => _currentFiles;
  List<FileModel> get directoryEntries => _directoryEntries;
  int get allFilesCount => _allFiles.length;
  bool get isLoading => _isLoading;
  bool get isInlineRenaming => _isInlineRenaming;
  bool get isCutMode => _isCutMode;
  bool get canPaste => _canPaste;
  bool get enableBetaFeatures => _enableBetaFeatures;
  bool get isLicenseAccepted => _isLicenseAccepted;
  bool get hasUpdate => _hasUpdate;
  String? get latestVersion => _latestVersion;
  String? get errorMessage => _errorMessage;
  bool get isWebFileSystemSupported => _fs.isSupported;
  bool get supportsDirectPathInput => false;
  bool get supportsExternalFolderDrop => _fs.isSupported;
  bool get hasUsableDirectory => _currentDirectory?.handle != null;
  List<WebSavedDirectory> get savedDirectories => _savedDirectories;
  List<WebDirectory> get breadcrumbs => List.unmodifiable(_breadcrumbs);
  List<String> get breadcrumbLabels =>
      _breadcrumbs.map((breadcrumb) => breadcrumb.name).toList(growable: false);

  int get resetCount => _resetCount;
  int get selectionVersion => _selectionVersion;
  int get navTreeResetTick => _navTreeResetTick;
  int get treeVersion => 0;
  String? get navigationSource => _navigationSource;
  String? get navigationContextRoot => _navigationContextRoot;

  bool get canUndo => _lastUndoTransaction.isNotEmpty;
  int get undoCount => _lastUndoTransaction.isEmpty ? 0 : 1;
  bool get canGoBack => _navIndex > 0;
  bool get canGoForward => _navIndex < _navHistory.length - 1;
  List<String> get backHistory =>
      _navIndex <= 0 ? [] : _navHistory.sublist(0, _navIndex).reversed.toList();
  List<String> get forwardHistory => _navIndex >= _navHistory.length - 1
      ? []
      : _navHistory.sublist(_navIndex + 1);

  RenameMode get renameMode => _renameMode;
  NumberingMode get numberingMode => _numberingMode;
  ValidationType get validationType => _validationType;
  InitialDirectoryMode get initialDirectoryMode => _initialDirectoryMode;
  String get fixedInitialDirectory => _fixedInitialDirectory;
  String? get findText => _findText;
  String? get replaceText => _replaceText;
  String? get appendText => _appendText;
  String? get deleteToText => _deleteToText;
  int get startNumber => _startNumber;
  int get insertIndex => _insertIndex;
  int get digits => _digits;
  bool get extensionToLowerCase => _extensionToLowerCase;
  bool get useRegex => _useRegex;
  bool get saveSequenceNumber => _saveSequenceNumber;
  String get listRenameText => _listRenameText;
  String get extensionChangeText => _extensionChangeText;
  String get extensionAddText => _extensionAddText;
  String get dateFormat => _dateFormat;
  DatePosition get datePosition => _datePosition;
  String get etcTimestamp => _etcTimestamp;
  bool get etcAttribReadOnly => _etcAttribReadOnly;
  bool get etcAttribHidden => _etcAttribHidden;
  bool get etcAttribArchive => _etcAttribArchive;
  bool get etcAttribSystem => _etcAttribSystem;

  RenameMode get lastMainMode => _lastMainMode;
  RenameMode get lastSubMode => _lastSubMode;
  RenameMode get lastEtcMode => _lastEtcMode;
  RenameMode get lastExtraMode => _lastExtraMode;
  RenameMode get lastStringMode => _lastStringMode;

  String get filterText => _filterText;
  bool get hideSystemFiles => _hideSystemFiles;
  bool get recursiveSearch => _recursiveSearch;
  bool get showPreview => _showPreview;
  bool get showFolders => _showFolders;
  bool get isCompactMode => _isCompactMode;
  bool get touchMode => _touchMode;
  bool get isFilterSpecific => _isFilterSpecific;
  bool get isFilterRegex => _isFilterRegex;
  AppThemeType get appTheme => _appTheme;
  MenuLabelType get menuLabelType => _menuLabelType;
  Color get seedColor => _seedColor;
  int get sortColumnIndex => _sortColumnIndex;
  bool get sortAscending => _sortAscending;
  bool get hasValidationError => _currentFiles.any((f) => f.hasValidationError);
  bool get hasInvalidFilenamesSelected => _currentFiles.any(
        (f) => f.isSelected && f.validationErrorMessage != null,
      );
  int get validFileCount => _currentFiles
      .where((f) => f.isSelected && f.validationErrorMessage == null)
      .length;
  int get invalidFileCount => _currentFiles
      .where((f) => f.isSelected && f.validationErrorMessage != null)
      .length;
  int get selectedFilesCount => _currentFiles.where((f) => f.isSelected).length;
  double get textPreviewFontSize => _textPreviewFontSize;

  bool get isEnlargedPreviewOpen => _isEnlargedPreviewOpen;
  int get enlargedPreviewIndex => _enlargedPreviewIndex;
  FileModel? get enlargedPreviewFile => (_enlargedPreviewIndex >= 0 &&
          _enlargedPreviewIndex < _currentFiles.length)
      ? _currentFiles[_enlargedPreviewIndex]
      : null;
  int get enlargedPreviewSelectedListIndex {
    final file = enlargedPreviewFile;
    if (file == null) return -1;
    return _currentFiles.where((f) => f.isSelected).toList().indexOf(file);
  }

  List<String> get appendHistory => _appendHistory;
  List<String> get deleteFromHistory => _deleteFromHistory;
  List<String> get deleteToHistory => _deleteToHistory;
  List<String> get findHistory => _findHistory;
  List<String> get replaceHistory => _replaceHistory;
  List<String> get extensionHistory => _extensionHistory;

  ThemeMode get themeMode {
    switch (_appTheme) {
      case AppThemeType.system:
        return ThemeMode.system;
      case AppThemeType.dark:
      case AppThemeType.darkGray:
        return ThemeMode.dark;
      case AppThemeType.light:
        return ThemeMode.light;
    }
  }

  Locale get currentLocale {
    switch (_menuLabelType) {
      case MenuLabelType.namery:
        return const Locale('ja', 'NM');
      case MenuLabelType.english:
        return const Locale('en');
      case MenuLabelType.chinese:
        return const Locale('zh');
      case MenuLabelType.spanish:
        return const Locale('es');
      case MenuLabelType.standard:
        return const Locale('ja');
    }
  }

  bool get canExecute {
    final selected = _currentFiles.where((f) => f.isSelected);
    if (selected.isEmpty) return false;
    if (_renameMode == RenameMode.changeTimestamp ||
        _renameMode == RenameMode.changeAttributes) {
      return true;
    }
    return selected.any(
      (f) => f.validationErrorMessage == null && f.originalName != f.newName,
    );
  }

  bool get canMoveUp {
    for (var i = 1; i < _currentFiles.length; i++) {
      if (_currentFiles[i].isSelected && !_currentFiles[i - 1].isSelected) {
        return true;
      }
    }
    return false;
  }

  bool get canMoveDown {
    for (var i = 0; i < _currentFiles.length - 1; i++) {
      if (_currentFiles[i].isSelected && !_currentFiles[i + 1].isSelected) {
        return true;
      }
    }
    return false;
  }

  Future<void> init() async {
    _isCompactMode = _settings.getBool('isCompactMode') ?? true;
    _touchMode = _settings.getBool('touchMode') ?? false;
    _enableBetaFeatures = _settings.getBool('enableBetaFeatures') ?? false;
    _isLicenseAccepted = _settings.getBool('isLicenseAccepted') ?? false;
    _filterText = _settings.getString('filterText') ?? '';
    _isFilterSpecific = _filterText.isNotEmpty;
    _hideSystemFiles = _settings.getBool('hideSystemFiles') ?? false;
    _recursiveSearch = _settings.getBool('recursiveSearch') ?? false;
    _showPreview = _settings.getBool('showPreview') ?? true;
    _showFolders = _settings.getBool('showFolders') ?? true;
    _saveSequenceNumber = _settings.getBool('saveSequenceNumber') ?? false;
    final seedColorVal = _settings.getInt('seedColor');
    if (seedColorVal != null) _seedColor = Color(seedColorVal);
    _loadEnumSettings();
    _etcTimestamp = _settings.getString('etcTimestamp') ?? _defaultTimestamp();
    notifyListeners();
  }

  void _loadEnumSettings() {
    final appThemeStr = _settings.getString('appTheme') ?? 'light';
    _appTheme = AppThemeType.values.firstWhere(
      (e) => e.name == appThemeStr,
      orElse: () => AppThemeType.light,
    );
    final menuLabelStr = _settings.getString('menuLabelType');
    final pageMenuLabelType = _pageMenuLabelType();
    if (pageMenuLabelType != null) {
      _menuLabelType = pageMenuLabelType;
    } else if (menuLabelStr != null) {
      _menuLabelType = MenuLabelType.values.firstWhere(
        (e) => e.name == menuLabelStr,
        orElse: () => MenuLabelType.standard,
      );
    } else {
      _menuLabelType = _defaultMenuLabelTypeForLocales(_readPreferredLocales());
    }
    final validationIndex = _settings.getInt('validationType');
    if (validationIndex != null &&
        validationIndex < ValidationType.values.length) {
      _validationType = ValidationType.values[validationIndex];
    }
    final initialIndex = _settings.getInt('initialDirectoryMode');
    if (initialIndex != null &&
        initialIndex < InitialDirectoryMode.values.length) {
      _initialDirectoryMode = InitialDirectoryMode.values[initialIndex];
    }
  }

  void _saveState() {
    _settings.set('isCompactMode', _isCompactMode, saveImmediate: false);
    _settings.set('touchMode', _touchMode, saveImmediate: false);
    _settings.set('enableBetaFeatures', _enableBetaFeatures,
        saveImmediate: false);
    _settings.set('isLicenseAccepted', _isLicenseAccepted,
        saveImmediate: false);
    _settings.set('appTheme', _appTheme.name, saveImmediate: false);
    _settings.set('menuLabelType', _menuLabelType.name, saveImmediate: false);
    _settings.set('seedColor', _seedColor.toARGB32(), saveImmediate: false);
    _settings.set('filterText', _filterText, saveImmediate: false);
    _settings.set('hideSystemFiles', _hideSystemFiles, saveImmediate: false);
    _settings.set('recursiveSearch', _recursiveSearch, saveImmediate: false);
    _settings.set('showPreview', _showPreview, saveImmediate: false);
    _settings.set('showFolders', _showFolders, saveImmediate: false);
    _settings.set('saveSequenceNumber', _saveSequenceNumber,
        saveImmediate: false);
    _settings.set('validationType', _validationType.index,
        saveImmediate: false);
    _settings.set('initialDirectoryMode', _initialDirectoryMode.index,
        saveImmediate: false);
    _settings.set('fixedInitialDirectory', _fixedInitialDirectory,
        saveImmediate: false);
    _settings.saveSettings();
  }

  String _defaultTimestamp() {
    final now = DateTime.now();
    return '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> pickLocalDirectory() async {
    if (!_fs.isSupported) {
      _errorMessage = _localized(
        (l10n) => l10n.labelWebUnsupportedBrowserMessage,
        'このブラウザはローカルフォルダ連携に対応していません。',
      );
      notifyListeners();
      return;
    }
    await _guarded(() async {
      final directory = await _fs.pickDirectory();
      if (directory == null) return;
      _navigationSource = 'tree';
      _navigationContextRoot = directory.id;
      _selectionVersion++;
      await _openRoot(directory);
      _savedDirectories = await _fs.listSavedDirectories();
    });
  }

  Future<void> loadSavedDirectories() async {
    if (!_fs.isSupported) return;
    await _guarded(() async {
      _savedDirectories = await _fs.listSavedDirectories();
    });
  }

  Future<bool> forgetSavedDirectory(WebSavedDirectory directory) async {
    var success = false;
    await _guarded(() async {
      await _fs.forgetSavedDirectory(directory.id);
      _savedDirectories = await _fs.listSavedDirectories();
      if (_navigationContextRoot == directory.id) {
        _navigationSource = null;
        _navigationContextRoot = null;
        _breadcrumbs.clear();
        _currentDirectory = null;
        _allFiles = [];
        _currentFiles = [];
        _directoryEntries = [];
      }
      _navTreeResetTick++;
      success = true;
    });
    return success && _errorMessage == null;
  }

  Future<void> openSavedDirectory(WebSavedDirectory directory) async {
    await _guarded(() async {
      var permission = directory.permission;
      if (permission != 'granted') {
        permission = await _fs.requestPermission(directory.handle);
      }
      if (permission != 'granted') {
        _errorMessage = _localized(
          (l10n) => l10n.labelWebDirectoryPermissionDenied,
          'フォルダへのアクセスが許可されませんでした。',
        );
        return;
      }
      _navigationSource = 'tree';
      _navigationContextRoot = directory.id;
      _selectionVersion++;
      await _openRoot(directory);
      _savedDirectories = await _fs.listSavedDirectories();
    });
  }

  Future<void> openDroppedDirectory(WebSavedDirectory directory) async {
    await openSavedDirectory(directory);
  }

  Future<void> openDirectory(FileModel entry) async {
    if (!entry.isDirectory || entry.handle == null) return;
    await _guarded(() async {
      _navigationSource = 'tree';
      _selectionVersion++;
      _breadcrumbs.add(WebDirectory(
        name: entry.originalName,
        path: entry.path,
        relativePath: entry.relativePath,
        handle: entry.handle,
      ));
      _currentDirectory = _breadcrumbs.last;
      await _listCurrentDirectory();
    });
  }

  Future<void> openNavigationDirectory(
    WebSavedDirectory root,
    List<WebDirectoryLocation> locations,
  ) async {
    await _guarded(() async {
      var permission = root.permission;
      if (permission != 'granted') {
        permission = await _fs.requestPermission(root.handle);
      }
      if (permission != 'granted') {
        _errorMessage = _localized(
          (l10n) => l10n.labelWebDirectoryPermissionDenied,
          'フォルダへのアクセスが許可されませんでした。',
        );
        return;
      }
      _navigationSource = 'tree';
      _navigationContextRoot = root.id;
      _selectionVersion++;
      _breadcrumbs
        ..clear()
        ..add(WebDirectory(
          name: root.name,
          path: root.name,
          relativePath: '',
          handle: root.handle,
        ));
      for (final location in locations) {
        _breadcrumbs.add(WebDirectory(
          name: location.name,
          path: p.posix.join(root.name, location.relativePath),
          relativePath: location.relativePath,
          handle: location.handle,
        ));
      }
      _currentDirectory = _breadcrumbs.last;
      await _listCurrentDirectory();
      _savedDirectories = await _fs.listSavedDirectories();
    });
  }

  Future<List<FileModel>> listNavigationDirectoryChildren({
    required Object handle,
    required String rootPath,
    required String relativePath,
  }) async {
    final entries = await _fs.listDirectory(handle, relativePath, false);
    return entries
        .where((entry) => entry.isDirectory)
        .where((entry) => !_hideSystemFiles || !entry.name.startsWith('.'))
        .map((entry) => _toNavigationFileModel(entry, rootPath))
        .toList(growable: false);
  }

  Future<void> openBreadcrumb(int index) async {
    if (index < 0 || index >= _breadcrumbs.length) return;
    await _guarded(() async {
      _breadcrumbs.removeRange(index + 1, _breadcrumbs.length);
      _currentDirectory = _breadcrumbs.isEmpty ? null : _breadcrumbs.last;
      await _listCurrentDirectory();
    });
  }

  Future<void> setDirectoryPath(String path,
      {bool addToHistory = true, String? source, String? contextRoot}) async {
    _navigationSource = source;
    _navigationContextRoot = contextRoot;
    _selectionVersion++;
    _currentDirectory = path.isEmpty
        ? null
        : WebDirectory(
            name: p.posix.basename(path),
            path: path,
            relativePath: path,
            handle: null,
          );
    _allFiles = [];
    _currentFiles = [];
    _directoryEntries = [];
    if (addToHistory && path.isNotEmpty) {
      if (_navIndex < _navHistory.length - 1) {
        _navHistory.removeRange(_navIndex + 1, _navHistory.length);
      }
      _navHistory.remove(path);
      _navHistory.add(path);
      _navIndex = _navHistory.length - 1;
    }
    notifyListeners();
  }

  Future<void> goBack() async {
    if (!canGoBack) return;
    _navIndex--;
    await setDirectoryPath(_navHistory[_navIndex], addToHistory: false);
  }

  Future<void> goForward() async {
    if (!canGoForward) return;
    _navIndex++;
    await setDirectoryPath(_navHistory[_navIndex], addToHistory: false);
  }

  Future<void> jumpBack(int steps) async {
    final index = _navIndex - steps;
    if (index < 0) return;
    _navIndex = index;
    await setDirectoryPath(_navHistory[_navIndex], addToHistory: false);
  }

  Future<void> jumpForward(int steps) async {
    final index = _navIndex + steps;
    if (index >= _navHistory.length) return;
    _navIndex = index;
    await setDirectoryPath(_navHistory[_navIndex], addToHistory: false);
  }

  Future<void> goUp() async {
    if (_breadcrumbs.length > 1) {
      await openBreadcrumb(_breadcrumbs.length - 2);
      return;
    }
    final parent = _currentDirectory?.parent;
    if (parent != null) await setDirectoryPath(parent.path);
  }

  Future<void> _openRoot(WebSavedDirectory directory) async {
    _breadcrumbs
      ..clear()
      ..add(WebDirectory(
        name: directory.name,
        path: directory.name,
        relativePath: '',
        handle: directory.handle,
      ));
    _currentDirectory = _breadcrumbs.last;
    await _listCurrentDirectory();
  }

  Future<void> _listCurrentDirectory() async {
    final directory = _currentDirectory;
    if (directory == null || directory.handle == null) return;
    final entries = await _fs.listDirectory(
      directory.handle!,
      directory.relativePath,
      _recursiveSearch,
    );
    _directoryEntries = _recursiveSearch
        ? (await _fs.listDirectory(
            directory.handle!,
            directory.relativePath,
            false,
          ))
            .map(_toFileModel)
            .toList()
        : [];
    _allFiles = entries.map(_toFileModel).toList();
    if (!_recursiveSearch) _directoryEntries = _allFiles;
    _applyFilters();
    _errorMessage = null;
  }

  FileModel _toFileModel(WebFileEntry entry) {
    final baseParent = _currentDirectory?.path ?? '';
    final displayRelativeParent = _relativeParentFromCurrentDirectory(entry);
    final parent = displayRelativeParent.isEmpty
        ? baseParent
        : p.posix.join(baseParent, displayRelativeParent);
    final file = FileModel(
      originalName: entry.name,
      parentPath: parent,
      isDirectory: entry.isDirectory,
      modified: entry.lastModified,
      byteSize: entry.size,
      handle: entry.handle,
      parentHandle: entry.parentHandle,
    )..setRelativePath(entry.relativePath);
    file.setDisplayRelativePath(displayRelativeParent);
    return file;
  }

  FileModel _toNavigationFileModel(WebFileEntry entry, String rootPath) {
    final entryParentPath = p.posix.dirname(entry.relativePath);
    final parent = entryParentPath == '.'
        ? rootPath
        : p.posix.join(rootPath, entryParentPath);
    final file = FileModel(
      originalName: entry.name,
      parentPath: parent,
      isDirectory: entry.isDirectory,
      modified: entry.lastModified,
      byteSize: entry.size,
      handle: entry.handle,
      parentHandle: entry.parentHandle,
    )..setRelativePath(entry.relativePath);
    file.setDisplayRelativePath(entryParentPath == '.' ? '' : entryParentPath);
    return file;
  }

  String _relativeParentFromCurrentDirectory(WebFileEntry entry) {
    final currentRelativePath = _currentDirectory?.relativePath ?? '';
    final entryParentPath = p.posix.dirname(entry.relativePath);
    if (entryParentPath == '.') return '';
    if (currentRelativePath.isEmpty) return entryParentPath;
    if (entryParentPath == currentRelativePath) return '';
    final prefix = '$currentRelativePath/';
    if (entryParentPath.startsWith(prefix)) {
      return entryParentPath.substring(prefix.length);
    }
    return entryParentPath;
  }

  void _restoreSelectionByPath(String path, bool selected) {
    // Keep this in sync with docs/selection_ctrl_mode_contract.md.
    for (final file in _currentFiles) {
      if (file.path != path) continue;
      file.setSelected(selected, notify: false);
      file.notifyIfChanged();
      return;
    }
  }

  Future<void> _guarded(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      _errorMessage = _friendlyErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _friendlyErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('NotFoundError')) {
      return _localized(
        (l10n) => l10n.labelWebAccessUnavailable,
        'フォルダまたはファイルを読み込めませんでした。移動、削除、同期中などにより一部の項目へアクセスできない可能性があります。',
      );
    }
    return message;
  }

  Future<void> refresh() async {
    _errorMessage = null;
    if (_currentDirectory?.handle != null) {
      await _guarded(_listCurrentDirectory);
      return;
    }
    notifyListeners();
  }

  Future<void> checkForUpdates() async {}
  Future<void> requestAndroidPermissions(BuildContext context) async {}
  Future<void> checkClipboard() async {}
  Future<void> cancelScan() async {}

  void acceptLicense() {
    _isLicenseAccepted = true;
    _saveState();
    notifyListeners();
  }

  void setUpdateInfo(bool hasUpdate, String? version) {
    _hasUpdate = hasUpdate;
    _latestVersion = version;
    notifyListeners();
  }

  void setInlineRenaming(bool isRenaming) {
    _isInlineRenaming = isRenaming;
    notifyListeners();
  }

  void setCompactMode(bool isCompact) {
    _isCompactMode = isCompact;
    _saveState();
    notifyListeners();
  }

  void setTouchMode(bool value) {
    _touchMode = value;
    _saveState();
    notifyListeners();
  }

  void setEnableBetaFeatures(bool enable) {
    _enableBetaFeatures = enable;
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

  void updateInitialDirectorySettings(InitialDirectoryMode mode, String path) {
    _initialDirectoryMode = mode;
    _fixedInitialDirectory = path;
    _saveState();
    notifyListeners();
  }

  Future<void> updateFilterSettings({
    String? filter,
    bool? hideSystem,
    bool? recursive,
    bool? preview,
    bool? showFolders,
    bool? isSpecific,
    bool? isRegex,
  }) async {
    if (isSpecific != null) {
      _isFilterSpecific = isSpecific;
      if (!isSpecific) _filterText = '';
    }
    if (filter != null) {
      _filterText = filter;
      _isFilterSpecific = filter.isNotEmpty;
    }
    var shouldReload = false;
    if (hideSystem != null) _hideSystemFiles = hideSystem;
    if (recursive != null && recursive != _recursiveSearch) {
      _recursiveSearch = recursive;
      shouldReload = _currentDirectory?.handle != null;
    }
    if (preview != null) _showPreview = preview;
    if (showFolders != null) _showFolders = showFolders;
    if (isRegex != null) _isFilterRegex = isRegex;
    if (shouldReload) {
      _saveState();
      await _guarded(_listCurrentDirectory);
      return;
    }
    _applyFilters();
    _saveState();
    notifyListeners();
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
    bool immediate = false,
  }) {
    if (mode != null) {
      _renameMode = mode;
      if (isSubMode(mode)) {
        _lastSubMode = mode;
      } else if (isExtraMode(mode)) {
        _lastExtraMode = mode;
      } else if (isEtcMode(mode)) {
        _lastEtcMode = mode;
      } else {
        _lastMainMode = mode;
      }
      if ([
        RenameMode.append,
        RenameMode.prepend,
        RenameMode.insert,
        RenameMode.numbering,
      ].contains(mode)) {
        _lastStringMode = mode;
      }
    }
    if (numberingMode != null) _numberingMode = numberingMode;
    if (find != null || findText != null) _findText = find ?? findText;
    if (replace != null || replaceText != null) {
      _replaceText = replace ?? replaceText;
    }
    if (append != null || appendText != null)
      _appendText = append ?? appendText;
    if (deleteTo != null || deleteToText != null) {
      _deleteToText = deleteTo ?? deleteToText;
    }
    if (start != null || startNumber != null)
      _startNumber = (start ?? startNumber)!;
    if (insertIndex != null) _insertIndex = insertIndex;
    if (digit != null || digits != null) _digits = (digit ?? digits)!;
    if (extensionToLowerCase != null) {
      _extensionToLowerCase = extensionToLowerCase;
    }
    if (useRegex != null) _useRegex = useRegex;
    if (saveSequenceNumber != null) _saveSequenceNumber = saveSequenceNumber;
    if (listText != null) _listRenameText = listText;
    if (extensionChangeText != null) _extensionChangeText = extensionChangeText;
    if (extensionAddText != null) _extensionAddText = extensionAddText;
    if (dateFormat != null) _dateFormat = dateFormat;
    if (datePosition != null) _datePosition = datePosition;
    if (validationType != null) _validationType = validationType;
    if (etcTimestamp != null) _etcTimestamp = etcTimestamp;
    if (etcAttribReadOnly != null) _etcAttribReadOnly = etcAttribReadOnly;
    if (etcAttribHidden != null) _etcAttribHidden = etcAttribHidden;
    if (etcAttribArchive != null) _etcAttribArchive = etcAttribArchive;
    if (etcAttribSystem != null) _etcAttribSystem = etcAttribSystem;
    _updatePreviews();
    _saveState();
    notifyListeners();
  }

  bool isMainMode(RenameMode mode) =>
      !isSubMode(mode) && !isExtraMode(mode) && !isEtcMode(mode);
  bool isSubMode(RenameMode mode) => [
        RenameMode.extensionRemove,
        RenameMode.extensionAdd,
        RenameMode.extensionUpper,
        RenameMode.extensionLower,
        RenameMode.formatProperCase,
        RenameMode.listRename,
      ].contains(mode);
  bool isExtraMode(RenameMode mode) => [
        RenameMode.appendDate,
        RenameMode.convHalfToFull,
        RenameMode.convFullToHalf,
        RenameMode.convFullKataToHira,
        RenameMode.convHiraToFullKata,
        RenameMode.convFullAlphaToHalfAlpha,
        RenameMode.convNumToHalf,
      ].contains(mode);
  bool isEtcMode(RenameMode mode) => [
        RenameMode.changeTimestamp,
        RenameMode.changeAttributes,
      ].contains(mode);

  void _applyFilters() {
    _currentFiles = _allFiles.where((file) {
      if (_hideSystemFiles && file.originalName.startsWith('.')) return false;
      if (!_showFolders && file.isDirectory) return false;
      if (_filterText.isEmpty) return true;
      if (_isFilterRegex) {
        try {
          return RegExp(_filterText, caseSensitive: false)
              .hasMatch(file.originalName);
        } catch (_) {
          return true;
        }
      }
      return file.originalName
          .toLowerCase()
          .contains(_filterText.toLowerCase());
    }).toList();
  }

  void _updatePreviews() {
    var number = _startNumber;
    for (final file in _currentFiles) {
      if (!file.isSelected) {
        file.setNewName(file.originalName, notify: false);
        file.setValidationError(null, notify: false);
        file.notifyIfChanged();
        continue;
      }
      var name = file.originalName;
      final ext = p.posix.extension(name);
      final stem =
          ext.isEmpty ? name : name.substring(0, name.length - ext.length);
      switch (_renameMode) {
        case RenameMode.append:
          name = '$stem${_appendText ?? ''}$ext';
          break;
        case RenameMode.prepend:
          name = '${_appendText ?? ''}$name';
          break;
        case RenameMode.replace:
          final find = _findText ?? '';
          if (find.isNotEmpty) name = name.replaceAll(find, _replaceText ?? '');
          break;
        case RenameMode.numbering:
          name =
              '${(_appendText ?? '').isEmpty ? stem : _appendText}${number.toString().padLeft(_digits, '0')}$ext';
          number++;
          break;
        case RenameMode.extension:
          final nextExt = _extensionChangeText.trim();
          if (nextExt.isNotEmpty) {
            name = '$stem.${nextExt.replaceFirst(RegExp(r'^\.'), '')}';
          }
          break;
        case RenameMode.extensionUpper:
          name = '$stem${ext.toUpperCase()}';
          break;
        case RenameMode.extensionLower:
          name = '$stem${ext.toLowerCase()}';
          break;
        default:
          break;
      }
      file.setNewName(name, notify: false);
      file.setValidationError(name.trim().isEmpty ? 'ファイル名が空です' : null,
          notify: false);
      file.notifyIfChanged();
    }
  }

  void setNewName(FileModel entry, String newName) {
    entry.setNewName(newName, notify: false);
    entry.setValidationError(_validateNewName(entry, newName), notify: false);
    _validateDuplicates();
    entry.notifyIfChanged();
    notifyListeners();
  }

  void applyReplacePreview({
    required String find,
    required String replace,
    required bool selectedOnly,
  }) {
    if (find.isEmpty) return;
    for (final entry in _targetEntries(selectedOnly)) {
      if (!entry.isFile) continue;
      setNewName(entry, entry.originalName.replaceAll(find, replace));
    }
  }

  void applyNumberingPreview({
    required String baseName,
    required int startNumber,
    required int digits,
    required bool selectedOnly,
  }) {
    var number = startNumber;
    for (final entry in _targetEntries(selectedOnly)) {
      if (!entry.isFile) continue;
      final ext = p.posix.extension(entry.originalName);
      final padded = number.toString().padLeft(digits.clamp(1, 12), '0');
      setNewName(entry, '$baseName$padded$ext');
      number++;
    }
  }

  void resetPreview({bool selectedOnly = false}) {
    for (final entry in _targetEntries(selectedOnly)) {
      setNewName(entry, entry.originalName);
    }
  }

  Iterable<FileModel> _targetEntries(bool selectedOnly) {
    return selectedOnly
        ? _currentFiles.where((entry) => entry.isSelected)
        : _currentFiles;
  }

  String? _validateNewName(FileModel entry, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      return _localized(
        (l10n) => l10n.labelWebNameRequired,
        'ファイル名を入力してください。',
      );
    }
    if (RegExp(r'[\\/:*?"<>|]').hasMatch(trimmed)) {
      return _localized(
        (l10n) => l10n.labelWebInvalidFileNameChars,
        'ファイル名に使用できない文字が含まれています: / \\ : * ? " < > |',
      );
    }
    if (entry.originalName != trimmed &&
        _currentFiles.any(
          (other) =>
              other != entry &&
              other.parentPath == entry.parentPath &&
              other.originalName.toLowerCase() == trimmed.toLowerCase(),
        )) {
      return _localized(
        (l10n) => l10n.labelWebDuplicateItem,
        '同じ名前の項目が既にあります。',
      );
    }
    return null;
  }

  void _validateDuplicates() {
    final counts = <String, int>{};
    for (final entry in _currentFiles) {
      final key = '${entry.parentPath}/${entry.newName}'.toLowerCase();
      counts[key] = (counts[key] ?? 0) + 1;
    }
    for (final entry in _currentFiles) {
      final currentError = _validateNewName(entry, entry.newName);
      if (currentError != null) {
        entry.setValidationError(currentError, notify: false);
        continue;
      }
      final key = '${entry.parentPath}/${entry.newName}'.toLowerCase();
      entry.setValidationError(
        (counts[key] ?? 0) > 1
            ? _localized(
                (l10n) => l10n.labelWebDuplicateFile,
                '同じ名前のファイルが既にあります。',
              )
            : null,
        notify: false,
      );
    }
  }

  void updateVisibleRange(int start, int end) {}

  void toggleSelection(FileModel file) {
    file.isSelected = !file.isSelected;
    notifyListeners();
  }

  void selectAll(bool select) {
    for (final file in _currentFiles) {
      file.setSelected(select, notify: false);
      file.notifyIfChanged();
    }
    notifyListeners();
  }

  void selectRange(int start, int end,
      {bool exclusive = true, List<bool>? baseStates}) {
    final minIndex = start < end ? start : end;
    final maxIndex = start > end ? start : end;
    for (var i = 0; i < _currentFiles.length; i++) {
      final inside = i >= minIndex && i <= maxIndex;
      final next = baseStates != null && i < baseStates.length
          ? (inside ? !baseStates[i] : baseStates[i])
          : inside || (!exclusive && _currentFiles[i].isSelected);
      _currentFiles[i].setSelected(next, notify: false);
      _currentFiles[i].notifyIfChanged();
    }
    notifyListeners();
  }

  void sortFiles(int columnIndex, bool ascending, {bool notify = true}) {
    _sortColumnIndex = columnIndex;
    _sortAscending = ascending;
    _currentFiles.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      int result;
      switch (columnIndex) {
        case 1:
          result = a.newName.toLowerCase().compareTo(b.newName.toLowerCase());
          break;
        case 2:
          result = a.size.compareTo(b.size);
          break;
        case 3:
          result = a.displayRelativePath
              .toLowerCase()
              .compareTo(b.displayRelativePath.toLowerCase());
          break;
        case 4:
          result = a.fileType.toLowerCase().compareTo(b.fileType.toLowerCase());
          break;
        case 5:
          result = a.dateModified.compareTo(b.dateModified);
          break;
        case 6:
          result = a.attributes.compareTo(b.attributes);
          break;
        case 0:
        default:
          result = a.originalName
              .toLowerCase()
              .compareTo(b.originalName.toLowerCase());
          break;
      }
      return ascending ? result : -result;
    });
    if (notify) notifyListeners();
  }

  void reorderFiles(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _currentFiles.removeAt(oldIndex);
    _currentFiles.insert(newIndex.clamp(0, _currentFiles.length), item);
    notifyListeners();
  }

  void moveSelection(bool up) {
    if (up) {
      for (var i = 1; i < _currentFiles.length; i++) {
        if (_currentFiles[i].isSelected && !_currentFiles[i - 1].isSelected) {
          final item = _currentFiles[i - 1];
          _currentFiles[i - 1] = _currentFiles[i];
          _currentFiles[i] = item;
        }
      }
    } else {
      for (var i = _currentFiles.length - 2; i >= 0; i--) {
        if (_currentFiles[i].isSelected && !_currentFiles[i + 1].isSelected) {
          final item = _currentFiles[i + 1];
          _currentFiles[i + 1] = _currentFiles[i];
          _currentFiles[i] = item;
        }
      }
    }
    notifyListeners();
  }

  void moveSelectedToTop() {
    final selected = _currentFiles.where((f) => f.isSelected).toList();
    final rest = _currentFiles.where((f) => !f.isSelected).toList();
    _currentFiles = [...selected, ...rest];
    notifyListeners();
  }

  void moveSelectedToBottom() {
    final selected = _currentFiles.where((f) => f.isSelected).toList();
    final rest = _currentFiles.where((f) => !f.isSelected).toList();
    _currentFiles = [...rest, ...selected];
    notifyListeners();
  }

  Future<void> copySelection() async {
    _canPaste = false;
  }

  Future<void> cutSelection() async {
    _isCutMode = true;
    notifyListeners();
  }

  void clearCutState() {
    _isCutMode = false;
    for (final file in _currentFiles) {
      file.setCut(false, notify: false);
      file.notifyIfChanged();
    }
    notifyListeners();
  }

  Future<void> pasteFromClipboard() async {}
  Future<void> createNewFolder() async {}
  Future<int> deleteSelectedFiles() async => 0;

  Future<int> executeRename() async {
    final selected = _currentFiles.where((entry) => entry.isSelected).toList();
    if (selected.any((entry) => entry.validationErrorMessage != null)) {
      return 0;
    }
    final targets =
        selected.where((entry) => entry.originalName != entry.newName).toList();
    if (targets.isEmpty) return 0;

    var count = 0;
    final undoActions = <WebUndoAction>[];
    await _guarded(() async {
      for (final entry in targets) {
        try {
          final parentHandle = entry.parentHandle;
          if (parentHandle == null) {
            entry.markError(_localized(
              (l10n) => l10n.labelWebItemAccessLost,
              '項目へのアクセス情報が失われています。フォルダを選択し直してください。',
            ));
            continue;
          }
          await _fs.renameFile(
            parentHandle: parentHandle,
            oldName: entry.originalName,
            newName: entry.newName,
          );
          undoActions.add(WebUndoAction(
            entry.path,
            p.posix.join(entry.parentPath, entry.newName),
            parentHandle: parentHandle,
          ));
          entry.markRenamed();
          count++;
        } catch (e) {
          entry.markError(e.toString());
        }
      }
      if (undoActions.isNotEmpty) {
        _lastUndoTransaction
          ..clear()
          ..addAll(undoActions);
      }
      await _listCurrentDirectory();
      if (count > 0) _navTreeResetTick++;
    });
    return count;
  }

  Future<void> renameOneFile(FileModel file, String newName) async {
    final trimmed = newName.trim();
    if (file.originalName == trimmed || trimmed.isEmpty) return;
    final wasSelected = file.isSelected;
    final renamedPath = p.posix.join(file.parentPath, trimmed);

    setNewName(file, trimmed);
    if (file.validationErrorMessage != null) return;

    final parentHandle = file.parentHandle;
    if (parentHandle == null) {
      file.markError(_localized(
        (l10n) => l10n.labelWebFileAccessLost,
        'ファイルへのアクセス情報が失われています。フォルダを選択し直してください。',
      ));
      notifyListeners();
      return;
    }

    await _guarded(() async {
      await _fs.renameFile(
        parentHandle: parentHandle,
        oldName: file.originalName,
        newName: trimmed,
      );
      _lastUndoTransaction
        ..clear()
        ..add(WebUndoAction(
          file.path,
          p.posix.join(file.parentPath, trimmed),
          parentHandle: parentHandle,
        ));
      await _listCurrentDirectory();
      _navTreeResetTick++;
      _restoreSelectionByPath(renamedPath, wasSelected);
    });
  }

  Future<Map<String, dynamic>> undo() async {
    if (_lastUndoTransaction.isEmpty) return {'count': 0, 'errors': []};

    var count = 0;
    final errors = <String>[];
    final actions = List<WebUndoAction>.from(_lastUndoTransaction.reversed);

    await _guarded(() async {
      for (final action in actions) {
        final parentHandle = action.parentHandle;
        final oldName = p.posix.basename(action.oldPath);
        final newName = p.posix.basename(action.newPath);
        if (parentHandle == null) {
          errors.add('$newName: フォルダへのアクセス情報が失われています。');
          continue;
        }
        try {
          await _fs.renameFile(
            parentHandle: parentHandle,
            oldName: newName,
            newName: oldName,
          );
          count++;
        } catch (e) {
          errors.add('$newName: $e');
        }
      }
      if (count > 0) {
        _lastUndoTransaction.clear();
        _navTreeResetTick++;
      }
      await _listCurrentDirectory();
    });

    return {'count': count, 'errors': errors};
  }

  void clearInputHistory() {
    _findHistory = [];
    _replaceHistory = [];
    _appendHistory = [];
    _extensionHistory = [];
    _deleteFromHistory = [];
    _deleteToHistory = [];
    notifyListeners();
  }

  void resetSettings() {
    _appTheme = AppThemeType.light;
    _menuLabelType = MenuLabelType.standard;
    _seedColor = Colors.green;
    _isCompactMode = true;
    _touchMode = false;
    _enableBetaFeatures = false;
    _initialDirectoryMode = InitialDirectoryMode.lastUsed;
    _fixedInitialDirectory = '';
    _renameMode = RenameMode.numbering;
    _numberingMode = NumberingMode.stringNumber;
    _validationType = ValidationType.auto;
    _filterText = '';
    _isFilterSpecific = false;
    _resetCount++;
    _saveState();
    notifyListeners();
  }

  void addHistory(HistoryType type, String value) {
    if (value.isEmpty) return;
    final target = switch (type) {
      HistoryType.find => _findHistory,
      HistoryType.replace => _replaceHistory,
      HistoryType.add => _appendHistory,
      HistoryType.extension => _extensionHistory,
      HistoryType.remove => _deleteFromHistory,
      HistoryType.deleteTo => _deleteToHistory,
    };
    target.remove(value);
    target.insert(0, value);
    if (target.length > 20) target.removeRange(20, target.length);
    notifyListeners();
  }

  List<WebUndoAction> getLastUndoTransaction() => _lastUndoTransaction;

  void resetNavTree() {
    _navTreeResetTick++;
    notifyListeners();
  }

  void setTextPreviewFontSize(double size) {
    _textPreviewFontSize = size.clamp(8.0, 40.0);
    notifyListeners();
  }

  void openEnlargedPreview(FileModel file) {
    _enlargedPreviewIndex = _currentFiles.indexOf(file);
    if (_enlargedPreviewIndex >= 0) {
      _isEnlargedPreviewOpen = true;
      notifyListeners();
    }
  }

  void closeEnlargedPreview() {
    _isEnlargedPreviewOpen = false;
    notifyListeners();
  }

  void nextEnlargedPreview() {
    _moveEnlargedPreview(1);
  }

  void prevEnlargedPreview() {
    _moveEnlargedPreview(-1);
  }

  void _moveEnlargedPreview(int delta) {
    final selected = _currentFiles.where((f) => f.isSelected).toList();
    if (selected.isEmpty) return;
    final current = enlargedPreviewFile;
    var index = selected.indexOf(current ?? selected.first);
    index = (index + delta + selected.length) % selected.length;
    _enlargedPreviewIndex = _currentFiles.indexOf(selected[index]);
    notifyListeners();
  }
}
