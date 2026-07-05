import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:printing/printing.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

import '../../core/file_model.dart';
import '../../core/web_file_system_service.dart';
import 'preview_document_view.dart';

final WebFileSystemService _fileSystem = WebFileSystemService();

Widget buildPlatformThumbnailContent(
  BuildContext context,
  FileModel file,
  AppLocalizations l10n,
  String extension,
) {
  if (file.isDirectory) {
    return const Icon(Icons.folder, color: Colors.amber, size: 24);
  }
  if (_imageExtensions.contains(extension)) {
    return FutureBuilder<Uint8List>(
      future: _readFileBytes(file, 0),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, size: 16),
          );
        }
        return const Icon(Icons.image, color: Colors.grey, size: 24);
      },
    );
  }
  if (extension == 'svg') {
    return FutureBuilder<Uint8List>(
      future: _readFileBytes(file, 0),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SvgPicture.memory(snapshot.data!, fit: BoxFit.contain);
        }
        return const Icon(Icons.image, color: Colors.grey, size: 24);
      },
    );
  }
  if (extension == 'pdf') {
    return const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24);
  }
  if (extension == 'zip') {
    return FutureBuilder<List<String>>(
      future: listPlatformArchiveFiles(file),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.all(2.0),
            child: Text(
              snapshot.data!.join('\n'),
              style: const TextStyle(
                fontSize: 5,
                fontFamily: 'Consolas',
                height: 1.0,
                color: Colors.black87,
              ),
              overflow: TextOverflow.fade,
            ),
          );
        }
        return const Icon(Icons.inventory_2_outlined,
            color: Colors.grey, size: 24);
      },
    );
  }
  final isTextExtension = _textExtensions.contains(extension);
  return FutureBuilder<String>(
    future: readPlatformTextPreview(file, l10n, limit: 200),
    builder: (context, snapshot) {
      if (snapshot.hasData &&
          snapshot.data != l10n.labelPreviewBinaryError &&
          (isTextExtension || snapshot.data!.length > 10)) {
        return Padding(
          padding: const EdgeInsets.all(2.0),
          child: Text(
            snapshot.data!,
            style: const TextStyle(
              fontSize: 6,
              fontFamily: 'Consolas',
              height: 1.1,
              color: Colors.black87,
            ),
            overflow: TextOverflow.fade,
          ),
        );
      }
      return const Icon(Icons.insert_drive_file, color: Colors.grey, size: 24);
    },
  );
}

Widget buildPlatformImagePreview(
  BuildContext context,
  FileModel file,
  AppLocalizations l10n,
  String extension,
) {
  return FutureBuilder<Uint8List>(
    future: _readFileBytes(file, 0),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return PreviewDocumentMessage(
          message: unsupportedPreviewMessage(file, extension),
        );
      }
      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: Image.memory(
          snapshot.data!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              PreviewDocumentMessage(message: l10n.labelPreviewImageLoadFailed),
        ),
      );
    },
  );
}

Widget buildPlatformSvgPreview(
  BuildContext context,
  FileModel file,
  AppLocalizations l10n,
) {
  return FutureBuilder<Uint8List>(
    future: _readFileBytes(file, 0),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return PreviewDocumentMessage(
          message: unsupportedPreviewMessage(file, 'svg'),
        );
      }
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: SvgPicture.memory(
          snapshot.data!,
          fit: BoxFit.contain,
          placeholderBuilder: (context) =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    },
  );
}

Widget buildPlatformPdfPreview(
  BuildContext context,
  FileModel file,
  AppLocalizations l10n, {
  bool isThumbnail = false,
}) {
  if (isThumbnail) {
    return const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24);
  }
  return _WebPdfPreview(file: file, l10n: l10n);
}

bool canReadTextPreview(FileModel file, String extension) {
  return !file.isDirectory && file.handle != null;
}

bool canListArchivePreview(FileModel file, String extension) {
  return !file.isDirectory && file.handle != null && extension == 'zip';
}

Future<String> readPlatformTextPreview(
  FileModel file,
  AppLocalizations l10n, {
  int limit = 2048,
}) async {
  try {
    final bytes = await _readFileBytes(file, limit);
    if (bytes.contains(0)) {
      return l10n.labelPreviewBinaryError;
    }
    final content = utf8.decode(bytes, allowMalformed: true);
    final totalSize = file.byteSize;
    if (totalSize != null && totalSize > limit) {
      final sizeStr = (totalSize / 1024).toStringAsFixed(1);
      return '$content\n\n... (Omitted, Total: $sizeStr KB)';
    }
    return content;
  } catch (_) {
    return l10n.labelPreviewBinaryError;
  }
}

Future<List<String>> listPlatformArchiveFiles(FileModel file) async {
  try {
    final bytes = await _readFileBytes(file, 0);
    final archive = ZipDecoder().decodeBytes(bytes);
    return archive.files
        .take(20)
        .map((file) =>
            '  ${file.name}${(!file.isFile || file.name.endsWith('/')) ? "" : ""}')
        .toList();
  } catch (_) {
    return const [];
  }
}

String unsupportedPreviewMessage(FileModel file, String extension) {
  final target =
      extension.isEmpty ? 'このファイル' : '${extension.toUpperCase()}ファイル';
  return 'Web版では$targetの内容プレビューは未対応です。\n'
      'ファイル名、種類、サイズなどの情報は一覧で確認できます。';
}

Future<Uint8List> _readFileBytes(FileModel file, int limit) async {
  final handle = file.handle;
  if (handle == null) {
    throw StateError('File handle is unavailable.');
  }
  return _fileSystem.readFileBytes(handle, limit);
}

class _WebPdfPreview extends StatefulWidget {
  const _WebPdfPreview({required this.file, required this.l10n});

  final FileModel file;
  final AppLocalizations l10n;

  @override
  State<_WebPdfPreview> createState() => _WebPdfPreviewState();
}

class _WebPdfPreviewState extends State<_WebPdfPreview> {
  Uint8List? _cachedImageData;
  bool _isLoading = false;
  String? _lastPath;

  @override
  void initState() {
    super.initState();
    _render();
  }

  @override
  void didUpdateWidget(_WebPdfPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _render();
    }
  }

  Future<void> _render() async {
    final path = widget.file.path;
    if (_lastPath == path && _cachedImageData != null) return;
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final bytes = await _readFileBytes(widget.file, 0);
      final images = Printing.raster(bytes, pages: [0], dpi: 144.0);
      await for (final image in images) {
        final data = await image.toPng();
        if (mounted) {
          setState(() {
            _cachedImageData = data;
            _isLoading = false;
            _lastPath = path;
          });
        }
        break;
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _cachedImageData = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _cachedImageData == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_cachedImageData == null) {
      return PreviewDocumentMessage(
        message: unsupportedPreviewMessage(widget.file, 'pdf'),
      );
    }
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Image.memory(_cachedImageData!, fit: BoxFit.contain),
      ),
    );
  }
}

const _imageExtensions = {'png', 'jpg', 'jpeg', 'bmp', 'gif', 'webp', 'ico'};

const _textExtensions = {
  'txt',
  'csv',
  'json',
  'ini',
  'log',
  'dart',
  'yaml',
  'md',
  'html',
  'xml',
  'sql',
  'js',
  'py',
  'css',
};
