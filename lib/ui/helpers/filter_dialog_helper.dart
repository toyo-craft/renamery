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
                        l10n.labelFilterOptions, // 「検索と表示設定」
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        controller: filterCtrl,
                        decoration: InputDecoration(
                          hintText: l10n.labelSearchHint,
                          prefixIcon: const Icon(Symbols.search, size: 20),
                          suffixIcon: filterCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Symbols.close, size: 16),
                                  onPressed: () {
                                    filterCtrl.clear();
                                    provider.updateFilterSettings(
                                        isSpecific: false, filter: '');
                                  },
                                )
                              : null,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (val) {
                          provider.updateFilterSettings(
                              isSpecific: val.isNotEmpty, filter: val);
                        },
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
