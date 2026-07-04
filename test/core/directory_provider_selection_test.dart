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

  group('DirectoryProvider.renameOneFile', () {
    late Directory tempDir;
    late DirectoryProvider provider;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('renamery_rename_');
      File('${tempDir.path}${Platform.pathSeparator}old.txt')
          .writeAsStringSync('old');

      provider = DirectoryProvider();
      await provider.setDirectory(tempDir, addToHistory: false);
      provider.sortFiles(0, true);

      expect(provider.currentFiles.map((file) => file.originalName), [
        'old.txt',
      ]);
    });

    tearDown(() async {
      await provider.cancelScan();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('preserves unselected state after rename', () async {
      await provider.renameOneFile(provider.currentFiles.single, 'new.txt');

      expect(provider.currentFiles.map((file) => file.originalName), [
        'new.txt',
      ]);
      expect(provider.currentFiles.single.isSelected, false);
    });

    test('preserves selected state after rename', () async {
      provider.toggleSelection(provider.currentFiles.single);

      await provider.renameOneFile(provider.currentFiles.single, 'new.txt');

      expect(provider.currentFiles.map((file) => file.originalName), [
        'new.txt',
      ]);
      expect(provider.currentFiles.single.isSelected, true);
    });
  });

  group('DirectoryProvider.openDroppedDirectoryPath', () {
    late Directory tempDir;
    late Directory droppedDir;
    late File droppedFile;
    late DirectoryProvider provider;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('renamery_drop_');
      droppedDir = Directory('${tempDir.path}${Platform.pathSeparator}folder')
        ..createSync();
      droppedFile = File('${tempDir.path}${Platform.pathSeparator}file.txt')
        ..writeAsStringSync('file');
      File('${droppedDir.path}${Platform.pathSeparator}inside.txt')
          .writeAsStringSync('inside');

      provider = DirectoryProvider();
    });

    tearDown(() async {
      await provider.cancelScan();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('opens a dropped directory path on desktop platforms', () async {
      if (!provider.supportsExternalFolderDrop) return;

      final message = await provider.openDroppedDirectoryPath(droppedDir.path);

      expect(message, isNull);
      expect(provider.currentDirectory?.path, droppedDir.path);
      expect(provider.currentFiles.map((file) => file.originalName), [
        'inside.txt',
      ]);
    });

    test('rejects a dropped file path', () async {
      if (!provider.supportsExternalFolderDrop) return;

      final message = await provider.openDroppedDirectoryPath(droppedFile.path);

      expect(message, contains('フォルダ'));
      expect(provider.currentDirectory, isNull);
    });
  });
}

List<bool> _selection(DirectoryProvider provider) =>
    provider.currentFiles.map((file) => file.isSelected).toList();
