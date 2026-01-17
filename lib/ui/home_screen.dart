import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:multi_split_view/multi_split_view.dart';
import '../../core/directory_provider.dart';
import 'panels/navigation_panel.dart';
import 'panels/file_list_panel.dart';
import 'panels/settings_panel.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/settings_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WindowListener {
  late final MultiSplitViewController _controller;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    // Default weights
    double w1 = 0.2;
    double w2 = 0.5;
    double w3 = 0.3;

    // Restore weights
    final savedWeights = SettingsService().getList<dynamic>('splitWeights');
    if (savedWeights != null && savedWeights.length == 3) {
      try {
        w1 = (savedWeights[0] as num).toDouble();
        w2 = (savedWeights[1] as num).toDouble();
        w3 = (savedWeights[2] as num).toDouble();
      } catch (e) {
        // ignore error, use defaults
      }
    }

    _controller = MultiSplitViewController(
      areas: [
        Area(
          flex: w1,
          builder: (c, a) => const NavigationPanel(),
        ),
        Area(
          flex: w2,
          builder: (c, a) => const FileListPanel(),
        ),
        Area(
          flex: w3,
          builder: (c, a) => const SettingsPanel(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowResize() {
    _saveWindowState();
  }

  @override
  void onWindowMove() {
    _saveWindowState();
  }

  Future<void> _saveWindowState() async {
    final size = await windowManager.getSize();
    final pos = await windowManager.getPosition();
    final s = SettingsService();
    s.set('windowWidth', size.width);
    s.set('windowHeight', size.height);
    s.set('windowX', pos.dx);
    s.set('windowY', pos.dy);
  }

  void _saveSplitState() {
    final s = SettingsService();
    final weights = _controller.areas.map((a) => a.flex ?? 0.0).toList();
    s.set('splitWeights', weights);
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
              // Create a settings dialog or just rely on panel
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
        child: MultiSplitView(
          controller: _controller,
          resizable: true,
          onDividerDragEnd: (index) => _saveSplitState(),
        ),
      ),
      bottomNavigationBar: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        color: Colors.grey[200],
        child: Consumer<DirectoryProvider>(
          builder: (context, provider, child) {
            final total = provider.allFilesCount; // Total available
            final current =
                provider.currentFiles.length; // Currently displayed (filtered)
            final selected =
                provider.currentFiles.where((f) => f.isSelected).length;

            String countText = '';
            if (current != total) {
              // Filtering active
              countText =
                  'Display: $current / Total: $total File : Selected $selected File';
            } else {
              // No filtering
              countText = '全 $total File : Selected $selected File';
            }

            String statusText = provider.isLoading ? 'Processing...' : 'Ready';

            return Row(
              children: [
                Text(
                  countText,
                  style: const TextStyle(fontSize: 12),
                ),
                const Spacer(),
                Text(
                  statusText,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
