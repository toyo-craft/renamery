import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/directory_provider.dart';
import '../helpers/undo_helper.dart';
import '../helpers/copy_helper.dart';
import 'package:path/path.dart' as p;
import '../settings_screen.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showDrawerMenu;

  const HomeAppBar({
    super.key,
    this.showDrawerMenu = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectoryProvider>();
    // final iconColor = Colors.green[700]; // Removed fixed color
    const iconSize = 28.0;

    return AppBar(
      leading: showDrawerMenu
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.folder),
                color: Theme.of(context).colorScheme.primary,
                tooltip: 'メニュー (フォルダ)',
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            )
          : null,
      automaticallyImplyLeading: false, // We handle it manually
      titleSpacing: 0,
      title: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          return Row(
            children: [
              const SizedBox(width: 8),
              // 1. Back Group
              IconButton(
                icon: const Icon(Icons.arrow_back),
                // color: iconColor, // Use Theme Default
                iconSize: iconSize,
                tooltip: '戻る',
                onPressed: provider.canGoBack ? () => provider.goBack() : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              PopupMenuButton<int>(
                icon: const Icon(Icons.arrow_drop_down),
                // color: Colors.white, // Use Theme
                enabled: provider.backHistory.isNotEmpty,
                onSelected: (steps) => provider.jumpBack(steps),
                itemBuilder: (context) {
                  return List.generate(provider.backHistory.length, (index) {
                    return PopupMenuItem(
                      value: index + 1,
                      height: 32,
                      child: Text(p.basename(provider.backHistory[index]),
                          style: const TextStyle(fontSize: 12)),
                    );
                  });
                },
                tooltip: '履歴 (戻る)',
              ),

              // 2. Forward Group
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                // color: iconColor,
                iconSize: iconSize,
                tooltip: '進む',
                onPressed:
                    provider.canGoForward ? () => provider.goForward() : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              PopupMenuButton<int>(
                icon: const Icon(Icons.arrow_drop_down),
                // color: Colors.white,
                enabled: provider.forwardHistory.isNotEmpty,
                onSelected: (steps) => provider.jumpForward(steps),
                itemBuilder: (context) {
                  return List.generate(provider.forwardHistory.length, (index) {
                    return PopupMenuItem(
                      value: index + 1,
                      height: 32,
                      child: Text(p.basename(provider.forwardHistory[index]),
                          style: const TextStyle(fontSize: 12)),
                    );
                  });
                },
                tooltip: '履歴 (進む)',
              ),

              const SizedBox(
                  height: 24,
                  child: VerticalDivider(width: 20, indent: 4, endIndent: 4)),

              // 3. Execute
              IconButton(
                icon: const Icon(Icons.play_arrow),
                // color: iconColor,
                iconSize: iconSize,
                tooltip: provider.hasInvalidFilenames
                    ? 'エラー：ファイル名に禁止文字が含まれています'
                    : '実行',
                onPressed:
                    (provider.canExecute && !provider.hasInvalidFilenames)
                        ? () => _confirmAndExecute(context, provider)
                        : null,
              ),

              // 4. Undo
              if (!isNarrow)
                TextButton.icon(
                  icon: const Icon(Icons.undo),
                  label: Text(
                      provider.canUndo ? '戻す (${provider.undoCount})' : '戻す'),
                  style: TextButton.styleFrom(
                    // foregroundColor: iconColor, // Use theme
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: provider.canUndo
                      ? () => UndoHelper.handleUndo(context, provider)
                      : null,
                )
              else
                IconButton(
                  icon: const Icon(Icons.undo),
                  // color: iconColor,
                  iconSize: iconSize,
                  tooltip:
                      provider.canUndo ? '戻す (${provider.undoCount})' : '戻す',
                  onPressed: provider.canUndo
                      ? () => UndoHelper.handleUndo(context, provider)
                      : null,
                ),

              if (!isNarrow) ...[
                // Wide Layout: Show all icons
                const SizedBox(
                    height: 24,
                    child: VerticalDivider(width: 20, indent: 4, endIndent: 4)),

                // 5. Copy Group
                IconButton(
                  icon: const Icon(Icons.content_copy),
                  // color: Colors.grey[700], // Use Theme
                  iconSize: iconSize,
                  tooltip: 'コピー (現在名)',
                  onPressed: provider.currentFiles.any((f) => f.isSelected)
                      ? () => CopyHelper.handleCopy(context, provider)
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                PopupMenuButton<int>(
                  icon: const Icon(Icons.arrow_drop_down),
                  // color: Colors.white,
                  enabled: provider.currentFiles.any((f) => f.isSelected) ||
                      provider.getLastUndoTransaction().isNotEmpty,
                  onSelected: (value) async {
                    await CopyHelper.handleCopyMenu(context, provider, value);
                  },
                  itemBuilder: (context) => _buildCopyMenuItems(provider),
                  tooltip: 'コピーオプション',
                ),

                const SizedBox(
                    height: 24,
                    child: VerticalDivider(width: 20, indent: 4, endIndent: 4)),

                // 6. Up/Down
                IconButton(
                  icon: const Icon(Icons.expand_less),
                  // color: iconColor,
                  iconSize: iconSize,
                  tooltip: '上に移動',
                  onPressed: provider.canMoveUp
                      ? () => provider.moveSelection(true)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.expand_more),
                  // color: iconColor,
                  iconSize: iconSize,
                  tooltip: '下に移動',
                  onPressed: provider.canMoveDown
                      ? () => provider.moveSelection(false)
                      : null,
                ),

                const SizedBox(
                    height: 24,
                    child: VerticalDivider(width: 20, indent: 4, endIndent: 4)),

                // 8. Refresh
                IconButton(
                  icon: const Icon(Icons.refresh),
                  // color: iconColor,
                  iconSize: iconSize,
                  tooltip: '全て更新',
                  onPressed: () => provider.refresh(),
                ),
              ] else ...[
                // Narrow Layout: Show Overflow Menu
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert), //, color: iconColor),
                  tooltip: 'その他の操作',
                  onSelected: (value) async {
                    switch (value) {
                      case 'copy_name':
                        await CopyHelper.handleCopy(context, provider);
                        break;
                      case 'copy_path':
                        await CopyHelper.handleCopyMenu(context, provider, 2);
                        break;
                      case 'copy_fullpath':
                        await CopyHelper.handleCopyMenu(context, provider, 3);
                        break;
                      case 'copy_undo':
                        await CopyHelper.handleCopyMenu(context, provider, 4);
                        break;
                      case 'move_up':
                        provider.moveSelection(true);
                        break;
                      case 'move_down':
                        provider.moveSelection(false);
                        break;
                      case 'refresh':
                        provider.refresh();
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    final hasSelection =
                        provider.currentFiles.any((f) => f.isSelected);
                    final hasUndo =
                        provider.getLastUndoTransaction().isNotEmpty;
                    return [
                      // Flattened Copy Options
                      PopupMenuItem(
                        value: 'copy_name',
                        enabled: hasSelection,
                        child: const Row(
                          children: [
                            Icon(Icons.content_copy, size: 20),
                            SizedBox(width: 8),
                            Text('コピー (現在名)'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'copy_path',
                        enabled: hasSelection,
                        child: const Row(
                          children: [
                            Icon(Icons.copy, size: 20),
                            SizedBox(width: 8),
                            Text('コピー (パス)'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'copy_fullpath',
                        enabled: hasSelection,
                        child: const Row(
                          children: [
                            Icon(Icons.copy_all, size: 20),
                            SizedBox(width: 8),
                            Text('コピー (フルパス)'),
                          ],
                        ),
                      ),
                      if (hasUndo)
                        const PopupMenuItem(
                          value: 'copy_undo',
                          child: Row(
                            children: [
                              Icon(Icons.history, size: 20),
                              SizedBox(width: 8),
                              Text('変更記録をコピー'),
                            ],
                          ),
                        ),
                      const PopupMenuDivider(),
                      // Move
                      PopupMenuItem(
                        value: 'move_up',
                        enabled: provider.canMoveUp,
                        child: const Row(
                          children: [
                            Icon(Icons.expand_less, size: 20),
                            SizedBox(width: 8),
                            Text('上に移動'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'move_down',
                        enabled: provider.canMoveDown,
                        child: const Row(
                          children: [
                            Icon(Icons.expand_more, size: 20),
                            SizedBox(width: 8),
                            Text('下に移動'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      // Refresh
                      const PopupMenuItem(
                        value: 'refresh',
                        child: Row(
                          children: [
                            Icon(Icons.refresh, size: 20),
                            SizedBox(width: 8),
                            Text('全て更新'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          },
          tooltip: 'アプリ設定',
        ),
      ],
    );
  }

  Future<void> _confirmAndExecute(
      BuildContext context, DirectoryProvider provider) async {
    if (!provider.currentFiles.any((f) => f.isSelected)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ファイルが選択されていません')),
      );
      return;
    }

    final executedCount = await provider.executeRename();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$executedCount 個のファイルをリネームしました')),
      );
    }
  }

  List<PopupMenuEntry<int>> _buildCopyMenuItems(DirectoryProvider provider) {
    final hasSelection = provider.currentFiles.any((f) => f.isSelected);
    final hasUndo = provider.getLastUndoTransaction().isNotEmpty;

    return [
      PopupMenuItem(
        value: 1,
        height: 32,
        enabled: hasSelection,
        child: const Text('クリップボードへ現在のリストをコピー', style: TextStyle(fontSize: 12)),
      ),
      PopupMenuItem(
        value: 2,
        height: 32,
        enabled: hasSelection,
        child: const Text('クリップボードへ現在のリストをコピー (Path)',
            style: TextStyle(fontSize: 12)),
      ),
      PopupMenuItem(
        value: 3,
        height: 32,
        enabled: hasSelection,
        child:
            const Text('クリップボードへフルパスリストをコピー', style: TextStyle(fontSize: 12)),
      ),
      PopupMenuItem(
        value: 4,
        height: 32,
        enabled: hasUndo,
        child: const Text('直前の変更記録をクリップボードへ', style: TextStyle(fontSize: 12)),
      ),
    ];
  }
}
