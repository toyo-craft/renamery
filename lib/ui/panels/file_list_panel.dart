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

  // Initial column widths
  double _colWidthOriginal = 300.0;
  double _colWidthNew = 300.0;
  double _colWidthStatus = 100.0;

  // Fixed widths
  final double _widthDragHandle = 32.0; // Icon 20 + padding
  final double _widthCheckbox = 32.0; // Checkbox 24 + padding
  final double _widthSpace = 8.0;

  @override
  void dispose() {
    _horizontalController.dispose();
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
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.currentDirectory == null) {
          return const Center(child: Text('フォルダを選択してください'));
        }

        if (provider.currentFiles.isEmpty) {
          return const Center(child: Text('ファイルがありません'));
        }

        // Calculate total width based on columns
        final totalWidth =
            _widthDragHandle +
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
            return Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              trackVisibility: true,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: totalWidth, // Use calculated total width
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: Row(
                          children: [
                            SizedBox(width: _widthDragHandle),
                            SizedBox(
                              width: _widthCheckbox,
                              child: Checkbox(
                                value: provider.currentFiles.every(
                                  (f) => f.isSelected,
                                ),
                                onChanged: (val) =>
                                    provider.selectAll(val ?? false),
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
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (provider.sortColumnIndex == 0)
                                      Icon(
                                        provider.sortAscending
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        size: 16,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            // Resizer 1
                            _buildResizeHandle((details) {
                              setState(() {
                                _colWidthOriginal += details.delta.dx;
                                if (_colWidthOriginal < 50)
                                  _colWidthOriginal = 50;
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
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (provider.sortColumnIndex == 1)
                                      Icon(
                                        provider.sortAscending
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        size: 16,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            // Resizer 2
                            _buildResizeHandle((details) {
                              setState(() {
                                _colWidthNew += details.delta.dx;
                                if (_colWidthNew < 50) _colWidthNew = 50;
                              });
                            }),
                            SizedBox(width: _widthSpace),

                            // Status
                            SizedBox(
                              width: _colWidthStatus,
                              child: const Text(
                                '状態',
                                style: TextStyle(fontWeight: FontWeight.bold),
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
                          width: totalWidth, // Enforce header width on list
                          child: ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            itemCount: provider.currentFiles.length,
                            onReorder: (oldIndex, newIndex) {
                              provider.reorderFiles(oldIndex, newIndex);
                            },
                            itemBuilder: (context, index) {
                              final fileModel = provider.currentFiles[index];
                              final isDir = fileModel.entity is Directory;
                              final isModified =
                                  fileModel.originalName != fileModel.newName;
                              final isSelected = fileModel.isSelected;
                              final key = ValueKey(fileModel.entity.path);

                              return InkWell(
                                key: key,
                                onTap: () =>
                                    provider.toggleSelection(fileModel),
                                child: Container(
                                  color: isSelected
                                      ? Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .withOpacity(0.3)
                                      : (index % 2 == 0
                                            ? Colors.white
                                            : Colors.grey[50]),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: _widthDragHandle,
                                        child: ReorderableDragStartListener(
                                          index: index,
                                          child: const Icon(
                                            Icons.drag_indicator,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: _widthCheckbox,
                                        child: Checkbox(
                                          value: isSelected,
                                          onChanged: (val) => provider
                                              .toggleSelection(fileModel),
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
                                                  : Icons.insert_drive_file,
                                              color: isDir
                                                  ? Colors.amber
                                                  : Colors.blueGrey,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                fileModel.originalName,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(
                                        width: 16,
                                      ), // Skip Resizer 1
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
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                      const SizedBox(
                                        width: 16,
                                      ), // Skip Resizer 2
                                      SizedBox(width: _widthSpace),

                                      // Status
                                      SizedBox(
                                        width: _colWidthStatus,
                                        child: Text(
                                          isDir
                                              ? ''
                                              : (isModified ? '変更あり' : '-'),
                                          style: TextStyle(
                                            color: isModified
                                                ? Colors.orange
                                                : Colors.grey,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
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
        );
      },
    );
  }
}
