import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();

  factory SettingsService() {
    return _instance;
  }

  SettingsService._internal();

  Map<String, dynamic> _settings = {};
  bool _isSaving = false;
  bool _needsSaveAgain = false;

  Future<void> loadSettings() async {
    try {
      final file = await _getSettingsFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        _settings = json.decode(content);
        if (kDebugMode) print('Settings loaded from: ${file.path}');
      }
    } catch (e) {
      if (kDebugMode) print('Error loading settings: $e');
    }
  }

  Future<void> saveSettings() async {
    if (_isSaving) {
      _needsSaveAgain = true;
      return;
    }

    _isSaving = true;
    try {
      final file = await _getSettingsFile();
      await file.writeAsString(json.encode(_settings));
      if (kDebugMode) print('Settings saved to: ${file.path}');
    } catch (e) {
      if (kDebugMode) print('Error saving settings: $e');
    } finally {
      _isSaving = false;
      if (_needsSaveAgain) {
        _needsSaveAgain = false;
        saveSettings();
      }
    }
  }

  Future<File> _getSettingsFile() async {
    final String directoryPath;

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final dir = await getApplicationDocumentsDirectory();
      directoryPath = dir.path;
    } else if (!kIsWeb && Platform.isWindows) {
      // Windows: Program Files への書き込み制限を避けるため AppData を優先
      // ただし、実行ファイルと同じ場所に settings.json が既にある場合はポータブルモードとして維持
      final exePath = Platform.resolvedExecutable;
      final exeDir = p.dirname(exePath);
      final portableFile = File(p.join(exeDir, 'settings.json'));
      
      if (await portableFile.exists()) {
        directoryPath = exeDir;
      } else {
        final appDataDir = await getApplicationSupportDirectory();
        directoryPath = appDataDir.path;
      }
    } else {
      final dir = await getApplicationSupportDirectory();
      directoryPath = dir.path;
    }

    final path = p.join(directoryPath, 'settings.json');
    final file = File(path);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    return file;
  }

  dynamic get(String key) => _settings[key];

  void set(String key, dynamic value, {bool saveImmediate = true}) {
    _settings[key] = value;
    if (saveImmediate) saveSettings();
  }

  int? getInt(String key) {
    final val = _settings[key];
    if (val is num) return val.toInt();
    return null;
  }

  double? getDouble(String key) {
    final val = _settings[key];
    if (val is num) return val.toDouble();
    return null;
  }

  bool? getBool(String key) => _settings[key] as bool?;
  String? getString(String key) => _settings[key] as String?;

  List<String> getStringList(String key) {
    final val = _settings[key];
    if (val is List) return val.map((e) => e.toString()).toList();
    return [];
  }

  List<T>? getList<T>(String key) {
    final val = _settings[key];
    if (val is List) return val.cast<T>();
    return null;
  }
}
