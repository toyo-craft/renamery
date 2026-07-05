enum WebEntryKind { file, directory }

enum WebEntryStatus { original, pending, renamed, error }

abstract class WebFileSystemClient {
  bool get isSupported;

  Future<WebSavedDirectory?> pickDirectory();
  Future<List<WebSavedDirectory>> listSavedDirectories();
  Future<void> forgetSavedDirectory(String id);
  Future<String> requestPermission(Object handle);
  Future<List<WebFileEntry>> listDirectory(
    Object directoryHandle,
    String relativePath,
    bool recursive,
  );
  Future<void> renameFile({
    required Object parentHandle,
    required String oldName,
    required String newName,
  });
}

class WebSavedDirectory {
  WebSavedDirectory({
    required this.id,
    required this.name,
    required this.handle,
    required this.permission,
    required this.lastUsedAt,
  });

  final String id;
  final String name;
  final Object handle;
  final String permission;
  final DateTime? lastUsedAt;

  bool get isGranted => permission == 'granted';
}

class WebFileEntry {
  WebFileEntry({
    required this.name,
    required this.relativePath,
    required this.kind,
    required this.handle,
    required this.parentHandle,
    this.size,
    this.lastModified,
  }) : newName = name;

  final String name;
  final String relativePath;
  final WebEntryKind kind;
  final Object handle;
  final Object parentHandle;
  final int? size;
  final DateTime? lastModified;

  String newName;
  bool isSelected = false;
  WebEntryStatus status = WebEntryStatus.original;
  String? errorMessage;

  bool get isDirectory => kind == WebEntryKind.directory;
  bool get isFile => kind == WebEntryKind.file;
  String get id => '$relativePath/$name';
}

class WebDirectoryLocation {
  WebDirectoryLocation({
    required this.name,
    required this.relativePath,
    required this.handle,
  });

  final String name;
  final String relativePath;
  final Object handle;
}
