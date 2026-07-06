import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:printing/printing.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

import '../../core/file_model.dart';
import 'preview_document_view.dart';

Widget buildPlatformThumbnailContent(
  BuildContext context,
  FileModel file,
  AppLocalizations l10n,
  String extension,
) {
  final path = file.path;
  if (_imageExtensions.contains(extension)) {
    return Image.file(
      io.File(path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.broken_image, size: 16),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return const Icon(Icons.image, color: Colors.grey, size: 24);
      },
    );
  }
  if (extension == 'svg') {
    return FutureBuilder<Uint8List>(
      future: io.File(path).readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SvgPicture.memory(snapshot.data!, fit: BoxFit.contain);
        }
        return const Icon(Icons.image, color: Colors.grey, size: 24);
      },
    );
  }
  if (extension == 'pdf') {
    return buildPlatformPdfPreview(context, file, l10n, isThumbnail: true);
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
  if (file.isDirectory) {
    return const Icon(Icons.folder, color: Colors.amber, size: 24);
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
  return Padding(
    padding: const EdgeInsets.all(4.0),
    child: Image.file(
      io.File(file.path),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          PreviewDocumentMessage(message: l10n.labelPreviewImageLoadFailed),
    ),
  );
}

Widget buildPlatformSvgPreview(
  BuildContext context,
  FileModel file,
  AppLocalizations l10n,
) {
  return FutureBuilder<Uint8List>(
    future: io.File(file.path).readAsBytes(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return PreviewDocumentMessage(
            message: l10n.labelPreviewImageLoadFailed);
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
  return _PdfPreview(file: file, l10n: l10n, isThumbnail: isThumbnail);
}

bool canReadTextPreview(FileModel file, String extension) => !file.isDirectory;

bool canListArchivePreview(FileModel file, String extension) {
  return !file.isDirectory && extension == 'zip';
}

Future<String> readPlatformTextPreview(
  FileModel file,
  AppLocalizations l10n, {
  int limit = 2048,
}) async {
  try {
    final target = io.File(file.path);
    final len = await target.length();
    final stream = target.openRead(0, limit);
    final chunks = await stream.toList();
    final bytes = chunks.expand((element) => element).toList();
    if (bytes.contains(0)) {
      return l10n.labelPreviewBinaryError;
    }
    final content = utf8.decode(bytes, allowMalformed: true);
    if (len > limit) {
      final sizeStr = (len / 1024).toStringAsFixed(1);
      return '$content\n\n${l10n.labelPreviewOmitted(sizeStr)}';
    }
    return content;
  } catch (_) {
    return l10n.labelPreviewBinaryError;
  }
}

Future<List<String>> listPlatformArchiveFiles(FileModel file) async {
  try {
    final bytes = await io.File(file.path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    return archive.files
        .take(20)
        .map((file) =>
            '  ${file.name}${(!file.isFile || file.name.endsWith('/')) ? "" : ""}')
        .toList();
  } catch (_) {
    return [];
  }
}

String unsupportedPreviewMessage(
  FileModel file,
  String extension,
  AppLocalizations l10n,
) {
  return l10n.labelPreviewUnavailable;
}

class _PdfPreview extends StatefulWidget {
  const _PdfPreview({
    required this.file,
    required this.l10n,
    this.isThumbnail = false,
  });

  final FileModel file;
  final AppLocalizations l10n;
  final bool isThumbnail;

  @override
  State<_PdfPreview> createState() => _PdfPreviewState();
}

class _PdfPreviewState extends State<_PdfPreview> {
  Uint8List? _cachedImageData;
  bool _isLoading = false;
  String? _lastPath;

  @override
  void initState() {
    super.initState();
    _render();
  }

  @override
  void didUpdateWidget(_PdfPreview oldWidget) {
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
      final bytes = await io.File(path).readAsBytes();
      final dpi = widget.isThumbnail ? 72.0 : 144.0;
      final images = Printing.raster(bytes, pages: [0], dpi: dpi);

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
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _cachedImageData == null) {
      return widget.isThumbnail
          ? const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24)
          : const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_cachedImageData == null) {
      return PreviewDocumentMessage(
          message: widget.l10n.labelPreviewUnavailable);
    }

    return Container(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(widget.isThumbnail ? 0.0 : 4.0),
        child: Image.memory(
          _cachedImageData!,
          fit: widget.isThumbnail ? BoxFit.cover : BoxFit.contain,
        ),
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
