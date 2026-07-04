import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:windows_single_instance/windows_single_instance.dart';

import '../core/settings_service.dart';

class AppPlatform {
  static Future<void> ensureSingleInstance(List<String> args) async {
    if (!Platform.isWindows) return;
    await WindowsSingleInstance.ensureSingleInstance(
      args,
      'ToyoCraftLab.ReNamery.SingleInstance',
      onSecondWindow: (args) async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  static Future<void> ensureWindowInitialized() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.ensureInitialized();
    }
  }

  static Future<void> restoreWindowState() async {
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;

    final width = SettingsService().getDouble('windowWidth') ?? 1024.0;
    final height = SettingsService().getDouble('windowHeight') ?? 768.0;
    final x = SettingsService().getDouble('windowX');
    final y = SettingsService().getDouble('windowY');

    final windowOptions = WindowOptions(
      size: Size(width, height),
      center: x == null || y == null,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'ReNamery',
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      if (x != null && y != null) {
        await windowManager.setPosition(Offset(x, y));
      }
    });
  }

  static void syncWindowAppearance({
    required bool isDarkMode,
    required Color surface,
  }) {
    if (!Platform.isWindows) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await windowManager.setBrightness(
        isDarkMode ? Brightness.dark : Brightness.light,
      );
      await windowManager.setBackgroundColor(surface);
    });
  }

  static Future<bool> exitApplication() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.close();
      return true;
    }
    await SystemNavigator.pop();
    return true;
  }
}
