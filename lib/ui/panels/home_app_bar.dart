import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/directory_provider.dart';
import '../helpers/undo_helper.dart';
import '../helpers/copy_helper.dart';
import 'package:path/path.dart' as p;
import '../settings_screen.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<DirectoryProvider>();
    const iconSize = 28.0;

    return AppBar(
      leading: showDrawerMenu
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.folder),
                color: Theme.of(context).colorScheme.primary,
                tooltip: l10n.labelMenuFolder,
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
          final isNarrow = constraints.maxWidth < 650;
          return Row(
            children: [
              const SizedBox(width: 8),
              // 1. Back Group
              IconButton(
                icon: const Icon(Icons.arrow_back),
                iconSize: iconSize,
                tooltip: l10n.labelNavBack,
                onPressed: provider.canGoBack ? () => provider.goBack() : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              PopupMenuButton<int>(
                icon: const Icon(Icons.arrow_drop_down),
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
                tooltip: l10n.labelHistoryBack,
              ),

              // 2. Forward Group
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                iconSize: iconSize,
                tooltip: l10n.labelNavForward,
                onPressed:
                    provider.canGoForward ? () => provider.goForward() : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              PopupMenuButton<int>(
                icon: const Icon(Icons.arrow_drop_down),
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
                tooltip: l10n.labelHistoryForward,
              ),

              // 2.5. Up Group
              IconButton(
                icon: const Icon(Icons.arrow_upward),
                iconSize: iconSize,
                tooltip: l10n.labelNavUp,
                onPressed: provider.currentDirectory?.parent != null
                    ? () => provider.goUp()
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              const SizedBox(
                  height: 24,
                  child: VerticalDivider(width: 20, indent: 4, endIndent: 4)),

              // 3. Execute
              IconButton(
                icon: const Icon(Icons.play_arrow),
                iconSize: iconSize,
                tooltip: provider.hasInvalidFilenames
                    ? l10n.labelErrorInvalidFilename
                    : l10n.labelExecute,
                onPressed:
                    (provider.canExecute && !provider.hasInvalidFilenames)
                        ? () => _confirmAndExecute(context, provider, l10n)
                        : null,
              ),

              // 4. Undo
              if (!isNarrow)
                TextButton.icon(
                  icon: const Icon(Icons.undo),
                  label: Text(provider.canUndo
                      ? '${l10n.labelUndo} (${provider.undoCount})'
                      : l10n.labelUndo),
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: provider.canUndo
                      ? () => UndoHelper.handleUndo(context, provider)
                      : null,
                )
              else
                IconButton(
                  icon: const Icon(Icons.undo),
                  iconSize: iconSize,
                  tooltip: provider.canUndo
                      ? '${l10n.labelUndo} (${provider.undoCount})'
                      : l10n.labelUndo,
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
                  iconSize: iconSize,
                  tooltip: l10n.labelCopyName,
                  onPressed: provider.currentFiles.any((f) => f.isSelected)
                      ? () => CopyHelper.handleCopy(context, provider)
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                PopupMenuButton<int>(
                  icon: const Icon(Icons.arrow_drop_down),
                  enabled: provider.currentFiles.any((f) => f.isSelected) ||
                      provider.getLastUndoTransaction().isNotEmpty,
                  onSelected: (value) async {
                    await CopyHelper.handleCopyMenu(context, provider, value);
                  },
                  itemBuilder: (context) => _buildCopyMenuItems(provider, l10n),
                  tooltip: l10n.labelCopyOptions,
                ),

                const SizedBox(
                    height: 24,
                    child: VerticalDivider(width: 20, indent: 4, endIndent: 4)),

                // 6. Up/Down
                IconButton(
                  icon: const Icon(Icons.expand_less),
                  iconSize: iconSize,
                  tooltip: l10n.labelMoveUp,
                  onPressed: provider.canMoveUp
                      ? () => provider.moveSelection(true)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.expand_more),
                  iconSize: iconSize,
                  tooltip: l10n.labelMoveDown,
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
                  iconSize: iconSize,
                  tooltip: l10n.labelRefresh,
                  onPressed: () => provider.refresh(),
                ),
              ] else ...[
                // Narrow Layout: Show Overflow Menu
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: l10n.labelMenuMore,
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
                        child: Row(
                          children: [
                            const Icon(Icons.content_copy, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n.labelCopyName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'copy_path',
                        enabled: hasSelection,
                        child: Row(
                          children: [
                            const Icon(Icons.copy, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n.labelCopyPath),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'copy_fullpath',
                        enabled: hasSelection,
                        child: Row(
                          children: [
                            const Icon(Icons.copy_all, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n.labelCopyFullPath),
                          ],
                        ),
                      ),
                      if (hasUndo)
                        PopupMenuItem(
                          value: 'copy_undo',
                          child: Row(
                            children: [
                              const Icon(Icons.history, size: 20),
                              const SizedBox(width: 8),
                              Text(l10n.labelCopyUndo),
                            ],
                          ),
                        ),
                      const PopupMenuDivider(),
                      // Move
                      PopupMenuItem(
                        value: 'move_up',
                        enabled: provider.canMoveUp,
                        child: Row(
                          children: [
                            const Icon(Icons.expand_less, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n.labelMoveUp),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'move_down',
                        enabled: provider.canMoveDown,
                        child: Row(
                          children: [
                            const Icon(Icons.expand_more, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n.labelMoveDown),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      // Refresh
                      PopupMenuItem(
                        value: 'refresh',
                        child: Row(
                          children: [
                            const Icon(Icons.refresh, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n.labelRefresh),
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
          tooltip: l10n.labelMenuSettings,
        ),
      ],
    );
  }

  Future<void> _confirmAndExecute(BuildContext context,
      DirectoryProvider provider, AppLocalizations l10n) async {
    if (!provider.currentFiles.any((f) => f.isSelected)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.labelMsgNoSelection)),
      );
      return;
    }

    final executedCount = await provider.executeRename();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.labelMsgExecutedCount(executedCount))),
      );
    }
  }

  List<PopupMenuEntry<int>> _buildCopyMenuItems(
      DirectoryProvider provider, AppLocalizations l10n) {
    final hasSelection = provider.currentFiles.any((f) => f.isSelected);
    final hasUndo = provider.getLastUndoTransaction().isNotEmpty;

    return [
      PopupMenuItem(
        value: 1,
        height: 32,
        enabled: hasSelection,
        child: Text(l10n.labelCopyListClipboard,
            style: const TextStyle(fontSize: 12)),
      ),
      PopupMenuItem(
        value: 2,
        height: 32,
        enabled: hasSelection,
        child:
            Text(l10n.labelCopyListPath, style: const TextStyle(fontSize: 12)),
      ),
      PopupMenuItem(
        value: 3,
        height: 32,
        enabled: hasSelection,
        child:
            Text(l10n.labelCopyFullPath, style: const TextStyle(fontSize: 12)),
      ),
      PopupMenuItem(
        value: 4,
        height: 32,
        enabled: hasUndo,
        child: Text(l10n.labelCopyUndo, style: const TextStyle(fontSize: 12)),
      ),
    ];
  }
}
