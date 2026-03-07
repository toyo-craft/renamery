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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.labelSettingsTitle),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 0 : 16.0,
          vertical: 8.0,
        ),
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
                const SizedBox(height: 12),
                // 言語選択: Wrap + ChoiceChip（モバイルでの文字切れ防止）
                _buildLanguageSelector(context, provider, isMobile),
                const SizedBox(height: 20),
                Text(l10n.labelSettingsThemeTitle),
                const SizedBox(height: 12),
                // テーマ選択: Wrap + ChoiceChip（モバイルでの重なり防止）
                _buildThemeSelector(context, provider, l10n, isMobile),
                const SizedBox(height: 20),
                Text(l10n.labelSettingsColorTitle),
                const SizedBox(height: 12),
                // カラー選択: タッチターゲット拡大
                Wrap(
                  spacing: isMobile ? 12 : 8,
                  runSpacing: isMobile ? 12 : 8,
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
                        borderRadius: BorderRadius.circular(isMobile ? 22 : 16),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: provider.seedColor == color
                                ? Border.all(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    width: 2.5,
                                  )
                                : null,
                          ),
                          child: CircleAvatar(
                            backgroundColor: color,
                            radius: isMobile ? 22 : 16,
                            child: provider.seedColor == color
                                ? const Icon(Symbols.check,
                                    size: 18, color: Colors.white)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          _buildSectionHeader(context, l10n.labelSettingsSectionOS),
          // OS選択: モバイルではボトムシート、デスクトップではDropdown
          isMobile
              ? _buildOSTileMobile(context, provider, l10n)
              : _buildOSTileDesktop(context, provider, l10n),
          const Divider(),
          _buildSectionHeader(context, l10n.labelSettingsSectionInitialDir),
          // 初期ディレクトリ: モバイルではボトムシート、デスクトップではDropdown
          isMobile
              ? _buildInitDirTileMobile(context, provider, l10n)
              : _buildInitDirTileDesktop(context, provider, l10n),
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

  // --- 言語選択ウィジェット ---
  Widget _buildLanguageSelector(
      BuildContext context, DirectoryProvider provider, bool isMobile) {
    final items = <MapEntry<MenuLabelType, String>>[
      const MapEntry(MenuLabelType.namery, 'Namery (JP)'),
      const MapEntry(MenuLabelType.standard, '日本語'),
      const MapEntry(MenuLabelType.english, 'English'),
      const MapEntry(MenuLabelType.chinese, '中文'),
      const MapEntry(MenuLabelType.spanish, 'Español'),
    ];

    if (isMobile) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((entry) {
          final isSelected = provider.menuLabelType == entry.key;
          return ChoiceChip(
            label: Text(entry.value),
            selected: isSelected,
            onSelected: (_) => provider.setMenuLabelType(entry.key),
            materialTapTargetSize: MaterialTapTargetSize.padded,
          );
        }).toList(),
      );
    } else {
      return SegmentedButton<MenuLabelType>(
        segments: items
            .map((e) => ButtonSegment(value: e.key, label: Text(e.value)))
            .toList(),
        selected: {provider.menuLabelType},
        onSelectionChanged: (Set<MenuLabelType> newSelection) {
          provider.setMenuLabelType(newSelection.first);
        },
        showSelectedIcon: false,
      );
    }
  }

  // --- テーマ選択ウィジェット ---
  Widget _buildThemeSelector(BuildContext context, DirectoryProvider provider,
      AppLocalizations l10n, bool isMobile) {
    final items = <MapEntry<AppThemeType, ({String label, IconData icon})>>[
      MapEntry(AppThemeType.system, (
        label: l10n.labelSettingsThemeSystem,
        icon: Symbols.brightness_auto
      )),
      MapEntry(AppThemeType.light,
          (label: l10n.labelSettingsThemeLight, icon: Symbols.brightness_high)),
      MapEntry(AppThemeType.dark,
          (label: l10n.labelSettingsThemeDark, icon: Symbols.brightness_4)),
      MapEntry(AppThemeType.darkGray,
          (label: l10n.labelSettingsThemeGray, icon: Symbols.contrast)),
    ];

    if (isMobile) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((entry) {
          final isSelected = provider.appTheme == entry.key;
          return ChoiceChip(
            avatar: Icon(entry.value.icon, size: 18),
            label: Text(entry.value.label),
            selected: isSelected,
            onSelected: (_) => provider.setAppTheme(entry.key),
            materialTapTargetSize: MaterialTapTargetSize.padded,
          );
        }).toList(),
      );
    } else {
      return SegmentedButton<AppThemeType>(
        segments: items
            .map((e) => ButtonSegment(
                value: e.key,
                label: Text(e.value.label),
                icon: Icon(e.value.icon)))
            .toList(),
        selected: {provider.appTheme},
        onSelectionChanged: (Set<AppThemeType> newSelection) {
          provider.setAppTheme(newSelection.first);
        },
        showSelectedIcon: false,
      );
    }
  }

  // --- OS選択: モバイル用（タップ→ボトムシート） ---
  Widget _buildOSTileMobile(
      BuildContext context, DirectoryProvider provider, AppLocalizations l10n) {
    return ListTile(
      title: Text(l10n.labelSettingsOSTitle),
      subtitle: Text(l10n.labelSettingsOSSubtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getValidationLabel(provider.validationType, l10n),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Symbols.chevron_right),
        ],
      ),
      onTap: () => _showOSBottomSheet(context, provider, l10n),
    );
  }

  // --- OS選択: デスクトップ用（従来のDropdown） ---
  Widget _buildOSTileDesktop(
      BuildContext context, DirectoryProvider provider, AppLocalizations l10n) {
    return ListTile(
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
    );
  }

  // --- 初期ディレクトリ: モバイル用 ---
  Widget _buildInitDirTileMobile(
      BuildContext context, DirectoryProvider provider, AppLocalizations l10n) {
    return ListTile(
      title: Text(l10n.labelSettingsInitDirTitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            provider.initialDirectoryMode == InitialDirectoryMode.lastUsed
                ? l10n.labelSettingsInitDirLast
                : l10n.labelSettingsInitDirFixed,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Symbols.chevron_right),
        ],
      ),
      onTap: () => _showInitDirBottomSheet(context, provider, l10n),
    );
  }

  // --- 初期ディレクトリ: デスクトップ用 ---
  Widget _buildInitDirTileDesktop(
      BuildContext context, DirectoryProvider provider, AppLocalizations l10n) {
    return ListTile(
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
    );
  }

  // --- OS選択ボトムシート ---
  void _showOSBottomSheet(
      BuildContext context, DirectoryProvider provider, AppLocalizations l10n) {
    final items = <MapEntry<ValidationType, String>>[
      MapEntry(ValidationType.auto, '${l10n.labelSettingsOSAuto} (OS)'),
      const MapEntry(ValidationType.windows, 'Windows'),
      MapEntry(ValidationType.mac, l10n.labelSettingsOSMac),
      MapEntry(ValidationType.linux, l10n.labelSettingsOSLinux),
      MapEntry(ValidationType.ios, l10n.labelSettingsOSiOS),
      MapEntry(ValidationType.android, l10n.labelSettingsOSAndroid),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.labelSettingsOSTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Divider(),
              ...items.map((entry) {
                final isSelected = provider.validationType == entry.key;
                return ListTile(
                  title: Text(entry.value),
                  leading: isSelected
                      ? Icon(Symbols.check,
                          color: Theme.of(context).colorScheme.primary)
                      : const SizedBox(width: 24),
                  selected: isSelected,
                  onTap: () {
                    provider.updateRenameSettings(validationType: entry.key);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // --- 初期ディレクトリ選択ボトムシート ---
  void _showInitDirBottomSheet(
      BuildContext context, DirectoryProvider provider, AppLocalizations l10n) {
    final items = <MapEntry<InitialDirectoryMode, String>>[
      MapEntry(InitialDirectoryMode.lastUsed, l10n.labelSettingsInitDirLast),
      MapEntry(InitialDirectoryMode.fixed, l10n.labelSettingsInitDirFixed),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.labelSettingsInitDirTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Divider(),
              ...items.map((entry) {
                final isSelected = provider.initialDirectoryMode == entry.key;
                return ListTile(
                  title: Text(entry.value),
                  leading: isSelected
                      ? Icon(Symbols.check,
                          color: Theme.of(context).colorScheme.primary)
                      : const SizedBox(width: 24),
                  selected: isSelected,
                  onTap: () {
                    provider.updateInitialDirectorySettings(
                        entry.key, provider.fixedInitialDirectory);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // --- Validation Typeのラベル取得 ---
  String _getValidationLabel(ValidationType type, AppLocalizations l10n) {
    switch (type) {
      case ValidationType.auto:
        return '${l10n.labelSettingsOSAuto} (OS)';
      case ValidationType.windows:
        return 'Windows';
      case ValidationType.mac:
        return l10n.labelSettingsOSMac;
      case ValidationType.linux:
        return l10n.labelSettingsOSLinux;
      case ValidationType.ios:
        return l10n.labelSettingsOSiOS;
      case ValidationType.android:
        return l10n.labelSettingsOSAndroid;
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
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
