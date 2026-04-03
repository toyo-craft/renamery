import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';
import '../../core/directory_provider.dart';
import '../../core/file_model.dart';
import '../../core/rename_engine.dart';
import '../../utils/platform_utils.dart';

class FileListPanel extends StatefulWidget {
  const FileListPanel({super.key});

  @override
  State<FileListPanel> createState() => _FileListPanelState();
}

class _FileListPanelState extends State<FileListPanel> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final TextEditingController _pathController = TextEditingController();

  String? _editingFilePath;
  late TextEditingController _renameController;
  final FocusNode _renameFocusNode = FocusNode();
  final FocusNode _fileListFocusNode = FocusNode();

  // Step 1: Selection drag state
  Offset? _dragStart;
  Offset? _dragUpdate;
  Timer? _scrollTimer;
  List<bool>? _initialSelectionStates;
  int? _draggingIndex;
  Key _reorderableListKey = UniqueKey();

  double _colWidthOriginal = 200.0;
  double _colWidthNew = 200.0;
  double _colWidthSize = 80.0;
  double _colWidthPath = 150.0;
  double _colWidthType = 100.0;
  double _colWidthDate = 140.0;
  final double _colWidthAttr = 60.0;

  final double _widthDragHandle = 32.0;
  final double _widthCheckbox = 32.0;
  final double _widthSpace = 8.0;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController();
    _renameFocusNode.addListener(() {
      if (!_renameFocusNode.hasFocus && _editingFilePath != null) {
        setState(() { _editingFilePath = null; });
        context.read<DirectoryProvider>().setInlineRenaming(false);
      }
    });

    // グローバルキーハンドラを追加
    HardwareKeyboard.instance.addHandler(_handleGlobalKey);
  }

  bool _handleGlobalKey(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      final provider = context.read<DirectoryProvider>();

      // 1. ドラッグ移動のキャンセル
      if (_draggingIndex != null) {
        setState(() {
          _draggingIndex = null;
          _reorderableListKey = UniqueKey();
        });
        return true;
      }

      // 2. インラインリネームのキャンセル
      if (_editingFilePath != null) {
        setState(() { _editingFilePath = null; });
        provider.setInlineRenaming(false);
        return true;
      }

      // 3. ラバーバンド選択（矩形表示）のキャンセル
      if (_dragStart != null) {
        setState(() {
          _dragStart = null;
          _dragUpdate = null;
          _initialSelectionStates = null;
        });
        return true;
      }

      // 4. 全選択解除
      if (provider.currentFiles.any((f) => f.isSelected)) {
        provider.selectAll(false);
        return true;
      }

      // 5. 切り取り状態の解除
      if (provider.isCutMode) {
        provider.clearCutState();
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKey);
    _horizontalController.dispose();
    _verticalController.dispose();
    _pathController.dispose();
    _renameController.dispose();
    _renameFocusNode.dispose();
    _fileListFocusNode.dispose();
    super.dispose();
  }

  Widget _buildResizeHandle(Function(DragUpdateDetails) onDrag) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: onDrag,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: SizedBox(
          width: 16,
          height: double.infinity,
          child: Center(
            child: VerticalDivider(width: 1, thickness: 1, color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String label, double width, int sortIndex, DirectoryProvider provider) {
    final isActive = provider.sortColumnIndex == sortIndex;
    final color = isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () => provider.sortFiles(sortIndex, !provider.sortAscending),
        child: Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color), overflow: TextOverflow.ellipsis)),
            if (isActive) Icon(provider.sortAscending ? Icons.expand_less : Icons.expand_more, size: 14, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(String text, double width, {Color? color, TextStyle? style}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: (style ?? const TextStyle()).copyWith(color: color ?? style?.color ?? Theme.of(context).colorScheme.onSurface, fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  TextSpan _buildDiffTextSpan(BuildContext context, String oldText, String newText, bool hasError, {TextStyle? style, RenameMode? mode, int? startNumber, int? digits}) {
    final baseTextStyle = (style ?? const TextStyle()).copyWith(fontSize: 12, color: hasError ? Theme.of(context).colorScheme.error : style?.color ?? Theme.of(context).colorScheme.onSurface);
    if (oldText == newText || hasError) {
      return TextSpan(text: newText, style: baseTextStyle);
    }

    // 特定の削除モードにおける確定的ハイライト処理
    if (mode == RenameMode.deleteStart || mode == RenameMode.deleteEnd || mode == RenameMode.deleteFrom) {
      int delStart = 0;
      int delCount = digits ?? 0;
      
      if (mode == RenameMode.deleteStart) {
        delStart = 0;
      } else if (mode == RenameMode.deleteEnd) {
        delStart = oldText.length - delCount;
      } else if (mode == RenameMode.deleteFrom) {
        delStart = (startNumber ?? 1) - 1;
      }

      delStart = delStart.clamp(0, oldText.length);
      int delEnd = (delStart + delCount).clamp(0, oldText.length);
      
      final prefix = oldText.substring(0, delStart);
      final deleted = oldText.substring(delStart, delEnd);
      final suffix = oldText.substring(delEnd);

      return TextSpan(
        style: baseTextStyle,
        children: [
          if (prefix.isNotEmpty) TextSpan(text: prefix, style: TextStyle(color: style?.color ?? Theme.of(context).colorScheme.onSurface)),
          if (deleted.isNotEmpty) TextSpan(text: deleted, style: TextStyle(color: Colors.red.withValues(alpha: 0.7), decoration: TextDecoration.lineThrough)),
          if (suffix.isNotEmpty) TextSpan(text: suffix, style: TextStyle(color: style?.color ?? Theme.of(context).colorScheme.onSurface)),
        ],
      );
    }

    // その他のモードは従来の差分アルゴリズムを使用
    int prefixLen = 0;
    while (prefixLen < oldText.length && prefixLen < newText.length && oldText[prefixLen] == newText[prefixLen]) {
      prefixLen++;
    }
    int suffixLen = 0;
    while (suffixLen < oldText.length - prefixLen && suffixLen < newText.length - prefixLen && oldText[oldText.length - 1 - suffixLen] == newText[newText.length - 1 - suffixLen]) {
      suffixLen++;
    }
    final prefix = oldText.substring(0, prefixLen);
    final deleted = oldText.substring(prefixLen, oldText.length - suffixLen);
    final added = newText.substring(prefixLen, newText.length - suffixLen);
    final suffix = oldText.substring(oldText.length - suffixLen);
    return TextSpan(
      style: baseTextStyle,
      children: [
        if (prefix.isNotEmpty) TextSpan(text: prefix, style: TextStyle(color: style?.color ?? Theme.of(context).colorScheme.onSurface)),
        if (deleted.isNotEmpty) TextSpan(text: deleted, style: TextStyle(color: Colors.red.withValues(alpha: 0.7), decoration: TextDecoration.lineThrough)),
        if (added.isNotEmpty) TextSpan(text: added, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        if (suffix.isNotEmpty) TextSpan(text: suffix, style: TextStyle(color: style?.color ?? Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }

  Future<void> _showBackgroundContextMenu(BuildContext context, TapDownDetails details, DirectoryProvider provider, AppLocalizations l10n) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(details.globalPosition & const Size(40, 40), Offset.zero & overlay.size),
      items: [
        PopupMenuItem(value: 'up_folder', child: Text(l10n.labelCtxUpOneFolder)),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'paste', enabled: provider.canPaste, child: Text(l10n.labelCtxPasteItems)),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'new_folder', child: Text(l10n.labelCtxCreateFolder)),
        PopupMenuItem(value: 'refresh', child: Text(l10n.labelCtxRefresh)),
      ],
    );
    if (!mounted || result == null) return;
    switch (result) {
      case 'up_folder': await provider.goUp(); break;
      case 'paste': await provider.pasteFromClipboard(); break;
      case 'new_folder': await provider.createNewFolder(); break;
      case 'refresh': await provider.refresh(); break;
    }
  }

  Future<void> _showRowContextMenu(BuildContext context, TapDownDetails details, FileModel fileModel, DirectoryProvider provider, AppLocalizations l10n) async {
    if (!fileModel.isSelected) provider.toggleSelection(fileModel);
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(details.globalPosition & const Size(40, 40), Offset.zero & overlay.size),
      items: [
        PopupMenuItem(value: 'up_folder', child: Text(l10n.labelCtxUpOneFolder)),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'copy', child: Text(l10n.labelCtxCopyItems)),
        PopupMenuItem(value: 'cut', child: Text(l10n.labelCtxCutItems)),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'rename', child: Text(l10n.labelCtxRenameGeneral)),        PopupMenuItem(value: 'batch_rename', child: Text(l10n.labelCtxBatchRename)),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'open', child: Text(l10n.labelCtxOpenWithAssoc)),
        PopupMenuItem(value: 'top', child: Text(l10n.labelCtxMoveToTop)),
        PopupMenuItem(value: 'bottom', child: Text(l10n.labelCtxMoveToBottom)),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.labelCtxDeleteItems, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const Icon(Icons.delete, color: Colors.red, size: 20),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'refresh', child: Text(l10n.labelCtxRefresh)),
        PopupMenuItem(value: 'properties', child: Text(l10n.labelCtxProperties)),
      ],
    );
    if (!mounted || result == null) return;
    switch (result) {
      case 'up_folder': await provider.goUp(); break;
      case 'copy': await provider.copySelection(); break;
      case 'cut': await provider.cutSelection(); break;
      case 'rename':        setState(() { _editingFilePath = fileModel.entity.path; _renameController.text = fileModel.originalName; });
        provider.setInlineRenaming(true);
        WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _renameFocusNode.requestFocus(); });
        break;
      case 'batch_rename': await provider.executeRename(); break;
      case 'open': PlatformUtils.openFile(fileModel.entity.path); break;
      case 'top': provider.moveSelectedToTop(); break;
      case 'bottom': provider.moveSelectedToBottom(); break;
      case 'refresh': await provider.refresh(); break;
      case 'properties': PlatformUtils.showPropertiesDialog(context, fileModel); break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.labelDialogTrashTitle),
            content: Text(l10n.labelDialogTrashMessage),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.labelDialogCancel)),
              TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: Text(l10n.labelDialogDelete)),
            ],
          ),
        );
        if (confirm == true) await provider.deleteSelectedFiles();
        break;
    }
  }

  void _updateSelectionOnScroll(Offset localPosition, List<FileModel> files, DirectoryProvider provider) {
    if (_dragStart == null) return;
    
    final currentAbsY = localPosition.dy + _verticalController.offset;
    final minY = (_dragStart!.dy < currentAbsY ? _dragStart!.dy : currentAbsY);
    final maxY = (_dragStart!.dy > currentAbsY ? _dragStart!.dy : currentAbsY);
    
    final rowH = provider.touchMode ? 50.0 : 34.0;
    final filesHeight = files.length * rowH;
    if (minY >= filesHeight || maxY <= 0) {
      provider.selectRange(-1, -1, exclusive: !HardwareKeyboard.instance.isControlPressed, baseStates: _initialSelectionStates);
      return;
    }

    final startIndex = (minY / rowH).floor().clamp(0, files.length - 1);
    final endIndex = (maxY / rowH).floor().clamp(0, files.length - 1);
    
    provider.selectRange(startIndex, endIndex, exclusive: !HardwareKeyboard.instance.isControlPressed, baseStates: _initialSelectionStates);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<DirectoryProvider>(
      builder: (context, provider, child) {
        if (provider.currentDirectory != null && _pathController.text != provider.currentDirectory!.path) {
          _pathController.text = provider.currentDirectory!.path;
        }
        final files = provider.currentFiles;
        final totalWidth = _widthDragHandle + _widthCheckbox + (_widthSpace * 7) + (_colWidthOriginal + 16) + (_colWidthNew + 16) + (_colWidthSize + 16) + (_colWidthPath + 16) + (_colWidthType + 16) + (_colWidthDate + 16) + _colWidthAttr + 32.0;

        return LayoutBuilder(
          builder: (context, constraints) {
            return Focus(
              autofocus: true,
              canRequestFocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  debugPrint('Key Event: ${event.logicalKey}');
                  if (event.logicalKey == LogicalKeyboardKey.f2) {
                    final selectedFile = provider.currentFiles.where((f) => f.isSelected).firstOrNull;
                    if (selectedFile != null) {
                      setState(() { _editingFilePath = selectedFile.entity.path; _renameController.text = selectedFile.originalName; });
                      provider.setInlineRenaming(true);
                      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _renameFocusNode.requestFocus(); });
                      return KeyEventResult.handled;
                    }
                  }
                  if (event.logicalKey == LogicalKeyboardKey.escape) {
                    debugPrint('ESC Pressed. Dragging: ${_draggingIndex != null}');
                    if (_draggingIndex != null) {
                      setState(() {
                        _draggingIndex = null;
                        _reorderableListKey = UniqueKey();
                      });
                      return KeyEventResult.handled;
                    }
                    if (_editingFilePath != null) {
                      setState(() { _editingFilePath = null; });
                      provider.setInlineRenaming(false);
                      return KeyEventResult.handled;
                    }
                    if (_dragStart != null) {
                      setState(() {
                        _dragStart = null;
                        _dragUpdate = null;
                        _initialSelectionStates = null;
                      });
                      return KeyEventResult.handled;
                    }
                    
                    // 何もアクティブでない場合、全選択解除を実行
                    if (provider.currentFiles.any((f) => f.isSelected)) {
                      provider.selectAll(false);
                      return KeyEventResult.handled;
                    }
                  }
                  if (event.logicalKey == LogicalKeyboardKey.f5) { provider.refresh(); return KeyEventResult.handled; }
                }
                return KeyEventResult.ignored;
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Row(
                      children: [
                        Text(l10n.labelFullPath, style: const TextStyle(fontSize: 13)),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border.all(color: Theme.of(context).colorScheme.outline), borderRadius: BorderRadius.circular(2)),
                            child: TextField(
                              controller: _pathController,
                              style: const TextStyle(fontSize: 13),
                              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), border: InputBorder.none, isDense: true),
                              onSubmitted: (value) => provider.setDirectory(io.Directory(value)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(icon: Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.primary), tooltip: l10n.labelMenuGo, onPressed: () => provider.setDirectory(io.Directory(_pathController.text))),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: () {
                              final allSelected = files.isNotEmpty && files.every((f) => f.isSelected);
                              provider.selectAll(!allSelected);
                            },
                            child: Text(files.isNotEmpty && files.every((f) => f.isSelected) ? l10n.labelDeselectAll : l10n.labelSelectAll),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Focus(
                      focusNode: _fileListFocusNode,
                      autofocus: true,
                      child: Builder(
                        builder: (context) {
                          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                          if (provider.currentDirectory == null) return Center(child: Text(l10n.labelSelectFolderPrompt(l10n.labelTermFolder)));

                          return Scrollbar(
                            controller: _verticalController,
                            thumbVisibility: true,
                            notificationPredicate: (n) => n.depth == 1,
                            child: Scrollbar(
                              controller: _horizontalController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              notificationPredicate: (n) => n.depth == 0,
                              child: SingleChildScrollView(
                                controller: _horizontalController,
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: totalWidth, minHeight: constraints.maxHeight - 56),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onSecondaryTapDown: (_) {},
                                        child: Container(
                                          width: totalWidth, height: 36,
                                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1.0))),
                                          child: Row(
                                            children: [
                                              SizedBox(width: _widthDragHandle),
                                              SizedBox(width: _widthCheckbox, child: Checkbox(value: files.isNotEmpty && files.every((f) => f.isSelected), onChanged: (val) => provider.selectAll(val ?? false), visualDensity: VisualDensity.compact)),
                                              SizedBox(width: _widthSpace),
                                              _buildHeaderCell(l10n.labelColName, _colWidthOriginal, 0, provider),
                                              _buildResizeHandle((d) => setState(() => _colWidthOriginal = (_colWidthOriginal + d.delta.dx).clamp(50.0, 500.0))),
                                              SizedBox(width: _widthSpace),
                                              _buildHeaderCell(l10n.labelColNewName, _colWidthNew, 1, provider),
                                              _buildResizeHandle((d) => setState(() => _colWidthNew = (_colWidthNew + d.delta.dx).clamp(50.0, 500.0))),
                                              SizedBox(width: _widthSpace),
                                              _buildHeaderCell(l10n.labelColSize, _colWidthSize, 2, provider),
                                              _buildResizeHandle((d) => setState(() => _colWidthSize = (_colWidthSize + d.delta.dx).clamp(40.0, 200.0))),
                                              SizedBox(width: _widthSpace),
                                              _buildHeaderCell(l10n.labelColPath, _colWidthPath, 3, provider),
                                              _buildResizeHandle((d) => setState(() => _colWidthPath = (_colWidthPath + d.delta.dx).clamp(50.0, 300.0))),
                                              SizedBox(width: _widthSpace),
                                              _buildHeaderCell(l10n.labelColType, _colWidthType, 4, provider),
                                              _buildResizeHandle((d) => setState(() => _colWidthType = (_colWidthType + d.delta.dx).clamp(50.0, 200.0))),
                                              SizedBox(width: _widthSpace),
                                              _buildHeaderCell(l10n.labelColDate, _colWidthDate, 5, provider),
                                              _buildResizeHandle((d) => setState(() => _colWidthDate = (_colWidthDate + d.delta.dx).clamp(80.0, 200.0))),
                                              SizedBox(width: _widthSpace),
                                              _buildHeaderCell(l10n.labelColAttr, _colWidthAttr, 6, provider),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: SizedBox(
                                          width: totalWidth,
                                          child: Listener(
                                            onPointerDown: (event) {
                                              // マウス操作のみ矩形選択を開始する（タッチ操作はスクロールを優先）
                                              if (event.kind != PointerDeviceKind.mouse) return;

                                              if (event.buttons == kPrimaryMouseButton) {
                                                // ドラッグハンドルやチェックボックスの領域（左端 72px）でのクリックは無視
                                                if (event.localPosition.dx < (_widthDragHandle + _widthCheckbox + _widthSpace)) {
                                                  return;
                                                }

                                                setState(() {
                                                  // リスト全体における絶対座標を保存
                                                  _dragStart = Offset(event.localPosition.dx, event.localPosition.dy + _verticalController.offset);
                                                  _dragUpdate = _dragStart;
                                                  
                                                  // ドラッグ開始時の選択状態を保存 (スナップショット)
                                                  _initialSelectionStates = provider.currentFiles.map((f) => f.isSelected).toList();
                                                });
                                                debugPrint('Drag Start (Abs): $_dragStart');
                                              }
                                            },
                                            onPointerMove: (event) {
                                              // ドラッグ中に ESC キーが押されたかチェック
                                              if (_draggingIndex != null && HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.escape)) {
                                                setState(() {
                                                  _draggingIndex = null;
                                                  _reorderableListKey = UniqueKey();
                                                });
                                                debugPrint('ESC detected during move. Drag cancelled.');
                                                return;
                                              }

                                              if (_dragStart != null) {
                                                setState(() {
                                                  _dragUpdate = Offset(event.localPosition.dx, event.localPosition.dy + _verticalController.offset);
                                                });
                                                
                                                // ドラッグ距離（画面上）の判定
                                                final currentLocalPos = event.localPosition;
                                                final startLocalPos = Offset(_dragStart!.dx, _dragStart!.dy - _verticalController.offset);
                                                if ((currentLocalPos - startLocalPos).distance < 5.0) return;

                                                // 自動スクロール判定
                                                const scrollThreshold = 30.0;
                                                const scrollSpeed = 15.0;
                                                final containerHeight = constraints.maxHeight - 56;
                                                
                                                if (event.localPosition.dy < scrollThreshold) {
                                                  _scrollTimer ??= Timer.periodic(const Duration(milliseconds: 50), (timer) {
                                                    final newOffset = (_verticalController.offset - scrollSpeed).clamp(0.0, _verticalController.position.maxScrollExtent);
                                                    _verticalController.jumpTo(newOffset);
                                                    // スクロール中も選択範囲を更新
                                                    _updateSelectionOnScroll(event.localPosition, files, provider);
                                                  });
                                                } else if (event.localPosition.dy > containerHeight - scrollThreshold) {
                                                  _scrollTimer ??= Timer.periodic(const Duration(milliseconds: 50), (timer) {
                                                    final newOffset = (_verticalController.offset + scrollSpeed).clamp(0.0, _verticalController.position.maxScrollExtent);
                                                    _verticalController.jumpTo(newOffset);
                                                    // スクロール中も選択範囲を更新
                                                    _updateSelectionOnScroll(event.localPosition, files, provider);
                                                  });
                                                } else {
                                                  _scrollTimer?.cancel();
                                                  _scrollTimer = null;
                                                }

                                                _updateSelectionOnScroll(event.localPosition, files, provider);
                                              }
                                            },
                                            onPointerUp: (event) {
                                              if (_dragStart != null) {
                                                _scrollTimer?.cancel();
                                                _scrollTimer = null;
                                                setState(() {
                                                  _dragStart = null;
                                                  _dragUpdate = null;
                                                  _initialSelectionStates = null;
                                                });
                                                debugPrint('Drag End');
                                              }
                                            },
                                            child: Stack(
                                              children: [
                                                ScrollConfiguration(
                                                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                                                  child: ListView(
                                                    controller: _verticalController,
                                                    padding: EdgeInsets.zero,
                                                    children: [
                                                      if (files.isNotEmpty)
                                                        SizedBox(
                                                          height: files.length * (provider.touchMode ? 50.0 : 34.0),
                                                          child: ReorderableListView.builder(
                                                            key: _reorderableListKey,
                                                            primary: false,
                                                            shrinkWrap: true,
                                                            padding: EdgeInsets.zero,
                                                            buildDefaultDragHandles: false,
                                                            itemCount: files.length,
                                                            onReorder: (oldIdx, newIdx) => provider.reorderFiles(oldIdx, newIdx),
                                                            onReorderStart: (index) => setState(() => _draggingIndex = index),
                                                            onReorderEnd: (_) => setState(() => _draggingIndex = null),
                                                            proxyDecorator: (child, index, animation) {
                                                              return AnimatedBuilder(
                                                                animation: animation,
                                                                builder: (context, child) {
                                                                  final provider = context.read<DirectoryProvider>();
                                                                  final selectedCount = provider.currentFiles.where((f) => f.isSelected).length;
                                                                  final isMultiMove = provider.currentFiles[index].isSelected && selectedCount > 1;
                                                                  final rowH = provider.touchMode ? 48.0 : 32.0;

                                                                  return Material(
                                                                    elevation: 12.0,
                                                                    color: Colors.transparent,
                                                                    shadowColor: Colors.black.withValues(alpha: 0.4),
                                                                    child: Stack(
                                                                      clipBehavior: Clip.none,
                                                                      children: [
                                                                        if (isMultiMove) ...[
                                                                          // 背後レイヤー 2
                                                                          Positioned(
                                                                            top: 8, left: 8, right: 8, bottom: -8,
                                                                            child: Container(
                                                                              height: rowH, margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 1.0),
                                                                              decoration: BoxDecoration(
                                                                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                                                                borderRadius: BorderRadius.circular(8),
                                                                                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          // 背後レイヤー 1
                                                                          Positioned(
                                                                            top: 4, left: 4, right: 4, bottom: -4,
                                                                            child: Container(
                                                                              height: rowH, margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 1.0),
                                                                              decoration: BoxDecoration(
                                                                                color: Theme.of(context).colorScheme.surfaceContainerHigh.withValues(alpha: 0.7),
                                                                                borderRadius: BorderRadius.circular(8),
                                                                                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                        // メインの行
                                                                        Stack(
                                                                          children: [
                                                                            Positioned.fill(
                                                                              child: Container(
                                                                                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 1.0),
                                                                                decoration: BoxDecoration(
                                                                                  color: Theme.of(context).colorScheme.surface,
                                                                                  borderRadius: BorderRadius.circular(8),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            child!,
                                                                          ],
                                                                        ),
                                                                        if (isMultiMove)

                                                                          Positioned(
                                                                            right: -12,
                                                                            top: -12,
                                                                            child: Container(
                                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                                              decoration: BoxDecoration(
                                                                                color: Theme.of(context).colorScheme.primary,
                                                                                borderRadius: BorderRadius.circular(20),
                                                                                boxShadow: [
                                                                                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3)),
                                                                                ],
                                                                              ),
                                                                              child: Row(
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                children: [
                                                                                  const Icon(Icons.copy_all, color: Colors.white, size: 14),
                                                                                  const SizedBox(width: 4),
                                                                                  Text(
                                                                                    '$selectedCount',
                                                                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                },
                                                                child: child,
                                                              );
                                                            },
                                                            itemBuilder: (context, index) {
                                                              final file = files[index];
                                                              final isDir = file.entity is io.Directory;
                                                              final isEditing = _editingFilePath == file.entity.path;

                                                              final rowH = provider.touchMode ? 48.0 : 32.0;
                                                              final iconS = provider.touchMode ? 28.0 : 18.0;
                                                              final dragS = provider.touchMode ? 24.0 : 16.0;
                                                              
                                                              // 現在移動中の他の選択項目をゴースト化（半透明）
                                                              final isGhost = _draggingIndex != null && file.isSelected && index != _draggingIndex;
                                                              
                                                              // 不透明度の決定: ドラッグゴースト(0.3) > 切り取り状態(0.5) > 通常(1.0)
                                                              final currentOpacity = isGhost ? 0.3 : (file.isCut ? 0.5 : 1.0);
                                                              // 切り取り中のテキストスタイル
                                                              final baseStyle = TextStyle(
                                                                fontSize: provider.touchMode ? 15.0 : 12.0, 
                                                                fontWeight: file.isSelected ? FontWeight.w600 : FontWeight.normal,
                                                                fontStyle: file.isCut ? FontStyle.italic : FontStyle.normal,
                                                                color: file.isCut ? Theme.of(context).colorScheme.onSurfaceVariant : null,
                                                              );

                                                              return GestureDetector(
                                                                key: ValueKey(file.entity.path),
                                                                behavior: HitTestBehavior.opaque,
                                                                onSecondaryTapDown: (details) => _showRowContextMenu(context, details, file, provider, l10n),
                                                                child: Opacity(
                                                                  opacity: currentOpacity,
                                                                  child: InkWell(
                                                                    onTap: () => provider.toggleSelection(file),
                                                                    child: Container(
                                                                      height: rowH,
                                                                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 1.0),
                                                                      decoration: BoxDecoration(
                                                                        color: file.isSelected ? Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5) : (index % 2 == 0 ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surfaceContainerLow),
                                                                        borderRadius: BorderRadius.circular(8),
                                                                        border: file.isSelected ? Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)) : null,
                                                                      ),
                                                                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: provider.touchMode ? 4.0 : 2.0),
                                                                      child: Row(
                                                                        children: [
                                                                          SizedBox(width: provider.touchMode ? 40.0 : _widthDragHandle, child: ReorderableDragStartListener(index: index, child: Icon(Icons.drag_indicator, size: dragS, color: file.isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant))),
                                                                          SizedBox(width: provider.touchMode ? 40.0 : _widthCheckbox, child: Checkbox(value: file.isSelected, onChanged: (val) => provider.toggleSelection(file), visualDensity: provider.touchMode ? VisualDensity.standard : VisualDensity.compact)),
                                                                          SizedBox(width: _widthSpace),
                                                                          SizedBox(
                                                                            width: _colWidthOriginal,
                                                                            child: isEditing
                                                                                ? TextField(
                                                                                    controller: _renameController,
                                                                                    focusNode: _renameFocusNode,
                                                                                    autofocus: true,
                                                                                    style: TextStyle(fontSize: provider.touchMode ? 15.0 : 12.0),
                                                                                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(4), border: OutlineInputBorder()),
                                                                                    onSubmitted: (val) {
                                                                                      provider.renameOneFile(file, val);
                                                                                      setState(() { _editingFilePath = null; });
                                                                                      provider.setInlineRenaming(false);
                                                                                    },
                                                                                  )
                                                                                : Row(
                                                                                    children: [
                                                                                      GestureDetector(
                                                                                        onDoubleTap: () { if (isDir) { provider.setDirectory(file.entity as io.Directory); } else { PlatformUtils.openFile(file.entity.path); } },
                                                                                        child: Icon(isDir ? Icons.folder : Icons.insert_drive_file, color: isDir ? Theme.of(context).colorScheme.tertiary : Theme.of(context).colorScheme.secondary, size: iconS),
                                                                                      ),

                                                                                      const SizedBox(width: 8),
                                                                                      Expanded(
                                                                                        child: GestureDetector(
                                                                                          onDoubleTap: () {
                                                                                            setState(() { _editingFilePath = file.entity.path; _renameController.text = file.originalName; });
                                                                                            provider.setInlineRenaming(true);
                                                                                            WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _renameFocusNode.requestFocus(); });
                                                                                          },
                                                                                          child: Text(file.originalName, overflow: TextOverflow.ellipsis, style: baseStyle),
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                          ),
                                                                          SizedBox(width: _widthSpace + 16),
                                                                          SizedBox(width: _colWidthNew, child: Row(children: [Expanded(child: RichText(text: _buildDiffTextSpan(context, file.originalName, file.newName, file.hasValidationError, style: baseStyle, mode: provider.renameMode, startNumber: provider.startNumber, digits: provider.digits), overflow: TextOverflow.ellipsis)), if (file.hasValidationError) Tooltip(message: file.validationErrorMessage ?? 'Error', child: Padding(padding: const EdgeInsets.only(left: 4), child: Icon(Icons.error_outline, color: Colors.red, size: iconS - 2)))] )),
                                                                          SizedBox(width: _widthSpace + 16),
                                                                          _buildCell(file.size, _colWidthSize, style: baseStyle),
                                                                          SizedBox(width: _widthSpace + 16),
                                                                          _buildCell(file.displayRelativePath, _colWidthPath, color: Theme.of(context).colorScheme.onSurfaceVariant, style: baseStyle),
                                                                          SizedBox(width: _widthSpace + 16),
                                                                          _buildCell(file.fileType, _colWidthType, style: baseStyle),
                                                                          SizedBox(width: _widthSpace + 16),
                                                                          _buildCell(file.dateModified, _colWidthDate, style: baseStyle),
                                                                          SizedBox(width: _widthSpace + 16),
                                                                          _buildCell(file.attributes, _colWidthAttr, color: Theme.of(context).colorScheme.onSurfaceVariant, style: baseStyle),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            },

                                                          ),
                                                        ),
                                                      GestureDetector(
                                                        behavior: HitTestBehavior.opaque,
                                                        onTap: () => _fileListFocusNode.requestFocus(),
                                                        onSecondaryTapDown: (details) => _showBackgroundContextMenu(context, details, provider, l10n),
                                                        child: Container(
                                                          width: totalWidth,
                                                          height: constraints.maxHeight,
                                                          alignment: Alignment.topCenter,
                                                          child: files.isEmpty ? Padding(padding: const EdgeInsets.only(top: 100), child: Text(l10n.labelNoFiles)) : null,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (_dragStart != null && _dragUpdate != null)
                                                  Positioned.fill(
                                                    child: IgnorePointer(
                                                      child: CustomPaint(
                                                        painter: SelectionPainter(
                                                          start: Offset(_dragStart!.dx, _dragStart!.dy - _verticalController.offset),
                                                          update: Offset(_dragUpdate!.dx, _dragUpdate!.dy - _verticalController.offset),
                                                          color: Theme.of(context).colorScheme.primary,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class SelectionPainter extends CustomPainter {
  final Offset start;
  final Offset update;
  final Color color;

  SelectionPainter({required this.start, required this.update, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromPoints(start, update);
    final paint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);

    final borderPaint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(SelectionPainter oldDelegate) {
    return oldDelegate.start != start || oldDelegate.update != update;
  }
}
