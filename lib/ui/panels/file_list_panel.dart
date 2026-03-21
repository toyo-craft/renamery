import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/directory_provider.dart';
import '../../core/file_model.dart';
import '../../l10n/generated/app_localizations.dart';
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

  // Inline Editing
  String? _editingFilePath;
  late TextEditingController _renameController;
  final FocusNode _renameFocusNode = FocusNode();
  final FocusNode _fileListFocusNode = FocusNode();

  // Column Widths
  double _colWidthOriginal = 250.0;
  double _colWidthNew = 250.0;
  double _colWidthSize = 80.0;
  double _colWidthPath = 150.0;
  double _colWidthType = 100.0;
  double _colWidthDate = 140.0;
  final double _colWidthAttr = 60.0;

  // Selection Drag State
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool _isDraggingSelection = false;
  Set<String> _preDragSelectedPaths = {};
  final Map<String, GlobalKey> _itemKeys = {};

  // Fixed widths for layout
  final double _widthDragHandle = 32.0;
  final double _widthCheckbox = 32.0;
  final double _widthSpace = 16.0;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController();
    _renameFocusNode.addListener(() {
      if (!_renameFocusNode.hasFocus && _editingFilePath != null) {
        _cancelRename();
      }
    });
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    _pathController.dispose();
    _renameController.dispose();
    _renameFocusNode.dispose();
    _fileListFocusNode.dispose();
    super.dispose();
  }

  void _cancelRename() {
    if (mounted) {
      setState(() {
        _editingFilePath = null;
      });
      context.read<DirectoryProvider>().setInlineRenaming(false);
    }
  }

  void _startRename(FileModel file) {
    setState(() {
      _editingFilePath = file.entity.path;
      _renameController.text = file.originalName;
    });
    context.read<DirectoryProvider>().setInlineRenaming(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _renameFocusNode.requestFocus();
        _renameController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _renameController.text.length,
        );
      }
    });
  }

  Future<void> _submitRename(FileModel file, String newName) async {
    final provider = context.read<DirectoryProvider>();
    await provider.renameOneFile(file, newName);
    _cancelRename();
  }

  double _getTotalWidth() {
    return _widthDragHandle +
        _widthCheckbox +
        (_widthSpace * 6) +
        _colWidthOriginal +
        _colWidthNew +
        _colWidthSize +
        _colWidthPath +
        _colWidthType +
        _colWidthDate +
        _colWidthAttr +
        40.0; // Extra padding
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<DirectoryProvider>();

    if (provider.currentDirectory != null &&
        _pathController.text != provider.currentDirectory!.path) {
      _pathController.text = provider.currentDirectory!.path;
    }

    return Focus(
      autofocus: true,
      focusNode: _fileListFocusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.f2) {
            final selected = provider.currentFiles.where((f) => f.isSelected).firstOrNull;
            if (selected != null) {
              _startRename(selected);
              return KeyEventResult.handled;
            }
          }
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            if (_editingFilePath != null) {
              _cancelRename();
              return KeyEventResult.handled;
            }
          }
          if (event.logicalKey == LogicalKeyboardKey.f5) {
            provider.refresh();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        children: [
          _buildPathBar(l10n, provider),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) => _onPanStart(details, provider),
                  onPanUpdate: (details) => _onPanUpdate(details, provider),
                  onPanEnd: (details) => _onPanEnd(details),
                  onSecondaryTapDown: (details) => _showContextMenu(context, details, provider, null),
                  child: Stack(
                    children: [
                      _buildFileTable(l10n, provider, constraints),
                      if (_isDraggingSelection && _dragStart != null && _dragCurrent != null)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: SelectionPainter(
                              start: _dragStart!,
                              current: _dragCurrent!,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathBar(AppLocalizations l10n, DirectoryProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Text(l10n.labelFullPath, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                controller: _pathController,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  border: InputBorder.none,
                ),
                onSubmitted: (value) => provider.setDirectory(Directory(value)),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, size: 20),
            onPressed: () => provider.setDirectory(Directory(_pathController.text)),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTable(AppLocalizations l10n, DirectoryProvider provider, BoxConstraints constraints) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.currentDirectory == null) {
      return Center(child: Text(l10n.labelSelectFolderPrompt(l10n.labelTermFolder)));
    }

    final totalWidth = _getTotalWidth();
    final files = provider.currentFiles;

    return Scrollbar(
      controller: _verticalController,
      thumbVisibility: true,
      child: Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        notificationPredicate: (n) => n.depth == 0,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            child: Column(
              children: [
                _buildTableHeader(l10n, provider),
                Expanded(
                  child: ReorderableListView.builder(
                    scrollController: _verticalController,
                    itemCount: files.length,
                    onReorder: provider.reorderFiles,
                    buildDefaultDragHandles: false,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      return _buildFileRow(context, index, file, provider, l10n);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(AppLocalizations l10n, DirectoryProvider provider) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          SizedBox(width: _widthDragHandle),
          SizedBox(
            width: _widthCheckbox,
            child: Checkbox(
              value: provider.currentFiles.isNotEmpty && provider.currentFiles.every((f) => f.isSelected),
              onChanged: (val) => provider.selectAll(val ?? false),
              visualDensity: VisualDensity.compact,
            ),
          ),
          SizedBox(width: _widthSpace),
          _buildHeaderCell(l10n.labelColName, _colWidthOriginal, 0, provider, (d) {
            setState(() => _colWidthOriginal = (_colWidthOriginal + d.delta.dx).clamp(50.0, 800.0));
          }),
          _buildHeaderCell(l10n.labelColNewName, _colWidthNew, 1, provider, (d) {
            setState(() => _colWidthNew = (_colWidthNew + d.delta.dx).clamp(50.0, 800.0));
          }),
          _buildHeaderCell(l10n.labelColSize, _colWidthSize, 2, provider, (d) {
            setState(() => _colWidthSize = (_colWidthSize + d.delta.dx).clamp(40.0, 300.0));
          }),
          _buildHeaderCell(l10n.labelColPath, _colWidthPath, 3, provider, (d) {
            setState(() => _colWidthPath = (_colWidthPath + d.delta.dx).clamp(50.0, 500.0));
          }),
          _buildHeaderCell(l10n.labelColType, _colWidthType, 4, provider, (d) {
            setState(() => _colWidthType = (_colWidthType + d.delta.dx).clamp(50.0, 300.0));
          }),
          _buildHeaderCell(l10n.labelColDate, _colWidthDate, 5, provider, (d) {
            setState(() => _colWidthDate = (_colWidthDate + d.delta.dx).clamp(80.0, 300.0));
          }),
          _buildHeaderCell(l10n.labelColAttr, _colWidthAttr, 6, provider, null),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, double width, int sortIndex, DirectoryProvider provider, Function(DragUpdateDetails)? onResize) {
    final isActive = provider.sortColumnIndex == sortIndex;
    final color = isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      width: width + (onResize != null ? 16 : 0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => provider.sortFiles(sortIndex, !provider.sortAscending),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isActive)
                    Icon(provider.sortAscending ? Icons.expand_less : Icons.expand_more, size: 14, color: color),
                ],
              ),
            ),
          ),
          if (onResize != null)
            GestureDetector(
              onHorizontalDragUpdate: onResize,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: Container(
                  width: 16,
                  alignment: Alignment.centerRight,
                  child: VerticalDivider(width: 1, thickness: 1, color: Theme.of(context).dividerColor),
                ),
              ),
            ),
          SizedBox(width: _widthSpace),
        ],
      ),
    );
  }

  Widget _buildFileRow(BuildContext context, int index, FileModel file, DirectoryProvider provider, AppLocalizations l10n) {
    final isSelected = file.isSelected;
    final isEditing = _editingFilePath == file.entity.path;
    final isDir = file.entity is Directory;
    final key = _itemKeys.putIfAbsent(file.entity.path, () => GlobalKey());

    return GestureDetector(
      key: ValueKey(file.entity.path),
      onSecondaryTapDown: (details) => _showContextMenu(context, details, provider, file),
      onTap: () {
        final isCtrl = HardwareKeyboard.instance.isControlPressed;
        if (isCtrl) {
          provider.toggleSelection(file);
        } else {
          provider.selectAll(false);
          provider.toggleSelection(file);
        }
      },
      onDoubleTap: () {
        if (isDir) {
          provider.setDirectory(file.entity as Directory);
        } else {
          launchUrl(Uri.file(file.entity.path));
        }
      },
      child: Container(
        key: key,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : (index % 2 == 0 ? Colors.transparent : Theme.of(context).colorScheme.surfaceContainerLowest),
          border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
        ),
        child: Row(
          children: [
            SizedBox(
              width: _widthDragHandle,
              child: ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_indicator, size: 16),
              ),
            ),
            SizedBox(
              width: _widthCheckbox,
              child: Checkbox(
                value: isSelected,
                onChanged: (val) => provider.toggleSelection(file),
                visualDensity: VisualDensity.compact,
              ),
            ),
            SizedBox(width: _widthSpace),
            // Original Name
            SizedBox(
              width: _colWidthOriginal + 16,
              child: isEditing
                  ? Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: TextField(
                        controller: _renameController,
                        focusNode: _renameFocusNode,
                        autofocus: true,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(4), border: OutlineInputBorder()),
                        onSubmitted: (val) => _submitRename(file, val),
                      ),
                    )
                  : Row(
                      children: [
                        Icon(isDir ? Icons.folder : Icons.insert_drive_file, size: 16, color: isDir ? Colors.amber : Colors.blueGrey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(file.originalName, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                        ),
                        SizedBox(width: _widthSpace),
                      ],
                    ),
            ),
            // New Name
            SizedBox(
              width: _colWidthNew + 16,
              child: Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: _buildDiffTextSpan(context, file.originalName, file.newName, file.hasValidationError),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (file.hasValidationError)
                    const Tooltip(message: "Error", child: Icon(Icons.error_outline, color: Colors.red, size: 14)),
                  SizedBox(width: _widthSpace),
                ],
              ),
            ),
            _buildDataCell(file.size, _colWidthSize),
            _buildDataCell(file.displayRelativePath, _colWidthPath),
            _buildDataCell(file.fileType, _colWidthType),
            _buildDataCell(file.dateModified, _colWidthDate),
            _buildDataCell(file.attributes, _colWidthAttr),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, double width) {
    return SizedBox(
      width: width + 16,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Text(text, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
      ),
    );
  }

  TextSpan _buildDiffTextSpan(
      BuildContext context, String oldText, String newText, bool hasError) {
    if (oldText == newText || hasError) {
      return TextSpan(
        text: newText,
        style: TextStyle(
          fontSize: 12,
          color: hasError
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.onSurface,
        ),
      );
    }

    int prefixLen = 0;
    while (prefixLen < oldText.length &&
        prefixLen < newText.length &&
        oldText[prefixLen] == newText[prefixLen]) {
      prefixLen++;
    }

    int suffixLen = 0;
    while (suffixLen < oldText.length - prefixLen &&
        suffixLen < newText.length - prefixLen &&
        oldText[oldText.length - 1 - suffixLen] ==
            newText[newText.length - 1 - suffixLen]) {
      suffixLen++;
    }

    final prefix = oldText.substring(0, prefixLen);
    final deleted = oldText.substring(prefixLen, oldText.length - suffixLen);
    final added = newText.substring(prefixLen, newText.length - suffixLen);
    final suffix = oldText.substring(oldText.length - suffixLen);

    return TextSpan(
      style: const TextStyle(fontSize: 12),
      children: [
        if (prefix.isNotEmpty)
          TextSpan(
              text: prefix,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        if (deleted.isNotEmpty)
          TextSpan(
            text: deleted,
            style: TextStyle(
              color: Colors.red.withValues(alpha: 0.7),
              decoration: TextDecoration.lineThrough,
            ),
          ),
        if (added.isNotEmpty)
          TextSpan(
            text: added,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (suffix.isNotEmpty)
          TextSpan(
              text: suffix,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }

  void _onPanStart(DragStartDetails details, DirectoryProvider provider) {
    if (_editingFilePath != null) return;
    setState(() {
      _dragStart = details.localPosition;
      _dragCurrent = details.localPosition;
      _isDraggingSelection = true;
      final isCtrl = HardwareKeyboard.instance.isControlPressed;
      if (!isCtrl) {
        provider.selectAll(false);
        _preDragSelectedPaths = {};
      } else {
        _preDragSelectedPaths = provider.currentFiles.where((f) => f.isSelected).map((f) => f.entity.path).toSet();
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details, DirectoryProvider provider) {
    if (!_isDraggingSelection) return;
    setState(() {
      _dragCurrent = details.localPosition;
    });
    _updateSelectionRect(provider);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDraggingSelection = false;
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  void _updateSelectionRect(DirectoryProvider provider) {
    if (_dragStart == null || _dragCurrent == null) return;

    final rect = Rect.fromPoints(_dragStart!, _dragCurrent!);
    final isCtrl = HardwareKeyboard.instance.isControlPressed;

    for (var file in provider.currentFiles) {
      final key = _itemKeys[file.entity.path];
      if (key == null || key.currentContext == null) continue;

      final RenderBox box = key.currentContext!.findRenderObject() as RenderBox;
      final Offset position = box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
      final itemRect = position & box.size;

      final isOverlapping = rect.overlaps(itemRect);

      if (isCtrl) {
        final wasSelected = _preDragSelectedPaths.contains(file.entity.path);
        if (isOverlapping) {
          if (file.isSelected == wasSelected) provider.toggleSelection(file);
        } else {
          if (file.isSelected != wasSelected) provider.toggleSelection(file);
        }
      } else {
        if (isOverlapping != file.isSelected) {
          provider.toggleSelection(file);
        }
      }
    }
  }

  Future<void> _showContextMenu(BuildContext context, TapDownDetails details, DirectoryProvider provider, FileModel? file) async {
    if (file != null && !file.isSelected) {
      provider.selectAll(false);
      provider.toggleSelection(file);
    }

    final l10n = AppLocalizations.of(context)!;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(details.globalPosition & const Size(40, 40), Offset.zero & overlay.size),
      items: [
        if (file != null) ...[
          PopupMenuItem(value: 'rename', child: Text(l10n.labelCtxRenameGeneral)),
          PopupMenuItem(value: 'open', child: Text(l10n.labelCtxOpenWithAssoc)),
          const PopupMenuDivider(),
          PopupMenuItem(value: 'copy', child: Text(l10n.labelCtxCopy)),
          PopupMenuItem(value: 'cut', child: Text(l10n.labelCtxCut)),
          const PopupMenuDivider(),
          PopupMenuItem(value: 'delete', child: Text(l10n.labelCtxDeleteItems, style: const TextStyle(color: Colors.red))),
        ],
        if (file == null) ...[
          PopupMenuItem(value: 'up', child: Text(l10n.labelCtxUpOneFolder)),
          PopupMenuItem(value: 'new_folder', child: Text(l10n.labelCtxNewFolder)),
          PopupMenuItem(value: 'paste', enabled: provider.canPaste, child: Text(l10n.labelCtxPaste)),
          const PopupMenuDivider(),
          PopupMenuItem(value: 'refresh', child: Text(l10n.labelCtxRefresh)),
        ],
        if (file != null) ...[
          const PopupMenuDivider(),
          PopupMenuItem(value: 'properties', child: Text(l10n.labelCtxProperties)),
        ]
      ],
    );

    if (result == null) return;
    switch (result) {
      case 'rename': if (file != null) _startRename(file); break;
      case 'open': if (file != null) launchUrl(Uri.file(file.entity.path)); break;
      case 'copy': provider.copySelection(); break;
      case 'cut': provider.cutSelection(); break;
      case 'paste': provider.pasteFromClipboard(); break;
      case 'delete': _confirmDelete(provider, l10n); break;
      case 'up': provider.goUp(); break;
      case 'new_folder': provider.createNewFolder(); break;
      case 'refresh': provider.refresh(); break;
      case 'properties': if (file != null) PlatformUtils.showPropertiesDialog(context, file); break;
    }
  }

  Future<void> _confirmDelete(DirectoryProvider provider, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.labelDialogTrashTitle),
        content: Text(l10n.labelDialogTrashMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.labelDialogCancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.labelDialogDelete),
          ),
        ],
      ),
    );
    if (confirm == true) await provider.deleteSelectedFiles();
  }
}

class SelectionPainter extends CustomPainter {
  final Offset start;
  final Offset current;
  final Color color;
  SelectionPainter({required this.start, required this.current, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromPoints(start, current);
    canvas.drawRect(rect, Paint()..color = color.withOpacity(0.2)..style = PaintingStyle.fill);
    canvas.drawRect(rect, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.0);
  }

  @override
  bool shouldRepaint(SelectionPainter oldDelegate) => oldDelegate.start != start || oldDelegate.current != current;
}
