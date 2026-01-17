import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/directory_provider.dart';
import '../../core/rename_engine.dart';
import 'tabs/main_tab.dart';
import 'tabs/sub_tab.dart';

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
      // Tab is animating, wait for end? Or update immediately?
      // Usually indexIsChanging is true during animation.
      // But we want to switch mode immediately when user taps.
    } else {
      // Animation finished or immediate tap.
      // Determine which mode to activate based on tab index.
      // Main Tab (0) -> Uses its last active mode? Or Default?
      // Sub Tab (1) -> Uses its last active mode?
      // ReNamery preserves the "last selected radio" per tab?
      // Or does it have a default?
      // Let's assume we need to switch to *some* valid mode for that tab.
      final provider = context.read<DirectoryProvider>();
      final index = _tabController.index;

      RenameMode? targetMode;
      if (index == 0) {
        // Main Tab active.
        if (isSubTabMode(provider.renameMode)) {
          // Restore last active Main Tab mode
          targetMode = provider.lastMainMode;
        }
      } else if (index == 1) {
        // Sub Tab active.
        if (!isSubTabMode(provider.renameMode)) {
          // Restore last active Sub Tab mode
          targetMode = provider.lastSubMode;
        }
      }

      if (targetMode != null) {
        provider.updateRenameSettings(mode: targetMode, immediate: true);
      }
    }
  }

  bool isSubTabMode(RenameMode mode) {
    return [
      RenameMode
          .extension, // Note: Shared? 'extension' usually in SubTab now? Original Namery had it in Main?
      // Actually in our clean SubTab, we used 'extension'.
      // Let's check RenameEngine definition.
      // extension, extensionRemove, extensionAdd, extensionUpper, extensionLower, formatProperCase, listRename
      // are SubTab modes.
      // replace, append, prepend, numbering, upper, lower, capitalize, insert, delete... are MainTab modes.
      RenameMode.extensionRemove,
      RenameMode.extensionAdd,
      RenameMode.extensionUpper,
      RenameMode.extensionLower,
      RenameMode.formatProperCase,
      RenameMode.listRename,
    ].contains(mode);
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = context.watch<DirectoryProvider>().isCompactMode;
    final double padding = isCompact ? 4.0 : 8.0;

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
            tabs: const [
              Tab(text: 'Main'),
              Tab(text: 'Sub'),
              Tab(text: 'Extra'),
              Tab(text: 'etc'),
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
              Center(child: Text('Extra Tab (Coming Soon)')),
              Center(child: Text('etc Tab (Coming Soon)')),
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
                      const Expanded(
                        child: Text(
                          '拡張子は小文字化',
                          style: TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Density Toggle
              InkWell(
                onTap: () => context.read<DirectoryProvider>().setCompactMode(
                    !context.read<DirectoryProvider>().isCompactMode),
                borderRadius: BorderRadius.circular(4.0),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: isCompact ? 2.0 : 4.0),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 36, // Switch width
                        child: Switch(
                          value:
                              !context.watch<DirectoryProvider>().isCompactMode,
                          onChanged: (val) => context
                              .read<DirectoryProvider>()
                              .setCompactMode(!val),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'タッチモード (ゆったり表示)',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: padding),

              ElevatedButton(
                onPressed: () async {
                  final provider = context.read<DirectoryProvider>();
                  final count = await provider.executeRename();
                  if (context.mounted) {
                    final message = count > 0
                        ? '$count 個のファイルをリネームしました'
                        : 'リネームされたファイルはありません (選択を確認してください)';

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      vertical: isCompact ? 12 : 16, horizontal: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Go ReNamery!!',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: '設定をリセット',
                child: IconButton(
                  onPressed: () {
                    context.read<DirectoryProvider>().resetSettings();
                  },
                  icon: const Icon(Icons.refresh),
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
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
