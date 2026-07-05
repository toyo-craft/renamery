import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'web_file_system_types.dart';

WebFileSystemClient createWebFileSystemClient() => _JsWebFileSystemClient();

class _JsWebFileSystemClient implements WebFileSystemClient {
  @override
  bool get isSupported {
    try {
      return _bridgeIsSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<WebSavedDirectory?> pickDirectory() async {
    final result = await _bridgePickDirectory().toDart;
    if (result == null) return null;
    return _savedDirectoryFromJs(result);
  }

  @override
  Future<List<WebSavedDirectory>> listSavedDirectories() async {
    final result = await _bridgeListSavedDirectories().toDart;
    return result.toDart.map(_savedDirectoryFromJs).toList();
  }

  @override
  Future<void> forgetSavedDirectory(String id) async {
    await _bridgeForgetSavedDirectory(id).toDart;
  }

  @override
  Future<String> requestPermission(Object handle) async {
    final result =
        await _bridgeRequestDirectoryPermission(handle as JSObject).toDart;
    return result.toDart;
  }

  @override
  Future<List<WebFileEntry>> listDirectory(
    Object directoryHandle,
    String relativePath,
    bool recursive,
  ) async {
    final result = await _bridgeListDirectory(
      directoryHandle as JSObject,
      relativePath,
      recursive,
    ).toDart;
    return result.toDart.map(_entryFromJs).toList();
  }

  @override
  Future<Uint8List> readFileBytes(Object fileHandle, int limit) async {
    final result =
        await _bridgeReadFileBytes(fileHandle as JSObject, limit).toDart;
    return result.toDart;
  }

  @override
  Future<void> renameFile({
    required Object parentHandle,
    required String oldName,
    required String newName,
  }) async {
    await _bridgeRenameFile(parentHandle as JSObject, oldName, newName).toDart;
  }

  WebSavedDirectory _savedDirectoryFromJs(_JsSavedDirectory value) {
    final lastUsedRaw = value.lastUsedAt;
    DateTime? lastUsedAt;
    if (lastUsedRaw != null) {
      lastUsedAt = DateTime.fromMillisecondsSinceEpoch(lastUsedRaw.toInt());
    }
    return WebSavedDirectory(
      id: value.id,
      name: value.name,
      handle: value.handle,
      permission: value.permission,
      lastUsedAt: lastUsedAt,
    );
  }

  WebFileEntry _entryFromJs(_JsFileEntry value) {
    final sizeRaw = value.size;
    final modifiedRaw = value.lastModified;
    return WebFileEntry(
      name: value.name,
      relativePath: value.relativePath,
      kind: value.kind == 'directory'
          ? WebEntryKind.directory
          : WebEntryKind.file,
      handle: value.handle,
      parentHandle: value.parentHandle,
      size: sizeRaw?.toInt(),
      lastModified: modifiedRaw != null
          ? DateTime.fromMillisecondsSinceEpoch(modifiedRaw.toInt())
          : null,
    );
  }
}

extension type _JsSavedDirectory(JSObject _) implements JSObject {
  external String get id;
  external String get name;
  external JSObject get handle;
  external String get permission;
  external double? get lastUsedAt;
}

extension type _JsFileEntry(JSObject _) implements JSObject {
  external String get name;
  external String get relativePath;
  external String get kind;
  external JSObject get handle;
  external JSObject get parentHandle;
  external double? get size;
  external double? get lastModified;
}

@JS('renameryFs.isSupported')
external bool _bridgeIsSupported();

@JS('renameryFs.pickDirectory')
external JSPromise<_JsSavedDirectory?> _bridgePickDirectory();

@JS('renameryFs.listSavedDirectories')
external JSPromise<JSArray<_JsSavedDirectory>> _bridgeListSavedDirectories();

@JS('renameryFs.forgetSavedDirectory')
external JSPromise<JSAny?> _bridgeForgetSavedDirectory(String id);

@JS('renameryFs.requestDirectoryPermission')
external JSPromise<JSString> _bridgeRequestDirectoryPermission(JSObject handle);

@JS('renameryFs.listDirectory')
external JSPromise<JSArray<_JsFileEntry>> _bridgeListDirectory(
  JSObject handle,
  String relativePath,
  bool recursive,
);

@JS('renameryFs.readFileBytes')
external JSPromise<JSUint8Array> _bridgeReadFileBytes(
  JSObject fileHandle,
  int limit,
);

@JS('renameryFs.renameFile')
external JSPromise<JSAny?> _bridgeRenameFile(
  JSObject parentHandle,
  String oldName,
  String newName,
);
