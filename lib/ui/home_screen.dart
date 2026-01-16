import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:multi_split_view/multi_split_view.dart';
import '../../core/directory_provider.dart';
import 'panels/navigation_panel.dart';
import 'panels/file_list_panel.dart';
import 'panels/settings_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final MultiSplitViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MultiSplitViewController(
      areas: [
        Area(flex: 0.2, builder: (c, a) => const NavigationPanel()),
        Area(flex: 0.5, builder: (c, a) => const FileListPanel()),
        Area(flex: 0.3, builder: (c, a) => const SettingsPanel()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReNamery'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: context.watch<DirectoryProvider>().canUndo
                ? () {
                    context.read<DirectoryProvider>().undo();
                  }
                : null,
            tooltip: 'Undo',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Open Settings
            },
            tooltip: 'Settings',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: MultiSplitViewTheme(
        data: MultiSplitViewThemeData(
          dividerThickness: 10,
          dividerPainter: DividerPainters.grooved1(
            color: Colors.grey[400]!,
            highlightedColor: Colors.blue,
          ),
        ),
        child: MultiSplitView(controller: _controller, resizable: true),
      ),
    );
  }
}
