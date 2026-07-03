import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:material_symbols_icons/symbols.dart';
import '../../core/directory_provider_platform.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

class CopyHelper {
  static Future<void> handleCopy(
      BuildContext context, DirectoryProvider provider) async {
    await handleCopyMenu(context, provider, 1);
  }

  static Future<void> handleCopyMenu(
      BuildContext context, DirectoryProvider provider, int value) async {
    final l10n = AppLocalizations.of(context)!;
    // 1: Names, 2: Names+Path (Relative), 3: Full Path, 4: Undo Log

    // Logic for 4 is distinct (based on undo log)
    if (value == 4) {
      final transaction = provider.getLastUndoTransaction();
      if (transaction.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.labelMsgNoUndoRecord)),
          );
        }
        return;
      }

      final text =
          transaction.map((t) => '${t.oldPath}\t${t.newPath}').join('\n');
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.labelMsgUndoRecordCopied)),
        );
      }
      return;
    }

    // Common logic for 1, 2, 3 (Target Selection)
    final selected = provider.currentFiles.where((f) => f.isSelected);

    if (selected.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.labelMsgNoSelection)),
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
      message = l10n.labelMsgCopyNamesSuccess(target.length);
    } else if (value == 2) {
      // Current List (Path)
      text = target.map((f) {
        if (f.displayRelativePath.isNotEmpty) {
          return '${f.displayRelativePath}\\${f.originalName}';
        }
        return f.originalName;
      }).join('\n');
      message = l10n.labelMsgCopyRelativePathsSuccess(target.length);
    } else if (value == 3) {
      // Full List
      text = target.map((f) {
        return f.path;
      }).join('\n');
      message = l10n.labelMsgCopyFullPathsSuccess(target.length);
    }

    await Clipboard.setData(ClipboardData(text: text));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // モバイル版：コピー形式を選択するボトムシートを表示
  static void showCopyOptionsBottomSheet(
      BuildContext context, DirectoryProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  l10n.labelCopyOptions,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Divider(height: 1),
              _buildBottomSheetItem(
                context,
                icon: Symbols.file_copy,
                title: l10n.labelCopyListClipboard,
                onTap: () {
                  Navigator.pop(context);
                  handleCopyMenu(context, provider, 1);
                },
              ),
              _buildBottomSheetItem(
                context,
                icon: Symbols.account_tree,
                title: l10n.labelCopyListPath,
                onTap: () {
                  Navigator.pop(context);
                  handleCopyMenu(context, provider, 2);
                },
              ),
              _buildBottomSheetItem(
                context,
                icon: Symbols.terminal,
                title: l10n.labelCopyFullPath,
                onTap: () {
                  Navigator.pop(context);
                  handleCopyMenu(context, provider, 3);
                },
              ),
              _buildBottomSheetItem(
                context,
                icon: Symbols.history,
                title: l10n.labelCopyUndo,
                onTap: () {
                  Navigator.pop(context);
                  handleCopyMenu(context, provider, 4);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildBottomSheetItem(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      onTap: onTap,
    );
  }
}
