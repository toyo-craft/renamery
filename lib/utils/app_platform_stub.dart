import 'package:flutter/material.dart';

class AppPlatform {
  static Future<void> ensureSingleInstance(List<String> args) async {}

  static Future<void> ensureWindowInitialized() async {}

  static Future<void> restoreWindowState() async {}

  static void syncWindowAppearance({
    required bool isDarkMode,
    required Color surface,
  }) {}
}
