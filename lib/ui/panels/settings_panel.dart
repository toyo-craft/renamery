import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/directory_provider.dart';
import 'tabs/main_tab.dart';

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
    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Main'),
              Tab(text: 'Sub'),
              Tab(text: 'Extra'),
              Tab(text: 'etc'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              MainTab(),
              Center(child: Text('Sub Tab (Coming Soon)')),
              Center(child: Text('Extra Tab (Coming Soon)')),
              Center(child: Text('etc Tab (Coming Soon)')),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          width: double.infinity,
          color: Theme.of(context).colorScheme.surface,
          child: ElevatedButton.icon(
            onPressed: () {
              // Execute rename
              // We need valid context with provider access, which we have here.
              // We probably want a dialogue confirmation? For MVP, just execute.
              context.read<DirectoryProvider>().executeRename();
            },
            icon: const Icon(Icons.drive_file_rename_outline),
            label: const Text('リネーム実行'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}
