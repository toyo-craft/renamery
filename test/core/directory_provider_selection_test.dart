import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:renamery/core/directory_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DirectoryProvider.selectRange', () {
    late Directory tempDir;
    late DirectoryProvider provider;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('renamery_selection_');
      for (final name in ['01.txt', '02.txt', '03.txt', '04.txt']) {
        File('${tempDir.path}${Platform.pathSeparator}$name')
            .writeAsStringSync(name);
      }

      provider = DirectoryProvider();
      await provider.setDirectory(tempDir, addToHistory: false);
      provider.sortFiles(0, true);

      expect(provider.currentFiles.map((file) => file.originalName), [
        '01.txt',
        '02.txt',
        '03.txt',
        '04.txt',
      ]);
    });

    tearDown(() async {
      await provider.cancelScan();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('selects an inclusive range exclusively', () {
      provider.selectRange(1, 2);

      expect(_selection(provider), [false, true, true, false]);
    });

    test('normalizes a reversed range', () {
      provider.selectRange(3, 1);

      expect(_selection(provider), [false, true, true, true]);
    });

    test('toggles only the range when base states are supplied', () {
      provider.currentFiles[0].isSelected = true;
      provider.currentFiles[2].isSelected = true;
      final baseStates = _selection(provider);

      provider.selectRange(1, 3, baseStates: baseStates);

      expect(_selection(provider), [true, true, false, true]);
    });
  });
}

List<bool> _selection(DirectoryProvider provider) =>
    provider.currentFiles.map((file) => file.isSelected).toList();
