import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/directory_provider.dart';
import '../../l10n/generated/app_localizations.dart';

class FilterDialogHelper {
  static void showFilterPopup(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<DirectoryProvider>();
    final TextEditingController filterCtrl =
        TextEditingController(text: provider.filterText);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<DirectoryProvider>(
          builder: (context, provider, child) {
            final bool isRegex = provider.isFilterRegex;
            final colorScheme = Theme.of(context).colorScheme;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Text(
                        l10n.labelFilterOptions, 
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Container(
                        height: 48,
                        decoration: ShapeDecoration(
                          color: isRegex ? colorScheme.inverseSurface : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          shape: StadiumBorder(
                            side: isRegex ? BorderSide(color: colorScheme.primary, width: 1) : BorderSide.none,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Center(
                              child: IconButton(
                                icon: Icon(
                                  Symbols.regular_expression, 
                                  size: 24,
                                  fill: isRegex ? 1 : 0,
                                  color: isRegex ? colorScheme.onInverseSurface : colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () {
                                  provider.updateFilterSettings(isRegex: !isRegex);
                                },
                                tooltip: l10n.labelRegex,
                              ),
                            ),
                            Expanded(
                              child: Align(
                                alignment: const Alignment(0, -0.1), // 垂直方向の微調整
                                child: TextField(
                                  controller: filterCtrl,
                                  decoration: InputDecoration.collapsed(
                                    hintText: isRegex ? l10n.labelRegexSearchHint : l10n.labelSearchHint,
                                    hintStyle: TextStyle(
                                      color: isRegex ? colorScheme.onInverseSurface.withValues(alpha: 0.6) : null
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: isRegex ? colorScheme.onInverseSurface : null,
                                  ),
                                  onChanged: (val) {
                                    provider.updateFilterSettings(
                                        isSpecific: val.isNotEmpty, filter: val);
                                  },
                                ),
                              ),
                            ),
                            if (filterCtrl.text.isNotEmpty)
                              Center(
                                child: IconButton(
                                  icon: Icon(
                                    Symbols.close, 
                                    size: 20,
                                    color: isRegex ? colorScheme.onInverseSurface : null,
                                  ),
                                  onPressed: () {
                                    filterCtrl.clear();
                                    provider.updateFilterSettings(
                                        isSpecific: false, filter: '');
                                  },
                                ),
                              ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        provider.showFolders
                            ? Symbols.folder
                            : Symbols.folder_off,
                        fill: 1,
                        color: provider.showFolders
                            ? Colors.amber[700]
                            : Colors.grey,
                      ),
                      title: Text(l10n.labelSettingsFolders),
                      trailing: Switch(
                        value: provider.showFolders,
                        onChanged: (val) =>
                            provider.updateFilterSettings(showFolders: val),
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                        Symbols.shield,
                        fill: provider.hideSystemFiles ? 0 : 1,
                        color: provider.hideSystemFiles
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(l10n.labelSettingsSystemFiles),
                      trailing: Switch(
                        value: !provider.hideSystemFiles,
                        onChanged: (val) =>
                            provider.updateFilterSettings(hideSystem: !val),
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                        Symbols.account_tree,
                        fill: provider.recursiveSearch ? 1 : 0,
                        color: provider.recursiveSearch
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      title: Text(l10n.labelSettingsRecursive),
                      trailing: Switch(
                        value: provider.recursiveSearch,
                        onChanged: (val) =>
                            provider.updateFilterSettings(recursive: val),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) => filterCtrl.dispose());
  }
}
