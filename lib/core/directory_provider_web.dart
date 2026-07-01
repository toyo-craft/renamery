import 'package:flutter/material.dart';

import 'settings_service.dart';
import 'web_file_system_service.dart';

enum HistoryType { find, replace, add, extension, remove, deleteTo }

enum AppThemeType { system, light, dark, darkGray }

enum MenuLabelType { standard, namery, english, chinese, spanish }

class DirectoryProvider extends ChangeNotifier {
  DirectoryProvider({
    WebFileSystemClient? fileSystem,
    SettingsService? settings,
  })  : _fs = fileSystem ?? WebFileSystemService(),
        _settings = settings ?? SettingsService();

  final WebFileSystemClient _fs;
  final SettingsService _settings;

  bool _isLoading = false;
  bool _isCompactMode = true;
  AppThemeType _appTheme = AppThemeType.light;
  MenuLabelType _menuLabelType = MenuLabelType.standard;
  Color _seedColor = Colors.green;
  String? _errorMessage;

  List<WebSavedDirectory> _savedDirectories = [];
  List<WebFileEntry> _currentFiles = [];
  final List<WebDirectoryLocation> _breadcrumbs = [];

  bool get isLoading => _isLoading;
  bool get isCompactMode => _isCompactMode;
  AppThemeType get appTheme => _appTheme;
  Color get seedColor => _seedColor;
  String? get errorMessage => _errorMessage;
  bool get isWebFileSystemSupported => _fs.isSupported;
  List<WebSavedDirectory> get savedDirectories => _savedDirectories;
  List<WebFileEntry> get currentFiles => _currentFiles;
  List<WebDirectoryLocation> get breadcrumbs => List.unmodifiable(_breadcrumbs);
  WebDirectoryLocation? get currentDirectory =>
      _breadcrumbs.isEmpty ? null : _breadcrumbs.last;

  int get selectedFilesCount => _currentFiles.where((f) => f.isSelected).length;

  bool get canExecute {
    final selected = _currentFiles.where((file) => file.isSelected).toList();
    if (selected.isEmpty) return false;
    if (selected.any((file) => _validateNewName(file, file.newName) != null)) {
      return false;
    }
    return selected.any((file) => file.isFile && file.name != file.newName);
  }

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

  Future<void> init() async {
    _isCompactMode = _settings.getBool('isCompactMode') ?? true;
    final appThemeStr = _settings.getString('appTheme') ?? 'light';
    _appTheme = AppThemeType.values.firstWhere(
      (e) => e.name == appThemeStr,
      orElse: () => AppThemeType.light,
    );
    final menuLabelStr = _settings.getString('menuLabelType');
    if (menuLabelStr != null) {
      _menuLabelType = MenuLabelType.values.firstWhere(
        (e) => e.name == menuLabelStr,
        orElse: () => MenuLabelType.standard,
      );
    }
    final seedColorVal = _settings.getInt('seedColor');
    if (seedColorVal != null) _seedColor = Color(seedColorVal);
    await loadSavedDirectories();
  }

  Future<void> loadSavedDirectories() async {
    if (!_fs.isSupported) return;
    await _guarded(() async {
      _savedDirectories = await _fs.listSavedDirectories();
    });
  }

  Future<void> pickLocalDirectory() async {
    if (!_fs.isSupported) {
      _errorMessage = 'このブラウザはローカルフォルダ連携に対応していません。';
      notifyListeners();
      return;
    }
    await _guarded(() async {
      final directory = await _fs.pickDirectory();
      if (directory == null) return;
      await _openRoot(directory);
      _savedDirectories = await _fs.listSavedDirectories();
    });
  }

  Future<void> openSavedDirectory(WebSavedDirectory directory) async {
    await _guarded(() async {
      var permission = directory.permission;
      if (permission != 'granted') {
        permission = await _fs.requestPermission(directory.handle);
      }
      if (permission != 'granted') {
        _errorMessage = 'フォルダへのアクセスが許可されませんでした。';
        return;
      }
      await _openRoot(directory);
      _savedDirectories = await _fs.listSavedDirectories();
    });
  }

  Future<void> openDirectory(WebFileEntry entry) async {
    if (!entry.isDirectory) return;
    await _guarded(() async {
      _breadcrumbs.add(WebDirectoryLocation(
        name: entry.name,
        relativePath: entry.relativePath,
        handle: entry.handle,
      ));
      await _listCurrentDirectory();
    });
  }

  Future<void> openBreadcrumb(int index) async {
    if (index < 0 || index >= _breadcrumbs.length) return;
    await _guarded(() async {
      _breadcrumbs.removeRange(index + 1, _breadcrumbs.length);
      await _listCurrentDirectory();
    });
  }

  Future<void> goUp() async {
    if (_breadcrumbs.length <= 1) return;
    await openBreadcrumb(_breadcrumbs.length - 2);
  }

  Future<void> refresh() async {
    if (currentDirectory == null) return;
    await _guarded(_listCurrentDirectory);
  }

  void toggleSelection(WebFileEntry entry) {
    entry.isSelected = !entry.isSelected;
    notifyListeners();
  }

  void selectAll(bool selected) {
    for (final file in _currentFiles) {
      file.isSelected = selected;
    }
    notifyListeners();
  }

  void setNewName(WebFileEntry entry, String newName) {
    entry.newName = newName;
    entry.status = entry.name == newName
        ? WebEntryStatus.original
        : WebEntryStatus.pending;
    entry.errorMessage = _validateNewName(entry, newName);
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
      setNewName(entry, entry.name.replaceAll(find, replace));
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
      final extIndex = entry.name.lastIndexOf('.');
      final ext = extIndex > 0 ? entry.name.substring(extIndex) : '';
      final padded = number.toString().padLeft(digits.clamp(1, 12), '0');
      setNewName(entry, '$baseName$padded$ext');
      number++;
    }
  }

  void resetPreview({bool selectedOnly = false}) {
    for (final entry in _targetEntries(selectedOnly)) {
      setNewName(entry, entry.name);
    }
  }

  Future<int> executeRename() async {
    final selected = _currentFiles.where((entry) => entry.isSelected).toList();
    if (selected
        .any((entry) => _validateNewName(entry, entry.newName) != null)) {
      return 0;
    }

    final targets = selected
        .where((entry) => entry.isFile && entry.name != entry.newName)
        .toList();
    if (targets.isEmpty) return 0;

    var count = 0;
    await _guarded(() async {
      for (final entry in targets) {
        try {
          await _fs.renameFile(
            parentHandle: entry.parentHandle,
            oldName: entry.name,
            newName: entry.newName,
          );
          entry.status = WebEntryStatus.renamed;
          count++;
        } catch (e) {
          entry.status = WebEntryStatus.error;
          entry.errorMessage = e.toString();
        }
      }
      await _listCurrentDirectory();
    });
    return count;
  }

  Future<void> _openRoot(WebSavedDirectory directory) async {
    _breadcrumbs
      ..clear()
      ..add(WebDirectoryLocation(
        name: directory.name,
        relativePath: '',
        handle: directory.handle,
      ));
    await _listCurrentDirectory();
  }

  Future<void> _listCurrentDirectory() async {
    final directory = currentDirectory;
    if (directory == null) {
      _currentFiles = [];
      return;
    }
    _currentFiles = await _fs.listDirectory(
      directory.handle,
      directory.relativePath,
    );
  }

  Iterable<WebFileEntry> _targetEntries(bool selectedOnly) {
    if (!selectedOnly || selectedFilesCount == 0) return _currentFiles;
    return _currentFiles.where((entry) => entry.isSelected);
  }

  Future<void> _guarded(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? _validateNewName(WebFileEntry entry, String newName) {
    if (entry.isDirectory && entry.name != newName) {
      return 'Web版のフォルダーリネームは後続対応です。';
    }
    if (newName.trim().isEmpty) return '名前を入力してください。';
    if (newName.contains('/') || newName.contains('\\')) {
      return 'ファイル名に / または \\ は使用できません。';
    }
    final duplicate = _currentFiles.any((other) {
      if (other == entry) return false;
      return other.newName.toLowerCase() == newName.toLowerCase();
    });
    if (duplicate) return '同じ名前の項目があります。';
    return null;
  }
}
