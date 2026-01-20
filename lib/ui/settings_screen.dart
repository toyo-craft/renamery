import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/directory_provider.dart';
import '../../core/rename_engine.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<DirectoryProvider>(
          builder: (context, provider, _) => Text(provider.labelSettingsTitle),
        ),
      ),
      body: Consumer<DirectoryProvider>(
        builder: (context, provider, child) {
          return ListView(
            children: [
              _buildSectionHeader(
                  context, provider.labelSettingsSectionDisplay),
              SwitchListTile(
                title: Text(provider.labelSettingsTouchModeTitle),
                subtitle: Text(provider.labelSettingsTouchModeSubtitle),
                value: !provider.isCompactMode,
                onChanged: (val) {
                  provider.setCompactMode(!val);
                },
              ),
              const Divider(),
              const Divider(),
              _buildSectionHeader(
                  context, provider.labelSettingsSectionAppearance),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.labelSettingsMenuLabelTitle),
                    const SizedBox(height: 8),
                    SegmentedButton<MenuLabelType>(
                      segments: [
                        ButtonSegment(
                            value: MenuLabelType.standard,
                            label: Text(provider.labelSettingsLangJP),
                            icon: const Icon(Icons.language)),
                        ButtonSegment(
                            value: MenuLabelType.namery,
                            label: Text(provider.labelSettingsLangNamery),
                            icon: const Icon(Icons.history)),
                        ButtonSegment(
                            value: MenuLabelType.english,
                            label: Text(provider.labelSettingsLangEN),
                            icon: const Icon(Icons.language)),
                        ButtonSegment(
                            value: MenuLabelType.chinese,
                            label: Text(provider.labelSettingsLangCN),
                            icon: const Icon(Icons.language)),
                      ],
                      selected: {provider.menuLabelType},
                      onSelectionChanged: (Set<MenuLabelType> newSelection) {
                        provider.setMenuLabelType(newSelection.first);
                      },
                      showSelectedIcon: false,
                    ),
                    const SizedBox(height: 16),
                    Text(provider.labelSettingsThemeTitle),
                    const SizedBox(height: 8),
                    SegmentedButton<AppThemeType>(
                      segments: [
                        ButtonSegment(
                            value: AppThemeType.system,
                            label: Text(provider.labelSettingsThemeSystem),
                            icon: const Icon(Icons.brightness_auto)),
                        ButtonSegment(
                            value: AppThemeType.light,
                            label: Text(provider.labelSettingsThemeLight),
                            icon: const Icon(Icons.brightness_high)),
                        ButtonSegment(
                            value: AppThemeType.dark,
                            label: Text(provider.labelSettingsThemeDark),
                            icon: const Icon(Icons.brightness_4)),
                        ButtonSegment(
                            value: AppThemeType.darkGray,
                            label: Text(provider.labelSettingsThemeGray),
                            icon: const Icon(Icons.contrast)),
                      ],
                      selected: {provider.appTheme},
                      onSelectionChanged: (Set<AppThemeType> newSelection) {
                        provider.setAppTheme(newSelection.first);
                      },
                      showSelectedIcon: false,
                    ),
                    const SizedBox(height: 16),
                    Text(provider.labelSettingsColorTitle),
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
                              child: provider.seedColor.value == color.value
                                  ? const Icon(Icons.check,
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
              _buildSectionHeader(context, provider.labelSettingsSectionOS),
              ListTile(
                title: Text(provider.labelSettingsOSTitle),
                subtitle: Text(provider.labelSettingsOSSubtitle),
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
                      child: Text('${provider.labelSettingsOSAuto} (OS)'),
                    ),
                    const DropdownMenuItem(
                      value: ValidationType.windows,
                      child: Text('Windows'),
                    ),
                    const DropdownMenuItem(
                      value: ValidationType.mac,
                      child: Text('Mac (Finder compatible)'),
                    ),
                    const DropdownMenuItem(
                      value: ValidationType.linux,
                      child: Text('Linux'),
                    ),
                    const DropdownMenuItem(
                      value: ValidationType.ios,
                      child: Text('iOS (iPhone/iPad)'),
                    ),
                    const DropdownMenuItem(
                      value: ValidationType.android,
                      child: Text('Android'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              _buildSectionHeader(
                  context, provider.labelSettingsSectionInitialDir),
              ListTile(
                title: Text(provider.labelSettingsInitDirTitle),
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
                      child: Text(provider.labelSettingsInitDirLast),
                    ),
                    DropdownMenuItem(
                      value: InitialDirectoryMode.fixed,
                      child: Text(provider.labelSettingsInitDirFixed),
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
                            hintText: '${provider.termFolder} Path',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          onChanged: (val) {
                            // Simple debounce or update on editing complete might be better but onChanged is responsive
                            provider.updateInitialDirectorySettings(
                                provider.initialDirectoryMode, val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.folder_open),
                        onPressed: () async {
                          final String? directoryPath =
                              await getDirectoryPath();
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
              _buildSectionHeader(context, provider.labelSettingsSectionReset),
              ListTile(
                title: Text(provider.labelSettingsClearHistory),
                subtitle: Text(provider.labelSettingsClearHistorySub),
                leading: const Icon(Icons.history, color: Colors.orange),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(provider.labelSettingsClearHistory),
                      content: Text(provider.labelSettingsClearHistorySub),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(provider.labelDialogCancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                          child: Text(provider.labelDialogDelete),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    provider.clearInputHistory();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(provider.labelMsgHistoryCleared)),
                      );
                    }
                  }
                },
              ),
              const Divider(),
              ListTile(
                title: Text(provider.labelSettingsResetAll),
                subtitle: Text(provider.labelSettingsResetAllSub),
                leading: const Icon(Icons.restore, color: Colors.red),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(provider.labelSettingsResetAll),
                      content: Text(
                          provider.labelSettingsResetAllSub), // Or similar msg
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(provider.labelDialogCancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                          child: Text(provider.labelDialogReset),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    provider.resetSettings();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(provider.labelMsgSettingsReset)),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
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
