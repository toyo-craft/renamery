import 'dart:typed_data';

import 'web_file_system_types.dart';

WebFileSystemClient createWebFileSystemClient() =>
    const _UnsupportedWebFileSystemClient();

class _UnsupportedWebFileSystemClient implements WebFileSystemClient {
  const _UnsupportedWebFileSystemClient();

  @override
  bool get isSupported => false;

  @override
  Future<WebSavedDirectory?> pickDirectory() async => null;

  @override
  Future<List<WebSavedDirectory>> listSavedDirectories() async => const [];

  @override
  Future<void> forgetSavedDirectory(String id) async {}

  @override
  Future<String> requestPermission(Object handle) async => 'denied';

  @override
  Future<List<WebFileEntry>> listDirectory(
    Object directoryHandle,
    String relativePath,
    bool recursive,
  ) async =>
      const [];

  @override
  Future<Uint8List> readFileBytes(Object fileHandle, int limit) async {
    throw UnsupportedError('File System Access API is unavailable.');
  }

  @override
  Future<void> renameFile({
    required Object parentHandle,
    required String oldName,
    required String newName,
  }) async {
    throw UnsupportedError('File System Access API is unavailable.');
  }
}
