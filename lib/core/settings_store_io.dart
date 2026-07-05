import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

String? _memorySettingsJson;

Future<String?> readSettingsJson() async {
  try {
    final file = await _getSettingsFile();
    if (!await file.exists()) return null;
    final content = await file.readAsString();
    if (kDebugMode) debugPrint('Settings loaded from: ${file.path}');
    return content;
  } on MissingPluginException {
    return _memorySettingsJson;
  }
}

Future<void> writeSettingsJson(String content) async {
  try {
    final file = await _getSettingsFile();
    await file.writeAsString(content);
    if (kDebugMode) debugPrint('Settings saved to: ${file.path}');
  } on MissingPluginException {
    _memorySettingsJson = content;
  }
}

Future<File> _getSettingsFile() async {
  final String directoryPath;

  if (Platform.isAndroid || Platform.isIOS) {
    final dir = await getApplicationDocumentsDirectory();
    directoryPath = dir.path;
  } else if (Platform.isWindows) {
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
