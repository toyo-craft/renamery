import 'web_file_system_service_stub.dart'
    if (dart.library.js_interop) 'web_file_system_service_js.dart'
    as implementation;
import 'web_file_system_types.dart';

export 'web_file_system_types.dart';

class WebFileSystemService implements WebFileSystemClient {
  WebFileSystemService()
      : _delegate = implementation.createWebFileSystemClient();

  final WebFileSystemClient _delegate;

  @override
  bool get isSupported => _delegate.isSupported;

  @override
  Future<WebSavedDirectory?> pickDirectory() => _delegate.pickDirectory();

  @override
  Future<List<WebSavedDirectory>> listSavedDirectories() =>
      _delegate.listSavedDirectories();

  @override
  Future<String> requestPermission(Object handle) =>
      _delegate.requestPermission(handle);

  @override
  Future<List<WebFileEntry>> listDirectory(
    Object directoryHandle,
    String relativePath,
  ) =>
      _delegate.listDirectory(directoryHandle, relativePath);

  @override
  Future<void> renameFile({
    required Object parentHandle,
    required String oldName,
    required String newName,
  }) =>
      _delegate.renameFile(
        parentHandle: parentHandle,
        oldName: oldName,
        newName: newName,
      );
}
