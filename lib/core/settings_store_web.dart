import 'package:shared_preferences/shared_preferences.dart';

const _settingsKey = 'renamery.settings.json';

Future<String?> readSettingsJson() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_settingsKey);
}

Future<void> writeSettingsJson(String content) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_settingsKey, content);
}
