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

import 'helpers/undo_helper.dart';
import 'helpers/copy_helper.dart';
import 'settings_screen.dart';

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

    // Watch provider for toolbar updates
    final provider = context.watch<DirectoryProvider>();
    final iconColor = Colors.green[700]; // Namery Green-ish
    final iconSize = 28.0;

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
            titleSpacing: 0, // Minimize spacing to fit more icons if needed
            title: Row(
              children: [
                const SizedBox(width: 8),
                // 1. Back Group
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: iconColor,
                  iconSize: iconSize,
                  tooltip: '戻る',
                  onPressed:
                      provider.canGoBack ? () => provider.goBack() : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                PopupMenuButton<int>(
                  icon: const Icon(Icons.arrow_drop_down),
                  color: Colors.white,
                  enabled: provider.backHistory.isNotEmpty,
                  onSelected: (steps) => provider.jumpBack(steps),
                  itemBuilder: (context) {
                    return List.generate(provider.backHistory.length, (index) {
                      return PopupMenuItem(
                        value: index + 1,
                        height: 32,
                        child: Text(provider.backHistory[index],
                            style: const TextStyle(fontSize: 12)),
                      );
                    });
                  },
                  tooltip: '履歴 (戻る)',
                ),

                // 2. Forward Group
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  color: iconColor,
                  iconSize: iconSize,
                  tooltip: '進む',
                  onPressed:
                      provider.canGoForward ? () => provider.goForward() : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                PopupMenuButton<int>(
                  icon: const Icon(Icons.arrow_drop_down),
                  color: Colors.white,
                  enabled: provider.forwardHistory.isNotEmpty,
                  onSelected: (steps) => provider.jumpForward(steps),
                  itemBuilder: (context) {
                    return List.generate(provider.forwardHistory.length,
                        (index) {
                      return PopupMenuItem(
                        value: index + 1,
                        height: 32,
                        child: Text(provider.forwardHistory[index],
                            style: const TextStyle(fontSize: 12)),
                      );
                    });
                  },
                  tooltip: '履歴 (進む)',
                ),

                const SizedBox(
                    height: 24,
                    child: VerticalDivider(width: 20, indent: 4, endIndent: 4)),

                // 3. Execute
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  color: iconColor,
                  iconSize: iconSize,
                  tooltip: provider.hasInvalidFilenames
                      ? 'エラー：ファイル名に禁止文字が含まれています'
                      : '実行',
                  onPressed:
                      (provider.canExecute && !provider.hasInvalidFilenames)
                          ? () => _confirmAndExecute(context, provider)
                          : null,
                ),

                // 4. Undo
                TextButton.icon(
                  icon: const Icon(Icons.undo),
                  label: Text(
                      provider.canUndo ? '戻す (${provider.undoCount})' : '戻す'),
                  style: TextButton.styleFrom(
                    foregroundColor: iconColor,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: provider.canUndo
                      ? () => UndoHelper.handleUndo(context, provider)
                      : null,
                ),

                // 5. Copy Group
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.content_copy),
                      color: Colors.grey[700],
                      iconSize: iconSize,
                      tooltip: 'コピー (現在名)',
                      onPressed: provider.currentFiles.any((f) => f.isSelected)
                          ? () => CopyHelper.handleCopy(context, provider)
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    PopupMenuButton<int>(
                      icon: const Icon(Icons.arrow_drop_down),
                      color: Colors.white,
                      enabled: provider.currentFiles.any((f) => f.isSelected) ||
                          provider.getLastUndoTransaction().isNotEmpty,
                      onSelected: (value) async {
                        await CopyHelper.handleCopyMenu(
                            context, provider, value);
                      },
                      itemBuilder: (context) {
                        final hasSelection =
                            provider.currentFiles.any((f) => f.isSelected);
                        final hasUndo =
                            provider.getLastUndoTransaction().isNotEmpty;

                        return [
                          PopupMenuItem(
                            value: 1,
                            height: 32,
                            enabled: hasSelection,
                            child: const Text('クリップボードへ現在のリストをコピー',
                                style: TextStyle(fontSize: 12)),
                          ),
                          PopupMenuItem(
                            value: 2,
                            height: 32,
                            enabled: hasSelection,
                            child: const Text('クリップボードへ現在のリストをコピー (Path)',
                                style: TextStyle(fontSize: 12)),
                          ),
                          PopupMenuItem(
                            value: 3,
                            height: 32,
                            enabled: hasSelection,
                            child: const Text('クリップボードへフルパスリストをコピー',
                                style: TextStyle(fontSize: 12)),
                          ),
                          PopupMenuItem(
                            value: 4,
                            height: 32,
                            enabled: hasUndo,
                            child: const Text('直前の変更記録をクリップボードへ',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ];
                      },
                      tooltip: 'コピーオプション',
                    ),
                  ],
                ),

                const SizedBox(
                    height: 24,
                    child: VerticalDivider(width: 20, indent: 4, endIndent: 4)),

                // 6. Up
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  color: iconColor,
                  iconSize: iconSize,
                  tooltip: '上に移動',
                  onPressed: provider.canMoveUp
                      ? () => provider.moveSelection(true)
                      : null,
                ),

                // 7. Down
                IconButton(
                  icon: const Icon(Icons.arrow_downward),
                  color: iconColor,
                  iconSize: iconSize,
                  tooltip: '下に移動',
                  onPressed: provider.canMoveDown
                      ? () => provider.moveSelection(false)
                      : null,
                ),

                const SizedBox(
                    height: 24,
                    child: VerticalDivider(width: 20, indent: 4, endIndent: 4)),

                // 8. Refresh
                IconButton(
                  icon: const Icon(Icons.refresh),
                  color: iconColor,
                  iconSize: iconSize,
                  tooltip: '全て更新',
                  onPressed: () => provider.refresh(),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                tooltip: '設定',
              ),
            ],
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
              // ToolbarPanel Removed (Merged into AppBar)
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
