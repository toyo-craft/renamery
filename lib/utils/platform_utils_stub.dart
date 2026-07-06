import 'package:flutter/material.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

import '../core/file_model.dart';

// Custom Dialog for Web/Linux/Android fallback
void showCustomPropertiesDialog(BuildContext context, FileModel fileModel) {
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.labelPropertiesTitle(fileModel.originalName)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPropertyRow(
                l10n.labelPropertyKind,
                fileModel.isDirectory
                    ? l10n.labelPropertyFileFolder
                    : l10n.labelPropertyFile,
              ),
              _buildPropertyRow(
                  l10n.labelPropertyLocation, fileModel.parentPath),
              _buildPropertyRow(l10n.labelPropertySize, fileModel.size),
              const Divider(),
              _buildPropertyRow(
                  l10n.labelPropertyModified, fileModel.dateModified),
              const Divider(),
              _buildPropertyRow(
                  l10n.labelPropertyAttributes, fileModel.attributes),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      );
    },
  );
}

Widget _buildPropertyRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: SelectableText(value)),
      ],
    ),
  );
}

void showPropertiesDialogImpl(BuildContext context, FileModel fileModel) {
  showCustomPropertiesDialog(context, fileModel);
}

void openFileImpl(String path) {
  // Fallback
}
