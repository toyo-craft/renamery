import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/directory_provider.dart';
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                            .extensionToLowerCase),
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
                              .updateRenameSettings(extensionToLowerCase: val),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow),
                    const SizedBox(width: 8),
                    Flexible(
                      child: const Text(
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
