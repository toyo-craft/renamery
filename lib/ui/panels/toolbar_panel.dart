import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
// For Clipboard
import '../../core/directory_provider.dart';
import '../helpers/undo_helper.dart';
import '../helpers/copy_helper.dart';

class ToolbarPanel extends StatelessWidget {
  const ToolbarPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectoryProvider>();
    final iconColor = Colors.green[700]; // Namery Green-ish
    const iconSize = 28.0;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(bottom: BorderSide(color: Colors.grey[400]!)),
      ),
      child: Row(
        children: [
          // 1. Back Group
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Symbols.arrow_back),
                color: iconColor,
                iconSize: iconSize,
                tooltip: '戻る',
                onPressed: provider.canGoBack ? () => provider.goBack() : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              PopupMenuButton<int>(
                icon: const Icon(Symbols.arrow_drop_down),
                color: Colors.white,
                enabled: provider.backHistory.isNotEmpty,
                onSelected: (steps) {
                  provider.jumpBack(steps);
                },
                itemBuilder: (context) {
                  final history = provider.backHistory;
                  return List.generate(history.length, (index) {
                    final path = history[index];
                    return PopupMenuItem(
                      value: index + 1,
                      height: 32,
                      child: Text(path, style: const TextStyle(fontSize: 12)),
                    );
                  });
                },
                tooltip: '履歴 (戻る)',
              ),
            ],
          ),

          // 2. Forward Group
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Symbols.arrow_forward),
                color: iconColor,
                iconSize: iconSize,
                tooltip: '進む',
                onPressed:
                    provider.canGoForward ? () => provider.goForward() : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              PopupMenuButton<int>(
                icon: const Icon(Symbols.arrow_drop_down),
                color: Colors.white,
                enabled: provider.forwardHistory.isNotEmpty,
                onSelected: (steps) {
                  provider.jumpForward(steps);
                },
                itemBuilder: (context) {
                  final history = provider.forwardHistory;
                  return List.generate(history.length, (index) {
                    final path = history[index];
                    return PopupMenuItem(
                      value: index + 1,
                      height: 32,
                      child: Text(path, style: const TextStyle(fontSize: 12)),
                    );
                  });
                },
                tooltip: '履歴 (進む)',
              ),
            ],
          ),

          const VerticalDivider(width: 20, indent: 8, endIndent: 8),

          // 3. Execute
          IconButton(
            icon: const Icon(Symbols.play_arrow),
            color: iconColor,
            iconSize: iconSize,
            tooltip: provider.hasInvalidFilenamesSelected
                ? '一部のファイルにエラーがあります (クリックで詳細)'
                : '実行',
            onPressed: provider.canExecute
                ? () => _confirmAndExecute(context, provider)
                : null,
          ),

          // 4. Undo
          TextButton.icon(
            icon: const Icon(Symbols.undo),
            label: Text(provider.canUndo ? '戻す (${provider.undoCount})' : '戻す'),
            style: TextButton.styleFrom(
              foregroundColor: iconColor,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: provider.canUndo
                ? () => UndoHelper.handleUndo(context, provider)
                : null,
          ),

          // 5. Copy Group
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Symbols.content_copy),
                color: Colors.grey[700],
                iconSize: iconSize,
                tooltip: 'コピー (現在名)',
                onPressed: provider.currentFiles.any((f) => f.isSelected)
                    ? () => _handleCopy(context, provider)
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              PopupMenuButton<int>(
                icon: const Icon(Symbols.arrow_drop_down),
                color: Colors.white,
                // Enable if EITHER selection exists OR undo log exists
                enabled: provider.currentFiles.any((f) => f.isSelected) ||
                    provider.getLastUndoTransaction().isNotEmpty,
                onSelected: (value) async {
                  await _handleCopyMenu(context, provider, value);
                },
                itemBuilder: (context) {
                  final hasSelection =
                      provider.currentFiles.any((f) => f.isSelected);
                  final hasUndo = provider.getLastUndoTransaction().isNotEmpty;

                  return [
                    PopupMenuItem(
                      value: 1,
                      height: 32,
                      enabled: hasSelection,
                      child: const Text('クリップボードへ現在のリストをコピー',
                          style: TextStyle(fontSize: 12)),
                    ),
                    PopupMenuItem(
                      value: 2,
                      height: 32,
                      enabled: hasSelection,
                      child: const Text('相対パスリストをコピー',
                          style: TextStyle(fontSize: 12)),
                    ),
                    PopupMenuItem(
                      value: 3,
                      height: 32,
                      enabled: hasSelection,
                      child: const Text('クリップボードへフルパスリストをコピー',
                          style: TextStyle(fontSize: 12)),
                    ),
                    PopupMenuItem(
                      value: 4,
                      height: 32,
                      enabled: hasUndo,
                      child: const Text('直前の変更記録をクリップボードへ',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ];
                },
                tooltip: 'コピーオプション',
              ),
            ],
          ),

          const VerticalDivider(width: 20, indent: 8, endIndent: 8),

          // 6. Up
          IconButton(
            icon: const Icon(Symbols.expand_less),
            color: iconColor,
            iconSize: iconSize,
            tooltip: '上に移動',
            onPressed:
                provider.canMoveUp ? () => provider.moveSelection(true) : null,
          ),

          // 7. Down
          IconButton(
            icon: const Icon(Symbols.expand_more),
            color: iconColor,
            iconSize: iconSize,
            tooltip: '下に移動',
            onPressed: provider.canMoveDown
                ? () => provider.moveSelection(false)
                : null,
          ),

          const VerticalDivider(width: 20, indent: 8, endIndent: 8),

          // 8. Refresh
          IconButton(
            icon: const Icon(Symbols.refresh),
            color: iconColor,
            iconSize: iconSize,
            tooltip: '全て更新',
            onPressed: () => provider.refresh(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCopyMenu(
      BuildContext context, DirectoryProvider provider, int value) async {
    await CopyHelper.handleCopyMenu(context, provider, value);
  }

  Future<void> _handleCopy(
      BuildContext context, DirectoryProvider provider) async {
    await CopyHelper.handleCopy(context, provider);
  }

  Future<void> _confirmAndExecute(
      BuildContext context, DirectoryProvider provider) async {
    if (!provider.currentFiles.any((f) => f.isSelected)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ファイルが選択されていません')),
      );
      return;
    }

    final int invalidCount = provider.invalidFileCount;
    final int validCount = provider.validFileCount;

    if (invalidCount > 0) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('エラーを含むファイルのスキップ確認'),
          content: Text(
            '選択されたファイルの中に、ファイル名が不正（禁止文字・重複など）なものが $invalidCount 件あります。\n\n'
            'これらを除外し、正常な $validCount 件のファイルのみリネームを実行しますか？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('スキップして続行'),
            ),
          ],
        ),
      );

      if (shouldProceed != true) {
        return;
      }
    }

    final executedCount = await provider.executeRename();

    if (context.mounted) {
      if (executedCount > 0) {
        final msg = invalidCount > 0
            ? '$executedCount 件成功、$invalidCount 件はエラーのためスキップされました'
            : '$executedCount 個のファイルをリネームしました';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('実行できるファイルがありませんでした')),
        );
      }
    }
  }
}
