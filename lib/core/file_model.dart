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

  // Validation Error (separate from operation error)
  bool _hasValidationError = false;
  String? _validationErrorMessage;

  bool get hasValidationError => _hasValidationError;
  String? get validationErrorMessage => _validationErrorMessage;

  void setValidationError(String? message) {
    if (message != null) {
      _hasValidationError = true;
      _validationErrorMessage = message;
    } else {
      _hasValidationError = false;
      _validationErrorMessage = null;
    }
  }

  // Helpers for UI
  String get size {
    if (entity is File) {
      try {
        final len = (entity as File).lengthSync();
        if (len < 1024) return '$len B';
        return '${(len / 1024).ceil()} KB';
      } catch (e) {
        return 'Locked'; // Indicate file is locked/inaccessible
      }
    }
    return '';
  }

  String _relativePath = '';
  String _displayRelativePath = ''; // For UI display (full relative path)

  String get relativePath => _relativePath;
  String get displayRelativePath => _displayRelativePath;

  void setRelativePath(String path) {
    _relativePath = path;
  }

  void setDisplayRelativePath(String path) {
    _displayRelativePath = path;
  }

  String get fileType {
    if (entity is Directory) return 'Folder';
    try {
      if (!entity.uri.pathSegments.last.contains('.')) return 'File';
      final ext = entity.uri.pathSegments.last.split('.').last.toUpperCase();
      return '$ext File';
    } catch (_) {
      return 'File';
    }
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

  // Attributes
  bool _isReadOnly = false;
  bool _isHidden = false;
  bool _isSystem = false;
  bool _isArchive = false;

  void setAttributes({
    bool readOnly = false,
    bool hidden = false,
    bool system = false,
    bool archive = false,
  }) {
    _isReadOnly = readOnly;
    _isHidden = hidden;
    _isSystem = system;
    _isArchive = archive;
  }

  String get attributes {
    String attr = '';
    attr += (entity is Directory) ? 'd' : '-';
    attr += _isReadOnly ? 'r' : '-';
    attr += _isHidden ? 'h' : '-';
    attr += _isSystem ? 's' : '-';
    attr += _isArchive ? 'a' : '-';
    return attr;
  }
}
