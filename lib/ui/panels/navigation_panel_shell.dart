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
    List<Widget> trailingChildren = const [],
  }) : children = [
          for (final section in sections) ...section.widgets,
          ...trailingChildren,
        ];

  final ScrollController horizontalController;
  final ScrollController verticalController;
  final Widget? header;
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
                return Scrollbar(
                  controller: verticalController,
                  thumbVisibility: true,
                  child: Scrollbar(
                    controller: horizontalController,
                    notificationPredicate: (notification) =>
                        notification.depth == 1,
                    child: SingleChildScrollView(
                      controller: horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minWidth: constraints.maxWidth),
                        child: IntrinsicWidth(
                          child: SingleChildScrollView(
                            controller: verticalController,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: children,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
                    Icon(icon, size: 20, color: effectiveIconColor),
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
