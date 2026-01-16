import 'dart:io';

enum FileStatus { original, renamed, error, pending }

class FileModel {
  final FileSystemEntity entity;
  final String originalName;
  final String parentPath;

  String _newName;
  FileStatus _status;
  String? _errorMessage;

  FileModel({required this.entity})
      : originalName = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty),
        parentPath = entity.parent.path,
        _newName = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty),
        _status = FileStatus.original;

  bool isSelected = false;

  String get newName => _newName;
  FileStatus get status => _status;
  String? get errorMessage => _errorMessage;

  // 新しい名前の予定を設定（プレビュー用）
  void setNewName(String name) {
    _newName = name;
    _status = FileStatus.pending;
  }

  // リネーム成功としてマーク
  void markRenamed() {
    _status = FileStatus.renamed;
  }

  // 失敗としてマーク
  void markError(String message) {
    _status = FileStatus.error;
    _errorMessage = message;
  }

  // Helpers for UI
  String get size {
    if (entity is File) {
      final len = (entity as File).lengthSync();
      if (len < 1024) return '$len B';
      return '${(len / 1024).ceil()} KB';
    }
    return '';
  }

  String get relativePath {
    // For now, return empty or relative from parent?
    // Namery shows relative path if recursive.
    // We store parentPath. If we want relative to root search dir, we need to pass root.
    // For now, leave empty or show parent if different from current context (not easily known here without passing context).
    // Let's just return empty for flat list or a placeholder.
    return '';
  }

  String get fileType {
    if (entity is Directory) return 'Folder';
    final ext = entity.uri.pathSegments.last.split('.').last.toUpperCase();
    return '$ext File';
  }

  String get dateModified {
    try {
      final dt = entity.statSync().modified;
      // Simple Format: yyyy/MM/dd HH:mm
      return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  String get attributes {
    // Windows attributes not easily accessible via standard dart:io Stat without FFI or running command.
    // We can show '---A' placeholder or simple RW/RO.
    // custom implementation required for full attributes.
    // For now: D---- or ---- (Directory vs File)
    String attr = '';
    try {
      final stat = entity.statSync();
      attr += (entity is Directory) ? 'D' : '-';
      attr += '-'; // Archive?
      attr += (stat.mode & 0x80) == 0
          ? 'R'
          : '-'; // ReadOnly check (mode logic varies)
      // Dart StatMode is restricted.
      // Let's just return simplified.
      return (entity is Directory) ? 'D----' : '---A-';
    } catch (e) {
      return '';
    }
  }
}
