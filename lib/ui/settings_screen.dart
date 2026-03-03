import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/directory_provider.dart';
import '../../core/rename_engine.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:renamery/ui/dialogs/about_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<DirectoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.labelSettingsTitle),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, l10n.labelSettingsSectionDisplay),
          SwitchListTile(
            title: Text(l10n.labelSettingsTouchModeTitle),
            subtitle: Text(l10n.labelSettingsTouchModeSubtitle),
            value: !provider.isCompactMode,
            onChanged: (val) {
              provider.setCompactMode(!val);
            },
          ),
          const Divider(),
          const Divider(),
          _buildSectionHeader(context, l10n.labelSettingsSectionAppearance),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Symbols.language, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.labelSettingsMenuLabelTitle),
                  ],
                ),
                const SizedBox(height: 8),
                SegmentedButton<MenuLabelType>(
                  segments: const [
                    ButtonSegment(
                      value: MenuLabelType.namery,
                      label: Text('Namery (JP)'),
                    ),
                    ButtonSegment(
                      value: MenuLabelType.standard,
                      label: Text('日本語'),
                    ),
                    ButtonSegment(
                      value: MenuLabelType.english,
                      label: Text('English'),
                    ),
                    ButtonSegment(
                      value: MenuLabelType.chinese,
                      label: Text('中文'),
                    ),
                    ButtonSegment(
                      value: MenuLabelType.spanish,
                      label: Text('Español'),
                    ),
                  ],
                  selected: {provider.menuLabelType},
                  onSelectionChanged: (Set<MenuLabelType> newSelection) {
                    provider.setMenuLabelType(newSelection.first);
                  },
                  showSelectedIcon: false,
                ),
                const SizedBox(height: 16),
                Text(l10n.labelSettingsThemeTitle),
                const SizedBox(height: 8),
                SegmentedButton<AppThemeType>(
                  segments: [
                    ButtonSegment(
                        value: AppThemeType.system,
                        label: Text(l10n.labelSettingsThemeSystem),
                        icon: const Icon(Symbols.brightness_auto)),
                    ButtonSegment(
                        value: AppThemeType.light,
                        label: Text(l10n.labelSettingsThemeLight),
                        icon: const Icon(Symbols.brightness_high)),
                    ButtonSegment(
                        value: AppThemeType.dark,
                        label: Text(l10n.labelSettingsThemeDark),
                        icon: const Icon(Symbols.brightness_4)),
                    ButtonSegment(
                        value: AppThemeType.darkGray,
                        label: Text(l10n.labelSettingsThemeGray),
                        icon: const Icon(Symbols.contrast)),
                  ],
                  selected: {provider.appTheme},
                  onSelectionChanged: (Set<AppThemeType> newSelection) {
                    provider.setAppTheme(newSelection.first);
                  },
                  showSelectedIcon: false,
                ),
                const SizedBox(height: 16),
                Text(l10n.labelSettingsColorTitle),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final color in [
                      Colors.green,
                      Colors.blue,
                      Colors.indigo,
                      Colors.purple,
                      Colors.pink,
                      Colors.red,
                      Colors.orange,
                      Colors.brown,
                      Colors.blueGrey,
                    ])
                      InkWell(
                        onTap: () => provider.setSeedColor(color),
                        borderRadius: BorderRadius.circular(16),
                        child: CircleAvatar(
                          backgroundColor: color,
                          radius: 16,
                          child: provider.seedColor == color
                              ? const Icon(Symbols.check,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          _buildSectionHeader(context, l10n.labelSettingsSectionOS),
          ListTile(
            title: Text(l10n.labelSettingsOSTitle),
            subtitle: Text(l10n.labelSettingsOSSubtitle),
            trailing: DropdownButton<ValidationType>(
              value: provider.validationType,
              onChanged: (ValidationType? newValue) {
                if (newValue != null) {
                  provider.updateRenameSettings(validationType: newValue);
                }
              },
              items: [
                DropdownMenuItem(
                  value: ValidationType.auto,
                  child: Text('${l10n.labelSettingsOSAuto} (OS)'),
                ),
                const DropdownMenuItem(
                  value: ValidationType.windows,
                  child: Text('Windows'),
                ),
                DropdownMenuItem(
                  value: ValidationType.mac,
                  child: Text(l10n.labelSettingsOSMac),
                ),
                DropdownMenuItem(
                  value: ValidationType.linux,
                  child: Text(l10n.labelSettingsOSLinux),
                ),
                DropdownMenuItem(
                  value: ValidationType.ios,
                  child: Text(l10n.labelSettingsOSiOS),
                ),
                DropdownMenuItem(
                  value: ValidationType.android,
                  child: Text(l10n.labelSettingsOSAndroid),
                ),
              ],
            ),
          ),
          const Divider(),
          _buildSectionHeader(context, l10n.labelSettingsSectionInitialDir),
          ListTile(
            title: Text(l10n.labelSettingsInitDirTitle),
            trailing: DropdownButton<InitialDirectoryMode>(
              value: provider.initialDirectoryMode,
              onChanged: (InitialDirectoryMode? newValue) {
                if (newValue != null) {
                  provider.updateInitialDirectorySettings(
                      newValue, provider.fixedInitialDirectory);
                }
              },
              items: [
                DropdownMenuItem(
                  value: InitialDirectoryMode.lastUsed,
                  child: Text(l10n.labelSettingsInitDirLast),
                ),
                DropdownMenuItem(
                  value: InitialDirectoryMode.fixed,
                  child: Text(l10n.labelSettingsInitDirFixed),
                ),
              ],
            ),
          ),
          if (provider.initialDirectoryMode == InitialDirectoryMode.fixed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: provider.fixedInitialDirectory,
                      decoration: InputDecoration(
                        hintText: '${l10n.labelTermFolder} Path',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      onChanged: (val) {
                        provider.updateInitialDirectorySettings(
                            provider.initialDirectoryMode, val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Symbols.folder_open),
                    onPressed: () async {
                      final String? directoryPath = await getDirectoryPath();
                      if (directoryPath != null) {
                        provider.updateInitialDirectorySettings(
                            provider.initialDirectoryMode, directoryPath);
                      }
                    },
                  ),
                ],
              ),
            ),
          const Divider(),
          _buildSectionHeader(context, l10n.labelSettingsSectionReset),
          ListTile(
            title: Text(l10n.labelSettingsClearHistory),
            subtitle: Text(l10n.labelSettingsClearHistorySub),
            leading: const Icon(Symbols.history, color: Colors.orange),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.labelSettingsClearHistory),
                  content: Text(l10n.labelSettingsClearHistorySub),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.labelDialogCancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text(l10n.labelDialogDelete),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                provider.clearInputHistory();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.labelMsgHistoryCleared)),
                  );
                }
              }
            },
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.labelSettingsResetAll),
            subtitle: Text(l10n.labelSettingsResetAllSub),
            leading: const Icon(Symbols.restore, color: Colors.red),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.labelSettingsResetAll),
                  content: Text(l10n.labelSettingsResetAllSub),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.labelDialogCancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text(l10n.labelDialogReset),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                provider.resetSettings();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.labelMsgSettingsReset)),
                  );
                }
              }
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Development / Testing'),
          SwitchListTile(
            title: Text(l10n.labelSettingsBetaTitle),
            subtitle: Text(l10n.labelSettingsBetaSubtitle),
            value: provider.enableBetaFeatures,
            onChanged: (val) {
              provider.setEnableBetaFeatures(val);
            },
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.labelSettingsAboutTitle),
            leading: const Icon(Symbols.info),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const AboutAppDialog(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
