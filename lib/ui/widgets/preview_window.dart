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
  final int selectedCount;

  const PreviewWindow({super.key, this.file, this.selectedCount = 0});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (selectedCount > 1) {
      return Center(
        child: Text(
          l10n.labelPreviewSelectedCount(selectedCount),
          style: const TextStyle(color: Colors.grey),
        ),
      );
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

  Future<String> _readText(File file, AppLocalizations l10n) async {
    try {
      final len = await file.length();
      const int limit = 2 * 1024; // 2KB に制限して高速化

      final stream = file.openRead(0, limit);
      final chunks = await stream.toList();
      final bytes = chunks.expand((element) => element).toList();
      
      // バイナリチェック（NULL文字が含まれていたらテキストではないと判断）
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
}
