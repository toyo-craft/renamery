import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/home_screen.dart';
import 'core/directory_provider.dart';

import 'package:window_manager/window_manager.dart';
import 'core/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await SettingsService().loadSettings(); // Load settings early

  // Restore Window State
  // Restore Window State
  final width = SettingsService().getDouble('windowWidth') ?? 1024.0;
  final height = SettingsService().getDouble('windowHeight') ?? 768.0;
  final x = SettingsService().getDouble('windowX');
  final y = SettingsService().getDouble('windowY');

  WindowOptions windowOptions = WindowOptions(
    size: Size(width, height),
    center: x == null || y == null, // Center if no position saved
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'ReNamery',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    if (x != null && y != null) {
      await windowManager.setPosition(Offset(x, y));
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DirectoryProvider()..init()),
      ],
      child: const ReNameryApp(),
    ),
  );
}

class ReNameryApp extends StatelessWidget {
  const ReNameryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReNamery',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        fontFamily: 'Segoe UI', // Windowsでのネイティブな外観
      ),
      home: const HomeScreen(),
    );
  }
}
