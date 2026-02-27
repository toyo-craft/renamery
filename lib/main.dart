import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/home_screen.dart';
import 'core/directory_provider.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

import 'package:window_manager/window_manager.dart';
import 'core/settings_service.dart';

import 'dart:io';

import 'package:windows_single_instance/windows_single_instance.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    await WindowsSingleInstance.ensureSingleInstance(
        args, "ToyoCraftLab.ReNamery.SingleInstance",
        onSecondWindow: (args) async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
  }
  await SettingsService().loadSettings(); // Load settings early

  // Restore Window State
  final width = SettingsService().getDouble('windowWidth') ?? 1024.0;
  final height = SettingsService().getDouble('windowHeight') ?? 768.0;
  final x = SettingsService().getDouble('windowX');
  final y = SettingsService().getDouble('windowY');

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
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
  }

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
        final lightScheme = ColorScheme.fromSeed(
          seedColor: provider.seedColor,
          brightness: Brightness.light,
        );
        final darkScheme = ColorScheme.fromSeed(
          seedColor: provider.seedColor,
          brightness: Brightness.dark,
        );

        // Define Dark Gray Scheme (Neutral / High Contrast)
        final darkGrayScheme = ColorScheme.fromSeed(
          seedColor: provider.seedColor,
          brightness: Brightness.dark,
        ).copyWith(
          // Override surfaces to be more neutral/gray
          surface: const Color(0xFF1E1E1E),
          surfaceContainer: const Color(0xFF252526),
          surfaceContainerHigh: const Color(0xFF2D2D2D),
          surfaceContainerHighest: const Color(0xFF323233),
          onSurface: const Color(0xFFE0E0E0),
        );

        // Select Dark Theme Data
        final useDarkGray = provider.appTheme == AppThemeType.darkGray;
        final targetDarkScheme = useDarkGray ? darkGrayScheme : darkScheme;

        return MaterialApp(
          title: 'ReNamery',
          themeMode: provider.themeMode,
          locale: provider.currentLocale,
          theme: ThemeData(
            colorScheme: lightScheme,
            visualDensity: provider.isCompactMode
                ? VisualDensity.compact
                : VisualDensity.standard,
            useMaterial3: true,
            textTheme: GoogleFonts.notoSansJpTextTheme(),
            iconTheme: IconThemeData(
              color: lightScheme.primary,
              weight: 700.0,
            ),
            tabBarTheme: const TabBarThemeData(
              indicatorSize: TabBarIndicatorSize.label,
              labelPadding: EdgeInsets.symmetric(horizontal: 16.0),
            ),
            appBarTheme: AppBarTheme(
              iconTheme: IconThemeData(
                color: lightScheme.primary,
                weight: 700.0,
              ),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              border: UnderlineInputBorder(),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: targetDarkScheme,
            visualDensity: provider.isCompactMode
                ? VisualDensity.compact
                : VisualDensity.standard,
            useMaterial3: true,
            scaffoldBackgroundColor: useDarkGray
                ? const Color(0xFF1E1E1E)
                : null, // Enforce background
            textTheme: GoogleFonts.notoSansJpTextTheme(
              ThemeData(brightness: Brightness.dark).textTheme,
            ),
            iconTheme: IconThemeData(
              color: targetDarkScheme.primary,
              weight: 700.0,
            ),
            tabBarTheme: const TabBarThemeData(
              indicatorSize: TabBarIndicatorSize.label,
              labelPadding: EdgeInsets.symmetric(horizontal: 16.0),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: useDarkGray ? const Color(0xFF1F1F1F) : null,
              iconTheme: IconThemeData(
                color: targetDarkScheme.primary,
                weight: 700.0,
              ),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              border: UnderlineInputBorder(),
            ),
          ),
          home: const HomeScreen(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
    );
  }
}
