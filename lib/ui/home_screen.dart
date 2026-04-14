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
import 'panels/home_app_bar.dart';
import 'widgets/preview_window.dart';
import 'widgets/enlarged_preview_overlay.dart';

import 'helpers/undo_helper.dart';
import 'helpers/filter_dialog_helper.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

import 'widgets/license_agreement_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WindowListener {
  late final MultiSplitViewController _threePaneController;
  late final MultiSplitViewController _twoPaneController;
  
  // Floating Preview State
  bool _showFloatingPreview = false;
  Timer? _previewTimer;
  int _lastSelectedCount = 0;
  String _lastSelectedPath = '';

  void _triggerFloatingPreview(int currentCount, String currentPath) {
    if (currentCount == 0) {
      if (_showFloatingPreview) {
        setState(() => _showFloatingPreview = false);
      }
      return;
    }
    
    if (currentCount != _lastSelectedCount || currentPath != _lastSelectedPath) {
      _lastSelectedCount = currentCount;
      _lastSelectedPath = currentPath;
      
      _previewTimer?.cancel();
      setState(() => _showFloatingPreview = true);
      
      _previewTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _showFloatingPreview = false);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      windowManager.addListener(this);
    }

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

    _twoPaneController = MultiSplitViewController(
      areas: [
        Area(flex: 0.6, builder: (c, a) => const FileListPanel()),
        Area(flex: 0.4, builder: (c, a) => const SettingsPanel()),
      ],
    );

    _loadSplitState();

    // 初期チェックフロー (ライセンス同意 -> Android権限 -> アップデートチェック)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<DirectoryProvider>();
      
      // 1. ライセンス同意のチェック
      if (!provider.isLicenseAccepted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const LicenseAgreementDialog(),
        );
      }
      
      // 2. Android 権限のチェック
      if (mounted) {
        await provider.requestAndroidPermissions(context);
      }

      // 3. アップデートチェック (静かに実行)
      if (mounted) {
        await provider.checkForUpdates();
        if (provider.hasUpdate && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('新しいバージョン (v${provider.latestVersion}) が利用可能です'),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: '設定を見る',
                onPressed: () {
                  // 設定ドロワーを開く
                  provider.scaffoldKey.currentState?.openEndDrawer();
                },
              ),
              duration: const Duration(seconds: 10),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      windowManager.removeListener(this);
    }
    _previewTimer?.cancel();
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

    final bool showLeftPane = width >= 1100;
    final bool showRightPane = width >= 700;
    final bool isNarrow = width < 700;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }

        if (_isEditing()) {
          return KeyEventResult.ignored;
        }

        final logicalKey = event.logicalKey;
        final isCtrl = HardwareKeyboard.instance.isControlPressed;
        final provider = context.read<DirectoryProvider>();

        if (logicalKey == LogicalKeyboardKey.escape) {
          if (provider.isEnlargedPreviewOpen) {
            provider.closeEnlargedPreview();
            return KeyEventResult.handled;
          }
        }

        if (logicalKey == LogicalKeyboardKey.arrowLeft) {
          if (provider.isEnlargedPreviewOpen) {
            provider.prevEnlargedPreview();
            return KeyEventResult.handled;
          }
        }

        if (logicalKey == LogicalKeyboardKey.arrowRight) {
          if (provider.isEnlargedPreviewOpen) {
            provider.nextEnlargedPreview();
            return KeyEventResult.handled;
          }
        }

        if (isCtrl && logicalKey == LogicalKeyboardKey.keyZ) {
          final provider = context.read<DirectoryProvider>();
          if (provider.canUndo) {
            UndoHelper.handleUndo(context, provider);
            return KeyEventResult.handled;
          }
        }

        if (isCtrl && logicalKey == LogicalKeyboardKey.arrowUp) {
          final provider = context.read<DirectoryProvider>();
          if (provider.canMoveUp) {
            provider.moveSelection(true);
            return KeyEventResult.handled;
          }
        }

        if (isCtrl && logicalKey == LogicalKeyboardKey.arrowDown) {
          final provider = context.read<DirectoryProvider>();
          if (provider.canMoveDown) {
            provider.moveSelection(false);
            return KeyEventResult.handled;
          }
        }

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

        if (isCtrl && logicalKey == LogicalKeyboardKey.keyV) {
          final provider = context.read<DirectoryProvider>();
          if (provider.canPaste) {
            provider.pasteFromClipboard();
          }
          return KeyEventResult.handled;
        }

        if (isCtrl && logicalKey == LogicalKeyboardKey.keyA) {
          context.read<DirectoryProvider>().selectAll(true);
          return KeyEventResult.handled;
        }

        if (logicalKey == LogicalKeyboardKey.delete) {
          _handleDelete(context, l10n);
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          final provider = context.read<DirectoryProvider>();
          
          // 1. もし履歴があれば、まずは一つ前のディレクトリに戻る
          if (provider.canGoBack) {
            await provider.goBack();
            return;
          }

          // 2. 履歴がない（ルート画面）の場合は、終了確認ダイアログを表示
          if (!context.mounted) return;
          
          final bool? shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('アプリの終了'),
              content: const Text('ReNamery を終了しますか？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.labelDialogCancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('終了する'),
                ),
              ],
            ),
          );

          if (shouldExit == true) {
            // ユーザーが明示的に終了を選択した場合のみ、アプリを閉じる
            await SystemNavigator.pop();
          }
        },
        child: Consumer<DirectoryProvider>(
          builder: (context, provider, child) {
            return Stack(
              children: [
                Scaffold(
                  key: provider.scaffoldKey,
                  appBar: HomeAppBar(
                    showDrawerMenu: !showLeftPane,
                  ),
                  drawer: !showLeftPane
                      ? Drawer(
                          width: 300,
                          child: SafeArea(
                            child: NavigationPanel(key: ValueKey(provider.resetCount)),
                          ),
                        )
                      : null,
                  endDrawer: !showRightPane
                      ? const Drawer(
                          width: 350,
                          child: SafeArea(
                            child: SettingsPanel(),
                          ),
                        )
                      : null,
                  body: Column(
                    children: [
                      provider.isLoading
                          ? const SizedBox(
                              height: 2,
                              child: LinearProgressIndicator(),
                            )
                          : const SizedBox(height: 2),
                      Expanded(                        child: MultiSplitViewTheme(
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
                  bottomNavigationBar: isNarrow
                      ? _buildMobileBottomAppBar(context, l10n)
                      : _buildDesktopFooter(context, l10n),
                  floatingActionButton: _buildFAB(isNarrow, showRightPane, context, l10n),
                  floatingActionButtonLocation: isNarrow 
                      ? FloatingActionButtonLocation.centerDocked 
                      : FloatingActionButtonLocation.endFloat,
                ),
                if (isNarrow)
                  Builder(
                    builder: (context) {
                      final selected = provider.currentFiles.where((f) => f.isSelected).toList();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _triggerFloatingPreview(
                          selected.length,
                          selected.length == 1 ? selected.first.entity.path : ''
                        );
                      });

                      return Positioned(
                        left: 16,
                        bottom: 100, // BottomAppBarの上に来るように調整
                        child: AnimatedOpacity(
                          opacity: _showFloatingPreview ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: IgnorePointer(
                            ignoring: !_showFloatingPreview,
                            child: GestureDetector(
                              onTap: () {
                                if (selected.isNotEmpty) {
                                  provider.openEnlargedPreview(selected.last);
                                }
                              },
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                                    width: 2,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: PreviewWindow(
                                  file: selected.isNotEmpty ? selected.last : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  ),
                
                // モバイル版クイックルック
                if (isNarrow)
                  const EnlargedPreviewOverlay(isMobile: true),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget? _buildFAB(bool isNarrow, bool showRightPane, BuildContext context, AppLocalizations l10n) {
    final provider = context.watch<DirectoryProvider>();
    if (isNarrow) {
      // スキャン中（読み込み中）は停止ボタンとして機能させる
      if (provider.isLoading) {
        return FloatingActionButton(
          onPressed: () => provider.cancelScan(),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          foregroundColor: Theme.of(context).colorScheme.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: const Icon(Symbols.stop_circle, size: 32, fill: 0),
        );
      }

      return FloatingActionButton(
        onPressed: provider.canExecute ? () => _confirmAndExecute(context, provider, l10n) : null,
        backgroundColor: provider.canExecute 
            ? Theme.of(context).colorScheme.primary // 案1: より鮮明なブランドカラーに変更
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: provider.canExecute 
            ? Theme.of(context).colorScheme.onPrimary 
            : Theme.of(context).colorScheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
        elevation: provider.canExecute ? 6 : 0, // 実行可能な時だけ浮き上がらせる
        child: const Icon(Symbols.play_arrow, size: 32, fill: 1), // FILLを1に戻す
      );
    } else if (!showRightPane) {
      return FloatingActionButton(
        onPressed: () => provider.scaffoldKey.currentState?.openEndDrawer(),
        child: const Icon(Symbols.tune),
      );
    }
    return null;
  }

  Widget _buildMobileBottomAppBar(BuildContext context, AppLocalizations l10n) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      height: 70, // 高さを抑える
      child: Consumer<DirectoryProvider>(
        builder: (context, provider, child) {
          final total = provider.allFilesCount;
          final current = provider.currentFiles.length;
          final selected = provider.currentFiles.where((f) => f.isSelected).length;

          String countText = current != total
              ? l10n.labelStatusDisplayCount(current, total, selected)
              : l10n.labelStatusTotalCount(total, selected);
          
          if (selected > 0) {
            countText += _getSelectionDetails(provider.currentFiles.where((f) => f.isSelected).toList(), l10n);
          }

          String statusText = provider.isLoading ? l10n.labelStatusProcessing : l10n.labelStatusReady;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Search & Filter Icon
              IconButton(
                icon: const Icon(Symbols.search),
                onPressed: () => FilterDialogHelper.showFilterPopup(context),
                tooltip: l10n.labelFilterOptions,
              ),
              
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter, // 最下部中央へ
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      "$countText | $statusText", // 二行を一列に集約
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9, // フォントサイズを維持
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Right: Rename Settings Icon
              IconButton(
                icon: const Icon(Symbols.tune),
                onPressed: () => provider.scaffoldKey.currentState?.openEndDrawer(),
                tooltip: l10n.labelMenuRenameSettings,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopFooter(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            final selected = provider.currentFiles.where((f) => f.isSelected).length;

            String countText = current != total
                ? l10n.labelStatusDisplayCount(current, total, selected)
                : l10n.labelStatusTotalCount(total, selected);
            
            if (selected > 0) {
              countText += _getSelectionDetails(provider.currentFiles.where((f) => f.isSelected).toList(), l10n);
            }

            String statusText = provider.isLoading ? l10n.labelStatusProcessing : l10n.labelStatusReady;
            final canExecute = provider.canExecute;

            return Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        countText,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  height: 48,
                  width: 200,
                  child: provider.isLoading
                      ? FilledButton.icon(
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: Theme.of(context).colorScheme.errorContainer,
                            foregroundColor: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () => provider.cancelScan(),
                          icon: const Icon(Symbols.stop_circle, size: 24),
                          label: const Text(
                            'スキャン中止',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        )
                      : FilledButton.icon(
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: canExecute ? () => _confirmAndExecute(context, provider, l10n) : null,
                          icon: const Icon(Symbols.play_arrow, size: 24),
                          label: Text(
                            l10n.labelGoRenamery,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
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
    final provider = context.watch<DirectoryProvider>();
    Widget mainContent;

    if (showLeftPane && showRightPane) {
      mainContent = MultiSplitView(
        axis: Axis.horizontal,
        controller: _threePaneController,
        resizable: true,
        onDividerDragEnd: (index) => _saveSplitState(),
      );
    } else if (!showLeftPane && showRightPane) {
      mainContent = MultiSplitView(
        axis: Axis.horizontal,
        controller: _twoPaneController,
        resizable: true,
        onDividerDragEnd: (index) => _saveSplitState(),
      );
    } else {
      mainContent = const FileListPanel();
    }

    // デスクトップ版サイドシート対応
    if (showRightPane && provider.isEnlargedPreviewOpen) {
      return Row(
        children: [
          Expanded(child: mainContent),
          const EnlargedPreviewOverlay(isMobile: false),
        ],
      );
    }

    return mainContent;
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
    try {
      if (context.read<DirectoryProvider>().isInlineRenaming) return true;
    } catch (_) {}

    final focusNode = FocusManager.instance.primaryFocus;
    if (focusNode == null || focusNode.context == null) return false;

    if (focusNode.context!.findAncestorWidgetOfExactType<EditableText>() !=
        null) {
      return true;
    }
    if (focusNode.context!.findAncestorWidgetOfExactType<TextField>() != null) {
      return true;
    }
    if (focusNode.context!.findAncestorWidgetOfExactType<TextFormField>() !=
        null) {
      return true;
    }
    if (focusNode.context!.findAncestorWidgetOfExactType<SearchBar>() != null) {
      return true;
    }

    return false;
  }
}
