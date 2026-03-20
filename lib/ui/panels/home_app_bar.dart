import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
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
                icon: const Icon(Symbols.folder_open, fill: 1),
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
          final isWide = constraints.maxWidth >= 1020;
          final showIconFilters = !isWide && constraints.maxWidth >= 830;
          return Row(
            children: [
              const SizedBox(width: 8),
              // 1. Back Group
              IconButton(
                icon: const Icon(Symbols.arrow_back),
                iconSize: iconSize,
                tooltip: l10n.labelNavBack,
                onPressed: provider.canGoBack ? () => provider.goBack() : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              PopupMenuButton<int>(
                icon: const Icon(Symbols.arrow_drop_down),
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
                icon: const Icon(Symbols.arrow_forward),
                iconSize: iconSize,
                tooltip: l10n.labelNavForward,
                onPressed:
                    provider.canGoForward ? () => provider.goForward() : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              PopupMenuButton<int>(
                icon: const Icon(Symbols.arrow_drop_down),
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
                icon: const Icon(Symbols.arrow_upward),
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
                icon: const Icon(Symbols.play_arrow),
                iconSize: iconSize,
                tooltip: provider.hasInvalidFilenamesSelected
                    ? '一部のファイルにエラーがあります (クリックで詳細)'
                    : l10n.labelExecute,
                onPressed: provider.canExecute
                    ? () => _confirmAndExecute(context, provider, l10n)
                    : null,
              ),

              // 4. Undo / Redo
              if (!isNarrow) ...[
                TextButton.icon(
                  icon: const Icon(Symbols.undo),
                  label: Text(provider.canUndo
                      ? '${l10n.labelUndo} (${provider.undoCount})'
                      : l10n.labelUndo),
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: provider.canUndo
                      ? () => UndoHelper.handleUndo(context, provider)
                      : null,
                ),
                TextButton.icon(
                  icon: const Icon(Symbols.redo),
                  label: Text(provider.canRedo
                      ? '${l10n.labelRedo} (${provider.redoCount})'
                      : l10n.labelRedo),
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: provider.canRedo
                      ? () => UndoHelper.handleRedo(context, provider)
                      : null,
                ),
              ] else ...[
                IconButton(
                  icon: const Icon(Symbols.undo),
                  iconSize: iconSize,
                  tooltip: provider.canUndo
                      ? '${l10n.labelUndo} (${provider.undoCount})'
                      : l10n.labelUndo,
                  onPressed: provider.canUndo
                      ? () => UndoHelper.handleUndo(context, provider)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Symbols.redo),
                  iconSize: iconSize,
                  tooltip: provider.canRedo
                      ? '${l10n.labelRedo} (${provider.redoCount})'
                      : l10n.labelRedo,
                  onPressed: provider.canRedo
                      ? () => UndoHelper.handleRedo(context, provider)
                      : null,
                ),
              ],

              if (!isNarrow) ...[
                // Wide Layout: Show all icons
                const SizedBox(
                    height: 24,
                    child: VerticalDivider(width: 20, indent: 4, endIndent: 4)),

                // 5. Copy Group
                IconButton(
                  icon: const Icon(Symbols.content_copy),
                  iconSize: iconSize,
                  tooltip: l10n.labelCopyName,
                  onPressed: provider.currentFiles.any((f) => f.isSelected)
                      ? () => CopyHelper.handleCopy(context, provider)
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                PopupMenuButton<int>(
                  icon: const Icon(Symbols.arrow_drop_down),
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
                  icon: const Icon(Symbols.expand_less),
                  iconSize: iconSize,
                  tooltip: l10n.labelMoveUp,
                  onPressed: provider.canMoveUp
                      ? () => provider.moveSelection(true)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Symbols.expand_more),
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
                  icon: const Icon(Symbols.refresh),
                  iconSize: iconSize,
                  tooltip: l10n.labelRefresh,
                  onPressed: () => provider.refresh(),
                ),

                if (isWide) ...[
                  const SizedBox(
                      height: 24,
                      child:
                          VerticalDivider(width: 20, indent: 4, endIndent: 4)),
                  // 9. Filter Controls (Individual Toggle Buttons)
                  // Folder toggle — TextButton.icon style (like Undo), yellow/grey
                  Tooltip(
                    message: provider.showFolders
                        ? l10n.labelFilterHideFolders
                        : l10n.labelFilterShowFolders,
                    child: TextButton.icon(
                      icon: Icon(
                        provider.showFolders
                            ? Symbols.folder
                            : Symbols.folder_off,
                        size: 20,
                        fill: 1,
                        color: provider.showFolders
                            ? Colors.amber[700]
                            : Colors.grey,
                      ),
                      label: Text(
                        l10n.labelSettingsFolders,
                        style: TextStyle(
                          fontSize: 11,
                          color: provider.showFolders ? null : Colors.grey,
                        ),
                      ),
                      onPressed: () => context
                          .read<DirectoryProvider>()
                          .updateFilterSettings(
                              showFolders: !provider.showFolders),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        visualDensity: VisualDensity.compact,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // System files toggle
                  Tooltip(
                    message: provider.hideSystemFiles
                        ? l10n.labelSettingsShowSystemFiles
                        : l10n.labelFilterHideSystem,
                    child: TextButton.icon(
                      icon: Icon(
                        Symbols.shield,
                        size: 20,
                        fill: provider.hideSystemFiles ? 0 : 1,
                        color: provider.hideSystemFiles
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        l10n.labelSettingsSystemFiles,
                        style: TextStyle(
                          fontSize: 11,
                          color: provider.hideSystemFiles
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      onPressed: () => context
                          .read<DirectoryProvider>()
                          .updateFilterSettings(
                              hideSystem: !provider.hideSystemFiles),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        visualDensity: VisualDensity.compact,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Recursive search toggle
                  Tooltip(
                    message: provider.recursiveSearch
                        ? l10n.labelSettingsDisableRecursive
                        : l10n.labelFilterRecursive,
                    child: TextButton.icon(
                      icon: Icon(
                        Symbols.account_tree,
                        size: 20,
                        fill: provider.recursiveSearch ? 1 : 0,
                        color: provider.recursiveSearch
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      label: Text(
                        l10n.labelSettingsRecursive,
                        style: TextStyle(
                          fontSize: 11,
                          color: provider.recursiveSearch
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onPressed: () => context
                          .read<DirectoryProvider>()
                          .updateFilterSettings(
                              recursive: !provider.recursiveSearch),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        visualDensity: VisualDensity.compact,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Inline filter text input
                  SizedBox(
                    width: 130,
                    height: 28,
                    child: TextField(
                      controller: TextEditingController(
                        text: provider.filterText,
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: 'ファイル名...',
                        hintStyle:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                        prefixIcon: Icon(
                          Symbols.search,
                          size: 14,
                          color: provider.isFilterSpecific
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 26, minHeight: 28),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: provider.isFilterSpecific
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.withOpacity(0.4),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: provider.isFilterSpecific
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.withOpacity(0.4),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        suffixIcon: provider.isFilterSpecific
                            ? GestureDetector(
                                onTap: () => context
                                    .read<DirectoryProvider>()
                                    .updateFilterSettings(
                                        isSpecific: false, filter: ''),
                                child: const Icon(Symbols.close, size: 14),
                              )
                            : null,
                        suffixIconConstraints:
                            const BoxConstraints(minWidth: 24),
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: provider.isFilterSpecific
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onSubmitted: (value) {
                        context.read<DirectoryProvider>().updateFilterSettings(
                              isSpecific: value.isNotEmpty,
                              filter: value,
                            );
                      },
                    ),
                  ),
                ],

                if (showIconFilters) ...[
                  // Icon-only filter controls (no text labels)
                  const SizedBox(
                      height: 24,
                      child:
                          VerticalDivider(width: 20, indent: 4, endIndent: 4)),
                  // Folder toggle (icon only)
                  IconButton(
                    icon: Icon(
                      provider.showFolders
                          ? Symbols.folder
                          : Symbols.folder_off,
                      fill: 1,
                      color: provider.showFolders
                          ? Colors.amber[700]
                          : Colors.grey,
                    ),
                    iconSize: 20,
                    tooltip: provider.showFolders
                        ? l10n.labelFilterHideFolders
                        : l10n.labelFilterShowFolders,
                    onPressed: () => context
                        .read<DirectoryProvider>()
                        .updateFilterSettings(
                            showFolders: !provider.showFolders),
                    padding: const EdgeInsets.all(4),
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 8),
                  // System files toggle (icon only)
                  IconButton(
                    icon: Icon(
                      Symbols.shield,
                      fill: provider.hideSystemFiles ? 0 : 1,
                      color: provider.hideSystemFiles
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.primary,
                    ),
                    iconSize: 20,
                    tooltip: provider.hideSystemFiles
                        ? l10n.labelSettingsShowSystemFiles
                        : l10n.labelFilterHideSystem,
                    onPressed: () => context
                        .read<DirectoryProvider>()
                        .updateFilterSettings(
                            hideSystem: !provider.hideSystemFiles),
                    padding: const EdgeInsets.all(4),
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 8),
                  // Recursive search toggle (icon only)
                  IconButton(
                    icon: Icon(
                      Symbols.account_tree,
                      fill: provider.recursiveSearch ? 1 : 0,
                      color: provider.recursiveSearch
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    iconSize: 20,
                    tooltip: provider.recursiveSearch
                        ? l10n.labelSettingsDisableRecursive
                        : l10n.labelFilterRecursive,
                    onPressed: () => context
                        .read<DirectoryProvider>()
                        .updateFilterSettings(
                            recursive: !provider.recursiveSearch),
                    padding: const EdgeInsets.all(4),
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 8),
                  // Search field (compact, icon only)
                  SizedBox(
                    width: 100,
                    height: 28,
                    child: TextField(
                      controller: TextEditingController(
                        text: provider.filterText,
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: 'ファイル名...',
                        hintStyle:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                        prefixIcon: Icon(
                          Symbols.search,
                          size: 14,
                          color: provider.isFilterSpecific
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 26, minHeight: 28),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: provider.isFilterSpecific
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.withOpacity(0.4),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: provider.isFilterSpecific
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.withOpacity(0.4),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        suffixIcon: provider.isFilterSpecific
                            ? GestureDetector(
                                onTap: () => context
                                    .read<DirectoryProvider>()
                                    .updateFilterSettings(
                                        isSpecific: false, filter: ''),
                                child: const Icon(Symbols.close, size: 14),
                              )
                            : null,
                        suffixIconConstraints:
                            const BoxConstraints(minWidth: 24),
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: provider.isFilterSpecific
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onSubmitted: (value) {
                        context.read<DirectoryProvider>().updateFilterSettings(
                              isSpecific: value.isNotEmpty,
                              filter: value,
                            );
                      },
                    ),
                  ),
                ],
              ],

              // Unified spacer for right-aligning overflow menus
              if (isNarrow || (!isWide && !showIconFilters)) const Spacer(),

              if (isNarrow) ...[
                // Narrow Layout: Show Overflow Menu
                PopupMenuButton<String>(
                  icon: const Icon(Symbols.more_vert),
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
                            const Icon(Symbols.content_copy, size: 20),
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
                            const Icon(Symbols.copy_all, size: 20),
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
                            const Icon(Symbols.copy_all, size: 20),
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
                              const Icon(Symbols.history, size: 20),
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
                            const Icon(Symbols.expand_less, size: 20),
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
                            const Icon(Symbols.expand_more, size: 20),
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
                            const Icon(Symbols.refresh, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n.labelRefresh),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],

              // Filter divider + inline controls for narrow (fold into overflow was done above)
              // Filter popup when no inline filters
              if (!isWide && !showIconFilters) ...[
                Builder(
                  builder: (context) => IconButton(
                    icon: Icon(
                      Symbols.filter_list,
                      color: _isFilterActive(context)
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    tooltip: l10n.labelSettingsFilterTitle,
                    onPressed: () => _showFilterPopup(context, l10n),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Symbols.settings, fill: 1.0),
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
      // パターン2: エラーがある場合は確認ダイアログを表示
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

      // ダイアログでキャンセル、あるいはダイアログ外タップで閉じた場合は中断
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

  bool _isFilterActive(BuildContext context) {
    final provider = context.read<DirectoryProvider>();
    return provider.isFilterSpecific ||
        provider.hideSystemFiles ||
        provider.recursiveSearch;
  }

  void _showFilterPopup(BuildContext context, AppLocalizations l10n) {
    final provider = context.read<DirectoryProvider>();
    final filterCtrl = TextEditingController(text: provider.filterText);

    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        return Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: kToolbarHeight + 4, right: 8),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(12),
                child: StatefulBuilder(
                  builder: (context, setState) {
                    final p = context.watch<DirectoryProvider>();
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          l10n.labelSettingsFilterTitle,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        // Show Folders toggle
                        Row(children: [
                          Icon(Symbols.folder,
                              size: 18,
                              color: p.showFolders
                                  ? Colors.amber[700]
                                  : Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                              p.showFolders
                                  ? l10n.labelFilterHideFolders
                                  : l10n.labelFilterShowFolders,
                              style: const TextStyle(fontSize: 12)),
                          const Spacer(),
                          Switch(
                            value: p.showFolders,
                            onChanged: (val) {
                              context
                                  .read<DirectoryProvider>()
                                  .updateFilterSettings(showFolders: val);
                            },
                          ),
                        ]),
                        const Divider(height: 16),
                        // All Files radio
                        RadioListTile<bool>(
                          dense: true,
                          value: false,
                          groupValue: p.isFilterSpecific,
                          title: Text(l10n.labelFilterAll,
                              style: const TextStyle(fontSize: 12)),
                          onChanged: (val) {
                            if (val != null) {
                              context
                                  .read<DirectoryProvider>()
                                  .updateFilterSettings(isSpecific: val);
                            }
                          },
                        ),
                        // Specific filter radio + text field
                        RadioListTile<bool>(
                          dense: true,
                          value: true,
                          groupValue: p.isFilterSpecific,
                          title: Text(l10n.labelFilterSpecific,
                              style: const TextStyle(fontSize: 12)),
                          onChanged: (val) {
                            if (val != null) {
                              context
                                  .read<DirectoryProvider>()
                                  .updateFilterSettings(isSpecific: val);
                            }
                          },
                        ),
                        if (p.isFilterSpecific)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            child: TextField(
                              controller: filterCtrl,
                              autofocus: true,
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6)),
                              ),
                              onChanged: (val) {
                                context
                                    .read<DirectoryProvider>()
                                    .updateFilterSettings(filter: val);
                              },
                            ),
                          ),
                        const Divider(height: 8),
                        // Checkboxes
                        CheckboxListTile(
                          dense: true,
                          value: p.hideSystemFiles,
                          title: Text(l10n.labelFilterHideSystem,
                              style: const TextStyle(fontSize: 12)),
                          onChanged: (val) {
                            context
                                .read<DirectoryProvider>()
                                .updateFilterSettings(hideSystem: val ?? false);
                          },
                        ),
                        CheckboxListTile(
                          dense: true,
                          value: p.recursiveSearch,
                          title: Text(l10n.labelFilterRecursive,
                              style: const TextStyle(fontSize: 12)),
                          onChanged: (val) {
                            context
                                .read<DirectoryProvider>()
                                .updateFilterSettings(recursive: val ?? false);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    ).then((_) => filterCtrl.dispose());
  }
}
