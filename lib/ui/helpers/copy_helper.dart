import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import '../../core/directory_provider.dart';

class CopyHelper {
  static Future<void> handleCopy(
      BuildContext context, DirectoryProvider provider) async {
    await handleCopyMenu(context, provider, 1);
  }

  static Future<void> handleCopyMenu(
      BuildContext context, DirectoryProvider provider, int value) async {
    // 1: Names, 2: Names+Path (Relative), 3: Full Path, 4: Undo Log

    // Logic for 4 is distinct (based on undo log)
    if (value == 4) {
      final transaction = provider.getLastUndoTransaction();
      if (transaction.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('直前の変更記録がありません')),
          );
        }
        return;
      }

      final text =
          transaction.map((t) => '${t.oldPath}\t${t.newPath}').join('\n');
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('直前の変更記録をクリップボードにコピーしました')),
        );
      }
      return;
    }

    // Common logic for 1, 2, 3 (Target Selection)
    final selected = provider.currentFiles.where((f) => f.isSelected);

    // STRICT SELECTION: If no selection, do nothing (or show message if triggered explicitly?)
    // User said: "When file unselected, copy target is none".
    // Buttons are disabled in UI, but Shortcut might trigger it.
    // So we invoke safely.
    if (selected.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ファイルが選択されていません')),
        );
      }
      return;
    }

    final target = selected;

    String text = '';
    late String message;

    if (value == 1) {
      // Current List (Names)
      text = target.map((f) => f.originalName).join('\n');
      message = '${target.length} 件のファイル名をコピーしました';
    } else if (value == 2) {
      // Current List (Path)
      text = target.map((f) {
        if (f.displayRelativePath.isNotEmpty) {
          return '${f.displayRelativePath}\\${f.originalName}';
        }
        return f.originalName;
      }).join('\n');
      message = '${target.length} 件のファイルパス(相対)をコピーしました';
    } else if (value == 3) {
      // Full List
      text = target.map((f) {
        return f.entity.path;
      }).join('\n');
      message = '${target.length} 件のフルパスをコピーしました';
    }

    await Clipboard.setData(ClipboardData(text: text));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
