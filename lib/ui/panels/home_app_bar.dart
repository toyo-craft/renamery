import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/directory_provider.dart';
import '../helpers/undo_helper.dart';
import '../helpers/copy_helper.dart';
import '../helpers/filter_dialog_helper.dart';
import 'package:path/path.dart' as p;
import '../settings_screen.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

class HomeAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool showDrawerMenu;

  const HomeAppBar({
    super.key,
    this.showDrawerMenu = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> {
  late TextEditingController _filterController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DirectoryProvider>();
    _filterController = TextEditingController(text: provider.filterText);
  }

  @override
  void didUpdateWidget(HomeAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 外部からのフィルタテキスト変更を反映
    final provider = context.read<DirectoryProvider>();
    if (_filterController.text != provider.filterText) {
      _filterController.text = provider.filterText;
    }
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<DirectoryProvider>();
    const iconSize = 28.0;

    // 同期を確実にする
    if (_filterController.text != provider.filterText) {
      _filterController.text = provider.filterText;
    }

    return AppBar(
      leading: widget.showDrawerMenu
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
      automaticallyImplyLeading: false,
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
              if (!isNarrow)
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

              // 4. Undo
              if (!isNarrow)
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
                )
              else
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

              if (!isNarrow) ...[
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
                  // 9. Filter Controls
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
                  // Search Field (Stable Controller)
                  SizedBox(
                    width: 130,
                    height: 28,
                    child: TextField(
                      controller: _filterController,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: 'ファイル名...',
                        hintStyle:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                        prefixIcon: const Icon(Symbols.search, size: 14),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 26, minHeight: 28),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        suffixIcon: provider.isFilterSpecific
                            ? IconButton(
                                icon: const Icon(Symbols.close, size: 14),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  _filterController.clear();
                                  context
                                      .read<DirectoryProvider>()
                                      .updateFilterSettings(
                                          isSpecific: false, filter: '');
                                },
                              )
                            : null,
                        suffixIconConstraints:
                            const BoxConstraints(minWidth: 24),
                      ),
                      style: const TextStyle(fontSize: 12),
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
                  const SizedBox(
                      height: 24,
                      child:
                          VerticalDivider(width: 20, indent: 4, endIndent: 4)),
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
                    onPressed: () => context
                        .read<DirectoryProvider>()
                        .updateFilterSettings(
                            showFolders: !provider.showFolders),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Symbols.shield,
                      fill: provider.hideSystemFiles ? 0 : 1,
                      color: provider.hideSystemFiles
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.primary,
                    ),
                    iconSize: 20,
                    onPressed: () => context
                        .read<DirectoryProvider>()
                        .updateFilterSettings(
                            hideSystem: !provider.hideSystemFiles),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Symbols.account_tree,
                      fill: provider.recursiveSearch ? 1 : 0,
                      color: provider.recursiveSearch
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    iconSize: 20,
                    onPressed: () => context
                        .read<DirectoryProvider>()
                        .updateFilterSettings(
                            recursive: !provider.recursiveSearch),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    height: 28,
                    child: TextField(
                      controller: _filterController,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: 'ファイル名...',
                        hintStyle:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                        prefixIcon: const Icon(Symbols.search, size: 14),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 26, minHeight: 28),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        suffixIcon: provider.isFilterSpecific
                            ? IconButton(
                                icon: const Icon(Symbols.close, size: 14),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  _filterController.clear();
                                  context
                                      .read<DirectoryProvider>()
                                      .updateFilterSettings(
                                          isSpecific: false, filter: '');
                                },
                              )
                            : null,
                        suffixIconConstraints:
                            const BoxConstraints(minWidth: 24),
                      ),
                      style: const TextStyle(fontSize: 12),
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

              if (isNarrow || (!isWide && !showIconFilters)) const Spacer(),

              if (isNarrow) ...[
                PopupMenuButton<String>(
                  icon: const Icon(Symbols.more_vert),
                  onSelected: (value) async {
                    switch (value) {
                      case 'copy_name':
                        await CopyHelper.handleCopy(context, provider);
                        break;
                      case 'refresh':
                        provider.refresh();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'copy_name',
                      child: Text(l10n.labelCopyName),
                    ),
                    PopupMenuItem(
                      value: 'refresh',
                      child: Text(l10n.labelRefresh),
                    ),
                  ],
                ),
              ],

              if (!isWide && !showIconFilters && !isNarrow) ...[
                IconButton(
                  icon: const Icon(Symbols.search),
                  tooltip: l10n.labelFilterOptions,
                  onPressed: () => FilterDialogHelper.showFilterPopup(context),
                ),
              ],
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Symbols.settings, fill: 1.0),
          tooltip: l10n.labelMenuSettings,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _confirmAndExecute(BuildContext context,
      DirectoryProvider provider, AppLocalizations l10n) async {
    final executedCount = await provider.executeRename();
    if (context.mounted && executedCount > 0) {
      // (省略)
    }
  }

  // (中略)

  List<PopupMenuEntry<int>> _buildCopyMenuItems(
      DirectoryProvider provider, AppLocalizations l10n) {
    return [
      PopupMenuItem(
          value: 1, height: 32, child: Text(l10n.labelCopyListClipboard)),
      PopupMenuItem(value: 2, height: 32, child: Text(l10n.labelCopyListPath)),
      PopupMenuItem(value: 3, height: 32, child: Text(l10n.labelCopyFullPath)),
      PopupMenuItem(value: 4, height: 32, child: Text(l10n.labelCopyUndo)),
    ];
  }
}
