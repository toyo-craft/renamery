import 'package:flutter/material.dart';
import '../core/file_model.dart';

// Custom Dialog for Web/Linux/Android fallback
void showCustomPropertiesDialog(BuildContext context, FileModel fileModel) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('プロパティ: ${fileModel.originalName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPropertyRow(
                  '種類', fileModel.isDirectory ? 'ファイル フォルダ' : 'ファイル'),
              _buildPropertyRow('場所', fileModel.parentPath),
              _buildPropertyRow('サイズ', fileModel.size),
              const Divider(),
              _buildPropertyRow('更新日時', fileModel.dateModified),
              const Divider(),
              _buildPropertyRow('属性', fileModel.attributes),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
