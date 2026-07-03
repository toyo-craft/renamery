import 'package:flutter/material.dart';

import '../../core/file_model.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

class PreviewWindow extends StatelessWidget {
  final FileModel? file;
  final List<FileModel> selectedFiles;

  const PreviewWindow({super.key, this.file, this.selectedFiles = const []});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (selectedFiles.length > 1) {
      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: selectedFiles.length,
        itemBuilder: (context, index) {
          final item = selectedFiles[index];
          return ListTile(
            dense: true,
            leading: Icon(item.isDirectory ? Icons.folder : Icons.description),
            title: Text(item.originalName, overflow: TextOverflow.ellipsis),
            subtitle: Text(item.fileType),
          );
        },
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              file!.isDirectory ? Icons.folder : Icons.description,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              file!.originalName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'WEBでは実ファイルプレビューを後続対応で戻します。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
