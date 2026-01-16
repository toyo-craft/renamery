import 'package:flutter/material.dart';
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

  // Initial column widths
  double _colWidthOriginal = 300.0;
  double _colWidthNew = 300.0;
  final double _colWidthStatus = 100.0;

  // Fixed widths
  final double _widthDragHandle = 32.0; // Icon 20 + padding
  final double _widthCheckbox = 32.0; // Checkbox 24 + padding
  final double _widthSpace = 8.0;

  @override
  void dispose() {
    _horizontalController.dispose();
    _pathController.dispose();
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
            _widthSpace +
            _colWidthOriginal +
            16.0 + // Resizer
            _widthSpace +
            _colWidthNew +
            16.0 + // Resizer
            _widthSpace +
            _colWidthStatus +
            32.0; // Extra padding

        return LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Address Bar Area
                Container(
                  padding: const EdgeInsets.all(4.0),
                  color: Colors.grey[200],
                  child: Row(
                    children: [
                      const Text('フルパス > '),
                      Expanded(
                        child: Container(
                          height: 28, // Compact height
                          color: Colors.white,
                          child: TextField(
                            controller: _pathController,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 0,
                              ),
                              border: OutlineInputBorder(),
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
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (provider.currentDirectory == null) {
                        return const Center(child: Text('フォルダを選択してください'));
                      }
                      if (files.isEmpty) {
                        return const Center(child: Text('ファイルがありません'));
                      }
                      return Scrollbar(
                        controller: _horizontalController,
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
                                  height: 30, // Compact Header
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  child: Row(
                                    children: [
                                      SizedBox(width: _widthDragHandle),
                                      SizedBox(
                                        width: _widthCheckbox,
                                        child: Checkbox(
                                          value: files.every(
                                            (f) => f.isSelected,
                                          ),
                                          onChanged: (val) =>
                                              provider.selectAll(val ?? false),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                      SizedBox(width: _widthSpace),

                                      // Original Name
                                      SizedBox(
                                        width: _colWidthOriginal,
                                        child: InkWell(
                                          onTap: () => provider.sortFiles(
                                            0,
                                            !provider.sortAscending,
                                          ),
                                          child: Row(
                                            children: [
                                              const Expanded(
                                                child: Text(
                                                  '変更前ファイル名',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (provider.sortColumnIndex == 0)
                                                Icon(
                                                  provider.sortAscending
                                                      ? Icons.arrow_upward
                                                      : Icons.arrow_downward,
                                                  size: 14,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Resizer 1
                                      _buildResizeHandle((details) {
                                        setState(() {
                                          _colWidthOriginal += details.delta.dx;
                                          if (_colWidthOriginal < 50) {
                                            _colWidthOriginal = 50;
                                          }
                                        });
                                      }),
                                      SizedBox(width: _widthSpace),

                                      // New Name
                                      SizedBox(
                                        width: _colWidthNew,
                                        child: InkWell(
                                          onTap: () => provider.sortFiles(
                                            1,
                                            !provider.sortAscending,
                                          ),
                                          child: Row(
                                            children: [
                                              const Expanded(
                                                child: Text(
                                                  '変更後ファイル名 (プレビュー)',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (provider.sortColumnIndex == 1)
                                                Icon(
                                                  provider.sortAscending
                                                      ? Icons.arrow_upward
                                                      : Icons.arrow_downward,
                                                  size: 14,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Resizer 2
                                      _buildResizeHandle((details) {
                                        setState(() {
                                          _colWidthNew += details.delta.dx;
                                          if (_colWidthNew < 50) {
                                            _colWidthNew = 50;
                                          }
                                        });
                                      }),
                                      SizedBox(width: _widthSpace),

                                      // Status
                                      SizedBox(
                                        width: _colWidthStatus,
                                        child: const Text(
                                          '状態',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
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
                                        final isSelected = fileModel.isSelected;
                                        final key = ValueKey(
                                          fileModel.entity.path,
                                        );

                                        return InkWell(
                                          key: key,
                                          onTap: () => provider.toggleSelection(
                                            fileModel,
                                          ),
                                          child: Container(
                                            color: isSelected
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primaryContainer
                                                    .withValues(alpha: 0.3)
                                                : (index % 2 == 0
                                                    ? Colors.white
                                                    : Colors.grey[50]),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0,
                                              vertical: 2.0, // Low height
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: _widthDragHandle,
                                                  child:
                                                      ReorderableDragStartListener(
                                                    index: index,
                                                    child: const Icon(
                                                      Icons.drag_indicator,
                                                      size: 16,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: _widthCheckbox,
                                                  child: Checkbox(
                                                    value: isSelected,
                                                    onChanged: (val) => provider
                                                        .toggleSelection(
                                                      fileModel,
                                                    ),
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                  ),
                                                ),
                                                SizedBox(width: _widthSpace),

                                                // Original Name
                                                SizedBox(
                                                  width: _colWidthOriginal,
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        isDir
                                                            ? Icons.folder
                                                            : Icons
                                                                .insert_drive_file,
                                                        color: isDir
                                                            ? Colors.amber
                                                            : Colors.blueGrey,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          fileModel
                                                              .originalName,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                const SizedBox(width: 16),
                                                SizedBox(width: _widthSpace),

                                                // New Name
                                                SizedBox(
                                                  width: _colWidthNew,
                                                  child: Text(
                                                    fileModel.newName,
                                                    style: TextStyle(
                                                      color: isModified
                                                          ? Colors.blue
                                                          : Colors.black,
                                                      fontWeight: isModified
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                      fontSize: 12,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),

                                                const SizedBox(width: 16),
                                                SizedBox(width: _widthSpace),

                                                // Status
                                                SizedBox(
                                                  width: _colWidthStatus,
                                                  child: Text(
                                                    isDir
                                                        ? ''
                                                        : (isModified
                                                            ? '変更あり'
                                                            : '-'),
                                                    style: TextStyle(
                                                      color: isModified
                                                          ? Colors.orange
                                                          : Colors.grey,
                                                      fontSize: 11,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
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
              ],
            );
          },
        );
      },
    );
  }
}
