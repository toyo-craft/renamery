import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/directory_provider.dart';
import 'dart:io';

class FileListPanel extends StatefulWidget {
  const FileListPanel({super.key});

  @override
  State<FileListPanel> createState() => _FileListPanelState();
}

class _FileListPanelState extends State<FileListPanel> {
  final ScrollController _horizontalController = ScrollController();
  final TextEditingController _pathController = TextEditingController();

  // Inline Editing
  String? _editingFilePath;
  late TextEditingController _renameController;
  final FocusNode _renameFocusNode = FocusNode();
  final FocusNode _fileListFocusNode = FocusNode();

  // Column Widths
  double _colWidthOriginal = 200.0;
  double _colWidthNew = 200.0;
  double _colWidthSize = 80.0;
  double _colWidthPath = 150.0; // Relative Path
  double _colWidthType = 100.0;
  double _colWidthDate = 140.0;
  double _colWidthAttr = 60.0;

  // Fixed widths
  final double _widthDragHandle = 32.0; // Icon 20 + padding
  final double _widthCheckbox = 32.0; // Checkbox 24 + padding
  final double _widthSpace = 8.0;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController();
    _renameFocusNode.addListener(() {
      if (!_renameFocusNode.hasFocus && _editingFilePath != null) {
        // Cancel edit on lost focus? Or commit? Namery commits usually.
        // Let's cancel for safety or keep it open?
        // Usually clicking away cancels or commits. Let's cancel to be safe for now,
        // or just setState to null.
        setState(() {
          _editingFilePath = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _horizontalController.dispose();
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
        child: Container(
          width: 16,
          height: double.infinity,
          color: Colors.transparent,
          child: const Center(
            child: VerticalDivider(width: 1, thickness: 1, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(
      String label, double width, int sortIndex, DirectoryProvider provider) {
    // Is this column active?
    final isActive = provider.sortColumnIndex == sortIndex;
    final color = isActive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () => provider.sortFiles(sortIndex, !provider.sortAscending),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive)
              Icon(
                provider.sortAscending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 14,
                color: color,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(String text, double width,
      {bool isModified = false, bool isBold = false, Color? color}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          color: color ?? (isModified ? Colors.blue : Colors.black),
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DirectoryProvider>(
      builder: (context, provider, child) {
        // Sync text field with provider if not focused or just loaded
        if (provider.currentDirectory != null &&
            _pathController.text != provider.currentDirectory!.path) {
          _pathController.text = provider.currentDirectory!.path;
        }

        final files = provider.currentFiles; // Short alias

        // Calculate total width based on columns
        final totalWidth = _widthDragHandle +
            _widthCheckbox +
            (_widthSpace * 7) +
            _colWidthOriginal +
            16 +
            _colWidthNew +
            16 +
            _colWidthSize +
            16 +
            _colWidthPath +
            16 +
            _colWidthType +
            16 +
            _colWidthDate +
            16 +
            _colWidthAttr +
            32.0;

        return LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Address Bar Area
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  color: Colors.grey[200],
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'フルパス > ',
                        style: TextStyle(fontSize: 13),
                      ),
                      Expanded(
                        child: Container(
                          // Simple box for styling
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: TextField(
                            controller: _pathController,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              // Use content padding to control height naturally
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onSubmitted: (value) {
                              final dir = Directory(value);
                              provider.setDirectory(dir);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.arrow_forward,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        tooltip: '移動',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          provider.setDirectory(
                            Directory(_pathController.text),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Main Content
                // Main Content
                Expanded(
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.keyA,
                          control: true): () {
                        context.read<DirectoryProvider>().selectAll(true);
                      },
                    },
                    child: Focus(
                      focusNode: _fileListFocusNode,
                      autofocus: true,
                      child: GestureDetector(
                        onTap: () {
                          // Ensure focus is requested when clicking the background
                          FocusScope.of(context)
                              .requestFocus(_fileListFocusNode);
                        },
                        child: Builder(
                          builder: (context) {
                            if (provider.isLoading) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (provider.currentDirectory == null) {
                              return const Center(child: Text('フォルダを選択してください'));
                            }
                            if (files.isEmpty) {
                              return const Center(child: Text('ファイルがありません'));
                            }
                            return Scrollbar(
                              controller: _horizontalController, // Horizontal
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: SingleChildScrollView(
                                controller: _horizontalController,
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: totalWidth,
                                    minHeight: constraints.maxHeight - 40,
                                  ),
                                  child: Column(
                                    children: [
                                      // Header
                                      Container(
                                        height: 36, // Slightly taller Header
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surface, // Clean white/surface
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Theme.of(context)
                                                  .dividerColor,
                                              width: 1.0,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(width: _widthDragHandle),
                                            SizedBox(
                                              width: _widthCheckbox,
                                              child: Checkbox(
                                                value: files
                                                    .every((f) => f.isSelected),
                                                onChanged: (val) => provider
                                                    .selectAll(val ?? false),
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                            ),
                                            SizedBox(width: _widthSpace),

                                            // 1. Name
                                            _buildHeaderCell('名前',
                                                _colWidthOriginal, 0, provider),
                                            _buildResizeHandle((d) => setState(
                                                () => _colWidthOriginal =
                                                    (_colWidthOriginal +
                                                            d.delta.dx)
                                                        .clamp(50.0, 500.0))),
                                            SizedBox(width: _widthSpace),

                                            // 2. New Name
                                            _buildHeaderCell('変更後ファイル名',
                                                _colWidthNew, 1, provider),
                                            _buildResizeHandle((d) => setState(
                                                () => _colWidthNew =
                                                    (_colWidthNew + d.delta.dx)
                                                        .clamp(50.0, 500.0))),
                                            SizedBox(width: _widthSpace),

                                            // 3. Size
                                            _buildHeaderCell('サイズ',
                                                _colWidthSize, 2, provider),
                                            _buildResizeHandle((d) => setState(
                                                () => _colWidthSize =
                                                    (_colWidthSize + d.delta.dx)
                                                        .clamp(40.0, 200.0))),
                                            SizedBox(width: _widthSpace),

                                            // 4. Relative Path
                                            _buildHeaderCell('相対パス',
                                                _colWidthPath, 3, provider),
                                            _buildResizeHandle((d) => setState(
                                                () => _colWidthPath =
                                                    (_colWidthPath + d.delta.dx)
                                                        .clamp(50.0, 300.0))),
                                            SizedBox(width: _widthSpace),

                                            // 5. Type
                                            _buildHeaderCell('ファイルの種類',
                                                _colWidthType, 4, provider),
                                            _buildResizeHandle((d) => setState(
                                                () => _colWidthType =
                                                    (_colWidthType + d.delta.dx)
                                                        .clamp(50.0, 200.0))),
                                            SizedBox(width: _widthSpace),

                                            // 6. Modified
                                            _buildHeaderCell('更新日時',
                                                _colWidthDate, 5, provider),
                                            _buildResizeHandle((d) => setState(
                                                () => _colWidthDate =
                                                    (_colWidthDate + d.delta.dx)
                                                        .clamp(80.0, 200.0))),
                                            SizedBox(width: _widthSpace),

                                            // 7. Attributes
                                            _buildHeaderCell('属性',
                                                _colWidthAttr, 6, provider),
                                          ],
                                        ),
                                      ),
                                      // List
                                      Expanded(
                                        child: SizedBox(
                                          width: totalWidth,
                                          child: ReorderableListView.builder(
                                            buildDefaultDragHandles: false,
                                            itemCount: files.length,
                                            onReorder: (oldIndex, newIndex) {
                                              provider.reorderFiles(
                                                oldIndex,
                                                newIndex,
                                              );
                                            },
                                            itemBuilder: (context, index) {
                                              final fileModel = files[index];
                                              final isDir =
                                                  fileModel.entity is Directory;
                                              final isModified =
                                                  fileModel.originalName !=
                                                      fileModel.newName;
                                              final isSelected =
                                                  fileModel.isSelected;
                                              final key = ValueKey(
                                                fileModel.entity.path,
                                              );

                                              // Inline editing check
                                              final isEditing =
                                                  _editingFilePath ==
                                                      fileModel.entity.path;

                                              return InkWell(
                                                key: key,
                                                onTap: () =>
                                                    provider.toggleSelection(
                                                  fileModel,
                                                ),
                                                child: Container(
                                                  margin: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8.0,
                                                      vertical:
                                                          1.0), // Margin for floating effect
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? Theme.of(context)
                                                            .colorScheme
                                                            .secondaryContainer
                                                            .withValues(
                                                                alpha: 0.5)
                                                        : (index % 2 == 0
                                                            ? Colors.white
                                                            : Colors.grey[50]),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8), // Rounded
                                                    border: isSelected
                                                        ? Border.all(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary
                                                                .withValues(
                                                                    alpha: 0.3))
                                                        : null,
                                                  ),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8.0,
                                                    vertical:
                                                        4.0, // Comfortable height
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                        width: _widthDragHandle,
                                                        child:
                                                            ReorderableDragStartListener(
                                                          index: index,
                                                          child: Icon(
                                                            Icons
                                                                .drag_indicator,
                                                            size: 16,
                                                            color: isSelected
                                                                ? Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary
                                                                : Colors.grey,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: _widthCheckbox,
                                                        child: Checkbox(
                                                          value: isSelected,
                                                          onChanged: (val) =>
                                                              provider
                                                                  .toggleSelection(
                                                            fileModel,
                                                          ),
                                                          visualDensity:
                                                              VisualDensity
                                                                  .compact,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                          width: _widthSpace),

                                                      // 1. Name (with Double Click Edit)
                                                      SizedBox(
                                                        width:
                                                            _colWidthOriginal,
                                                        child: isEditing
                                                            ? TextField(
                                                                controller:
                                                                    _renameController,
                                                                focusNode:
                                                                    _renameFocusNode,
                                                                autofocus: true,
                                                                style:
                                                                    const TextStyle(
                                                                        fontSize:
                                                                            12),
                                                                decoration:
                                                                    const InputDecoration(
                                                                  isDense: true,
                                                                  contentPadding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              4),
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                ),
                                                                onSubmitted:
                                                                    (val) {
                                                                  provider.renameOneFile(
                                                                      fileModel,
                                                                      val);
                                                                  setState(() {
                                                                    _editingFilePath =
                                                                        null;
                                                                  });
                                                                },
                                                              )
                                                            : GestureDetector(
                                                                onDoubleTap:
                                                                    () {
                                                                  setState(() {
                                                                    _editingFilePath =
                                                                        fileModel
                                                                            .entity
                                                                            .path;
                                                                    _renameController
                                                                            .text =
                                                                        fileModel
                                                                            .originalName;
                                                                  });
                                                                },
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      isDir
                                                                          ? Icons
                                                                              .folder
                                                                          : Icons
                                                                              .insert_drive_file,
                                                                      color: isDir
                                                                          ? Colors
                                                                              .amber
                                                                          : Colors
                                                                              .blueGrey,
                                                                      size: 18,
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            8),
                                                                    Expanded(
                                                                      child:
                                                                          Text(
                                                                        fileModel
                                                                            .originalName,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              12,
                                                                          fontWeight: isSelected
                                                                              ? FontWeight.w600
                                                                              : FontWeight.normal,
                                                                          decoration: isSelected
                                                                              ? TextDecoration.underline
                                                                              : null, // M3 doesn't underline usually, but helpful
                                                                          decorationColor: Theme.of(context)
                                                                              .colorScheme
                                                                              .primary,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                      ),
                                                      SizedBox(
                                                          width:
                                                              _widthSpace + 16),

                                                      // 2. New Name
                                                      _buildCell(
                                                        fileModel.newName,
                                                        _colWidthNew,
                                                        isModified: isModified,
                                                        isBold: isModified,
                                                      ),
                                                      SizedBox(
                                                          width:
                                                              _widthSpace + 16),

                                                      // 3. Size
                                                      _buildCell(fileModel.size,
                                                          _colWidthSize,
                                                          color:
                                                              Colors.black87),
                                                      SizedBox(
                                                          width:
                                                              _widthSpace + 16),

                                                      // 4. Relative Path
                                                      _buildCell(
                                                          fileModel
                                                              .displayRelativePath,
                                                          _colWidthPath,
                                                          color:
                                                              Colors.black54),
                                                      SizedBox(
                                                          width:
                                                              _widthSpace + 16),

                                                      // 5. Type
                                                      _buildCell(
                                                          fileModel.fileType,
                                                          _colWidthType,
                                                          color:
                                                              Colors.black87),
                                                      SizedBox(
                                                          width:
                                                              _widthSpace + 16),

                                                      // 6. Modified
                                                      _buildCell(
                                                          fileModel
                                                              .dateModified,
                                                          _colWidthDate,
                                                          color:
                                                              Colors.black87),
                                                      SizedBox(
                                                          width:
                                                              _widthSpace + 16),

                                                      // 7. Attributes
                                                      _buildCell(
                                                          fileModel.attributes,
                                                          _colWidthAttr,
                                                          color:
                                                              Colors.black54),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
