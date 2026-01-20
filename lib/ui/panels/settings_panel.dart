import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/directory_provider.dart';
import '../../core/rename_engine.dart';
import 'tabs/main_tab.dart';
import 'tabs/sub_tab.dart';
import 'tabs/extra_tab.dart';
import 'tabs/etc_tab.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({super.key});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      // Animation ...
    } else {
      final provider = context.read<DirectoryProvider>();
      final index = _tabController.index;

      RenameMode? targetMode;
      if (index == 0) {
        // Main Tab
        // If current mode is NOT Main, switch to last Main.
        if (!provider.isMainMode(provider.renameMode)) {
          targetMode = provider.lastMainMode;
        }
      } else if (index == 1) {
        // Sub Tab
        if (!provider.isSubMode(provider.renameMode)) {
          targetMode = provider.lastSubMode;
        }
      } else if (index == 2) {
        // Extra Tab
        if (!provider.isExtraMode(provider.renameMode)) {
          targetMode = provider.lastExtraMode;
        }
      } else if (index == 3) {
        // Etc Tab
        if (!provider.isEtcMode(provider.renameMode)) {
          targetMode = provider.lastEtcMode;
        }
      }

      if (targetMode != null) {
        provider.updateRenameSettings(mode: targetMode, immediate: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectoryProvider>();
    final isCompact = provider.isCompactMode;
    final double padding = isCompact ? 4.0 : 8.0; // 4dp grid

    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding:
                const EdgeInsets.symmetric(horizontal: 16.0), // Consistent
            tabs: [
              Tab(text: provider.labelMainTab),
              Tab(text: provider.labelSubTab),
              Tab(text: provider.labelExtraTab),
              Tab(text: provider.labelEtcTab),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              MainTab(),
              SubTab(),
              ExtraTab(),
              EtcTab(),
            ],
          ),
        ),
        const Divider(height: 1),
        Container(
          padding: EdgeInsets.all(padding),
          width: double.infinity,
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Footer Options
              InkWell(
                onTap: () => context
                    .read<DirectoryProvider>()
                    .updateRenameSettings(
                        extensionToLowerCase: !context
                            .read<DirectoryProvider>()
                            .extensionToLowerCase,
                        immediate: true),
                borderRadius: BorderRadius.circular(4.0),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: isCompact ? 2.0 : 4.0),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: context
                              .watch<DirectoryProvider>()
                              .extensionToLowerCase,
                          onChanged: (val) => context
                              .read<DirectoryProvider>()
                              .updateRenameSettings(
                                  extensionToLowerCase: val, immediate: true),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.labelExtensionLower,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: isCompact ? 40 : 48,
                child: FilledButton.icon(
                  onPressed:
                      (provider.canExecute && !provider.hasInvalidFilenames)
                          ? () => _confirmAndExecute(context, provider)
                          : null,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(provider.labelGoRenamery,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  // style: defaults to Theme.of(context).colorScheme.primary
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndExecute(
      BuildContext context, DirectoryProvider provider) async {
    if (!provider.currentFiles.any((f) => f.isSelected)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ファイルが選択されていません')),
      );
      return;
    }

    final executedCount = await provider.executeRename();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$executedCount 個のファイルをリネームしました')),
      );
    }
  }
}
