import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'settings_store_stub.dart'
    if (dart.library.io) 'settings_store_io.dart'
    if (dart.library.html) 'settings_store_web.dart' as settings_store;

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
      final content = await settings_store.readSettingsJson();
      if (content != null) {
        _settings = json.decode(content);
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
      await settings_store.writeSettingsJson(json.encode(_settings));
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
