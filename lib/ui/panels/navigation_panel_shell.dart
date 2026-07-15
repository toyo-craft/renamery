import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:provider/provider.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

import '../../core/directory_provider_platform.dart';
import '../widgets/navigation_drop_zone.dart';
import '../widgets/preview_window.dart';

class NavigationPanelShell extends StatefulWidget {
  const NavigationPanelShell({super.key, required this.treeBuilder});

  final WidgetBuilder treeBuilder;

  @override
  State<NavigationPanelShell> createState() => _NavigationPanelShellState();
}

class _NavigationPanelShellState extends State<NavigationPanelShell> {
  late final MultiSplitViewController _splitterController;

  @override
  void initState() {
    super.initState();
    _splitterController = MultiSplitViewController(
      areas: [
        Area(
          flex: 0.7,
          builder: (context, area) => NavigationDropZone(
            child: widget.treeBuilder(context),
          ),
        ),
        Area(flex: 0.3, builder: (context, area) => _buildPreviewSection()),
      ],
    );
  }

  @override
  void dispose() {
    _splitterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiSplitViewTheme(
      data: MultiSplitViewThemeData(
        dividerThickness: 6,
        dividerPainter: DividerPainters.grooved1(
          color: Theme.of(context).dividerColor,
          highlightedColor: Theme.of(context).colorScheme.primary,
        ),
      ),
      child: MultiSplitView(
        axis: Axis.vertical,
        controller: _splitterController,
      ),
    );
  }

  Widget _buildPreviewSection() {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<DirectoryProvider>();
    final selected = provider.currentFiles
        .where((file) => file.isSelected)
        .toList(growable: false);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              l10n.labelFilterPreview,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: PreviewWindow(
              file: selected.length == 1 ? selected.first : null,
              selectedFiles: selected,
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationTreeView extends StatelessWidget {
  NavigationTreeView.sections({
    super.key,
    required this.horizontalController,
    required this.verticalController,
    required List<NavigationSection> sections,
    this.header,
    this.enableHorizontalScroll = true,
    List<Widget> trailingChildren = const [],
  }) : children = [
          for (final section in sections) ...section.widgets,
          ...trailingChildren,
        ];

  final ScrollController horizontalController;
  final ScrollController verticalController;
  final Widget? header;
  final bool enableHorizontalScroll;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) header!,
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tree = SingleChildScrollView(
                  controller: verticalController,
                  child: _NavigationTreeViewport(
                    width: constraints.maxWidth,
                    horizontalController: horizontalController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  ),
                );

                return Scrollbar(
                  controller: verticalController,
                  thumbVisibility: true,
                  child: enableHorizontalScroll
                      ? Scrollbar(
                          controller: horizontalController,
                          notificationPredicate: (notification) =>
                              notification.depth == 1,
                          child: SingleChildScrollView(
                            controller: horizontalController,
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: IntrinsicWidth(child: tree),
                            ),
                          ),
                        )
                      : tree,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationTreeViewport extends InheritedWidget {
  const _NavigationTreeViewport({
    required this.width,
    required this.horizontalController,
    required super.child,
  });

  final double width;
  final ScrollController horizontalController;

  static _NavigationTreeViewport? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_NavigationTreeViewport>();
  }

  @override
  bool updateShouldNotify(_NavigationTreeViewport oldWidget) {
    return width != oldWidget.width ||
        horizontalController != oldWidget.horizontalController;
  }
}

class NavigationSection {
  const NavigationSection({
    this.title,
    this.onAction,
    this.actionIcon,
    this.actionTooltip,
    this.items = const [],
    this.children = const [],
  });

  factory NavigationSection.pc(
    BuildContext context, {
    VoidCallback? onAction,
    IconData? actionIcon,
    String? actionTooltip,
    List<NavigationItem> items = const [],
    List<Widget> children = const [],
  }) {
    return NavigationSection(
      title: AppLocalizations.of(context)!.labelNavPC,
      onAction: onAction,
      actionIcon: actionIcon,
      actionTooltip: actionTooltip,
      items: items,
      children: children,
    );
  }

  final String? title;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final String? actionTooltip;
  final List<NavigationItem> items;
  final List<Widget> children;

  List<Widget> get widgets {
    return [
      if (title != null)
        NavigationSectionHeader(
          title!,
          onAction: onAction,
          actionIcon: actionIcon,
          actionTooltip: actionTooltip,
        ),
      ...items.map(NavigationInfoTile.item),
      ...children,
    ];
  }
}

class NavigationSectionHeader extends StatelessWidget {
  const NavigationSectionHeader(
    this.title, {
    super.key,
    this.onAction,
    this.actionIcon,
    this.actionTooltip,
  });

  final String title;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final String? actionTooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (onAction != null && actionIcon != null)
            IconButton(
              icon: Icon(actionIcon, size: 16),
              onPressed: onAction,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              tooltip: actionTooltip,
            ),
        ],
      ),
    );
  }
}

class NavigationItem {
  const NavigationItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.depth = 1,
    this.enabled = true,
    this.selected = false,
    this.height = 44,
    this.iconFill = 0,
    this.iconColor,
    this.selectedColor,
    this.semanticLabel,
    this.trailing,
    this.onTap,
  });

  const NavigationItem.disabled({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.depth = 1,
    String? semanticLabel,
  })  : enabled = false,
        selected = false,
        height = 44,
        iconFill = 0,
        iconColor = null,
        selectedColor = null,
        semanticLabel = semanticLabel ?? '$title $subtitle',
        trailing = null,
        onTap = null;

  const NavigationItem.folder({
    required this.title,
    this.subtitle,
    this.depth = 1,
    this.enabled = true,
    this.selected = false,
    this.height = 40,
    this.iconFill = 0,
    this.iconColor = Colors.amber,
    this.selectedColor,
    String? semanticLabel,
    this.trailing,
    this.onTap,
  })  : icon = Symbols.folder,
        semanticLabel = semanticLabel ?? '$title フォルダ';

  final IconData icon;
  final String title;
  final String? subtitle;
  final int depth;
  final bool enabled;
  final bool selected;
  final double height;
  final double iconFill;
  final Color? iconColor;
  final Color? selectedColor;
  final String? semanticLabel;
  final Widget? trailing;
  final VoidCallback? onTap;
}

class NavigationBreadcrumbItem {
  const NavigationBreadcrumbItem({
    required this.label,
    this.onPressed,
    this.icon = Symbols.folder,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
}

class NavigationInfoTile extends StatelessWidget {
  const NavigationInfoTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.depth = 1,
    this.enabled = true,
    this.selected = false,
    this.height = 44,
    this.iconFill = 0,
    this.iconColor,
    this.selectedColor,
    this.semanticLabel,
    this.trailing,
    this.onTap,
  });

  NavigationInfoTile.item(NavigationItem item, {super.key})
      : icon = item.icon,
        title = item.title,
        subtitle = item.subtitle,
        depth = item.depth,
        enabled = item.enabled,
        selected = item.selected,
        height = item.height,
        iconFill = item.iconFill,
        iconColor = item.iconColor,
        selectedColor = item.selectedColor,
        semanticLabel = item.semanticLabel,
        trailing = item.trailing,
        onTap = item.onTap;

  final IconData icon;
  final String title;
  final String? subtitle;
  final int depth;
  final bool enabled;
  final bool selected;
  final double height;
  final double iconFill;
  final Color? iconColor;
  final Color? selectedColor;
  final String? semanticLabel;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveIconColor = enabled
        ? (iconColor ?? colorScheme.primary)
        : colorScheme.onSurfaceVariant;

    return Semantics(
      button: onTap != null,
      enabled: enabled,
      label: semanticLabel ?? title,
      child: ExcludeSemantics(
        child: Material(
          color: selected
              ? selectedColor ??
                  colorScheme.primaryContainer.withValues(alpha: 0.35)
              : Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: EdgeInsets.only(left: 8.0 + depth * 12, right: 8),
              child: SizedBox(
                height: height,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: effectiveIconColor,
                      fill: iconFill,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                enabled ? null : colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationExpandableItem extends StatelessWidget {
  const NavigationExpandableItem({
    super.key,
    required this.title,
    required this.isExpanded,
    required this.onToggle,
    this.subtitle,
    this.icon = Symbols.folder,
    this.expandedIcon = Symbols.folder_open,
    this.enabled = true,
    this.selected = false,
    this.isLoading = false,
    this.iconColor,
    this.selectedColor,
    this.semanticLabel,
    this.trailing,
    this.errorMessage,
    this.children = const [],
    this.onTap,
    this.onSecondaryTap,
    this.onLongPress,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final IconData expandedIcon;
  final bool enabled;
  final bool selected;
  final bool isExpanded;
  final bool isLoading;
  final Color? iconColor;
  final Color? selectedColor;
  final String? semanticLabel;
  final Widget? trailing;
  final String? errorMessage;
  final List<Widget> children;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final VoidCallback? onLongPress;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectoryProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveIconColor =
        enabled ? (iconColor ?? Colors.amber) : colorScheme.onSurfaceVariant;
    final rowHeight = provider.touchMode ? 44.0 : 32.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0, bottom: 2.0),
          child: Semantics(
            button: onTap != null,
            enabled: enabled,
            label: semanticLabel ?? '$title フォルダ',
            child: Material(
              color: selected
                  ? selectedColor ?? colorScheme.secondaryContainer
                  : Colors.transparent,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewport = _NavigationTreeViewport.maybeOf(context);
                  final fallbackWidth = viewport?.width;
                  final width = constraints.hasBoundedWidth
                      ? constraints.maxWidth
                      : fallbackWidth;
                  Widget? trailingAction = trailing;
                  if (trailingAction != null && viewport != null) {
                    trailingAction = AnimatedBuilder(
                      animation: viewport.horizontalController,
                      child: trailingAction,
                      builder: (context, child) {
                        final offset = viewport.horizontalController.hasClients
                            ? viewport.horizontalController.offset
                            : 0.0;
                        return Transform.translate(
                          offset: Offset(offset, 0),
                          child: child,
                        );
                      },
                    );
                  }
                  final row = InkWell(
                    onTap: enabled ? onTap : null,
                    onSecondaryTap: enabled ? onSecondaryTap : null,
                    onLongPress: enabled ? onLongPress : null,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    child: SizedBox(
                      width: width,
                      height: rowHeight,
                      child: Row(
                        children: [
                          SizedBox(
                            width: provider.touchMode ? 32 : 24,
                            height: rowHeight,
                            child: InkWell(
                              onTap: enabled ? onToggle : null,
                              child: Icon(
                                isExpanded
                                    ? Symbols.keyboard_arrow_down
                                    : Symbols.keyboard_arrow_right,
                                size: provider.touchMode ? 24 : 16,
                                color: enabled
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.outline,
                              ),
                            ),
                          ),
                          Icon(
                            isExpanded ? expandedIcon : icon,
                            size: provider.touchMode ? 28 : 20,
                            color: effectiveIconColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: provider.touchMode ? 15 : 13,
                                    color: selected
                                        ? colorScheme.onSecondaryContainer
                                        : enabled
                                            ? null
                                            : colorScheme.onSurfaceVariant,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (subtitle != null)
                                  Text(
                                    subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (trailingAction != null) ...[
                            const SizedBox(width: 8),
                            trailingAction,
                          ],
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  );
                  if (width == null) return IntrinsicWidth(child: row);
                  return row;
                },
              ),
            ),
          ),
        ),
        if (isExpanded)
          Container(
            margin: EdgeInsets.only(left: provider.touchMode ? 15.0 : 11.0),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                  width: 1.0,
                ),
              ),
            ),
            padding: EdgeInsets.only(left: provider.touchMode ? 16.0 : 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ...children,
              ],
            ),
          ),
      ],
    );
  }
}

class NavigationBreadcrumbs extends StatelessWidget {
  const NavigationBreadcrumbs({
    super.key,
    required this.items,
    required this.emptyText,
  });

  final List<NavigationBreadcrumbItem> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return NavigationEmptyText(emptyText);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 6),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final item in items)
            ActionChip(
              avatar: Icon(item.icon, size: 16),
              label: Text(
                item.label,
                overflow: TextOverflow.ellipsis,
              ),
              visualDensity: VisualDensity.compact,
              onPressed: item.onPressed,
            ),
        ],
      ),
    );
  }
}

class NavigationEmptyText extends StatelessWidget {
  const NavigationEmptyText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 8, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
    );
  }
}

class NavigationMessageCard extends StatelessWidget {
  const NavigationMessageCard(
    this.message, {
    super.key,
    this.error = false,
  });

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        color: error
            ? colorScheme.errorContainer
            : colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            message,
            style: TextStyle(
              color:
                  error ? colorScheme.onErrorContainer : colorScheme.onSurface,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
