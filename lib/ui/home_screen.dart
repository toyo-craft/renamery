import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:path/path.dart' as p;
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
  late final MultiSplitViewController _mobileController;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    // Desktop Layout (3 Panes)
    double w1 = 0.2;
    double w2 = 0.5;
    double w3 = 0.3;

    final savedWeights = SettingsService().getList<dynamic>('splitWeights');
    if (savedWeights != null && savedWeights.length == 3) {
      try {
        w1 = (savedWeights[0] as num).toDouble();
        w2 = (savedWeights[1] as num).toDouble();
        w3 = (savedWeights[2] as num).toDouble();
      } catch (e) {
        // ignore error
      }
    }

    _controller = MultiSplitViewController(
      areas: [
        Area(flex: w1, builder: (c, a) => const NavigationPanel()),
        Area(flex: w2, builder: (c, a) => const FileListPanel()),
        Area(flex: w3, builder: (c, a) => const SettingsPanel()),
      ],
    );

    // Mobile Layout (2 Panes: FileList + Settings)
    double mw1 = 0.7;
    double mw2 = 0.3;

    final savedMobileWeights =
        SettingsService().getList<dynamic>('mobileSplitWeights');
    if (savedMobileWeights != null && savedMobileWeights.length == 2) {
      try {
        mw1 = (savedMobileWeights[0] as num).toDouble();
        mw2 = (savedMobileWeights[1] as num).toDouble();
      } catch (e) {
        // ignore error
      }
    }

    _mobileController = MultiSplitViewController(
      areas: [
        Area(flex: mw1, builder: (c, a) => const FileListPanel()),
        Area(flex: mw2, builder: (c, a) => const SettingsPanel()),
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

  void _saveMobileSplitState() {
    final s = SettingsService();
    final weights = _mobileController.areas.map((a) => a.flex ?? 0.0).toList();
    s.set('mobileSplitWeights', weights);
  }

  @override
  Widget build(BuildContext context) {
    // Responsive Logic
    // Breakpoint: 800px arbitrary for "Tablet/Desktop" split
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ReNamery'),
        centerTitle: false,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.undo),
            label: Text(
              context.watch<DirectoryProvider>().canUndo
                  ? '戻す(${context.watch<DirectoryProvider>().undoCount})'
                  : '戻す',
            ),
            onPressed: context.watch<DirectoryProvider>().canUndo
                ? () async {
                    final provider = context.read<DirectoryProvider>();

                    // 1. Get Transaction Info for Confirmation
                    final transaction = provider.getLastUndoTransaction();
                    if (transaction.isEmpty) return;

                    // 2. Show Confirmation Dialog
                    final shouldUndo = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('処理の復元',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          content: SizedBox(
                            width: 600, // Wide dialog
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${provider.currentDirectory?.path ?? ""}'),
                                const SizedBox(height: 8),
                                const Text(
                                  'において、直前に行った変更処理を復元しますか？\n変更後フォルダ内のファイルへ何らかのアクションを起こしている場合、失敗する可能性があります。',
                                  style: TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '計: ${transaction.length} Files',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    color: Colors.grey[100],
                                  ),
                                  child: ListView.builder(
                                    itemCount: transaction.length,
                                    itemBuilder: (context, index) {
                                      final action = transaction[index];
                                      // undo: rename new -> old
                                      // List format: newName <- oldName (UI requirement per image)
                                      // Actually image shows: \Name <- \Name
                                      // Which means Current <- Previous
                                      // UndoAction contains (original, new)
                                      // So we want to show: basename(new) <- basename(original)
                                      final oldName =
                                          p.basename(action.originalPath);
                                      final newName =
                                          p.basename(action.newPath);
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4.0, vertical: 1.0),
                                        child: Text(
                                          '$oldName  ←  $newName',
                                          style: const TextStyle(
                                            fontFamily: 'Consolas',
                                            fontSize: 12,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            ElevatedButton.icon(
                              onPressed: () => Navigator.of(context).pop(true),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('OK'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => Navigator.of(context).pop(false),
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('キャンセル',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        );
                      },
                    );

                    if (shouldUndo == true && context.mounted) {
                      // 3. Execute Undo
                      final result = await provider.undo();
                      final count = result['count'] as int;
                      final errors = result['errors'] as List<String>;

                      // 4. Show Result Dialog
                      if (context.mounted) {
                        await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Namery - rename tool'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$count/${transaction.length} 個の復元に成功しました。',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  if (errors.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    const Text('エラーが発生しました:',
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 100,
                                      width: double.maxFinite,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        border: Border.all(
                                            color: Colors.red.shade200),
                                      ),
                                      child: ListView(
                                        shrinkWrap: true,
                                        children: errors
                                            .map((e) => Text(e,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.red)))
                                            .toList(),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              actions: [
                                OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    }
                  }
                : null,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
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
      // Drawer is only available on Mobile
      drawer: !isDesktop
          ? const Drawer(
              width: 300, // Fixed width for drawer
              child: NavigationPanel(),
            )
          : null,
      body: MultiSplitViewTheme(
        data: MultiSplitViewThemeData(
          dividerThickness: 10,
          dividerPainter: DividerPainters.grooved1(
            color: Colors.grey[400]!,
            highlightedColor: Colors.blue,
          ),
        ),
        child: isDesktop
            ? MultiSplitView(
                controller: _controller,
                resizable: true,
                onDividerDragEnd: (index) => _saveSplitState(),
              )
            : MultiSplitView(
                controller: _mobileController,
                resizable: true,
                onDividerDragEnd: (index) => _saveMobileSplitState(),
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
