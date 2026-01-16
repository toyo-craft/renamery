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
}
