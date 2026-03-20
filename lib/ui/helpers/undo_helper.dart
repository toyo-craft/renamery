import 'package:flutter/material.dart';
import '../../core/directory_provider.dart';
import '../../core/undo_manager.dart';
import 'package:path/path.dart' as p;
import 'package:renamery/l10n/generated/app_localizations.dart';

class UndoHelper {
  static Future<void> handleUndo(
      BuildContext context, DirectoryProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    final transaction = provider.getLastUndoTransaction();
    if (transaction.isEmpty) return;

    final shouldUndo = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.labelUndoTitle,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.labelUndoConfirm(transaction.length)),
              const SizedBox(height: 16),
              Container(
                height: 200,
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
                child: ListView.builder(
                  itemCount: transaction.length,
                  itemBuilder: (context, index) {
                    const padding =
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4);
                    final item = transaction[index];
                    
                    return Padding(
                      padding: padding,
                      child: _buildActionRow(context, item, isUndo: true),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              child: Text(l10n.labelDialogCancel),
              onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
              child: Text(l10n.labelUndoRecoverBtn),
              onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (shouldUndo == true) {
      final result = await provider.undo();

      if (context.mounted) {
        final errors = (result['errors'] as List?) ?? [];
        
        if (errors.isNotEmpty) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Undo Error'),
              content: Text(errors.join('\n')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                )
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.labelMsgUndoSuccess)),
          );
        }
      }
    }
  }

  static Future<void> handleRedo(
      BuildContext context, DirectoryProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    if (!provider.canRedo) return;

    // Redo implementation: Similar to Undo but calls provider.redo()
    // For simplicity, we just execute redo directly or show confirm.
    // Given the user asked for Redo support, showing a confirmation is safer.
    
    final shouldRedo = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.labelRedoTitle,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(l10n.labelRedoConfirm(1)), // transaction count info not easily available for redo without peek
        actions: [
          TextButton(
              child: Text(l10n.labelDialogCancel),
              onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
              child: Text(l10n.labelRedoBtn),
              onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (shouldRedo == true) {
      final result = await provider.redo();

      if (context.mounted) {
        final errors = (result['errors'] as List?) ?? [];
        if (errors.isNotEmpty) {
          // Show error
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.labelMsgRedoSuccess)),
          );
        }
      }
    }
  }

  static Widget _buildActionRow(BuildContext context, UndoAction item, {required bool isUndo}) {
    IconData icon;
    String label;
    String detail;

    switch (item.type) {
      case UndoType.rename:
        icon = Icons.edit;
        label = 'Rename';
        detail = isUndo 
          ? '${p.basename(item.newPath)} → ${p.basename(item.originalPath!)}'
          : '${p.basename(item.originalPath!)} → ${p.basename(item.newPath)}';
        break;
      case UndoType.move:
        icon = Icons.move_to_inbox;
        label = 'Move';
        detail = isUndo 
          ? '${p.basename(item.newPath)} → Original Folder'
          : '${p.basename(item.originalPath!)} → ${p.dirname(item.newPath)}';
        break;
      case UndoType.copy:
        icon = Icons.copy;
        label = 'Copy';
        detail = isUndo 
          ? 'Remove Copy: ${p.basename(item.newPath)}'
          : 'Copy to: ${p.dirname(item.newPath)}';
        break;
      case UndoType.create:
        icon = Icons.create_new_folder;
        label = 'Create';
        detail = isUndo 
          ? 'Remove Folder: ${p.basename(item.newPath)}'
          : 'Create Folder: ${p.basename(item.newPath)}';
        break;
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(width: 8),
        Expanded(child: Text(detail, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
