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
                tooltip: provider.labelMenuFolder,
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
                iconSize: iconSize,
                tooltip: provider.labelNavBack,
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
                tooltip: provider.labelHistoryBack,
              ),

              // 2. Forward Group
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                // color: iconColor,
                iconSize: iconSize,
                tooltip: provider.labelNavForward,
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
                tooltip: provider.labelHistoryForward,
              ),

              const SizedBox(
                  height: 24,
                  child: VerticalDivider(width: 20, indent: 4, endIndent: 4)),

              // 3. Execute (Go ReNamery!!!)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: Text(provider.labelGoRenamery,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed:
                      (provider.canExecute && !provider.hasInvalidFilenames)
                          ? () => _confirmAndExecute(context, provider)
                          : null,
                ), // Tooltip handled by button? Or wrap? FilledButton handles tooltip if standard? No, need explicit Tooltip widget if desired, but text is self-explanatory.
              ),

              // 4. Undo
              if (!isNarrow)
                TextButton.icon(
                  icon: const Icon(Icons.undo),
                  label: Text(provider.canUndo
                      ? '${provider.labelUndo} (${provider.undoCount})'
                      : provider.labelUndo),
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
                  tooltip: provider.canUndo
                      ? '${provider.labelUndo} (${provider.undoCount})'
                      : provider.labelUndo,
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
                  tooltip: provider.labelCopyName,
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
                  tooltip: provider.labelCopyOptions,
                ),

                const SizedBox(
                    height: 24,
                    child: VerticalDivider(width: 20, indent: 4, endIndent: 4)),

                // 6. Up/Down
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  // color: iconColor,
                  iconSize: iconSize,
                  tooltip: provider.labelMoveUp,
                  onPressed: provider.canMoveUp
                      ? () => provider.moveSelection(true)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward),
                  // color: iconColor,
                  iconSize: iconSize,
                  tooltip: provider.labelMoveDown,
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
                  tooltip: provider.labelRefresh,
                  onPressed: () => provider.refresh(),
                ),
              ] else ...[
                // Narrow Layout: Show Overflow Menu
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert), //, color: iconColor),
                  tooltip: provider.labelMenuMore,
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
                            Icon(Icons.arrow_upward, size: 20),
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
                            Icon(Icons.arrow_downward, size: 20),
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
          tooltip: provider.labelMenuSettings,
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
        child: Text(provider.labelCopyListClipboard,
            style: const TextStyle(fontSize: 12)),
      ),
      PopupMenuItem(
        value: 2,
        height: 32,
        enabled: hasSelection,
        child: Text(
            '${provider.labelCopyListClipboard} (Path)', // Partially distinct? Or add labelCopyListPath
            style: const TextStyle(fontSize: 12)),
      ),
      PopupMenuItem(
        value: 3,
        height: 32,
        enabled: hasSelection,
        child: Text(provider.labelCopyFullPath,
            style: const TextStyle(fontSize: 12)),
      ),
      PopupMenuItem(
        value: 4,
        height: 32,
        enabled: hasUndo,
        child:
            Text(provider.labelCopyUndo, style: const TextStyle(fontSize: 12)),
      ),
    ];
  }
}
