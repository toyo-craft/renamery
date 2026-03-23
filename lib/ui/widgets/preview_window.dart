import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:archive/archive.dart';
import '../../core/file_model.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

class PreviewWindow extends StatelessWidget {
  final FileModel? file;
  final List<FileModel> selectedFiles;

  const PreviewWindow({super.key, this.file, this.selectedFiles = const []});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (selectedFiles.length > 1) {
      return _MultiSelectGridPreview(files: selectedFiles, l10n: l10n);
    }

    if (file == null) {
      return Center(
        child: Text(
          l10n.labelPreviewNoSelection,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    final path = file!.entity.path;
    final ext = path.contains('.') ? path.split('.').last.toLowerCase() : '';

    // 1. Image Preview
    if (['png', 'jpg', 'jpeg', 'bmp', 'gif', 'webp', 'ico'].contains(ext)) {
      return _ImagePreview(file: File(path), l10n: l10n);
    }

    // 2. SVG Preview
    if (ext == 'svg') {
      return _SvgPreview(file: File(path), l10n: l10n);
    }

    // 3. PDF Preview
    if (ext == 'pdf') {
      return _PdfPreview(file: File(path), l10n: l10n);
    }

    // 4. Archive Preview
    if (ext == 'zip') {
      return _ArchivePreview(file: File(path), l10n: l10n);
    }

    // 5. Text Preview (Default)
    return _TextPreview(file: File(path), l10n: l10n);
  }
}

class _MultiSelectGridPreview extends StatelessWidget {
  final List<FileModel> files;
  final AppLocalizations l10n;

  const _MultiSelectGridPreview({required this.files, required this.l10n});

  @override
  Widget build(BuildContext context) {
    const int maxDisplay = 9;
    final displayFiles = files.take(maxDisplay).toList();
    final remaining = files.length - maxDisplay;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        children: [
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: displayFiles.length,
            itemBuilder: (context, index) {
              final file = displayFiles[index];
              return _ThumbnailTile(file: file, l10n: l10n);
            },
          ),
          if (remaining > 0)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Theme.of(context).colorScheme.primary),
                ),
                child: Text(
                  '+$remaining',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThumbnailTile extends StatelessWidget {
  final FileModel file;
  final AppLocalizations l10n;

  const _ThumbnailTile({required this.file, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final path = file.entity.path;
    final ext = path.contains('.') ? path.split('.').last.toLowerCase() : '';

    Widget content;
    if (['png', 'jpg', 'jpeg', 'bmp', 'gif', 'webp', 'ico'].contains(ext)) {
      content = Image.file(File(path), fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 16));
    } else if (ext == 'svg') {
      content = SvgPicture.file(File(path), fit: BoxFit.contain, placeholderBuilder: (c) => const Icon(Icons.image, size: 16));
    } else if (ext == 'pdf') {
      // PDF もサムネイル表示に対応
      content = FutureBuilder<Uint8List?>(
        future: _renderThumbnail(path),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Icon(Icons.picture_as_pdf, color: Colors.red, size: 16);
          }
          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(snapshot.data!, fit: BoxFit.cover);
          }
          return const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24);
        },
      );
    } else if (ext == 'zip') {
      // ZIP もタイル表示に対応
      content = FutureBuilder<List<String>>(
        future: _listArchiveFiles(File(path)),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.all(2.0),
              child: Text(
                snapshot.data!.join('\n'),
                style: const TextStyle(fontSize: 5, fontFamily: 'Consolas', height: 1.0),
                overflow: TextOverflow.fade,
              ),
            );
          }
          return const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 24);
        },
      );
    } else if (file.entity is Directory) {
      content = const Icon(Icons.folder, color: Colors.amber, size: 24);
    } else {
      // テキスト系拡張子の判定
      final isTextExt = ['txt', 'csv', 'json', 'ini', 'log', 'dart', 'yaml', 'md', 'html', 'xml', 'sql', 'js', 'py', 'css'].contains(ext);
      
      // テキストファイルの可能性がある場合は中身をチラ見せ
      content = FutureBuilder<String>(
        future: _readText(File(path), l10n, limit: 200),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != l10n.labelPreviewBinaryError && (isTextExt || snapshot.data!.length > 10)) {
            return Padding(
              padding: const EdgeInsets.all(2.0),
              child: Text(
                snapshot.data!,
                style: const TextStyle(fontSize: 6, fontFamily: 'Consolas', height: 1.1),
                overflow: TextOverflow.fade,
              ),
            );
          }
          return const Icon(Icons.insert_drive_file, color: Colors.grey, size: 24);
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: content),
          // ファイル名オーバーレイ
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Text(
                  file.originalName,
                  style: const TextStyle(color: Colors.white, fontSize: 7, height: 1.1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _renderThumbnail(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      // サムネイル用なので低解像度で高速に
      final images = Printing.raster(bytes, pages: [0], dpi: 72);
      await for (final image in images) {
        return await image.toPng();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

class _ImagePreview extends StatelessWidget {
  final File file;
  final AppLocalizations l10n;

  const _ImagePreview({required this.file, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Center(child: Text(l10n.labelPreviewImageLoadFailed)),
      ),
    );
  }
}

class _SvgPreview extends StatelessWidget {
  final File file;
  final AppLocalizations l10n;

  const _SvgPreview({required this.file, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SvgPicture.file(
        file,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}

class _PdfPreview extends StatelessWidget {
  final File file;
  final AppLocalizations l10n;

  const _PdfPreview({required this.file, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _renderFirstPage(file.path),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(child: Text(l10n.labelPreviewUnavailable, style: const TextStyle(fontSize: 10, color: Colors.grey)));
        }
        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image.memory(
            snapshot.data!,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }

  Future<Uint8List?> _renderFirstPage(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      
      // raster を使用して1ページ目を取得
      final images = Printing.raster(bytes, pages: [0], dpi: 144);
      
      await for (final image in images) {
        return await image.toPng();
      }
      return null;
    } catch (e) {
      debugPrint('PDF Render Error (printing): $e');
      return null;
    }
  }
}

class _ArchivePreview extends StatelessWidget {
  final File file;
  final AppLocalizations l10n;

  const _ArchivePreview({required this.file, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _listArchiveFiles(file),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(l10n.labelPreviewUnavailable, style: const TextStyle(fontSize: 10, color: Colors.grey)));
        }
        
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Archive Contents:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                ],
              ),
              const Divider(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) => Text(
                    snapshot.data![index],
                    style: const TextStyle(fontSize: 11, fontFamily: 'Consolas'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<List<String>> _listArchiveFiles(File file) async {
  try {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    // 先頭20件までのファイル名を返す。ディレクトリ判定は名前の末尾または isFile を使用。
    return archive.files.take(20).map((f) => '  ${f.name}${(!f.isFile || f.name.endsWith('/')) ? "" : ""}').toList();
  } catch (e) {
    return [];
  }
}

class _TextPreview extends StatelessWidget {
  final File file;
  final AppLocalizations l10n;

  const _TextPreview({required this.file, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: FutureBuilder<String>(
        future: _readText(file, l10n),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 10)));
          }
          final text = snapshot.data ?? l10n.labelPreviewUnavailable;
          return SizedBox.expand(
            child: SingleChildScrollView(
              child: SelectableText(
                text,
                style: const TextStyle(fontSize: 11, fontFamily: 'Consolas'),
              ),
            ),
          );
        },
      ),
    );
  }
}

Future<String> _readText(File file, AppLocalizations l10n, {int limit = 2048}) async {
  try {
    final len = await file.length();
    final stream = file.openRead(0, limit);
    final chunks = await stream.toList();
    final bytes = chunks.expand((element) => element).toList();
    
    // バイナリチェック
    if (bytes.contains(0)) {
      return l10n.labelPreviewBinaryError;
    }

    String content = utf8.decode(bytes, allowMalformed: true);
    if (len > limit) {
      final sizeStr = (len / 1024).toStringAsFixed(1);
      return '$content\n\n... (Omitted, Total: $sizeStr KB)';
    }
    return content;
  } catch (e) {
    return l10n.labelPreviewBinaryError;
  }
}
