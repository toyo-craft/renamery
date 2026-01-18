import 'package:flutter/material.dart';
import '../../core/directory_provider.dart';
import 'package:path/path.dart' as p;

class UndoHelper {
  static Future<void> handleUndo(
      BuildContext context, DirectoryProvider provider) async {
    final transaction = provider.getLastUndoTransaction();
    if (transaction.isEmpty) return;

    final shouldUndo = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            const Text('処理の復元', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('直前に行った ${transaction.length} 件の変更を元に戻しますか？'),
              const SizedBox(height: 16),
              Container(
                height: 150,
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
                child: ListView.builder(
                  itemCount: transaction.length,
                  itemBuilder: (context, index) {
                    final padding =
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2);
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
              child: const Text('キャンセル'),
              onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
              child: const Text('復元'),
              onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (shouldUndo == true) {
      await provider.undo();

      // Optional: Show result toast/dialog?
      // ToolbarPanel didn't show result dialog in my LAST edit (I copied logic and simplified it).
      // Checking old HomeScreen logic... it DID show a result dialog.
      // My previous ToolbarPanel code: `if (shouldUndo == true) { await provider.undo(); }`
      // I should probably show a success message?
      // Let's add a simple snackbar for success.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('復元しました')),
        );
      }
    }
  }
}
