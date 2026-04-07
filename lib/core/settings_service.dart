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

  Future<void> loadSettings() async {
    try {
      final file = await _getSettingsFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        _settings = json.decode(content);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading settings: $e');
      }
    }
  }

  Future<void> saveSettings() async {
    try {
      final file = await _getSettingsFile();
      await file.writeAsString(json.encode(_settings));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving settings: $e');
      }
    }
  }

  Future<File> _getSettingsFile() async {
    final String directoryPath;

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      // モバイル環境: アプリ専用のドキュメントディレクトリを使用
      final dir = await getApplicationDocumentsDirectory();
      directoryPath = dir.path;
    } else {
      // デスクトップ環境: ポータブルモード (実行ファイル横)
      final exePath = Platform.resolvedExecutable;
      if (kDebugMode && !exePath.toLowerCase().endsWith('renamery.exe')) {
        directoryPath = Directory.current.path;
      } else {
        directoryPath = p.dirname(exePath);
      }
    }

    final path = p.join(directoryPath, 'settings.json');
    final file = File(path);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    return file;
  }

  // Generic Getters/Setters
  dynamic get(String key) => _settings[key];

  void set(String key, dynamic value) {
    _settings[key] = value;
    saveSettings(); // Auto-save on set
  }

  // Typed Getters (Safe)
  T? getValue<T>(String key) => _settings[key] as T?;

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
    if (val is List) {
      return val.map((e) => e.toString()).toList();
    }
    return [];
  }

  List<T>? getList<T>(String key) {
    final val = _settings[key];
    if (val is List) {
      return val.cast<T>();
    }
    return null;
  }
}
