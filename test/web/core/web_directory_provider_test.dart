// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:renamery/core/directory_provider_web.dart';
import 'package:renamery/core/web_file_system_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Web DirectoryProvider', () {
    test('unsupported browser reports an error without changing directory',
        () async {
      final fs = FakeWebFileSystemClient(isSupported: false);
      final provider = DirectoryProvider(fileSystem: fs);

      await provider.pickLocalDirectory();

      expect(provider.errorMessage, contains('対応していません'));
      expect(provider.currentDirectory, isNull);
      expect(provider.currentFiles, isEmpty);
      expect(provider.isLoading, false);
    });

    test('loads saved directories when File System Access API is supported',
        () async {
      final root = FakeHandle('root');
      final fs = FakeWebFileSystemClient()
        ..savedDirectories.add(savedDirectory('1', 'Work', root));

      final provider = DirectoryProvider(fileSystem: fs);

      await provider.loadSavedDirectories();

      expect(provider.savedDirectories.map((directory) => directory.name), [
        'Work',
      ]);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, false);
    });

    test('picking a local directory opens the root and lists children',
        () async {
      final root = FakeHandle('root');
      final folder = FakeHandle('folder');
      final fs = FakeWebFileSystemClient()
        ..pickResult = savedDirectory('1', 'Root', root)
        ..savedDirectories.add(savedDirectory('1', 'Root', root))
        ..entries[root] = [
          directoryEntry(name: 'Images', handle: folder, parent: root),
          fileEntry(name: 'old.txt', parent: root, size: 12),
        ];

      final provider = DirectoryProvider(fileSystem: fs);

      await provider.pickLocalDirectory();

      expect(provider.currentDirectory?.name, 'Root');
      expect(provider.breadcrumbs.map((breadcrumb) => breadcrumb.name), [
        'Root',
      ]);
      expect(provider.currentFiles.map((entry) => entry.name), [
        'Images',
        'old.txt',
      ]);
      expect(provider.savedDirectories.map((directory) => directory.name), [
        'Root',
      ]);
    });

    test('opening saved directory requests permission when needed', () async {
      final root = FakeHandle('root');
      final fs = FakeWebFileSystemClient()
        ..permissionResults[root] = 'granted'
        ..entries[root] = [
          fileEntry(name: 'a.txt', parent: root),
        ];

      final provider = DirectoryProvider(fileSystem: fs);

      await provider.openSavedDirectory(
        savedDirectory('1', 'Root', root, permission: 'prompt'),
      );

      expect(fs.requestedPermissions, [root]);
      expect(provider.currentDirectory?.name, 'Root');
      expect(provider.currentFiles.map((entry) => entry.name), ['a.txt']);
    });

    test('opening saved directory stops when permission is denied', () async {
      final root = FakeHandle('root');
      final fs = FakeWebFileSystemClient()..permissionResults[root] = 'denied';

      final provider = DirectoryProvider(fileSystem: fs);

      await provider.openSavedDirectory(
        savedDirectory('1', 'Root', root, permission: 'prompt'),
      );

      expect(fs.requestedPermissions, [root]);
      expect(provider.currentDirectory, isNull);
      expect(provider.errorMessage, contains('許可されませんでした'));
    });

    test('opening a child directory updates breadcrumbs and file list',
        () async {
      final root = FakeHandle('root');
      final child = FakeHandle('child');
      final fs = FakeWebFileSystemClient()
        ..pickResult = savedDirectory('1', 'Root', root)
        ..entries[root] = [
          directoryEntry(name: 'Child', handle: child, parent: root),
        ]
        ..entries[child] = [
          fileEntry(name: 'inside.txt', parent: child),
        ];

      final provider = DirectoryProvider(fileSystem: fs);

      await provider.pickLocalDirectory();
      await provider.openDirectory(provider.currentFiles.single);

      expect(provider.breadcrumbs.map((breadcrumb) => breadcrumb.name), [
        'Root',
        'Child',
      ]);
      expect(provider.currentFiles.map((entry) => entry.name), ['inside.txt']);
      expect(provider.currentFiles.single.parentPath, 'Root/Child');
      expect(provider.currentFiles.single.displayRelativePath, '');
    });

    test('opening breadcrumb returns to parent directory', () async {
      final root = FakeHandle('root');
      final child = FakeHandle('child');
      final fs = FakeWebFileSystemClient()
        ..pickResult = savedDirectory('1', 'Root', root)
        ..entries[root] = [
          directoryEntry(name: 'Child', handle: child, parent: root),
        ]
        ..entries[child] = [
          fileEntry(name: 'inside.txt', parent: child),
        ];

      final provider = DirectoryProvider(fileSystem: fs);

      await provider.pickLocalDirectory();
      await provider.openDirectory(provider.currentFiles.single);
      await provider.openBreadcrumb(0);

      expect(provider.breadcrumbs.map((breadcrumb) => breadcrumb.name), [
        'Root',
      ]);
      expect(provider.currentFiles.map((entry) => entry.name), ['Child']);
    });

    test('recursive search includes files in child directories', () async {
      final root = FakeHandle('root');
      final child = FakeHandle('child');
      final fs = FakeWebFileSystemClient()
        ..pickResult = savedDirectory('1', 'Root', root)
        ..entries[root] = [
          directoryEntry(name: 'Child', handle: child, parent: root),
          fileEntry(name: 'root.txt', parent: root),
        ]
        ..entries[child] = [
          fileEntry(name: 'inside.txt', parent: child),
        ];

      final provider = DirectoryProvider(fileSystem: fs);

      await provider.pickLocalDirectory();
      expect(provider.currentFiles.map((entry) => entry.name), [
        'Child',
        'root.txt',
      ]);

      await provider.updateFilterSettings(recursive: true);

      expect(provider.currentFiles.map((entry) => entry.name), [
        'Child',
        'inside.txt',
        'root.txt',
      ]);
      final inside = provider.currentFiles[1];
      expect(inside.parentPath, 'Root/Child');
      expect(inside.displayRelativePath, 'Child');
      expect(provider.directoryEntries.map((entry) => entry.name), [
        'Child',
        'root.txt',
      ]);
    });

    test('selection toggles and selectAll update selected count', () async {
      final root = FakeHandle('root');
      final fs = FakeWebFileSystemClient()
        ..pickResult = savedDirectory('1', 'Root', root)
        ..entries[root] = [
          fileEntry(name: 'a.txt', parent: root),
          fileEntry(name: 'b.txt', parent: root),
        ];

      final provider = DirectoryProvider(fileSystem: fs);

      await provider.pickLocalDirectory();

      provider.toggleSelection(provider.currentFiles.first);
      expect(provider.selectedFilesCount, 1);

      provider.selectAll(true);
      expect(provider.selectedFilesCount, 2);

      provider.selectAll(false);
      expect(provider.selectedFilesCount, 0);
    });

    test('replace preview applies to files only', () async {
      final root = FakeHandle('root');
      final folder = FakeHandle('folder');
      final fs = FakeWebFileSystemClient()
        ..pickResult = savedDirectory('1', 'Root', root)
        ..entries[root] = [
          directoryEntry(name: 'old-folder', handle: folder, parent: root),
          fileEntry(name: 'old-file.txt', parent: root),
        ];

      final provider = DirectoryProvider(fileSystem: fs);

      await provider.pickLocalDirectory();
      provider.selectAll(true);
      provider.applyReplacePreview(
        find: 'old',
        replace: 'new',
        selectedOnly: true,
      );

      expect(provider.currentFiles[0].newName, 'old-folder');
      expect(provider.currentFiles[1].newName, 'new-file.txt');
    });

    test('folder visibility filter does not hide navigation directory entries',
        () async {
      final root = FakeHandle('root');
      final folder = FakeHandle('folder');
      final fs = FakeWebFileSystemClient()
        ..pickResult = savedDirectory('1', 'Root', root)
        ..entries[root] = [
          directoryEntry(name: 'Folder', handle: folder, parent: root),
          fileEntry(name: 'file.txt', parent: root),
        ];

      final provider = DirectoryProvider(fileSystem: fs);

      await provider.pickLocalDirectory();
      provider.updateFilterSettings(showFolders: false);

      expect(provider.currentFiles.map((entry) => entry.name), ['file.txt']);
      expect(
        provider.directoryEntries.where((entry) => entry.isDirectory),
        hasLength(1),
      );
    });

    test('numbering preview keeps extensions and skips directories', () async {
      final root = FakeHandle('root');
      final folder = FakeHandle('folder');
      final fs = FakeWebFileSystemClient()
        ..pickResult = savedDirectory('1', 'Root', root)
        ..entries[root] = [
          directoryEntry(name: 'Folder', handle: folder, parent: root),
          fileEntry(name: 'a.txt', parent: root),
          fileEntry(name: 'b.jpg', parent: root),
        ];

      final provider = DirectoryProvider(fileSystem: fs);

      await provider.pickLocalDirectory();
      provider.applyNumberingPreview(
        baseName: 'photo_',
        startNumber: 7,
        digits: 3,
        selectedOnly: false,
      );

      expect(provider.currentFiles[0].newName, 'Folder');
      expect(provider.currentFiles[1].newName, 'photo_007.txt');
      expect(provider.currentFiles[2].newName, 'photo_008.jpg');
    });

    test('invalid new names disable execution', () async {
      final root = FakeHandle('root');
      final fs = FakeWebFileSystemClient()
        ..pickResult = savedDirectory('1', 'Root', root)
        ..entries[root] = [
          fileEntry(name: 'a.txt', parent: root),
          fileEntry(name: 'b.txt', parent: root),
        ];

      final provider = DirectoryProvider(fileSystem: fs);

      await provider.pickLocalDirectory();
      final file = provider.currentFiles.first;
      provider.toggleSelection(file);

      provider.setNewName(file, '');
      expect(file.errorMessage, contains('入力'));
      expect(provider.canExecute, false);

      provider.setNewName(file, 'bad/name.txt');
      expect(file.errorMessage, contains('/'));
      expect(provider.canExecute, false);

      provider.setNewName(file, 'b.txt');
      expect(file.errorMessage, contains('同じ名前'));
      expect(provider.canExecute, false);
    });

    test('duplicate preview names disable execution', () async {
      final root = FakeHandle('root');
      final fs = FakeWebFileSystemClient()
        ..pickResult = savedDirectory('1', 'Root', root)
        ..entries[root] = [
          fileEntry(name: 'a.txt', parent: root),
          fileEntry(name: 'b.txt', parent: root),
        ];

      final provider = DirectoryProvider(fileSystem: fs);

      await provider.pickLocalDirectory();
      provider.selectAll(true);
      provider.setNewName(provider.currentFiles[0], 'same.txt');
      provider.setNewName(provider.currentFiles[1], 'same.txt');

      expect(provider.currentFiles[1].errorMessage, contains('同じ名前'));
      expect(provider.canExecute, false);
    });

    test('directory rename is supported', () async {
      final root = FakeHandle('root');
      final folder = FakeHandle('folder');
      final fs = FakeWebFileSystemClient()
        ..pickResult = savedDirectory('1', 'Root', root)
        ..entries[root] = [
          directoryEntry(name: 'Folder', handle: folder, parent: root),
        ];

      final provider = DirectoryProvider(fileSystem: fs);

      await provider.pickLocalDirectory();
      final folderEntry = provider.currentFiles.single;
      provider.toggleSelection(folderEntry);
      provider.setNewName(folderEntry, 'Renamed');

      expect(folderEntry.errorMessage, isNull);
      expect(provider.canExecute, true);

      final count = await provider.executeRename();

      expect(count, 1);
      expect(fs.renameCalls, [
        const RenameCall(
          parentId: 'root',
          oldName: 'Folder',
          newName: 'Renamed',
        ),
      ]);
      expect(provider.currentFiles.map((entry) => entry.name), ['Renamed']);
    });

    test('canExecute requires a selected changed valid entry', () async {
      final root = FakeHandle('root');
      final fs = FakeWebFileSystemClient()
        ..pickResult = savedDirectory('1', 'Root', root)
        ..entries[root] = [
          fileEntry(name: 'old.txt', parent: root),
        ];

      final provider = DirectoryProvider(fileSystem: fs);

      await provider.pickLocalDirectory();
      final file = provider.currentFiles.single;

      provider.setNewName(file, 'new.txt');
      expect(provider.canExecute, false);

      provider.toggleSelection(file);
      expect(provider.canExecute, true);

      provider.setNewName(file, 'old.txt');
      expect(provider.canExecute, false);
    });

    test(
        'executeRename calls renameFile for selected changed valid entries only',
        () async {
      final root = FakeHandle('root');
      final folder = FakeHandle('folder');
      final fs = FakeWebFileSystemClient()
        ..pickResult = savedDirectory('1', 'Root', root)
        ..entries[root] = [
          directoryEntry(name: 'Folder', handle: folder, parent: root),
          fileEntry(name: 'old.txt', parent: root),
          fileEntry(name: 'unchanged.txt', parent: root),
        ];

      final provider = DirectoryProvider(fileSystem: fs);

      await provider.pickLocalDirectory();

      final folderEntry = provider.currentFiles[0];
      final changedFile = provider.currentFiles[1];
      final unchangedFile = provider.currentFiles[2];

      provider.toggleSelection(folderEntry);
      provider.toggleSelection(changedFile);
      provider.toggleSelection(unchangedFile);
      provider.setNewName(folderEntry, 'Renamed');
      provider.setNewName(changedFile, 'new.txt');

      final count = await provider.executeRename();

      expect(count, 2);
      expect(fs.renameCalls, [
        const RenameCall(
          parentId: 'root',
          oldName: 'Folder',
          newName: 'Renamed',
        ),
        const RenameCall(
          parentId: 'root',
          oldName: 'old.txt',
          newName: 'new.txt',
        ),
      ]);
      expect(provider.currentFiles.map((entry) => entry.name), [
        'Renamed',
        'new.txt',
        'unchanged.txt',
      ]);
      expect(provider.canUndo, true);
    });

    test('renameOneFile calls renameFile immediately', () async {
      final root = FakeHandle('root');
      final fs = FakeWebFileSystemClient()
        ..pickResult = savedDirectory('1', 'Root', root)
        ..entries[root] = [
          fileEntry(name: 'old.txt', parent: root),
        ];

      final provider = DirectoryProvider(fileSystem: fs);

      await provider.pickLocalDirectory();
      await provider.renameOneFile(provider.currentFiles.single, 'new.txt');

      expect(fs.renameCalls, [
        const RenameCall(
          parentId: 'root',
          oldName: 'old.txt',
          newName: 'new.txt',
        ),
      ]);
      expect(provider.currentFiles.map((entry) => entry.name), ['new.txt']);
      expect(provider.canUndo, true);
    });

    test('renameOneFile calls renameFile immediately for a directory',
        () async {
      final root = FakeHandle('root');
      final folder = FakeHandle('folder');
      final fs = FakeWebFileSystemClient()
        ..pickResult = savedDirectory('1', 'Root', root)
        ..entries[root] = [
          directoryEntry(name: 'Folder', handle: folder, parent: root),
        ];

      final provider = DirectoryProvider(fileSystem: fs);

      await provider.pickLocalDirectory();
      await provider.renameOneFile(provider.currentFiles.single, 'Renamed');

      expect(fs.renameCalls, [
        const RenameCall(
          parentId: 'root',
          oldName: 'Folder',
          newName: 'Renamed',
        ),
      ]);
      expect(provider.currentFiles.map((entry) => entry.name), ['Renamed']);
      expect(provider.canUndo, true);
    });

    test('undo reverts the last inline rename', () async {
      final root = FakeHandle('root');
      final fs = FakeWebFileSystemClient()
        ..pickResult = savedDirectory('1', 'Root', root)
        ..entries[root] = [
          fileEntry(name: 'old.txt', parent: root),
        ];

      final provider = DirectoryProvider(fileSystem: fs);

      await provider.pickLocalDirectory();
      await provider.renameOneFile(provider.currentFiles.single, 'new.txt');
      final result = await provider.undo();

      expect(result['count'], 1);
      expect(result['errors'], isEmpty);
      expect(fs.renameCalls, [
        const RenameCall(
          parentId: 'root',
          oldName: 'old.txt',
          newName: 'new.txt',
        ),
        const RenameCall(
          parentId: 'root',
          oldName: 'new.txt',
          newName: 'old.txt',
        ),
      ]);
      expect(provider.currentFiles.map((entry) => entry.name), ['old.txt']);
      expect(provider.canUndo, false);
    });

    test('executeRename does not run when selected entries include errors',
        () async {
      final root = FakeHandle('root');
      final fs = FakeWebFileSystemClient()
        ..pickResult = savedDirectory('1', 'Root', root)
        ..entries[root] = [
          fileEntry(name: 'ok.txt', parent: root),
          fileEntry(name: 'other.txt', parent: root),
        ];

      final provider = DirectoryProvider(fileSystem: fs);

      await provider.pickLocalDirectory();
      provider.selectAll(true);
      provider.setNewName(provider.currentFiles[0], 'renamed.txt');
      provider.setNewName(provider.currentFiles[1], 'renamed.txt');

      final count = await provider.executeRename();

      expect(count, 0);
      expect(fs.renameCalls, isEmpty);
    });

    test('executeRename keeps failed rename count out of result', () async {
      final root = FakeHandle('root');
      final fs = FakeWebFileSystemClient()
        ..pickResult = savedDirectory('1', 'Root', root)
        ..failingOldNames.add('bad.txt')
        ..entries[root] = [
          fileEntry(name: 'ok.txt', parent: root),
          fileEntry(name: 'bad.txt', parent: root),
        ];

      final provider = DirectoryProvider(fileSystem: fs);

      await provider.pickLocalDirectory();
      provider.selectAll(true);
      provider.setNewName(provider.currentFiles[0], 'renamed.txt');
      provider.setNewName(provider.currentFiles[1], 'failed.txt');

      final count = await provider.executeRename();

      expect(count, 1);
      expect(fs.renameCalls, [
        const RenameCall(
          parentId: 'root',
          oldName: 'ok.txt',
          newName: 'renamed.txt',
        ),
        const RenameCall(
          parentId: 'root',
          oldName: 'bad.txt',
          newName: 'failed.txt',
        ),
      ]);
    });
  });
}

class FakeHandle {
  const FakeHandle(this.id);

  final String id;

  @override
  String toString() => id;
}

class RenameCall {
  const RenameCall({
    required this.parentId,
    required this.oldName,
    required this.newName,
  });

  final String parentId;
  final String oldName;
  final String newName;

  @override
  bool operator ==(Object other) {
    return other is RenameCall &&
        other.parentId == parentId &&
        other.oldName == oldName &&
        other.newName == newName;
  }

  @override
  int get hashCode => Object.hash(parentId, oldName, newName);

  @override
  String toString() => '$parentId:$oldName->$newName';
}

class FakeWebFileSystemClient implements WebFileSystemClient {
  FakeWebFileSystemClient({this.isSupported = true});

  @override
  final bool isSupported;

  WebSavedDirectory? pickResult;
  final List<WebSavedDirectory> savedDirectories = [];
  final Map<Object, List<WebFileEntry>> entries = {};
  final Map<Object, String> permissionResults = {};
  final Set<String> failingOldNames = {};
  final List<Object> requestedPermissions = [];
  final List<RenameCall> renameCalls = [];

  @override
  Future<WebSavedDirectory?> pickDirectory() async => pickResult;

  @override
  Future<List<WebSavedDirectory>> listSavedDirectories() async {
    return List<WebSavedDirectory>.from(savedDirectories);
  }

  @override
  Future<String> requestPermission(Object handle) async {
    requestedPermissions.add(handle);
    return permissionResults[handle] ?? 'denied';
  }

  @override
  Future<List<WebFileEntry>> listDirectory(
    Object directoryHandle,
    String relativePath,
    bool recursive,
  ) async {
    final direct = (entries[directoryHandle] ?? const [])
        .map((entry) => _withRelativeBase(entry, relativePath))
        .toList();
    if (!recursive) return direct;

    final result = <WebFileEntry>[];
    for (final entry in direct) {
      result.add(entry);
      if (entry.isDirectory) {
        final children = await listDirectory(
          entry.handle,
          entry.relativePath,
          true,
        );
        result.addAll(children);
      }
    }
    return result;
  }

  WebFileEntry _withRelativeBase(WebFileEntry entry, String base) {
    final relativePath = base.isEmpty || entry.relativePath.startsWith('$base/')
        ? entry.relativePath
        : '$base/${entry.relativePath}';
    return WebFileEntry(
      name: entry.name,
      relativePath: relativePath,
      kind: entry.kind,
      handle: entry.handle,
      parentHandle: entry.parentHandle,
      size: entry.size,
      lastModified: entry.lastModified,
    );
  }

  @override
  Future<void> renameFile({
    required Object parentHandle,
    required String oldName,
    required String newName,
  }) async {
    renameCalls.add(
      RenameCall(
        parentId: (parentHandle as FakeHandle).id,
        oldName: oldName,
        newName: newName,
      ),
    );

    if (failingOldNames.contains(oldName)) {
      throw StateError('failed file: $oldName');
    }

    final list = entries[parentHandle];
    if (list == null) return;

    final index = list.indexWhere((entry) => entry.name == oldName);
    if (index == -1) {
      throw StateError('missing file: $oldName');
    }

    final old = list[index];
    list[index] = WebFileEntry(
      name: newName,
      relativePath: old.relativePath.replaceFirst(oldName, newName),
      kind: old.kind,
      handle: old.handle,
      parentHandle: old.parentHandle,
      size: old.size,
      lastModified: old.lastModified,
    );
  }
}

WebSavedDirectory savedDirectory(
  String id,
  String name,
  Object handle, {
  String permission = 'granted',
}) {
  return WebSavedDirectory(
    id: id,
    name: name,
    handle: handle,
    permission: permission,
    lastUsedAt: null,
  );
}

WebFileEntry fileEntry({
  required String name,
  required Object parent,
  int? size,
}) {
  return WebFileEntry(
    name: name,
    relativePath: name,
    kind: WebEntryKind.file,
    handle: FakeHandle('file:$name'),
    parentHandle: parent,
    size: size,
  );
}

WebFileEntry directoryEntry({
  required String name,
  required Object handle,
  required Object parent,
}) {
  return WebFileEntry(
    name: name,
    relativePath: name,
    kind: WebEntryKind.directory,
    handle: handle,
    parentHandle: parent,
  );
}
