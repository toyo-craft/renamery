import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/directory_provider_platform.dart';
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

          if (isNarrow) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(width: 2),
                _buildCompactIconButton(
                  context,
                  icon: Symbols.arrow_back,
                  tooltip: l10n.labelNavBack,
                  onPressed:
                      provider.canGoBack ? () => provider.goBack() : null,
                  onLongPress: provider.backHistory.isNotEmpty
                      ? () => _showHistoryMenu(
                          context, provider.backHistory, provider.jumpBack)
                      : null,
                ),
                _buildCompactIconButton(
                  context,
                  icon: Symbols.arrow_forward,
                  tooltip: l10n.labelNavForward,
                  onPressed:
                      provider.canGoForward ? () => provider.goForward() : null,
                  onLongPress: provider.forwardHistory.isNotEmpty
                      ? () => _showHistoryMenu(context, provider.forwardHistory,
                          provider.jumpForward)
                      : null,
                ),
                _buildCompactIconButton(
                  context,
                  icon: Symbols.arrow_upward,
                  tooltip: l10n.labelNavUp,
                  onPressed: provider.currentDirectory?.parent != null
                      ? () => provider.goUp()
                      : null,
                ),
                _buildCompactIconButton(
                  context,
                  icon: Symbols.undo,
                  tooltip: l10n.labelUndo,
                  onPressed: provider.canUndo
                      ? () => UndoHelper.handleUndo(context, provider)
                      : null,
                ),
                _buildCompactIconButton(
                  context,
                  icon: Symbols.content_copy,
                  tooltip: l10n.labelCopyOptions,
                  onPressed: () =>
                      CopyHelper.showCopyOptionsBottomSheet(context, provider),
                ),
                _buildCompactIconButton(
                  context,
                  icon: Symbols.expand_less,
                  tooltip: l10n.labelMoveUp,
                  onPressed: provider.canMoveUp
                      ? () => provider.moveSelection(true)
                      : null,
                ),
                _buildCompactIconButton(
                  context,
                  icon: Symbols.expand_more,
                  tooltip: l10n.labelMoveDown,
                  onPressed: provider.canMoveDown
                      ? () => provider.moveSelection(false)
                      : null,
                ),
                _buildCompactIconButton(
                  context,
                  icon: Symbols.refresh,
                  tooltip: l10n.labelRefresh,
                  onPressed: () => provider.refresh(),
                ),
                const SizedBox(width: 2),
              ],
            );
          }

          return Row(
            children: [
              const SizedBox(width: 8),
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
              const SizedBox(
                  height: 24,
                  child: VerticalDivider(width: 20, indent: 4, endIndent: 4)),
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
                    child: VerticalDivider(width: 20, indent: 4, endIndent: 4)),
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
                _buildRegexSearchBar(
                    context, provider, l10n, isNarrow ? 120 : 160),
              ],
              if (showIconFilters) ...[
                const SizedBox(
                    height: 24,
                    child: VerticalDivider(width: 20, indent: 4, endIndent: 4)),
                IconButton(
                  icon: Icon(
                    provider.showFolders ? Symbols.folder : Symbols.folder_off,
                    fill: 1,
                    color:
                        provider.showFolders ? Colors.amber[700] : Colors.grey,
                  ),
                  iconSize: 20,
                  onPressed: () => context
                      .read<DirectoryProvider>()
                      .updateFilterSettings(showFolders: !provider.showFolders),
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
                _buildRegexSearchBar(context, provider, l10n, 100),
              ],
              if (!isWide && !showIconFilters && !isNarrow) ...[
                const Spacer(),
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

  // --- Helper Methods for Mobile Header ---

  Widget _buildCompactIconButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
  }) {
    final bool isEnabled = onPressed != null;
    final color = isEnabled
        ? Theme.of(context).colorScheme.primary // 活性時はブランドカラー（プライマリ）
        : Theme.of(context).disabledColor; // 不活性時はグレー

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(
            icon,
            size: 24,
            fill: 1, // 塗りつぶしスタイル
            color: color,
          ),
        ),
      ),
    );
  }

  void _showHistoryMenu(
      BuildContext context, List<String> history, Function(int) onSelected) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<int>(
      context: context,
      position: position,
      items: List.generate(history.length, (index) {
        return PopupMenuItem(
          value: index + 1,
          height: 32,
          child: Text(p.basename(history[index]),
              style: const TextStyle(fontSize: 12)),
        );
      }),
    ).then((value) {
      if (value != null) onSelected(value);
    });
  }

  Widget _buildRegexSearchBar(BuildContext context, DirectoryProvider provider,
      AppLocalizations l10n, double width) {
    final bool isRegex = provider.isFilterRegex;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: 32,
      decoration: ShapeDecoration(
        color: isRegex
            ? colorScheme.inverseSurface
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: StadiumBorder(
          side: isRegex
              ? BorderSide(color: colorScheme.primary, width: 1)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Center(
            child: IconButton(
              icon: Icon(
                Symbols.regular_expression,
                size: 16,
                fill: isRegex ? 1 : 0,
                color: isRegex
                    ? colorScheme.onInverseSurface
                    : colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                provider.updateFilterSettings(isRegex: !isRegex);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 32),
              tooltip: l10n.labelRegex,
            ),
          ),
          Expanded(
            child: Align(
              alignment: const Alignment(0, -0.2),
              child: TextField(
                controller: _filterController,
                decoration: InputDecoration.collapsed(
                  hintText: isRegex
                      ? l10n.labelRegexSearchHint
                      : l10n.labelSearchHint,
                  hintStyle: TextStyle(
                      fontSize: 11,
                      color: isRegex
                          ? colorScheme.onInverseSurface.withValues(alpha: 0.6)
                          : Colors.grey),
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: isRegex
                      ? colorScheme.onInverseSurface
                      : colorScheme.onSurface,
                ),
                onChanged: (value) => provider.updateFilterSettings(
                    isSpecific: value.isNotEmpty, filter: value),
              ),
            ),
          ),
          if (provider.isFilterSpecific)
            Center(
              child: IconButton(
                icon: Icon(Symbols.close,
                    size: 14,
                    color: isRegex ? colorScheme.onInverseSurface : null),
                onPressed: () {
                  _filterController.clear();
                  provider.updateFilterSettings(isSpecific: false, filter: '');
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 32),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Future<void> _confirmAndExecute(BuildContext context,
      DirectoryProvider provider, AppLocalizations l10n) async {
    await provider.executeRename();
  }

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
