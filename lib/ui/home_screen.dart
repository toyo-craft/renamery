import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/directory_provider.dart';
import '../../core/settings_service.dart';
import 'panels/navigation_panel.dart';
import 'panels/file_list_panel.dart';
import 'panels/settings_panel.dart';
import 'panels/toolbar_panel.dart';
import 'helpers/undo_helper.dart';
import 'helpers/copy_helper.dart';

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

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          final provider = context.read<DirectoryProvider>();
          if (provider.canUndo) {
            UndoHelper.handleUndo(context, provider);
          }
        },
        const SingleActivator(LogicalKeyboardKey.arrowUp, control: true): () {
          final provider = context.read<DirectoryProvider>();
          if (provider.canMoveUp) provider.moveSelection(true);
        },
        const SingleActivator(LogicalKeyboardKey.arrowDown, control: true): () {
          final provider = context.read<DirectoryProvider>();
          if (provider.canMoveDown) provider.moveSelection(false);
        },
        const SingleActivator(LogicalKeyboardKey.keyC, control: true): () {
          final provider = context.read<DirectoryProvider>();
          CopyHelper.handleCopy(context, provider);
        },
        const SingleActivator(LogicalKeyboardKey.delete): () async {
          final provider = context.read<DirectoryProvider>();
          final selectedCount =
              provider.currentFiles.where((f) => f.isSelected).length;
          if (selectedCount == 0) return;

          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('削除の確認'),
              content: Text('$selectedCount 個のファイルを完全に削除しますか？\nこの操作は元に戻せません。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('削除'),
                ),
              ],
            ),
          );

          if (confirm == true && context.mounted) {
            final deleted = await provider.deleteSelectedFiles();
            if (context.mounted && deleted > 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$deleted 個のファイルを削除しました')),
              );
            }
          }
        },
      },
      child: Focus(
        // Focus widget to ensure key events are captured if no text field has focus
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('ReNamery'),
            centerTitle: false,
          ),
          // Drawer is only available on Mobile
          drawer: !isDesktop
              ? const Drawer(
                  width: 300,
                  child: NavigationPanel(),
                )
              : null,
          body: Column(
            children: [
              const ToolbarPanel(),
              Expanded(
                child: MultiSplitViewTheme(
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
              ),
            ],
          ),
          bottomNavigationBar: Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            color: Colors.grey[200],
            child: Consumer<DirectoryProvider>(
              builder: (context, provider, child) {
                final total = provider.allFilesCount; // Total available
                final current = provider
                    .currentFiles.length; // Currently displayed (filtered)
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

                String statusText =
                    provider.isLoading ? 'Processing...' : 'Ready';

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
        ),
      ),
    );
  }
}
