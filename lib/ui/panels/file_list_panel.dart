import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/directory_provider_platform.dart';
import '../../core/file_model.dart';
import '../../core/rename_diff_text.dart';
import '../../utils/platform_utils.dart';

class FileListPanel extends StatefulWidget {
  const FileListPanel({super.key});

  @override
  State<FileListPanel> createState() => _FileListPanelState();
}

class _FileListPanelState extends State<FileListPanel> {
  static final Uri _desktopAppUri =
      Uri.parse('https://toyo-craft.net/apps#renamery');

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  Key _reorderableListKey = UniqueKey();
  final FocusNode _fileListFocusNode = FocusNode();
  final FocusNode _renameFocusNode = FocusNode();
  final TextEditingController _renameController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();
  late final TapGestureRecognizer _desktopAppLinkRecognizer =
      TapGestureRecognizer()..onTap = _openDesktopAppLink;

  String? _editingFilePath;
  int? _lastSelectedIndex; // 範囲選択の起点（アンカー）
  String? _lastPrimaryTapKey;
  DateTime? _lastPrimaryTapAt;
  bool _suppressNextRowTap = false;
  int? _pendingNameTapIndex;
  VoidCallback? _pendingDoubleClickAction;
  Offset? _dragPendingStart;
  Offset? _dragStart;
  Offset? _dragUpdate;
  List<bool>? _initialSelectionStates;
  int? _draggingIndex;
  Timer? _autoScrollTimer;

  late Map<int, double> _columnWidths;
  static const double _widthDragHandle = 32.0;
  static const double _widthCheckbox = 32.0;
  static const double _widthSeparator = 16.0;
  static const double _dragSelectStartThreshold = 24.0;
  // Update docs/selection_ctrl_mode_contract.md and the selection tests before
  // changing the file-name click or double-click selection contract.
  static const Duration _doubleClickInterval = Duration(milliseconds: 450);

  @override
  void initState() {
    super.initState();
    _columnWidths = {
      0: 300.0,
      1: 300.0,
      2: 80.0,
      3: 200.0,
      4: 100.0,
      5: 140.0,
      6: 80.0,
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fileListFocusNode.requestFocus();
    });
    HardwareKeyboard.instance.addHandler(_handleGlobalKey);
  }

  bool _handleGlobalKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final primaryFocus = FocusManager.instance.primaryFocus;
    bool isWriting = false;

    if (primaryFocus != null) {
      final label = primaryFocus.debugLabel ?? '';
      if (label.contains('EditableText') || label.contains('TextField')) {
        isWriting = true;
      } else {
        primaryFocus.context?.visitAncestorElements((element) {
          if (element.widget is EditableText) {
            isWriting = true;
            return false;
          }
          return true;
        });
      }
    }

    final provider = context.read<DirectoryProvider>();
    final key = event.logicalKey;
    final isCtrl = HardwareKeyboard.instance.isControlPressed;

    if (key == LogicalKeyboardKey.escape) {
      bool handled = false;
      if (_draggingIndex != null) {
        setState(() {
          _draggingIndex = null;
          _reorderableListKey = UniqueKey();
        });
        handled = true;
      }
      if (_editingFilePath != null) {
        setState(() {
          _editingFilePath = null;
        });
        provider.setInlineRenaming(false);
        handled = true;
      }
      if (_dragStart != null || _dragPendingStart != null) {
        _stopAutoScroll();
        setState(() {
          _dragPendingStart = null;
          _dragStart = null;
          _dragUpdate = null;
          _initialSelectionStates = null;
        });
        handled = true;
      }
      if (isWriting) return handled;
      if (!handled && provider.currentFiles.any((f) => f.isSelected)) {
        provider.selectAll(false);
        handled = true;
      }
      if (!handled && provider.isCutMode) {
        provider.clearCutState();
        handled = true;
      }
      return handled;
    }

    if (isWriting || provider.isInlineRenaming) return false;

    if (isCtrl) {
      if (key == LogicalKeyboardKey.keyA) {
        provider.selectAll(true);
        return true;
      }
      if (key == LogicalKeyboardKey.keyD) {
        provider.selectAll(false);
        return true;
      }
      if (key == LogicalKeyboardKey.keyC) {
        provider.copySelection();
        return true;
      }
      if (key == LogicalKeyboardKey.keyX) {
        provider.cutSelection();
        return true;
      }
      if (key == LogicalKeyboardKey.keyV) {
        provider.pasteFromClipboard();
        return true;
      }
    }

    if (key == LogicalKeyboardKey.f2) {
      final selected =
          provider.currentFiles.where((f) => f.isSelected).toList();
      if (selected.isNotEmpty) {
        _startEdit(selected.first.path, selected.first.originalName, provider);
      }
      return true;
    }

    if (key == LogicalKeyboardKey.delete) {
      if (provider.currentFiles.any((f) => f.isSelected)) {
        final l10n = AppLocalizations.of(context)!;
        _showDeleteConfirmDialog(context, provider, l10n);
      }
      return true;
    }

    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKey);
    _stopAutoScroll();
    _horizontalController.dispose();
    _verticalController.dispose();
    _fileListFocusNode.dispose();
    _renameFocusNode.dispose();
    _renameController.dispose();
    _pathController.dispose();
    _desktopAppLinkRecognizer.dispose();
    super.dispose();
  }

  Future<void> _openDesktopAppLink() async {
    await launchUrl(_desktopAppUri, mode: LaunchMode.externalApplication);
  }

  void _startAutoScroll(
      double delta, List<FileModel> files, DirectoryProvider provider) {
    _autoScrollTimer?.cancel();
    _autoScrollTimer =
        Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_dragStart == null) {
        _stopAutoScroll();
        return;
      }
      final double newOffset = (_verticalController.offset + delta)
          .clamp(0.0, _verticalController.position.maxScrollExtent);
      _verticalController.jumpTo(newOffset);
      if (_dragUpdate != null) {
        _updateSelection(_dragUpdate!.dy, files, provider);
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<DirectoryProvider>();
    final files = provider.currentFiles;
    _pathController.text = provider.currentDirectory?.path ?? '';

    double totalWidth = _widthDragHandle + _widthCheckbox + _widthSeparator;
    for (int i = 0; i < _columnWidths.length; i++) {
      totalWidth += _columnWidths[i]! + _widthSeparator;
    }

    final rowHeight = provider.touchMode ? 50.0 : 34.0;
    final showWebEmptyPrompt =
        !provider.supportsDirectPathInput && !provider.hasUsableDirectory;

    if (showWebEmptyPrompt) {
      return _buildWebEmptyPrompt(context, provider);
    }

    return Column(
      children: [
        _buildAddressBar(context, provider, l10n),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double actualWidth =
                  totalWidth.clamp(constraints.maxWidth, double.infinity);
              return Focus(
                focusNode: _fileListFocusNode,
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  notificationPredicate: (notification) =>
                      notification.metrics.axis == Axis.vertical,
                  child: Scrollbar(
                    controller: _horizontalController,
                    thumbVisibility: true,
                    notificationPredicate: (notification) =>
                        notification.metrics.axis == Axis.horizontal,
                    child: SingleChildScrollView(
                      controller: _horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: actualWidth,
                        child: Column(
                          children: [
                            _buildHeader(context, provider, l10n),
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                // onTap: () => _fileListFocusNode.requestFocus(), // 干渉を防ぐため削除（Row側で実施）
                                onSecondaryTapDown: (details) =>
                                    _showBackgroundContextMenu(
                                        context, details, provider, l10n),
                                onLongPressStart: (details) {
                                  if (context.mounted) {
                                    _showBackgroundContextMenu(
                                        context,
                                        TapDownDetails(
                                            globalPosition:
                                                details.globalPosition),
                                        provider,
                                        l10n);
                                  }
                                },
                                child: Stack(
                                  children: [
                                    Listener(
                                      onPointerDown: (event) {
                                        final isMouse = event.kind ==
                                            PointerDeviceKind.mouse;
                                        const safeZone = _widthDragHandle +
                                            _widthCheckbox +
                                            _widthSeparator;
                                        if (isMouse &&
                                            event.buttons == kPrimaryButton &&
                                            !provider.isInlineRenaming &&
                                            event.localPosition.dx > safeZone &&
                                            files.isNotEmpty) {
                                          _dragPendingStart = Offset(
                                              event.localPosition.dx,
                                              event.localPosition.dy +
                                                  _verticalController.offset);
                                          _dragStart = null;
                                          _dragUpdate = null;
                                          _initialSelectionStates = files
                                              .map((f) => f.isSelected)
                                              .toList();
                                        }
                                      },
                                      onPointerMove: (event) {
                                        if (_dragPendingStart != null ||
                                            _dragStart != null) {
                                          final currentAbsY =
                                              event.localPosition.dy +
                                                  _verticalController.offset;
                                          final currentPosition = Offset(
                                              event.localPosition.dx,
                                              currentAbsY);
                                          if (_dragStart == null) {
                                            final pendingStart =
                                                _dragPendingStart;
                                            if (pendingStart == null ||
                                                (currentPosition - pendingStart)
                                                        .distance <
                                                    _dragSelectStartThreshold) {
                                              return;
                                            }
                                            _dragStart = pendingStart;
                                            _dragPendingStart = null;
                                          }
                                          setState(() {
                                            _dragUpdate = currentPosition;
                                          });
                                          const scrollZone = 40.0;
                                          if (event.localPosition.dy <
                                              scrollZone) {
                                            _startAutoScroll(
                                                -15.0, files, provider);
                                          } else if (event.localPosition.dy >
                                              (constraints.maxHeight -
                                                  32.0 -
                                                  scrollZone))
                                            _startAutoScroll(
                                                15.0, files, provider);
                                          else
                                            _stopAutoScroll();
                                          _updateSelection(
                                              currentAbsY, files, provider);
                                        }
                                      },
                                      onPointerUp: (_) {
                                        _stopAutoScroll();
                                        final pendingDoubleClickAction =
                                            _pendingDoubleClickAction;
                                        _pendingDoubleClickAction = null;
                                        if (_dragStart != null ||
                                            _dragUpdate != null) {
                                          setState(() {
                                            _dragPendingStart = null;
                                            _dragStart = null;
                                            _dragUpdate = null;
                                            _initialSelectionStates = null;
                                          });
                                        } else {
                                          _dragPendingStart = null;
                                          _dragStart = null;
                                          _dragUpdate = null;
                                          _initialSelectionStates = null;
                                        }
                                        if (pendingDoubleClickAction != null) {
                                          pendingDoubleClickAction.call();
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            if (mounted) {
                                              _suppressNextRowTap = false;
                                            }
                                          });
                                        }
                                      },
                                      child: NotificationListener<
                                          ScrollNotification>(
                                        onNotification: (notification) {
                                          if (notification.metrics.axis ==
                                              Axis.vertical) {
                                            final offset =
                                                _verticalController.offset;
                                            provider.updateVisibleRange(
                                                (offset / rowHeight).floor(),
                                                ((offset +
                                                            constraints
                                                                .maxHeight) /
                                                        rowHeight)
                                                    .ceil());
                                          }
                                          return false;
                                        },
                                        child: ReorderableListView.builder(
                                          key: _reorderableListKey,
                                          scrollController: _verticalController,
                                          itemCount: files.length,
                                          itemExtent: rowHeight,
                                          onReorder: provider.reorderFiles,
                                          onReorderStart: (index) => setState(
                                              () => _draggingIndex = index),
                                          onReorderEnd: (_) => setState(
                                              () => _draggingIndex = null),
                                          buildDefaultDragHandles: false,
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          padding: const EdgeInsets.only(
                                              bottom: 100),
                                          proxyDecorator:
                                              (child, index, animation) =>
                                                  _buildProxyDecorator(
                                                      child,
                                                      index,
                                                      animation,
                                                      provider,
                                                      rowHeight),
                                          itemBuilder: (itemContext, index) =>
                                              RepaintBoundary(
                                            key: ValueKey(files[index].path),
                                            child: _FileRow(
                                              index: index,
                                              file: files[index],
                                              columnWidths: _columnWidths,
                                              isEditing: _editingFilePath ==
                                                  files[index].path,
                                              isDragging:
                                                  _draggingIndex != null,
                                              isDraggedItem:
                                                  _draggingIndex == index,
                                              renameController:
                                                  _renameController,
                                              renameFocusNode: _renameFocusNode,
                                              onStartEdit: (path, name) =>
                                                  _startEdit(
                                                      path, name, provider),
                                              onQueueDoubleClick:
                                                  _queueDoubleClickAction,
                                              onEndEdit: () => setState(() {
                                                _editingFilePath = null;
                                                provider
                                                    .setInlineRenaming(false);
                                              }),
                                              onTap: (idx) {
                                                final isNameTap =
                                                    _pendingNameTapIndex == idx;
                                                _pendingNameTapIndex = null;
                                                if (!isNameTap &&
                                                    _suppressNextRowTap) {
                                                  _suppressNextRowTap = false;
                                                  return;
                                                }
                                                // 行タップ時にフォーカスを要求（重複タップ問題の解決への第一歩）
                                                _fileListFocusNode
                                                    .requestFocus();

                                                final isShift = HardwareKeyboard
                                                        .instance
                                                        .logicalKeysPressed
                                                        .contains(
                                                            LogicalKeyboardKey
                                                                .shiftLeft) ||
                                                    HardwareKeyboard.instance
                                                        .logicalKeysPressed
                                                        .contains(
                                                            LogicalKeyboardKey
                                                                .shiftRight);

                                                if (isShift &&
                                                    _lastSelectedIndex !=
                                                        null) {
                                                  // Shift範囲選択（トグル）
                                                  provider.selectRange(
                                                      _lastSelectedIndex!, idx,
                                                      exclusive: false,
                                                      baseStates: provider
                                                          .currentFiles
                                                          .map((f) =>
                                                              f.isSelected)
                                                          .toList());
                                                } else {
                                                  // 通常のトグル選択
                                                  provider.toggleSelection(
                                                      files[idx]);
                                                  _lastSelectedIndex = idx;
                                                }
                                              },
                                              onNameTap: (idx) {
                                                _pendingNameTapIndex = idx;
                                              },
                                              onShowMenu: (details, file) =>
                                                  _showRowContextMenu(
                                                      context,
                                                      details,
                                                      file,
                                                      provider,
                                                      l10n),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (files.isEmpty)
                                      Positioned(
                                          top: 100,
                                          left: 0,
                                          child: IgnorePointer(
                                              child: Container(
                                                  width: constraints.maxWidth,
                                                  alignment: Alignment.center,
                                                  child: Text(l10n.labelNoFiles,
                                                      style: TextStyle(
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .onSurfaceVariant))))),
                                    if (_dragStart != null &&
                                        _dragUpdate != null)
                                      Positioned.fill(
                                          child: IgnorePointer(
                                              child: CustomPaint(
                                                  painter: SelectionPainter(
                                                      start: Offset(
                                                          _dragStart!.dx,
                                                          _dragStart!.dy -
                                                              _verticalController
                                                                  .offset),
                                                      update: Offset(
                                                          _dragUpdate!.dx,
                                                          _dragUpdate!.dy -
                                                              _verticalController
                                                                  .offset),
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary)))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWebEmptyPrompt(
      BuildContext context, DirectoryProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isSupported = provider.isWebFileSystemSupported;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSupported ? Icons.folder_open : Icons.folder_off,
                  size: 64,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Semantics(
                  container: true,
                  label: isSupported
                      ? l10n.labelWebSelectFolderPromptTitle
                      : l10n.labelWebUnsupportedPromptTitle,
                  child: Text(
                    isSupported
                        ? l10n.labelWebSelectFolderPromptTitle
                        : l10n.labelWebUnsupportedPromptTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  container: true,
                  label: isSupported
                      ? l10n.labelWebSelectFolderPromptMessage
                      : l10n.labelWebUnsupportedPromptMessage,
                  child: Text(
                    isSupported
                        ? l10n.labelWebSelectFolderPromptMessage
                        : l10n.labelWebUnsupportedPromptMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
                if (isSupported) ...[
                  const SizedBox(height: 8),
                  Semantics(
                    container: true,
                    label: l10n.labelWebSelectFolderPromptPrivacy,
                    child: Text(
                      l10n.labelWebSelectFolderPromptPrivacy,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
                if (isSupported) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed:
                        provider.isLoading ? null : provider.pickLocalDirectory,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.labelSelectFolder),
                  ),
                ],
                const SizedBox(height: 12),
                _buildDesktopAppPromptLink(context, l10n, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopAppPromptLink(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    final baseStyle = TextStyle(
      color: colorScheme.onSurfaceVariant,
      fontSize: 12,
    );
    final linkStyle = baseStyle.copyWith(
      color: colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: colorScheme.primary,
    );
    return Semantics(
      link: true,
      child: Text.rich(
        TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: l10n.labelWebSelectFolderPromptDesktopBeforeLink),
            TextSpan(
              text: l10n.labelDesktopAppVersionLink,
              style: linkStyle,
              recognizer: _desktopAppLinkRecognizer,
            ),
            TextSpan(text: l10n.labelWebSelectFolderPromptDesktopAfterLink),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _startEdit(String path, String name, DirectoryProvider provider) {
    setState(() {
      _editingFilePath = path;
      _renameController.text = name;
    });
    provider.setInlineRenaming(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _renameFocusNode.requestFocus();
    });
  }

  bool _queueDoubleClickAction(String key, VoidCallback action) {
    final now = DateTime.now();
    final isDoubleClick = _lastPrimaryTapKey == key &&
        _lastPrimaryTapAt != null &&
        now.difference(_lastPrimaryTapAt!) <= _doubleClickInterval;

    _lastPrimaryTapKey = key;
    _lastPrimaryTapAt = now;

    if (!isDoubleClick) return false;

    _lastPrimaryTapKey = null;
    _lastPrimaryTapAt = null;
    _dragPendingStart = null;
    _dragStart = null;
    _dragUpdate = null;
    _initialSelectionStates = null;
    _pendingNameTapIndex = null;
    _suppressNextRowTap = true;
    _pendingDoubleClickAction = action;
    return true;
  }

  Widget _buildProxyDecorator(Widget child, int index,
      Animation<double> animation, DirectoryProvider provider, double rowH) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final selectedCount = provider.selectedFilesCount;
        final isMultiMove =
            provider.currentFiles[index].isSelected && selectedCount > 1;
        return Material(
          elevation: 12.0,
          color: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (isMultiMove) ...[
                Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    bottom: -8,
                    child: Container(
                        height: rowH,
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8)))),
                Positioned(
                    top: 4,
                    left: 4,
                    right: 4,
                    bottom: -4,
                    child: Container(
                        height: rowH,
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHigh
                                .withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8)))),
              ],
              Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8)),
                  child: child),
              if (isMultiMove)
                Positioned(
                    right: -12,
                    top: -12,
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('$selectedCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)))),
            ],
          ),
        );
      },
      child: child,
    );
  }

  void _updateSelection(
      double currentAbsY, List<FileModel> files, DirectoryProvider provider) {
    if (_dragStart == null ||
        _initialSelectionStates == null ||
        files.isEmpty) {
      return;
    }
    debugPrint('DEBUG: Rubber-band selection update triggered');
    final rowH = provider.touchMode ? 50.0 : 34.0;
    final startY = _dragStart!.dy;
    int idx1 = (startY / rowH).floor();
    int idx2 = (currentAbsY / rowH).floor();
    provider.selectRange(idx1 < idx2 ? idx1 : idx2, idx1 > idx2 ? idx1 : idx2,
        baseStates: _initialSelectionStates);
  }

  bool _isPathEditing = false;

  Widget _buildAddressBar(
      BuildContext context, DirectoryProvider provider, AppLocalizations l10n) {
    final hasSelection = provider.selectedFilesCount > 0;
    final colorScheme = Theme.of(context).colorScheme;
    final supportsDirectPathInput = provider.supportsDirectPathInput;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // パス表示・編集エリア
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: InkWell(
                onTap: !supportsDirectPathInput || _isPathEditing
                    ? null
                    : () => setState(() => _isPathEditing = true),
                child: _isPathEditing && supportsDirectPathInput
                    ? TextField(
                        controller: _pathController,
                        autofocus: true,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (val) {
                          if (val.isNotEmpty) {
                            provider.setDirectoryPath(val,
                                source: 'address_bar');
                          }
                          setState(() => _isPathEditing = false);
                        },
                        onTapOutside: (_) =>
                            setState(() => _isPathEditing = false),
                      )
                    : _buildBreadcrumbs(context, provider),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 実行・選択解除などのアクション
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
              backgroundColor: hasSelection
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHigh,
              foregroundColor: hasSelection
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            onPressed: () => provider.selectAll(!hasSelection),
            child: Text(
              hasSelection ? l10n.labelDeselectAll : l10n.labelSelectAll,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(BuildContext context, DirectoryProvider provider) {
    final labels = provider.breadcrumbLabels;
    if (labels.isEmpty) return const SizedBox.shrink();

    final List<Widget> items = [];

    for (var i = 0; i < labels.length; i++) {
      final label = labels[i];
      final isLast = i == labels.length - 1;

      items.add(
        InkWell(
          onTap: () => provider.openBreadcrumb(i),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                color: isLast ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          ),
        ),
      );

      if (!isLast) {
        items.add(
          Icon(Icons.chevron_right,
              size: 16,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.5)),
        );
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(children: items),
    );
  }

  Widget _buildHeader(
      BuildContext context, DirectoryProvider provider, AppLocalizations l10n) {
    final files = provider.currentFiles;
    final selectedCount = provider.selectedFilesCount;
    final bool? allSelected = files.isEmpty
        ? false
        : (selectedCount == 0
            ? false
            : (selectedCount == files.length ? true : null));
    return Container(
      height: 32,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Row(
        children: [
          const SizedBox(width: _widthDragHandle),
          SizedBox(
              width: _widthCheckbox,
              child: Checkbox(
                  value: allSelected,
                  tristate: true,
                  onChanged: (val) => provider.selectAll(val ?? false),
                  visualDensity: VisualDensity.compact)),
          const SizedBox(width: _widthSeparator),
          _buildHeaderCell(context, provider, l10n.labelColName, 0),
          const SizedBox(width: _widthSeparator),
          _buildHeaderCell(context, provider, l10n.labelColNewName, 1),
          const SizedBox(width: _widthSeparator),
          _buildHeaderCell(context, provider, l10n.labelColSize, 2),
          const SizedBox(width: _widthSeparator),
          _buildHeaderCell(context, provider, l10n.labelColPath, 3),
          const SizedBox(width: _widthSeparator),
          _buildHeaderCell(context, provider, l10n.labelColType, 4),
          const SizedBox(width: _widthSeparator),
          _buildHeaderCell(context, provider, l10n.labelColDate, 5),
          const SizedBox(width: _widthSeparator),
          _buildHeaderCell(context, provider, l10n.labelColAttr, 6),
          const SizedBox(width: _widthSeparator),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, DirectoryProvider provider,
      String label, int index) {
    final isActive = provider.sortColumnIndex == index;
    return SizedBox(
      width: _columnWidths[index]!,
      child: Row(
        children: [
          Expanded(
              child: InkWell(
                  onTap: () => provider.sortFiles(
                      index, isActive ? !provider.sortAscending : true),
                  child: Row(children: [
                    Expanded(
                        child: Text(label,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isActive
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface),
                            overflow: TextOverflow.ellipsis)),
                    if (isActive)
                      Icon(
                          provider.sortAscending
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary)
                  ]))),
          GestureDetector(
              onHorizontalDragUpdate: (details) => setState(() {
                    _columnWidths[index] =
                        (_columnWidths[index]! + details.delta.dx)
                            .clamp(40.0, 1000.0);
                  }),
              child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: Container(
                      width: 4,
                      height: 20,
                      color: Colors.grey.withOpacity(0.3)))),
        ],
      ),
    );
  }

  Future<void> _showRowContextMenu(BuildContext context, TapDownDetails details,
      FileModel file, DirectoryProvider provider, AppLocalizations l10n) async {
    if (!context.mounted) return;
    if (!file.isSelected) provider.toggleSelection(file);
    scheduleMicrotask(() async {
      if (!context.mounted) return;
      final RenderBox? overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox?;
      if (overlay == null) return;
      final RelativeRect position = RelativeRect.fromRect(
          details.globalPosition & const Size(40, 40),
          Offset.zero & overlay.size);
      final result =
          await showMenu<String>(context: context, position: position, items: [
        PopupMenuItem(
            value: 'up_folder', child: Text(l10n.labelCtxUpOneFolder)),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'copy', child: Text(l10n.labelCtxCopyItems)),
        PopupMenuItem(value: 'cut', child: Text(l10n.labelCtxCutItems)),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'rename', child: Text(l10n.labelCtxRenameGeneral)),
        PopupMenuItem(
            value: 'batch_rename', child: Text(l10n.labelCtxBatchRename)),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'top', child: Text(l10n.labelCtxMoveToTop)),
        PopupMenuItem(value: 'bottom', child: Text(l10n.labelCtxMoveToBottom)),
        PopupMenuItem(
            value: 'delete',
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.labelCtxDeleteItems,
                      style: const TextStyle(color: Colors.red)),
                  const Icon(Icons.delete, color: Colors.red, size: 20)
                ])),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'properties', child: Text(l10n.labelCtxProperties))
      ]);
      if (result == null || !context.mounted) return;
      switch (result) {
        case 'copy':
          await provider.copySelection();
          break;
        case 'cut':
          await provider.cutSelection();
          break;
        case 'rename':
          _startEdit(file.path, file.originalName, provider);
          break;
        case 'batch_rename':
          await provider.executeRename();
          break;
        case 'top':
          provider.moveSelectedToTop();
          break;
        case 'bottom':
          provider.moveSelectedToBottom();
          break;
        case 'delete':
          _showDeleteConfirmDialog(context, provider, l10n);
          break;
        case 'properties':
          PlatformUtils.showPropertiesDialog(context, file);
          break;
        case 'up_folder':
          await provider.goUp();
          break;
      }
    });
  }

  Future<void> _showBackgroundContextMenu(
      BuildContext context,
      TapDownDetails details,
      DirectoryProvider provider,
      AppLocalizations l10n) async {
    if (!context.mounted) return;
    scheduleMicrotask(() async {
      if (!context.mounted) return;
      final RenderBox? overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox?;
      if (overlay == null) return;
      final RelativeRect position = RelativeRect.fromRect(
          details.globalPosition & const Size(40, 40),
          Offset.zero & overlay.size);
      final result =
          await showMenu<String>(context: context, position: position, items: [
        PopupMenuItem(
            value: 'up_folder', child: Text(l10n.labelCtxUpOneFolder)),
        const PopupMenuDivider(),
        PopupMenuItem(
            value: 'new_folder', child: Text(l10n.labelCtxCreateFolder)),
        PopupMenuItem(
            value: 'paste',
            enabled: provider.canPaste,
            child: Text(l10n.labelCtxPasteItems)),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'select_all', child: Text(l10n.labelSelectAll)),
        PopupMenuItem(
            value: 'deselect_all', child: Text(l10n.labelDeselectAll)),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'refresh', child: Text(l10n.labelCtxRefresh))
      ]);
      if (result == null || !context.mounted) return;
      switch (result) {
        case 'new_folder':
          await provider.createNewFolder();
          break;
        case 'paste':
          await provider.pasteFromClipboard();
          break;
        case 'select_all':
          provider.selectAll(true);
          break;
        case 'deselect_all':
          provider.selectAll(false);
          break;
        case 'refresh':
          await provider.refresh();
          break;
        case 'up_folder':
          await provider.goUp();
          break;
      }
    });
  }

  Future<void> _showDeleteConfirmDialog(BuildContext context,
      DirectoryProvider provider, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(l10n.labelDialogTrashTitle),
                content: Text(l10n.labelDialogTrashMessage),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.labelDialogCancel)),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text(l10n.labelDialogDelete))
                ]));
    if (confirm == true) await provider.deleteSelectedFiles();
  }
}

class _FileRow extends StatelessWidget {
  final int index;
  final FileModel file;
  final Map<int, double> columnWidths;
  final bool isEditing;
  final bool isDragging;
  final bool isDraggedItem;
  final TextEditingController renameController;
  final FocusNode renameFocusNode;
  final Function(String, String) onStartEdit;
  final bool Function(String, VoidCallback) onQueueDoubleClick;
  final VoidCallback onEndEdit;
  final Function(int) onTap;
  final Function(int) onNameTap;
  final Function(TapDownDetails, FileModel) onShowMenu;
  const _FileRow(
      {required this.index,
      required this.file,
      required this.columnWidths,
      required this.isEditing,
      this.isDragging = false,
      this.isDraggedItem = false,
      required this.renameController,
      required this.renameFocusNode,
      required this.onStartEdit,
      required this.onQueueDoubleClick,
      required this.onEndEdit,
      required this.onTap,
      required this.onNameTap,
      required this.onShowMenu});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: file,
      child: Consumer<FileModel>(
        builder: (context, file, _) {
          final provider = context.read<DirectoryProvider>();
          final rowH = provider.touchMode ? 50.0 : 34.0;
          final iconS = provider.touchMode ? 28.0 : 18.0;
          final isDir = file.isDirectory;
          final isGhost = isDragging && file.isSelected && !isDraggedItem;
          final baseStyle = TextStyle(
              fontSize: provider.touchMode ? 15.0 : 12.0,
              fontWeight: file.isSelected ? FontWeight.w600 : FontWeight.normal,
              color: file.isCut
                  ? Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.5)
                  : null);
          return Opacity(
            opacity: isGhost ? 0.3 : 1.0,
            child: InkWell(
              onTap: () => onTap(index),
              onSecondaryTapDown: (details) {
                if (context.mounted) onShowMenu(details, file);
              },
              onLongPress: () {
                if (!context.mounted) return;
                final RenderBox? box = context.findRenderObject() as RenderBox?;
                if (box == null || !box.hasSize) return;
                final Offset position = box.localToGlobal(
                    Offset(box.size.width / 2, box.size.height / 2));
                onShowMenu(TapDownDetails(globalPosition: position), file);
              },
              child: Container(
                height: rowH,
                decoration: BoxDecoration(
                    color: file.isSelected
                        ? Theme.of(context)
                            .colorScheme
                            .secondaryContainer
                            .withOpacity(0.4)
                        : (index % 2 == 0
                            ? null
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerLow
                                .withOpacity(0.3)),
                    border: Border(
                        bottom: BorderSide(
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.1),
                            width: 0.5))),
                child: Row(
                  children: [
                    SizedBox(
                        width: 32,
                        child: ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_indicator,
                                size: 18, color: Colors.grey))),
                    SizedBox(
                        width: 32,
                        child: Checkbox(
                            value: file.isSelected,
                            onChanged: (_) => provider.toggleSelection(file),
                            visualDensity: VisualDensity.compact)),
                    const SizedBox(width: 16),
                    _buildCell(
                        0,
                        Row(
                          children: [
                            // アイコンは編集状態に関わらず常に表示
                            GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapDown: (_) => onQueueDoubleClick(
                                      'icon:${file.path}',
                                      () {
                                        if (isDir) {
                                          provider.openDirectory(file);
                                        } else {
                                          PlatformUtils.openFile(file.path);
                                        }
                                      },
                                    ),
                                onDoubleTap: () {
                                  if (isDir) {
                                    provider.openDirectory(file);
                                  } else {
                                    PlatformUtils.openFile(file.path);
                                  }
                                },
                                child: Icon(
                                    isDir
                                        ? Icons.folder
                                        : Icons.insert_drive_file,
                                    color: isDir
                                        ? Theme.of(context).colorScheme.tertiary
                                        : Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                    size: iconS)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: isEditing
                                    ? TextField(
                                        controller: renameController,
                                        focusNode: renameFocusNode,
                                        autofocus: true,
                                        style: baseStyle,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 8),
                                          border: OutlineInputBorder(),
                                          fillColor: Colors.transparent,
                                        ),
                                        onSubmitted: (val) {
                                          provider.renameOneFile(file, val);
                                          onEndEdit();
                                        },
                                        // 入力欄以外をクリックした際に編集状態を解除（ESCキー同様）
                                        onTapOutside: (event) {
                                          onEndEdit();
                                        },
                                      )
                                    : Align(
                                        alignment: Alignment.centerLeft,
                                        child: Listener(
                                            behavior:
                                                HitTestBehavior.translucent,
                                            onPointerDown: (_) {
                                              final isDoubleClick =
                                                  onQueueDoubleClick(
                                                'name:${file.path}',
                                                () => onStartEdit(file.path,
                                                    file.originalName),
                                              );
                                              if (!isDoubleClick) {
                                                onNameTap(index);
                                              }
                                            },
                                            child: Text(file.originalName,
                                                overflow: TextOverflow.ellipsis,
                                                style: baseStyle)))),
                          ],
                        ),
                        baseStyle),
                    const SizedBox(width: 16),
                    _buildCell(
                        1,
                        Row(children: [
                          Expanded(
                              child: RichText(
                                  text: RenameDiffText.build(
                                      context,
                                      file.originalName,
                                      file.newName,
                                      file.hasValidationError,
                                      style: baseStyle,
                                      mode: provider.renameMode,
                                      startNumber: provider.startNumber,
                                      digits: provider.digits),
                                  overflow: TextOverflow.ellipsis)),
                          if (file.hasValidationError)
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 16)
                        ])),
                    const SizedBox(width: 16),
                    _buildCell(
                        2,
                        Text(file.size,
                            overflow: TextOverflow.ellipsis, style: baseStyle)),
                    const SizedBox(width: 16),
                    _buildCell(
                        3,
                        Text(
                            file.displayRelativePath.isEmpty
                                ? '.'
                                : file.displayRelativePath,
                            overflow: TextOverflow.ellipsis,
                            style: baseStyle.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant))),
                    const SizedBox(width: 16),
                    _buildCell(
                        4,
                        Text(file.fileType,
                            overflow: TextOverflow.ellipsis, style: baseStyle)),
                    const SizedBox(width: 16),
                    _buildCell(
                        5,
                        Text(file.dateModified,
                            overflow: TextOverflow.ellipsis, style: baseStyle)),
                    const SizedBox(width: 16),
                    _buildCell(
                        6,
                        Text(file.attributes,
                            overflow: TextOverflow.ellipsis,
                            style: baseStyle.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant))),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCell(int colIndex, Widget content, [TextStyle? style]) =>
      SizedBox(width: columnWidths[colIndex]!, child: content);
}

class SelectionPainter extends CustomPainter {
  final Offset start;
  final Offset update;
  final Color color;
  SelectionPainter(
      {required this.start, required this.update, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromPoints(start, update);
    canvas.drawRect(
        rect,
        Paint()
          ..color = color.withOpacity(0.2)
          ..style = PaintingStyle.fill);
    canvas.drawRect(
        rect,
        Paint()
          ..color = color
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(SelectionPainter oldDelegate) =>
      oldDelegate.start != start || oldDelegate.update != update;
}
