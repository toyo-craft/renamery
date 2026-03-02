import 'package:flutter/material.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

import 'categories/category_add.dart';
import 'categories/category_remove.dart';
import 'categories/category_replace.dart';
import 'categories/category_numbering.dart';
import 'categories/category_extension.dart';
import 'categories/category_advanced.dart';

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({super.key});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    CategoryAddText(),
    CategoryRemoveText(),
    CategoryReplaceConvert(),
    CategoryNumbering(),
    CategoryExtension(),
    CategoryAdvanced(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (int index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                labelType: NavigationRailLabelType.all,
                useIndicator: true,
                indicatorColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.5),
                destinations: [
                  NavigationRailDestination(
                    icon: const Icon(Icons.add_circle_outline),
                    selectedIcon: const Icon(Icons.add_circle),
                    label: Text(l10n.labelCategoryAdd,
                        style: const TextStyle(fontSize: 11)),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.remove_circle_outline),
                    selectedIcon: const Icon(Icons.remove_circle),
                    label: Text(l10n.labelCategoryRemove,
                        style: const TextStyle(fontSize: 11)),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.find_replace_outlined),
                    selectedIcon: const Icon(Icons.find_replace),
                    label: Text(l10n.labelCategoryReplace,
                        style: const TextStyle(fontSize: 11)),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.format_list_numbered),
                    selectedIcon: const Icon(Icons.format_list_numbered),
                    label: Text(l10n.labelCategoryNumbering,
                        style: const TextStyle(fontSize: 11)),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.extension_outlined),
                    selectedIcon: const Icon(Icons.extension),
                    label: Text(l10n.labelCategoryExtension,
                        style: const TextStyle(fontSize: 11)),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.settings_applications_outlined),
                    selectedIcon: const Icon(Icons.settings_applications),
                    label: Text(l10n.labelCategoryAdvanced,
                        style: const TextStyle(fontSize: 11)),
                  ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),
              // Body
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _pages
                        .map((page) => SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 4.0),
                                child: Card(
                                  elevation: 0,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerLow,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: page,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
