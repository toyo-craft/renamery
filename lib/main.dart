import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/home_screen.dart';
import 'core/directory_provider.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:window_manager/window_manager.dart';
import 'core/settings_service.dart';

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:windows_single_instance/windows_single_instance.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android Permissions
  if (!kIsWeb && Platform.isAndroid) {
    await _requestAndroidPermissions();
  }

  if (!kIsWeb && Platform.isWindows) {
    await WindowsSingleInstance.ensureSingleInstance(
        args, "ToyoCraftLab.ReNamery.SingleInstance",
        onSecondWindow: (args) async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
  }
  await SettingsService().loadSettings(); // Load settings early

  // Restore Window State
  final width = SettingsService().getDouble('windowWidth') ?? 1024.0;
  final height = SettingsService().getDouble('windowHeight') ?? 768.0;
  final x = SettingsService().getDouble('windowX');
  final y = SettingsService().getDouble('windowY');

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    WindowOptions windowOptions = WindowOptions(
      size: Size(width, height),
      center: x == null || y == null, // Center if no position saved
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

        // Determine active scheme and brightness for window color synchronization
        final bool isDarkMode = provider.themeMode == ThemeMode.dark ||
            (provider.themeMode == ThemeMode.system &&
                View.of(context).platformDispatcher.platformBrightness ==
                    Brightness.dark);
        final currentScheme = isDarkMode ? targetDarkScheme : lightScheme;

        // Synchronize Windows title bar color with theme
        if (!kIsWeb && Platform.isWindows) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            // Set the window brightness to ensure title bar text color is correct
            await windowManager
                .setBrightness(isDarkMode ? Brightness.dark : Brightness.light);
            // Set the window background/title bar color
            await windowManager.setBackgroundColor(currentScheme.surface);
          });
        }

        return MaterialApp(
          title: 'ReNamery',
          themeMode: provider.themeMode,
          locale: provider.currentLocale,
          theme: ThemeData(
            fontFamilyFallback: const ['Meiryo', 'Yu Gothic', 'MS PGothic'],
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
            fontFamilyFallback: const ['Meiryo', 'Yu Gothic', 'MS PGothic'],
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
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            if (deviceLocale != null) {
              for (var locale in supportedLocales) {
                if (locale.languageCode == deviceLocale.languageCode) {
                  return deviceLocale;
                }
              }
            }
            // Fallback to English if the language is unsupported
            return const Locale('en');
          },
        );
      },
    );
  }
}

Future<void> _requestAndroidPermissions() async {
  // Check current status
  var status = await Permission.manageExternalStorage.status;
  
  if (!status.isGranted) {
    // First request
    status = await Permission.manageExternalStorage.request();
    
    // If still not granted (user needs to toggle in settings)
    if (!status.isGranted) {
      // Open app settings page for MANAGE_EXTERNAL_STORAGE
      await openAppSettings();
    }
  }
}
