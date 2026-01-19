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
import 'panels/home_app_bar.dart'; // Import new AppBar

import 'helpers/undo_helper.dart';
import 'helpers/copy_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WindowListener {
  late final MultiSplitViewController _threePaneController;
  late final MultiSplitViewController _twoPaneController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    // Initialize 3-Pane Controller (Desktop)
    _threePaneController = MultiSplitViewController(
      areas: [
        Area(flex: 0.2, builder: (c, a) => const NavigationPanel()),
        Area(flex: 0.5, builder: (c, a) => const FileListPanel()),
        Area(flex: 0.3, builder: (c, a) => const SettingsPanel()),
      ],
    );

    // Initialize 2-Pane Controller (Tablet)
    _twoPaneController = MultiSplitViewController(
      areas: [
        Area(flex: 0.6, builder: (c, a) => const FileListPanel()),
        Area(flex: 0.4, builder: (c, a) => const SettingsPanel()),
      ],
    );

    _loadSplitState();
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

  void _loadSplitState() {
    final s = SettingsService();
    final w3 = s.getList<dynamic>('splitWeights_3pane');
    if (w3 != null && w3.length == 3) {
      try {
        _threePaneController.areas[0].flex = (w3[0] as num).toDouble();
        _threePaneController.areas[1].flex = (w3[1] as num).toDouble();
        _threePaneController.areas[2].flex = (w3[2] as num).toDouble();
      } catch (_) {}
    }

    final w2 = s.getList<dynamic>('splitWeights_2pane');
    if (w2 != null && w2.length == 2) {
      try {
        _twoPaneController.areas[0].flex = (w2[0] as num).toDouble();
        _twoPaneController.areas[1].flex = (w2[1] as num).toDouble();
      } catch (_) {}
    }
  }

  void _saveSplitState() {
    final s = SettingsService();
    s.set('splitWeights_3pane',
        _threePaneController.areas.map((a) => a.flex ?? 0.0).toList());
    s.set('splitWeights_2pane',
        _twoPaneController.areas.map((a) => a.flex ?? 0.0).toList());
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // 1. Desktop: Left + Center + Right (Width >= 1100)
    // 2. Tablet: Center + Right (Width >= 700)
    // 3. Mobile: Center (Width < 700)

    // 1. Desktop: Left + Center + Right (Width >= 1100)
    // 2. Tablet: Center + Right (Width >= 700)
    // 3. Mobile: Center (Width < 700)

    final bool showLeftPane = width >= 1100;
    final bool showRightPane = width >= 700;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }

        // 1. If Editing, do NOT execute App Shortcuts.
        if (_isEditing()) {
          return KeyEventResult.ignored;
        }

        final logicalKey = event.logicalKey;
        final isCtrl = HardwareKeyboard.instance.isControlPressed;

        // Ctrl + Z : Undo
        if (isCtrl && logicalKey == LogicalKeyboardKey.keyZ) {
          final provider = context.read<DirectoryProvider>();
          if (provider.canUndo) {
            UndoHelper.handleUndo(context, provider);
            return KeyEventResult.handled;
          }
        }

        // Ctrl + ArrowUp : Move Selection Up
        if (isCtrl && logicalKey == LogicalKeyboardKey.arrowUp) {
          final provider = context.read<DirectoryProvider>();
          if (provider.canMoveUp) {
            provider.moveSelection(true);
            return KeyEventResult.handled;
          }
        }

        // Ctrl + ArrowDown : Move Selection Down
        if (isCtrl && logicalKey == LogicalKeyboardKey.arrowDown) {
          final provider = context.read<DirectoryProvider>();
          if (provider.canMoveDown) {
            provider.moveSelection(false);
            return KeyEventResult.handled;
          }
        }

        // Ctrl + C : Copy
        if (isCtrl && logicalKey == LogicalKeyboardKey.keyC) {
          final provider = context.read<DirectoryProvider>();
          CopyHelper.handleCopy(context, provider);
          return KeyEventResult.handled;
        }

        // Ctrl + A : Select All
        if (isCtrl && logicalKey == LogicalKeyboardKey.keyA) {
          context.read<DirectoryProvider>().selectAll(true);
          return KeyEventResult.handled;
        }

        // Delete : Delete Files
        if (logicalKey == LogicalKeyboardKey.delete) {
          _handleDelete(context);
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: HomeAppBar(
          showDrawerMenu:
              !showLeftPane, // Show Menu button if Left Pane is hidden
        ),
        // Left Drawer (if Left Pane hidden)
        drawer: !showLeftPane
            ? const Drawer(
                width: 300,
                child: NavigationPanel(),
              )
            : null,
        // Right Drawer (if Right Pane hidden)
        endDrawer: !showRightPane
            ? const Drawer(
                width: 350,
                child: SettingsPanel(),
              )
            : null,
        body: Column(
          children: [
            Expanded(
              child: MultiSplitViewTheme(
                data: MultiSplitViewThemeData(
                  dividerThickness: 10,
                  dividerPainter: DividerPainters.grooved1(
                    color: Colors.grey[400]!,
                    highlightedColor: Colors.blue,
                  ),
                ),
                child: _buildBody(showLeftPane, showRightPane),
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
              final total = provider.allFilesCount;
              final current = provider.currentFiles.length;
              final selected =
                  provider.currentFiles.where((f) => f.isSelected).length;

              String countText = '';
              if (current != total) {
                countText =
                    'Display: $current / Total: $total File : Selected $selected File';
              } else {
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
        floatingActionButton: !showRightPane
            ? FloatingActionButton(
                onPressed: () {
                  _scaffoldKey.currentState?.openEndDrawer();
                },
                child: const Icon(Icons.tune),
              )
            : null,
      ),
    );
  }

  Widget _buildBody(bool showLeftPane, bool showRightPane) {
    if (showLeftPane && showRightPane) {
      // 1. Desktop (3 Panes)
      return MultiSplitView(
        controller: _threePaneController,
        resizable: true,
        onDividerDragEnd: (index) => _saveSplitState(),
      );
    } else if (!showLeftPane && showRightPane) {
      // 2. Tablet (2 Panes: Center + Right)
      return MultiSplitView(
        controller: _twoPaneController,
        resizable: true,
        onDividerDragEnd: (index) => _saveSplitState(),
      );
    } else {
      // 3. Mobile (1 Pane: Center)
      return const FileListPanel();
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
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
  }

  bool _isEditing() {
    // 0. Explicit App State Check (Most Reliable)
    try {
      if (context.read<DirectoryProvider>().isInlineRenaming) return true;
    } catch (_) {}

    final focusNode = FocusManager.instance.primaryFocus;
    if (focusNode == null || focusNode.context == null) return false;

    // Robust check for various text input widgets
    // 1. Check for EditableText (Base class for most inputs)
    if (focusNode.context!.findAncestorWidgetOfExactType<EditableText>() !=
        null) {
      return true;
    }
    // 2. Check for TextField (Common wrapper)
    if (focusNode.context!.findAncestorWidgetOfExactType<TextField>() != null) {
      return true;
    }
    // 3. Check for TextFormField (Form wrapper)
    if (focusNode.context!.findAncestorWidgetOfExactType<TextFormField>() !=
        null) {
      return true;
    }
    // 4. Check for SearchBar (Material 3)
    if (focusNode.context!.findAncestorWidgetOfExactType<SearchBar>() != null) {
      return true;
    }

    return false;
  }
}
