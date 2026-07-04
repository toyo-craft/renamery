import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:renamery/core/directory_provider.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';
import 'package:renamery/ui/panels/file_list_panel.dart';

void main() {
  group('FileListPanel selection', () {
    late Directory tempDir;
    late DirectoryProvider provider;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('renamery_file_list_');
      for (final name in ['01.txt', '02.txt', '03.txt', '04.txt']) {
        File('${tempDir.path}${Platform.pathSeparator}$name')
            .writeAsStringSync(name);
      }

      provider = DirectoryProvider();
      await provider.setDirectory(tempDir, addToHistory: false);
      provider.sortFiles(0, true);
    });

    tearDown(() async {
      await provider.cancelScan();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('click toggles one file and shift-click toggles a range',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox.expand(child: FileListPanel()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _tapRowAtTextY(tester, '02.txt');
      await tester.pumpAndSettle();

      expect(_selection(provider), [false, true, false, false]);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await _tapRowAtTextY(tester, '04.txt');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      expect(_selection(provider), [false, false, true, true]);
    });

    testWidgets('small pointer jitter on a row does not clear selection',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox.expand(child: FileListPanel()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rowY = tester.getCenter(find.text('02.txt')).dy;
      final gesture = await tester.startGesture(Offset(700, rowY));
      await gesture.moveBy(const Offset(8, 2));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(_selection(provider), [false, true, false, false]);
    });

    testWidgets('clicking a file name toggles selection in default ctrl mode',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox.expand(child: FileListPanel()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('02.txt'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(_selection(provider), [false, true, false, false]);

      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump();
      await tester.tap(find.text('02.txt'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(_selection(provider), [false, false, false, false]);
    });

    testWidgets(
        'double-clicking an unselected file name keeps toggled selection while editing',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox.expand(child: FileListPanel()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('02.txt'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('02.txt'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(_selection(provider), [false, true, false, false]);
    });

    testWidgets(
        'double-clicking a selected file name keeps toggled-off selection while editing',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox.expand(child: FileListPanel()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      provider.toggleSelection(provider.currentFiles[1]);
      await tester.pumpAndSettle();

      await tester.tap(find.text('02.txt'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('02.txt'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(_selection(provider), [false, false, false, false]);
    });

    testWidgets('double-clicking name column whitespace does not start rename',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox.expand(child: FileListPanel()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rowY = tester.getCenter(find.text('02.txt')).dy;
      await tester.tapAt(Offset(360, rowY));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(Offset(360, rowY));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(_selection(provider), [false, false, false, false]);
    });
  });
}

List<bool> _selection(DirectoryProvider provider) =>
    provider.currentFiles.map((file) => file.isSelected).toList();

Future<void> _tapRowAtTextY(WidgetTester tester, String text) async {
  final rowY = tester.getCenter(find.text(text)).dy;
  await tester.tapAt(Offset(700, rowY));
}
