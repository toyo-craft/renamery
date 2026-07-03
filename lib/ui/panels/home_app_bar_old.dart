import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/directory_provider_platform.dart';
import '../settings_screen.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';
import '../helpers/undo_helper.dart';
import '../helpers/copy_helper.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showDrawerMenu;

  const HomeAppBar({
    super.key,
    this.showDrawerMenu = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<DirectoryProvider>();
    final isCompact = provider.isCompactMode;

    return AppBar(
      title: const Text(
        'ReNamery',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      leadingWidth: showDrawerMenu ? null : 0,
      leading: showDrawerMenu ? null : const SizedBox.shrink(),
      centerTitle: isCompact,
      bottom: isCompact
          ? PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            )
          : null,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final showWide = constraints.maxWidth > 800;
          if (isCompact) return const SizedBox.shrink();

          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (showWide) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 100),
                  child: Row(
                    children: [
                      _ActionButton(
                        icon: Icons.play_arrow,
                        label: l10n.labelExecute,
                        onPressed: () =>
                            _confirmAndExecute(context, provider, l10n),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.undo,
                        label: l10n.labelUndo,
                        onPressed: provider.getLastUndoTransaction().isEmpty
                            ? null
                            : () => UndoHelper.handleUndo(context, provider),
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.refresh,
                        label: l10n.labelRefresh,
                        onPressed: () => provider.refresh(),
                      ),
                      const SizedBox(width: 16),
                      // Copy Menu
                      PopupMenuButton<int>(
                        tooltip: l10n.labelCopyOptions,
                        itemBuilder: (context) =>
                            _buildCopyMenuItems(provider, l10n),
                        onSelected: (val) {
                          if (val == 1) {
                            CopyHelper.handleCopyMenu(context, provider, 1);
                          }
                          if (val == 2) {
                            CopyHelper.handleCopyMenu(context, provider, 2);
                          }
                          if (val == 3) {
                            CopyHelper.handleCopyMenu(context, provider, 3);
                          }
                          if (val == 4) {
                            CopyHelper.handleCopyMenu(context, provider, 4);
                          }
                        },
                        child: _ActionButton(
                          icon: Icons.copy,
                          label: l10n.labelCopyOptions,
                          onPressed: null, // Just to show the button style
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Narrow layout menu
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 60),
                  child: PopupMenuButton<int>(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 1,
                        child: Row(
                          children: [
                            const Icon(Icons.play_arrow, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n.labelExecute),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 2,
                        enabled: provider.getLastUndoTransaction().isNotEmpty,
                        child: Row(
                          children: [
                            const Icon(Icons.undo, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n.labelUndo),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 3,
                        child: Row(
                          children: [
                            const Icon(Icons.refresh, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n.labelRefresh),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      ..._buildCopyMenuItems(provider, l10n),
                    ],
                    onSelected: (val) {
                      if (val == 1) _confirmAndExecute(context, provider, l10n);
                      if (val == 2) UndoHelper.handleUndo(context, provider);
                      if (val == 3) provider.refresh();
                      // Values from _buildCopyMenuItems
                      if (val == 101) {
                        CopyHelper.handleCopyMenu(context, provider, 1);
                      }
                      if (val == 102) {
                        CopyHelper.handleCopyMenu(context, provider, 2);
                      }
                      if (val == 103) {
                        CopyHelper.handleCopyMenu(context, provider, 3);
                      }
                    },
                  ),
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
            : l10n.labelMsgExecutedCount(executedCount);
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

  List<PopupMenuEntry<int>> _buildCopyMenuItems(
      DirectoryProvider provider, AppLocalizations l10n) {
    final hasSelection = provider.currentFiles.any((f) => f.isSelected);
    final hasUndo = provider.getLastUndoTransaction().isNotEmpty;

    return [
      PopupMenuItem(
        value: 101, // Changed values to avoid collision in narrow menu
        height: 32,
        enabled: hasSelection,
        child: Text(l10n.labelCopyListClipboard,
            style: const TextStyle(fontSize: 12)),
      ),
      PopupMenuItem(
        value: 102,
        height: 32,
        enabled: hasSelection,
        child:
            Text(l10n.labelCopyListPath, style: const TextStyle(fontSize: 12)),
      ),
      PopupMenuItem(
        value: 103,
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final theme = Theme.of(context);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isEnabled
                  ? (color ?? theme.colorScheme.onSurface)
                  : theme.disabledColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isEnabled
                    ? theme.colorScheme.onSurface
                    : theme.disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
