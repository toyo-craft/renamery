import 'dart:io' as io;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:printing/printing.dart';
import 'package:archive/archive.dart';
import 'package:provider/provider.dart';
import '../../core/directory_provider.dart';
import '../../core/file_model.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

class PreviewWindow extends StatelessWidget {
  final FileModel? file;
  final List<FileModel> selectedFiles;

  const PreviewWindow({super.key, this.file, this.selectedFiles = const []});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 複数選択時は仮想化グリッドプレビューを表示
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
      return _ImagePreview(file: file!, l10n: l10n);
    }

    // 2. SVG Preview
    if (ext == 'svg') {
      return _SvgPreview(file: file!, l10n: l10n);
    }

    // 3. PDF Preview
    if (ext == 'pdf') {
      return _PdfPreview(file: file!, l10n: l10n);
    }

    // 4. Archive Preview
    if (ext == 'zip') {
      return _ArchivePreview(file: file!, l10n: l10n);
    }

    // 5. Text Preview (Default)
    return _TextPreview(file: file!, l10n: l10n);
  }
}

class _MultiSelectGridPreview extends StatelessWidget {
  final List<FileModel> files;
  final AppLocalizations l10n;

  const _MultiSelectGridPreview({required this.files, required this.l10n});

  @override
  Widget build(BuildContext context) {
    // 画面幅に応じて列数を動的に調整
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 100).floor().clamp(2, 6);
        
        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: GridView.builder(
            // GridView.builder により仮想化（画面外のタイルは描画しない）を有効化
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: files.length,
            itemBuilder: (context, index) {
              return _ThumbnailTile(
                key: ValueKey(files[index].entity.path),
                file: files[index], 
                l10n: l10n
              );
            },
          ),
        );
      },
    );
  }
}

class _ThumbnailTile extends StatelessWidget {
  final FileModel file;
  final AppLocalizations l10n;

  const _ThumbnailTile({super.key, required this.file, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final path = file.entity.path;
    final ext = path.contains('.') ? path.split('.').last.toLowerCase() : '';
    final provider = context.watch<DirectoryProvider>();
    final isEnlarged = provider.isEnlargedPreviewOpen;
    final isEnlargedActive = isEnlarged && provider.enlargedPreviewFile == file;

    // 文書系は常に白背景
    final bool isDocumentType = ['txt', 'pdf', 'zip', 'csv', 'json', 'ini', 'log', 'dart', 'yaml', 'md', 'html', 'xml', 'sql', 'js', 'py', 'css'].contains(ext);
    final Color? contentBgColor = (isEnlarged && isDocumentType) ? Colors.white : (isEnlarged ? null : Theme.of(context).colorScheme.surfaceContainerLow);

    return InkWell(
      onTap: () => provider.openEnlargedPreview(file),
      child: Container(
        decoration: BoxDecoration(
          color: contentBgColor,
          borderRadius: BorderRadius.circular(isEnlarged ? 8 : 4),
          border: Border.all(
            color: isEnlargedActive 
                ? Theme.of(context).colorScheme.primary 
                : (isEnlarged ? Colors.transparent : Theme.of(context).dividerColor), 
            width: isEnlargedActive ? 2.0 : 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(child: _buildContent(context, path, ext)),
            // リスト表示時のみファイル名オーバーレイを表示
            if (!isEnlarged)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  color: isEnlargedActive 
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)
                      : Colors.black.withValues(alpha: 0.5),
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
      ),
    );
  }

  Widget _buildContent(BuildContext context, String path, String ext) {
    // 段階的レンダリング: まずはアイコンを表示し、準備ができたら中身を表示
    if (['png', 'jpg', 'jpeg', 'bmp', 'gif', 'webp', 'ico'].contains(ext)) {
      return Image.file(
        io.File(path), 
        fit: BoxFit.cover, 
        errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 16),
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return const Icon(Icons.image, color: Colors.grey, size: 24); // ロード中プレースホルダー
        },
      );
    } else if (ext == 'svg') {
      return FutureBuilder<Uint8List>(
        future: io.File(path).readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return SvgPicture.memory(snapshot.data!, fit: BoxFit.contain);
          }
          return const Icon(Icons.image, color: Colors.grey, size: 24);
        },
      );
    } else if (ext == 'pdf') {
      return _PdfPreview(file: file, l10n: l10n, isThumbnail: true);
    } else if (ext == 'zip') {
      return FutureBuilder<List<String>>(
        future: _listArchiveFiles(io.File(path)),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.all(2.0),
              child: Text(
                snapshot.data!.join('\n'),
                style: const TextStyle(fontSize: 5, fontFamily: 'Consolas', height: 1.0, color: Colors.black87),
                overflow: TextOverflow.fade,
              ),
            );
          }
          return const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 24);
        },
      );
    } else if (file.entity is io.Directory) {
      return const Icon(Icons.folder, color: Colors.amber, size: 24);
    } else {
      final isTextExt = ['txt', 'csv', 'json', 'ini', 'log', 'dart', 'yaml', 'md', 'html', 'xml', 'sql', 'js', 'py', 'css'].contains(ext);
      return FutureBuilder<String>(
        future: _readText(io.File(path), l10n, limit: 200),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != l10n.labelPreviewBinaryError && (isTextExt || snapshot.data!.length > 10)) {
            return Padding(
              padding: const EdgeInsets.all(2.0),
              child: Text(
                snapshot.data!,
                style: const TextStyle(fontSize: 6, fontFamily: 'Consolas', height: 1.1, color: Colors.black87),
                overflow: TextOverflow.fade,
              ),
            );
          }
          return const Icon(Icons.insert_drive_file, color: Colors.grey, size: 24);
        },
      );
    }
  }
}

class _ImagePreview extends StatelessWidget {
  final FileModel file;
  final AppLocalizations l10n;

  const _ImagePreview({required this.file, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Image.file(
        io.File(file.entity.path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _ErrorDocumentView(message: l10n.labelPreviewImageLoadFailed),
      ),
    );
  }
}

class _SvgPreview extends StatelessWidget {
  final FileModel file;
  final AppLocalizations l10n;

  const _SvgPreview({required this.file, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: io.File(file.entity.path).readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _ErrorDocumentView(message: l10n.labelPreviewImageLoadFailed);
        }
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: SvgPicture.memory(
            snapshot.data!,
            fit: BoxFit.contain,
            placeholderBuilder: (context) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        );
      },
    );
  }
}

class _PdfPreview extends StatefulWidget {
  final FileModel file;
  final AppLocalizations l10n;
  final bool isThumbnail;

  const _PdfPreview({required this.file, required this.l10n, this.isThumbnail = false});

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
    if (oldWidget.file.entity.path != widget.file.entity.path) {
      _render();
    }
  }

  Future<void> _render() async {
    final path = widget.file.entity.path;
    if (_lastPath == path && _cachedImageData != null) return;

    if (mounted) setState(() { _isLoading = true; });
    
    try {
      final file = io.File(path);
      final bytes = await file.readAsBytes();
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
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
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
      return _ErrorDocumentView(message: widget.l10n.labelPreviewUnavailable);
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

class _ArchivePreview extends StatelessWidget {
  final FileModel file;
  final AppLocalizations l10n;

  const _ArchivePreview({required this.file, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectoryProvider>();
    final isEnlarged = provider.isEnlargedPreviewOpen;

    return Listener(
      onPointerSignal: (PointerSignalEvent event) {
        if (isEnlarged) {
          final dynamic signal = event;
          try {
            final delta = signal.scrollDelta.dy as double;
            provider.setTextPreviewFontSize(provider.textPreviewFontSize - (delta > 0 ? 1.0 : -1.0));
          } catch (_) {}
        }
      },
      child: Container(
        color: Colors.white,
        width: double.infinity, 
        child: FutureBuilder<List<String>>(
          future: _listArchiveFiles(file.entity as io.File),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return _ErrorDocumentView(message: l10n.labelPreviewUnavailable);
            }
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('Archive Contents:', style: TextStyle(fontSize: provider.textPreviewFontSize, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                  const Divider(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) => Text(
                        snapshot.data![index],
                        style: TextStyle(fontSize: provider.textPreviewFontSize, fontFamily: 'Consolas', color: Colors.black87),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Future<List<String>> _listArchiveFiles(io.File file) async {
  try {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    return archive.files.take(20).map((f) => '  ${f.name}${(!f.isFile || f.name.endsWith('/')) ? "" : ""}').toList();
  } catch (e) {
    return [];
  }
}

class _TextPreview extends StatelessWidget {
  final FileModel file;
  final AppLocalizations l10n;

  const _TextPreview({required this.file, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectoryProvider>();
    final isEnlarged = provider.isEnlargedPreviewOpen;

    return Listener(
      onPointerSignal: (PointerSignalEvent event) {
        if (isEnlarged) {
          final dynamic signal = event;
          try {
            final delta = signal.scrollDelta.dy as double;
            provider.setTextPreviewFontSize(provider.textPreviewFontSize - (delta > 0 ? 1.0 : -1.0));
          } catch (_) {}
        }
      },
      child: Container(
        color: Colors.white,
        width: double.infinity, 
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<String>(
          future: _readText(io.File(file.entity.path), l10n),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            }
            if (snapshot.hasError) {
              return _ErrorDocumentView(message: 'Error: ${snapshot.error}');
            }
            final text = snapshot.data ?? l10n.labelPreviewUnavailable;
            if (text == l10n.labelPreviewBinaryError) {
              return _ErrorDocumentView(message: text);
            }
            return SizedBox.expand(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical, 
                child: SelectableText(
                  text,
                  style: TextStyle(
                    fontSize: provider.textPreviewFontSize, 
                    fontFamily: 'Consolas', 
                    color: Colors.black87,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ErrorDocumentView extends StatelessWidget {
  final String message;
  const _ErrorDocumentView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, color: Colors.grey, size: 32),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontFamily: 'Consolas',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String> _readText(io.File file, AppLocalizations l10n, {int limit = 2048}) async {
  try {
    final len = await file.length();
    final stream = file.openRead(0, limit);
    final chunks = await stream.toList();
    final bytes = chunks.expand((element) => element).toList();
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
