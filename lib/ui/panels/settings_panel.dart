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
    return Column(
      children: [
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
        Container(
          padding: const EdgeInsets.all(8.0),
          width: double.infinity,
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Divider(height: 1),
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
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: context
                            .watch<DirectoryProvider>()
                            .extensionToLowerCase,
                        onChanged: (val) => context
                            .read<DirectoryProvider>()
                            .updateRenameSettings(extensionToLowerCase: val),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

              // Placeholder for "Select all on open" if needed
              // CheckboxListTile(...),
              ElevatedButton(
                onPressed: () {
                  context.read<DirectoryProvider>().executeRename();
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow, color: Colors.green),
                    const SizedBox(width: 8),
                    Flexible(
                      child: const Text(
                        'Go ReNamery!!',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
