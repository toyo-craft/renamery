import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../core/directory_provider.dart';
import '../../core/rename_engine.dart'; // 追加

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
  bool _hideBannerSession = false; // 今回のセッションでバナーを閉じたか

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
    final provider = context.watch<DirectoryProvider>();

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isCompact = constraints.maxWidth <= 360;

        return Column(
          children: [
            // アップデートバナー (案1: 最上段に差し込み)
            if (provider.hasUpdate && !_hideBannerSession)
              _buildUpdateBanner(context, provider),
            
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
                      // タブ選択時に自動でリネームモードを切り替える (案2の要素)
                      final provider = context.read<DirectoryProvider>();
                      switch (index) {
                        case 0: provider.updateRenameSettings(mode: RenameMode.append); break;
                        case 1: provider.updateRenameSettings(mode: RenameMode.deleteStart); break;
                        case 2: provider.updateRenameSettings(mode: RenameMode.replace); break;
                        case 3: provider.updateRenameSettings(mode: RenameMode.numbering); break;
                        case 4: provider.updateRenameSettings(mode: RenameMode.extension); break;
                        case 5: provider.updateRenameSettings(mode: RenameMode.changeTimestamp); break;
                      }
                    },
                    labelType: isCompact
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    useIndicator: true,
                    indicatorColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.5),
                    destinations: [
                      NavigationRailDestination(
                        icon: const Icon(Symbols.add_circle),
                        selectedIcon: const Icon(Symbols.add_circle),
                        label: Text(l10n.labelCategoryAdd,
                            style: const TextStyle(fontSize: 11)),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Symbols.do_not_disturb_on),
                        selectedIcon: const Icon(Symbols.do_not_disturb_on),
                        label: Text(l10n.labelCategoryRemove,
                            style: const TextStyle(fontSize: 11)),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Symbols.find_replace),
                        selectedIcon: const Icon(Symbols.find_replace),
                        label: Text(l10n.labelCategoryReplace,
                            style: const TextStyle(fontSize: 11)),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Symbols.format_list_numbered),
                        selectedIcon: const Icon(Symbols.format_list_numbered),
                        label: Text(l10n.labelCategoryNumbering,
                            style: const TextStyle(fontSize: 11)),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Symbols.extension),
                        selectedIcon: const Icon(Symbols.extension),
                        label: Text(l10n.labelCategoryExtension,
                            style: const TextStyle(fontSize: 11)),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Symbols.settings_applications),
                        selectedIcon: const Icon(Symbols.settings_applications,
                            fill: 1.0),
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
      },
    ),
  );
}

Widget _buildUpdateBanner(BuildContext context, DirectoryProvider provider) {
  final colorScheme = Theme.of(context).colorScheme;
  return Material(
    elevation: 2,
    color: colorScheme.secondaryContainer,
    child: InkWell(
      onTap: () => _launchExternalUrl('https://github.com/toyo-craft/renamery/releases'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            Icon(Symbols.info, color: colorScheme.onSecondaryContainer, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'アップデートが利用可能です (v${provider.latestVersion})',
                    style: TextStyle(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ここをタップして最新版をダウンロードしてください。',
                    style: TextStyle(
                      color: colorScheme.onSecondaryContainer.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Symbols.close, color: colorScheme.onSecondaryContainer, size: 20),
              onPressed: () {
                setState(() {
                  _hideBannerSession = true;
                });
              },
              visualDensity: VisualDensity.compact,
              tooltip: '閉じる',
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _launchExternalUrl(String url) async {
  try {
    if (Platform.isAndroid) {
      const channel = MethodChannel('jp.toyocraft.renamery/launcher');
      await channel.invokeMethod('launchUrl', {'url': url});
    } else {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $url');
      }
    }
  } catch (e) {
    debugPrint('Error launching URL: $e');
    try {
      final Uri uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
}
