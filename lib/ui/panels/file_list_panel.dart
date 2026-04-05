import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;

import '../../core/directory_provider.dart';
import '../../core/file_model.dart';
import '../../core/rename_engine.dart';
import '../helpers/filter_dialog_helper.dart';
import '../../utils/platform_utils.dart';

class FileListPanel extends StatefulWidget {
  const FileListPanel({super.key});

  @override
  State<FileListPanel> createState() => _FileListPanelState();
}

class _FileListPanelState extends State<FileListPanel> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final GlobalKey<ReorderableListState> _reorderableListKey = GlobalKey<ReorderableListState>();
  final FocusNode _fileListFocusNode = FocusNode();
  final FocusNode _renameFocusNode = FocusNode();
  final TextEditingController _renameController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();

  String? _editingFilePath;
  Offset? _dragStart;
  Offset? _dragUpdate;
  List<bool>? _initialSelectionStates;
  int? _draggingIndex;

  late Map<int, double> _columnWidths;
  static const double _widthDragHandle = 32.0;
  static const double _widthCheckbox = 32.0;

  @override
  void initState() {
    super.initState();
    _columnWidths = {
      0: 300.0, // Original Name
      1: 300.0, // New Name
      2: 80.0,  // Size
      3: 200.0, // Path
      4: 100.0, // Type
      5: 140.0, // Date
      6: 80.0,  // Attr
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fileListFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    _fileListFocusNode.dispose();
    _renameFocusNode.dispose();
    _renameController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<DirectoryProvider>();
    final files = provider.currentFiles;
    _pathController.text = provider.currentDirectory?.path ?? '';

    double totalWidth = _widthDragHandle + _widthCheckbox + 16.0; // Space
    for (var w in _columnWidths.values) { totalWidth += w + 16.0; }

    final rowHeight = provider.touchMode ? 50.0 : 34.0;

    return Column(
      children: [
        _buildAddressBar(context, provider, l10n),
        Expanded(
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.keyA, control: true): () => provider.selectAll(true),
              const SingleActivator(LogicalKeyboardKey.keyD, control: true): () => provider.selectAll(false),
              const SingleActivator(LogicalKeyboardKey.f2): () {
                final selected = files.where((f) => f.isSelected).toList();
                if (selected.isNotEmpty) {
                  setState(() { _editingFilePath = selected.first.entity.path; _renameController.text = selected.first.originalName; });
                  provider.setInlineRenaming(true);
                  WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _renameFocusNode.requestFocus(); });
                }
              },
              const SingleActivator(LogicalKeyboardKey.delete): () {
                if (provider.currentFiles.any((f) => f.isSelected)) {
                  _showDeleteConfirmDialog(context, provider, l10n);
                }
              },
            },
            child: Focus(
              focusNode: _fileListFocusNode,
              child: Scrollbar(
                controller: _horizontalController,
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalWidth,
                    child: Column(
                      children: [
                        _buildHeader(context, provider, l10n),
                        Expanded(
                          child: Listener(
                            onPointerDown: (event) {
                              if (event.buttons == kPrimaryButton && !provider.isInlineRenaming) {
                                setState(() {
                                  _dragStart = event.localPosition;
                                  _dragUpdate = event.localPosition;
                                  _initialSelectionStates = files.map((f) => f.isSelected).toList();
                                });
                              }
                            },
                            onPointerMove: (event) {
                              if (_dragStart != null) {
                                setState(() { _dragUpdate = event.localPosition; });
                                _updateSelection(event.localPosition, files, provider);
                              }
                            },
                            onPointerUp: (_) {
                              setState(() { _dragStart = null; _dragUpdate = null; _initialSelectionStates = null; });
                            },
                            child: Stack(
                              children: [
                                ListView.builder(
                                  controller: _verticalController,
                                  itemExtent: rowHeight, // これが重要: スクロール計算を O(1) にする
                                  itemCount: files.length,
                                  itemBuilder: (context, index) => RepaintBoundary( // 各行を独立してキャッシュ
                                    child: _FileRow(
                                      key: ValueKey(files[index].entity.path),
                                      index: index,
                                      file: files[index],
                                      columnWidths: _columnWidths,
                                      isEditing: _editingFilePath == files[index].entity.path,
                                      renameController: _renameController,
                                      renameFocusNode: _renameFocusNode,
                                      onStartEdit: (path, name) {
                                        setState(() { _editingFilePath = path; _renameController.text = name; });
                                        provider.setInlineRenaming(true);
                                        WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _renameFocusNode.requestFocus(); });
                                      },
                                      onEndEdit: () {
                                        setState(() { _editingFilePath = null; });
                                        provider.setInlineRenaming(false);
                                      },
                                    ),
                                  ),
                                ),
                                if (_dragStart != null && _dragUpdate != null)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: CustomPaint(
                                        painter: SelectionPainter(
                                          start: Offset(_dragStart!.dx, _dragStart!.dy + _verticalController.offset),
                                          update: Offset(_dragUpdate!.dx, _dragUpdate!.dy + _verticalController.offset),
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
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
          ),
        ),
      ],
    );
  }

  void _updateSelection(Offset localPosition, List<FileModel> files, DirectoryProvider provider) {
    if (_dragStart == null || _initialSelectionStates == null) return;
    final rowH = provider.touchMode ? 50.0 : 34.0;
    final startY = _dragStart!.dy + _verticalController.offset - 32.0; // Header offset
    final currentY = localPosition.dy + _verticalController.offset - 32.0;
    
    final minIndex = ((startY < currentY ? startY : currentY) / rowH).floor().clamp(0, files.length - 1);
    final maxIndex = ((startY > currentY ? startY : currentY) / rowH).floor().clamp(0, files.length - 1);

    provider.selectRange(minIndex, maxIndex, baseStates: _initialSelectionStates);
  }

  Widget _buildAddressBar(BuildContext context, DirectoryProvider provider, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: provider.canGoBack ? provider.goBack : null),
          IconButton(icon: const Icon(Icons.arrow_forward), onPressed: provider.canGoForward ? provider.goForward : null),
          IconButton(icon: const Icon(Icons.arrow_upward), onPressed: provider.goUp),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _pathController,
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder()),
              onSubmitted: (val) => provider.setDirectory(io.Directory(val)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.refresh), onPressed: provider.refresh),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DirectoryProvider provider, AppLocalizations l10n) {
    final files = provider.currentFiles;
    final selectedCount = provider.selectedFilesCount;
    final bool? allSelected = files.isEmpty ? false : (selectedCount == 0 ? false : (selectedCount == files.length ? true : null));

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
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 16),
          _buildHeaderCell(l10n.labelColName, 0),
          _buildHeaderCell(l10n.labelColNewName, 1),
          _buildHeaderCell(l10n.labelColSize, 2),
          _buildHeaderCell(l10n.labelColPath, 3),
          _buildHeaderCell(l10n.labelColType, 4),
          _buildHeaderCell(l10n.labelColDate, 5),
          _buildHeaderCell(l10n.labelColAttr, 6),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, int index) {
    return SizedBox(
      width: _columnWidths[index]! + 16,
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() { _columnWidths[index] = (_columnWidths[index]! + details.delta.dx).clamp(40.0, 1000.0); });
            },
            child: MouseRegion(cursor: SystemMouseCursors.resizeColumn, child: Container(width: 4, height: 20, color: Colors.grey.withValues(alpha: 0.3))),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmDialog(BuildContext context, DirectoryProvider provider, AppLocalizations l10n) async {
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
  }
}

class _FileRow extends StatelessWidget {
  final int index;
  final FileModel file;
  final Map<int, double> columnWidths;
  final bool isEditing;
  final TextEditingController renameController;
  final FocusNode renameFocusNode;
  final Function(String, String) onStartEdit;
  final VoidCallback onEndEdit;

  const _FileRow({
    super.key,
    required this.index,
    required this.file,
    required this.columnWidths,
    required this.isEditing,
    required this.renameController,
    required this.renameFocusNode,
    required this.onStartEdit,
    required this.onEndEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: file,
      child: Consumer<FileModel>(
        builder: (context, file, _) {
          final provider = context.read<DirectoryProvider>();
          final rowH = provider.touchMode ? 50.0 : 34.0;
          final iconS = provider.touchMode ? 28.0 : 18.0;
          final isDir = file.entity is io.Directory;

          final baseStyle = TextStyle(
            fontSize: provider.touchMode ? 15.0 : 12.0,
            fontWeight: file.isSelected ? FontWeight.w600 : FontWeight.normal,
            color: file.isCut ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5) : null,
          );

          return InkWell(
            onTap: () => provider.toggleSelection(file),
            child: Container(
              height: rowH,
              decoration: BoxDecoration(
                color: file.isSelected ? Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.4) : (index % 2 == 0 ? null : Theme.of(context).colorScheme.surfaceContainerLow.withValues(alpha: 0.3)),
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1), width: 0.5)),
              ),
              child: Row(
                children: [
                  SizedBox(width: 32, child: ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_indicator, size: 18, color: Colors.grey))),
                  SizedBox(width: 32, child: Checkbox(value: file.isSelected, onChanged: (_) => provider.toggleSelection(file), visualDensity: VisualDensity.compact)),
                  const SizedBox(width: 8),
                  _buildCell(0, isEditing 
                    ? TextField(controller: renameController, focusNode: renameFocusNode, autofocus: true, style: baseStyle, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(4), border: OutlineInputBorder()), onSubmitted: (val) { provider.renameOneFile(file, val); onEndEdit(); }) 
                    : Row(children: [
                        GestureDetector(onDoubleTap: () { if (isDir) provider.setDirectory(file.entity as io.Directory); else PlatformUtils.openFile(file.entity.path); }, child: Icon(isDir ? Icons.folder : Icons.insert_drive_file, color: isDir ? Theme.of(context).colorScheme.tertiary : Theme.of(context).colorScheme.secondary, size: iconS)),
                        const SizedBox(width: 8),
                        Expanded(child: GestureDetector(onDoubleTap: () => onStartEdit(file.entity.path, file.originalName), child: Text(file.originalName, overflow: TextOverflow.ellipsis, style: baseStyle))),
                      ]), baseStyle),
                  _buildCell(1, Row(children: [
                    Expanded(child: RichText(text: RenameEngine.buildDiffTextSpan(context, file.originalName, file.newName, file.hasValidationError, style: baseStyle, mode: provider.renameMode, startNumber: provider.startNumber, digits: provider.digits), overflow: TextOverflow.ellipsis)),
                    if (file.hasValidationError) Tooltip(message: file.validationErrorMessage ?? 'Error', child: const Icon(Icons.error_outline, color: Colors.red, size: 16)),
                  ]), baseStyle),
                  _buildCell(2, Text(file.size, overflow: TextOverflow.ellipsis, style: baseStyle), baseStyle),
                  _buildCell(3, Text(file.displayRelativePath, overflow: TextOverflow.ellipsis, style: baseStyle.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)), baseStyle),
                  _buildCell(4, Text(file.fileType, overflow: TextOverflow.ellipsis, style: baseStyle), baseStyle),
                  _buildCell(5, Text(file.dateModified, overflow: TextOverflow.ellipsis, style: baseStyle), baseStyle),
                  _buildCell(6, Text(file.attributes, overflow: TextOverflow.ellipsis, style: baseStyle.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)), baseStyle),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCell(int colIndex, Widget content, TextStyle style) {
    return SizedBox(width: columnWidths[colIndex]!, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: content));
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
    final paint = Paint()..color = color.withValues(alpha: 0.2)..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);
    final borderPaint = Paint()..color = color..strokeWidth = 1.0..style = PaintingStyle.stroke;
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(SelectionPainter oldDelegate) => oldDelegate.start != start || oldDelegate.update != update;
}
