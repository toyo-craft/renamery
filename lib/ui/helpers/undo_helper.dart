import 'package:flutter/material.dart';
import '../../core/directory_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.labelUndoConfirm(transaction.length)),
              const SizedBox(height: 16),
              Container(
                height: 150,
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
                child: ListView.builder(
                  itemCount: transaction.length,
                  itemBuilder: (context, index) {
                    const padding =
                        EdgeInsets.symmetric(horizontal: 4, vertical: 2);
                    final item = transaction[index];
                    final oldName = p.basename(item.oldPath);
                    final newName = p.basename(item.newPath);
                    return Padding(
                      padding: padding,
                      child: Text('$oldName ← $newName',
                          style: const TextStyle(fontSize: 12)),
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
      await provider.undo();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.labelMsgUndoSuccess)),
        );
      }
    }
  }
}
