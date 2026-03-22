import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;

import '../../core/directory_provider.dart';
import '../../core/file_model.dart';
import '../../core/settings_service.dart';
import 'panels/navigation_panel.dart';
import 'panels/file_list_panel.dart';
import 'panels/settings_panel.dart';
import 'panels/home_app_bar.dart'; // Import new AppBar

import 'helpers/undo_helper.dart';
import 'helpers/copy_helper.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

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
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      windowManager.addListener(this);
    }

    // Initialize 3-Pane Controller (Desktop)
    _threePaneController = MultiSplitViewController(
      areas: [
        Area(
            flex: 0.2,
            builder: (c, a) => Consumer<DirectoryProvider>(
                  builder: (context, provider, child) =>
                      NavigationPanel(key: ValueKey(provider.resetCount)),
                )),
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
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      windowManager.removeListener(this);
    }
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
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) return;
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

  String _getSelectionDetails(List<FileModel> selected, AppLocalizations l10n) {
    if (selected.isEmpty) return '';
    
    int images = 0;
    int pdfs = 0;
    int videos = 0;
    int audios = 0;
    int docs = 0;
    int archives = 0;
    int exes = 0;
    int others = 0;

    for (final f in selected) {
      final ext = p.extension(f.entity.path).toLowerCase();
      if (['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp', '.ico', '.svg'].contains(ext)) {
        images++;
      } else if (ext == '.pdf') {
        pdfs++;
      } else if (['.mp4', '.mov', '.avi', '.mkv', '.wmv', '.flv'].contains(ext)) {
        videos++;
      } else if (['.mp3', '.wav', '.m4a', '.flac', '.ogg'].contains(ext)) {
        audios++;
      } else if (['.docx', '.xlsx', '.pptx', '.txt', '.md', '.csv', '.html'].contains(ext)) {
        docs++;
      } else if (['.zip', '.7z', '.rar', '.tar', '.gz'].contains(ext)) {
        archives++;
      } else if (['.exe', '.msi', '.bat', '.sh'].contains(ext)) {
        exes++;
      } else {
        others++;
      }
    }

    final parts = <String>[];
    if (images > 0) parts.add('${l10n.labelTypeImage} $images');
    if (pdfs > 0) parts.add('${l10n.labelTypePDF} $pdfs');
    if (videos > 0) parts.add('${l10n.labelTypeVideo} $videos');
    if (audios > 0) parts.add('${l10n.labelTypeAudio} $audios');
    if (docs > 0) parts.add('${l10n.labelTypeDocument} $docs');
    if (archives > 0) parts.add('${l10n.labelTypeArchive} $archives');
    if (exes > 0) parts.add('${l10n.labelTypeExecutable} $exes');
    if (others > 0) parts.add('${l10n.labelTypeOther} $others');

    return ' (${parts.join(", ")})';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.of(context).size.width;

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
          final count = provider.currentFiles.where((f) => f.isSelected).length;
          if (count > 0) {
            provider.copySelection();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.labelMsgCopyFilesSuccess(count))),
            );
          }
          return KeyEventResult.handled;
        }

        // Ctrl + X : Cut
        if (isCtrl && logicalKey == LogicalKeyboardKey.keyX) {
          final provider = context.read<DirectoryProvider>();
          final count = provider.currentFiles.where((f) => f.isSelected).length;
          if (count > 0) {
            provider.cutSelection();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.labelMsgCutFilesSuccess(count))),
            );
          }
          return KeyEventResult.handled;
        }

        // Ctrl + V : Paste
        if (isCtrl && logicalKey == LogicalKeyboardKey.keyV) {
          final provider = context.read<DirectoryProvider>();
          if (provider.canPaste) {
            provider.pasteFromClipboard();
          }
          return KeyEventResult.handled;
        }

        // Ctrl + A : Select All
        if (isCtrl && logicalKey == LogicalKeyboardKey.keyA) {
          context.read<DirectoryProvider>().selectAll(true);
          return KeyEventResult.handled;
        }

        // Delete : Delete Files
        if (logicalKey == LogicalKeyboardKey.delete) {
          _handleDelete(context, l10n);
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
            ? Drawer(
                width: 300,
                child: Consumer<DirectoryProvider>(
                  builder: (context, provider, child) =>
                      NavigationPanel(key: ValueKey(provider.resetCount)),
                ),
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
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: SafeArea(
            child: Consumer<DirectoryProvider>(
              builder: (context, provider, child) {
                final total = provider.allFilesCount;
                final current = provider.currentFiles.length;
                final selected =
                    provider.currentFiles.where((f) => f.isSelected).length;

                String countText = '';
                if (current != total) {
                  countText =
                      l10n.labelStatusDisplayCount(current, total, selected);
                } else {
                  countText = l10n.labelStatusTotalCount(total, selected);
                }
                
                // Add selection details (Image, PDF, etc.)
                if (selected > 0) {
                  countText += _getSelectionDetails(provider.currentFiles.where((f) => f.isSelected).toList(), l10n);
                }

                String statusText = provider.isLoading
                    ? l10n.labelStatusProcessing
                    : l10n.labelStatusReady;

                final canExecute = provider.canExecute;

                return Row(
                  children: [
                    // Status
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            countText,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            statusText,
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Action Button
                    SizedBox(
                      height: 48,
                      width: 200,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                        onPressed: canExecute
                            ? () => _confirmAndExecute(context, provider, l10n)
                            : null,
                        icon: const Icon(Symbols.play_arrow, size: 24),
                        label: Text(
                          l10n.labelGoRenamery,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
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

  Future<void> _confirmAndExecute(BuildContext context,
      DirectoryProvider provider, AppLocalizations l10n) async {
    if (!provider.currentFiles.any((f) => f.isSelected)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No files selected')),
      );
      return;
    }

    final int invalidCount = provider.invalidFileCount;
    final int validCount = provider.validFileCount;

    if (invalidCount > 0) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('エラーを含むファイルのスキップ確認'),
          content: Text(
            '選択されたファイルの中に、ファイル名が不正（禁止文字・重複など）なものが $invalidCount 件あります。\n\n'
            'これらを除外し、正常な $validCount 件のファイルのみリネームを実行しますか？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('スキップして続行'),
            ),
          ],
        ),
      );

      if (shouldProceed != true) {
        return;
      }
    }

    final executedCount = await provider.executeRename();

    if (context.mounted) {
      if (executedCount > 0) {
        final msg = invalidCount > 0
            ? '$executedCount 件成功、$invalidCount 件はエラーのためスキップされました'
            : l10n.labelMsgExecutedCount(executedCount);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('実行できるファイルがありませんでした')),
        );
      }
    }
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

  Future<void> _handleDelete(
      BuildContext context, AppLocalizations l10n) async {
    final provider = context.read<DirectoryProvider>();
    final selectedCount =
        provider.currentFiles.where((f) => f.isSelected).length;
    if (selectedCount == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.labelDeleteConfirmTitle),
        content: Text(l10n.labelDeleteConfirmMessage(selectedCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.labelDialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.labelDialogDelete),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final deleted = await provider.deleteSelectedFiles();
      if (context.mounted && deleted > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.labelMsgDeletedCount(deleted))),
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
