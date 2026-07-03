import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

enum FileStatus { original, renamed, error, pending }

class FileModel extends ChangeNotifier {
  final FileSystemEntity entity;
  final String originalName;
  final String parentPath;

  String _newName;
  FileStatus _status;
  String? _errorMessage;

  FileModel({required this.entity})
      : originalName = p.basename(entity.path),
        parentPath = p.dirname(entity.path),
        _newName = p.basename(entity.path),
        _status = FileStatus.original;

  bool _isSelected = false;
  bool _isCut = false;
  bool _hasPendingChanges = false;

  bool get isDirectory => entity is Directory;
  String get path => entity.path;

  bool get isSelected => _isSelected;
  set isSelected(bool value) => setSelected(value);

  void setSelected(bool value, {bool notify = true}) {
    if (_isSelected != value) {
      _isSelected = value;
      if (notify) {
        notifyListeners();
      } else {
        _hasPendingChanges = true;
      }
    }
  }

  bool get isCut => _isCut;
  set isCut(bool value) => setCut(value);

  void setCut(bool value, {bool notify = true}) {
    if (_isCut != value) {
      _isCut = value;
      if (notify) {
        notifyListeners();
      } else {
        _hasPendingChanges = true;
      }
    }
  }

  String get newName => _newName;
  FileStatus get status => _status;
  String? get errorMessage => _errorMessage;

  void setNewName(String name, {bool notify = true}) {
    if (_newName != name) {
      _newName = name;
      _status = FileStatus.pending;
      if (notify) {
        notifyListeners();
      } else {
        _hasPendingChanges = true;
      }
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

  bool _hasValidationError = false;
  String? _validationErrorMessage;
  bool get hasValidationError => _hasValidationError;
  String? get validationErrorMessage => _validationErrorMessage;

  void setValidationError(String? message, {bool notify = true}) {
    bool hasChanged = false;
    if (message != null) {
      if (!_hasValidationError || _validationErrorMessage != message) {
        _hasValidationError = true;
        _validationErrorMessage = message;
        hasChanged = true;
      }
    } else {
      if (_hasValidationError) {
        _hasValidationError = false;
        _validationErrorMessage = null;
        hasChanged = true;
      }
    }
    if (hasChanged) {
      if (notify) {
        notifyListeners();
      } else {
        _hasPendingChanges = true;
      }
    }
  }

  void notifyIfChanged() {
    if (_hasPendingChanges) {
      _hasPendingChanges = false;
      notifyListeners();
    }
  }

  String? _cachedSize;
  String get size {
    if (entity is! File) return '';
    if (_cachedSize != null) return _cachedSize!;
    try {
      final len = (entity as File).lengthSync();
      _cachedSize = len < 1024 ? '$len B' : '${(len / 1024).ceil()} KB';
    } catch (_) {
      _cachedSize = 'Locked';
    }
    return _cachedSize!;
  }

  String? _cachedFileType;
  String get fileType {
    if (entity is Directory) return 'Folder';
    if (_cachedFileType != null) return _cachedFileType!;
    try {
      final name = originalName;
      if (!name.contains('.')) return 'File';
      _cachedFileType = '${name.split('.').last.toUpperCase()} File';
    } catch (_) {
      _cachedFileType = 'File';
    }
    return _cachedFileType!;
  }

  String? _cachedDateModified;
  String get dateModified {
    if (_cachedDateModified != null) return _cachedDateModified!;
    try {
      final dt = entity.statSync().modified;
      _cachedDateModified =
          '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      _cachedDateModified = '';
    }
    return _cachedDateModified!;
  }

  String _displayRelativePath = '';
  String get displayRelativePath => _displayRelativePath;
  void setDisplayRelativePath(String path) {
    _displayRelativePath = path;
  }

  String _relativePath = '';
  String get relativePath => _relativePath;
  void setRelativePath(String path) {
    _relativePath = path;
  }

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
    notifyListeners();
  }

  String get attributes {
    String attr = (entity is Directory) ? 'd' : '-';
    attr += _isReadOnly ? 'r' : '-';
    attr += _isHidden ? 'h' : '-';
    attr += _isSystem ? 's' : '-';
    attr += _isArchive ? 'a' : '-';
    return attr;
  }
}
