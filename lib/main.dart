import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    return Consumer<DirectoryProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'ReNamery',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            visualDensity: provider.isCompactMode
                ? VisualDensity.compact
                : VisualDensity.standard,
            useMaterial3: true,
            fontFamily: 'Segoe UI',
            tabBarTheme: TabBarThemeData(
              indicatorSize: TabBarIndicatorSize.label,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              border: UnderlineInputBorder(),
            ),
          ),
          home: const HomeScreen(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ja', 'JP'),
            Locale('en', 'US'),
          ],
        );
      },
    );
  }
}
