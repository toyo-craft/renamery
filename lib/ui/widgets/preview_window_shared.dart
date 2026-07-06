import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

import '../../core/directory_provider_platform.dart';
import '../../core/file_model.dart';
import 'preview_document_view.dart';
import 'preview_platform_content.dart';

class PreviewWindow extends StatelessWidget {
  const PreviewWindow({super.key, this.file, this.selectedFiles = const []});

  final FileModel? file;
  final List<FileModel> selectedFiles;

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

    final extension = _extensionOf(file!.path);
    if (_imageExtensions.contains(extension)) {
      return _ImagePreview(file: file!, l10n: l10n, extension: extension);
    }
    if (extension == 'svg') {
      return _SvgPreview(file: file!, l10n: l10n);
    }
    if (extension == 'pdf') {
      return _PdfPreview(file: file!, l10n: l10n);
    }
    if (extension == 'zip') {
      return _ArchivePreview(file: file!, l10n: l10n, extension: extension);
    }
    if (file!.isDirectory) {
      return PreviewDocumentMessage(message: l10n.labelTermFolder);
    }
    return _TextPreview(file: file!, l10n: l10n, extension: extension);
  }
}

class _MultiSelectGridPreview extends StatelessWidget {
  const _MultiSelectGridPreview({required this.files, required this.l10n});

  final List<FileModel> files;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 100).floor().clamp(2, 6);
        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: files.length,
            itemBuilder: (context, index) {
              return _ThumbnailTile(
                key: ValueKey(files[index].path),
                file: files[index],
                l10n: l10n,
              );
            },
          ),
        );
      },
    );
  }
}

class _ThumbnailTile extends StatelessWidget {
  const _ThumbnailTile({super.key, required this.file, required this.l10n});

  final FileModel file;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final extension = _extensionOf(file.path);
    final provider = context.watch<DirectoryProvider>();
    final isEnlarged = provider.isEnlargedPreviewOpen;
    final isEnlargedActive = isEnlarged && provider.enlargedPreviewFile == file;
    final isDocumentType = _documentExtensions.contains(extension);
    final Color? contentBgColor = (isEnlarged && isDocumentType)
        ? Colors.white
        : (isEnlarged
            ? null
            : Theme.of(context).colorScheme.surfaceContainerLow);

    return InkWell(
      onTap: () => provider.openEnlargedPreview(file),
      child: Container(
        decoration: BoxDecoration(
          color: contentBgColor,
          borderRadius: BorderRadius.circular(isEnlarged ? 8 : 4),
          border: Border.all(
            color: isEnlargedActive
                ? Theme.of(context).colorScheme.primary
                : (isEnlarged
                    ? Colors.transparent
                    : Theme.of(context).dividerColor),
            width: isEnlargedActive ? 2.0 : 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: buildPlatformThumbnailContent(
                context,
                file,
                l10n,
                extension,
              ),
            ),
            if (!isEnlarged)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  color: isEnlargedActive
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.7)
                      : Colors.black.withValues(alpha: 0.5),
                  child: Center(
                    child: Text(
                      file.originalName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        height: 1.1,
                      ),
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
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.file,
    required this.l10n,
    required this.extension,
  });

  final FileModel file;
  final AppLocalizations l10n;
  final String extension;

  @override
  Widget build(BuildContext context) {
    return buildPlatformImagePreview(context, file, l10n, extension);
  }
}

class _SvgPreview extends StatelessWidget {
  const _SvgPreview({required this.file, required this.l10n});

  final FileModel file;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return buildPlatformSvgPreview(context, file, l10n);
  }
}

class _PdfPreview extends StatelessWidget {
  const _PdfPreview({required this.file, required this.l10n});

  final FileModel file;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return buildPlatformPdfPreview(context, file, l10n);
  }
}

class _ArchivePreview extends StatelessWidget {
  const _ArchivePreview({
    required this.file,
    required this.l10n,
    required this.extension,
  });

  final FileModel file;
  final AppLocalizations l10n;
  final String extension;

  @override
  Widget build(BuildContext context) {
    if (!canListArchivePreview(file, extension)) {
      return PreviewDocumentMessage(
        message: unsupportedPreviewMessage(file, extension, l10n),
      );
    }
    final provider = context.watch<DirectoryProvider>();
    final isEnlarged = provider.isEnlargedPreviewOpen;

    return Listener(
      onPointerSignal: (PointerSignalEvent event) {
        if (isEnlarged) {
          final dynamic signal = event;
          try {
            final delta = signal.scrollDelta.dy as double;
            provider.setTextPreviewFontSize(
              provider.textPreviewFontSize - (delta > 0 ? 1.0 : -1.0),
            );
          } catch (_) {}
        }
      },
      child: Container(
        color: Colors.white,
        width: double.infinity,
        child: FutureBuilder<List<String>>(
          future: listPlatformArchiveFiles(file),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return PreviewDocumentMessage(
                message: l10n.labelPreviewUnavailable,
              );
            }
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.labelArchiveContents,
                        style: TextStyle(
                          fontSize: provider.textPreviewFontSize,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) => Text(
                        snapshot.data![index],
                        style: TextStyle(
                          fontSize: provider.textPreviewFontSize,
                          fontFamily: 'Consolas',
                          color: Colors.black87,
                        ),
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

class _TextPreview extends StatelessWidget {
  const _TextPreview({
    required this.file,
    required this.l10n,
    required this.extension,
  });

  final FileModel file;
  final AppLocalizations l10n;
  final String extension;

  @override
  Widget build(BuildContext context) {
    if (!canReadTextPreview(file, extension)) {
      return PreviewDocumentMessage(
        message: unsupportedPreviewMessage(file, extension, l10n),
      );
    }
    final provider = context.watch<DirectoryProvider>();
    final isEnlarged = provider.isEnlargedPreviewOpen;

    return Listener(
      onPointerSignal: (PointerSignalEvent event) {
        if (isEnlarged) {
          final dynamic signal = event;
          try {
            final delta = signal.scrollDelta.dy as double;
            provider.setTextPreviewFontSize(
              provider.textPreviewFontSize - (delta > 0 ? 1.0 : -1.0),
            );
          } catch (_) {}
        }
      },
      child: Container(
        color: Colors.white,
        width: double.infinity,
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<String>(
          future: readPlatformTextPreview(file, l10n),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            if (snapshot.hasError) {
              return PreviewDocumentMessage(
                message: l10n.labelPreviewError(snapshot.error.toString()),
              );
            }
            final text = snapshot.data ?? l10n.labelPreviewUnavailable;
            if (text == l10n.labelPreviewBinaryError) {
              return PreviewDocumentMessage(message: text);
            }
            return SizedBox.expand(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Semantics(
                  label: text,
                  child: SelectableText(
                    text,
                    style: TextStyle(
                      fontSize: provider.textPreviewFontSize,
                      fontFamily: 'Consolas',
                      color: Colors.black87,
                    ),
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

String _extensionOf(String path) {
  return path.contains('.') ? path.split('.').last.toLowerCase() : '';
}

const _imageExtensions = {'png', 'jpg', 'jpeg', 'bmp', 'gif', 'webp', 'ico'};

const _documentExtensions = {
  'txt',
  'pdf',
  'zip',
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
