import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

enum FileStatus { original, renamed, error, pending }

class FileModel extends ChangeNotifier {
  FileModel({
    dynamic entity,
    String? originalName,
    String? parentPath,
    this.isDirectory = false,
    this.modified,
    this.byteSize,
    this.handle,
    this.parentHandle,
  })  : entity = entity ??
            _WebFileEntity(_resolvePath(entity, originalName, parentPath)),
        originalName = originalName ??
            p.basename(_resolvePath(entity, originalName, parentPath)),
        parentPath =
            parentPath ?? _resolveParentPath(entity, originalName, parentPath),
        _newName = originalName ??
            p.basename(_resolvePath(entity, originalName, parentPath)),
        _status = FileStatus.original;

  final dynamic entity;
  final String originalName;
  final String parentPath;
  final bool isDirectory;
  final DateTime? modified;
  final int? byteSize;
  final Object? handle;
  final Object? parentHandle;

  String _newName;
  FileStatus _status;
  String? _errorMessage;
  bool _isSelected = false;
  bool _isCut = false;
  bool _hasPendingChanges = false;
  bool _hasValidationError = false;
  String? _validationErrorMessage;
  String _displayRelativePath = '';
  String _relativePath = '';

  String get path =>
      parentPath.isEmpty ? originalName : '$parentPath/$originalName';
  String get name => originalName;
  bool get isFile => !isDirectory;

  bool get isSelected => _isSelected;
  set isSelected(bool value) => setSelected(value);

  void setSelected(bool value, {bool notify = true}) {
    if (_isSelected == value) return;
    _isSelected = value;
    if (notify) {
      notifyListeners();
    } else {
      _hasPendingChanges = true;
    }
  }

  bool get isCut => _isCut;
  set isCut(bool value) => setCut(value);

  void setCut(bool value, {bool notify = true}) {
    if (_isCut == value) return;
    _isCut = value;
    if (notify) {
      notifyListeners();
    } else {
      _hasPendingChanges = true;
    }
  }

  String get newName => _newName;
  FileStatus get status => _status;
  String? get errorMessage => _errorMessage;

  void setNewName(String name, {bool notify = true}) {
    if (_newName == name) return;
    _newName = name;
    _status = FileStatus.pending;
    if (notify) {
      notifyListeners();
    } else {
      _hasPendingChanges = true;
    }
  }

  void markRenamed() {
    _status = FileStatus.renamed;
    notifyListeners();
  }

  void markError(String message) {
    _status = FileStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  bool get hasValidationError => _hasValidationError;
  String? get validationErrorMessage => _validationErrorMessage;

  void setValidationError(String? message, {bool notify = true}) {
    final changed = _validationErrorMessage != message;
    if (!changed) return;
    _hasValidationError = message != null;
    _validationErrorMessage = message;
    _errorMessage = message;
    if (notify) {
      notifyListeners();
    } else {
      _hasPendingChanges = true;
    }
  }

  void notifyIfChanged() {
    if (!_hasPendingChanges) return;
    _hasPendingChanges = false;
    notifyListeners();
  }

  String get size {
    if (isDirectory) return '';
    final len = byteSize;
    if (len == null) return '';
    return len < 1024 ? '$len B' : '${(len / 1024).ceil()} KB';
  }

  String get fileType {
    if (isDirectory) return 'Folder';
    if (!originalName.contains('.')) return 'File';
    return '${originalName.split('.').last.toUpperCase()} File';
  }

  String get dateModified {
    final dt = modified;
    if (dt == null) return '';
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String get displayRelativePath => _displayRelativePath;
  void setDisplayRelativePath(String path) {
    _displayRelativePath = path;
  }

  String get relativePath => _relativePath;
  void setRelativePath(String path) {
    _relativePath = path;
  }

  void setAttributes({
    bool readOnly = false,
    bool hidden = false,
    bool system = false,
    bool archive = false,
  }) {}

  String get attributes => isDirectory ? 'd----' : '-----';
}

String _resolvePath(dynamic entity, String? originalName, String? parentPath) {
  if (entity != null) return entity.path as String;
  if (parentPath == null || parentPath.isEmpty) return originalName ?? '';
  return '$parentPath/${originalName ?? ''}';
}

String _resolveParentPath(
    dynamic entity, String? originalName, String? parentPath) {
  if (parentPath != null) return parentPath;
  final path = _resolvePath(entity, originalName, parentPath);
  final parent = p.dirname(path);
  return parent == '.' ? '' : parent;
}

class _WebFileEntity {
  _WebFileEntity(this.path);

  final String path;
  Uri get uri => Uri(path: path);
}
