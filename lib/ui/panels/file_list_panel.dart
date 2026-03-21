import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/directory_provider.dart';
import '../../core/file_model.dart';
import 'dart:io';
import 'package:renamery/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
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
  double _colWidthOriginal = 200.0;
  double _colWidthNew = 200.0;
  double _colWidthSize = 80.0;
  double _colWidthPath = 150.0; // Relative Path
  double _colWidthType = 100.0;
  double _colWidthDate = 140.0;
  final double _colWidthAttr = 60.0;

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
        // Cancel edit on lost focus
        setState(() {
          _editingFilePath = null;
        });
        context.read<DirectoryProvider>().setInlineRenaming(false);
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
            child: VerticalDivider(
                width: 1,
                thickness: 1,
                color: Theme.of(context).colorScheme.outlineVariant),
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
                provider.sortAscending ? Icons.expand_less : Icons.expand_more,
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
          color: color ??
              (isModified
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface),
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        overflow: TextOverflow.ellipsis,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<DirectoryProvider>(
      builder: (context, provider, child) {
        if (provider.currentDirectory != null &&
            _pathController.text != provider.currentDirectory!.path) {
          _pathController.text = provider.currentDirectory!.path;
        }

        final files = provider.currentFiles;

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
            return Focus(
              autofocus: true,
              canRequestFocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.f2) {
                    final selectedFile = provider.currentFiles
                        .where((f) => f.isSelected)
                        .firstOrNull;
                    if (selectedFile != null) {
                      setState(() {
                        _editingFilePath = selectedFile.entity.path;
                        _renameController.text = selectedFile.originalName;
                      });
                      provider.setInlineRenaming(true);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _renameFocusNode.requestFocus();
                        }
                      });
                      return KeyEventResult.handled;
                    }
                  }
                  if (event.logicalKey == LogicalKeyboardKey.escape) {
                    if (_editingFilePath != null) {
                      setState(() {
                        _editingFilePath = null;
                      });
                      provider.setInlineRenaming(false);
                      return KeyEventResult.handled;
                    }
                  }
                  if (event.logicalKey == LogicalKeyboardKey.f5) {
                    provider.refresh();
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.keyR) {
                    if (_editingFilePath == null) {
                      final selectedFiles = provider.currentFiles
                          .where((f) => f.isSelected)
                          .toList();
                      if (selectedFiles.isNotEmpty) {
                        _showPropertiesDialog(context, selectedFiles.first);
                        return KeyEventResult.handled;
                      }
                    }
                  }
                }
                return KeyEventResult.ignored;
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          l10n.labelFullPath,
                          style: const TextStyle(fontSize: 13),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border.all(
                                  color: Theme.of(context).colorScheme.outline),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: TextField(
                              controller: _pathController,
                              style: const TextStyle(fontSize: 13),
                              decoration: const InputDecoration(
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
                          tooltip: l10n.labelMenuGo,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            provider.setDirectory(
                              Directory(_pathController.text),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: () {
                              provider.selectAll(true);
                            },
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: Text(l10n.labelSelectAll),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Focus(
                      focusNode: _fileListFocusNode,
                      autofocus: true,
                      child: GestureDetector(
                        onTap: () {
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
                              return Center(
                                  child: Text(l10n.labelSelectFolderPrompt(
                                      l10n.labelTermFolder)));
                            }
                            if (files.isEmpty) {
                              return Center(child: Text(l10n.labelNoFiles));
                            }
                            return Scrollbar(
                              controller: _verticalController,
                              thumbVisibility: true,
                              notificationPredicate: (notification) =>
                                  notification.depth == 1,
                              child: Scrollbar(
                                controller: _horizontalController,
                                thumbVisibility: true,
                                trackVisibility: true,
                                notificationPredicate: (notification) =>
                                    notification.depth == 0,
                                child: SingleChildScrollView(
                                  controller: _horizontalController,
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: totalWidth,
                                      minHeight: constraints.maxHeight - 56,
                                    ),
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onSecondaryTapDown:
                                          (TapDownDetails details) async {
                                        final RenderBox overlay =
                                            Overlay.of(context)
                                                    .context
                                                    .findRenderObject()
                                                as RenderBox;

                                        final result = await showMenu<String>(
                                          context: context,
                                          position: RelativeRect.fromRect(
                                            details.globalPosition &
                                                const Size(40, 40),
                                            Offset.zero & overlay.size,
                                          ),
                                          items: [
                                            PopupMenuItem(
                                                value: 'up_folder',
                                                child: Text(
                                                    l10n.labelCtxUpOneFolder)),
                                            const PopupMenuDivider(),
                                            PopupMenuItem(
                                                value: 'paste',
                                                enabled: provider.canPaste,
                                                child: Text(l10n.labelCtxPaste)),
                                            PopupMenuItem(
                                                value: 'new_folder',
                                                child: Text(
                                                    l10n.labelCtxNewFolder)),
                                            const PopupMenuDivider(),
                                            PopupMenuItem(
                                                value: 'refresh',
                                                child:
                                                    Text(l10n.labelCtxRefresh)),
                                          ],
                                        );

                                        if (!mounted) return;

                                        switch (result) {
                                          case 'up_folder':
                                            await provider.goUp();
                                            break;
                                          case 'paste':
                                            await provider.pasteFromClipboard();
                                            break;
                                          case 'new_folder':
                                            await provider.createNewFolder();
                                            break;
                                          case 'refresh':
                                            await provider.refresh();
                                            break;
                                        }
                                      },
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: totalWidth,
                                            height: 36,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
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
                                                SizedBox(
                                                    width: _widthDragHandle),
                                                SizedBox(
                                                  width: _widthCheckbox,
                                                  child: Checkbox(
                                                    value: files.every(
                                                        (f) => f.isSelected),
                                                    onChanged: (val) => provider
                                                        .selectAll(val ?? false),
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                  ),
                                                ),
                                                SizedBox(width: _widthSpace),
                                                _buildHeaderCell(
                                                    l10n.labelColName,
                                                    _colWidthOriginal,
                                                    0,
                                                    provider),
                                                _buildResizeHandle((d) =>
                                                    setState(() =>
                                                        _colWidthOriginal =
                                                            (_colWidthOriginal +
                                                                    d.delta.dx)
                                                                .clamp(50.0,
                                                                    500.0))),
                                                SizedBox(width: _widthSpace),
                                                _buildHeaderCell(
                                                    l10n.labelColNewName,
                                                    _colWidthNew,
                                                    1,
                                                    provider),
                                                _buildResizeHandle((d) =>
                                                    setState(() => _colWidthNew =
                                                        (_colWidthNew +
                                                                d.delta.dx)
                                                            .clamp(50.0, 500.0))),
                                                SizedBox(width: _widthSpace),
                                                _buildHeaderCell(
                                                    l10n.labelColSize,
                                                    _colWidthSize,
                                                    2,
                                                    provider),
                                                _buildResizeHandle((d) =>
                                                    setState(() => _colWidthSize =
                                                        (_colWidthSize +
                                                                d.delta.dx)
                                                            .clamp(40.0, 200.0))),
                                                SizedBox(width: _widthSpace),
                                                _buildHeaderCell(
                                                    l10n.labelColPath,
                                                    _colWidthPath,
                                                    3,
                                                    provider),
                                                _buildResizeHandle((d) =>
                                                    setState(() => _colWidthPath =
                                                        (_colWidthPath +
                                                                d.delta.dx)
                                                            .clamp(50.0, 300.0))),
                                                SizedBox(width: _widthSpace),
                                                _buildHeaderCell(
                                                    l10n.labelColType,
                                                    _colWidthType,
                                                    4,
                                                    provider),
                                                _buildResizeHandle((d) =>
                                                    setState(() => _colWidthType =
                                                        (_colWidthType +
                                                                d.delta.dx)
                                                            .clamp(50.0, 200.0))),
                                                SizedBox(width: _widthSpace),
                                                _buildHeaderCell(
                                                    l10n.labelColDate,
                                                    _colWidthDate,
                                                    5,
                                                    provider),
                                                _buildResizeHandle((d) =>
                                                    setState(() => _colWidthDate =
                                                        (_colWidthDate +
                                                                d.delta.dx)
                                                            .clamp(80.0, 200.0))),
                                                SizedBox(width: _widthSpace),
                                                _buildHeaderCell(
                                                    l10n.labelColAttr,
                                                    _colWidthAttr,
                                                    6,
                                                    provider),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: SizedBox(
                                              width: totalWidth,
                                              child: ScrollConfiguration(
                                                behavior: ScrollConfiguration.of(
                                                        context)
                                                    .copyWith(scrollbars: false),
                                                child:
                                                    ReorderableListView.builder(
                                                  scrollController:
                                                      _verticalController,
                                                  padding: EdgeInsets.zero,
                                                  buildDefaultDragHandles: false,
                                                  itemCount: files.length,
                                                  onReorder:
                                                      (oldIndex, newIndex) {
                                                    provider.reorderFiles(
                                                      oldIndex,
                                                      newIndex,
                                                    );
                                                  },
                                                  itemBuilder: (context, index) {
                                                    final fileModel =
                                                        files[index];
                                                    final isDir = fileModel.entity
                                                        is Directory;
                                                    final isSelected =
                                                        fileModel.isSelected;
                                                    final key = ValueKey(
                                                      fileModel.entity.path,
                                                    );
                                                    final isEditing =
                                                        _editingFilePath ==
                                                            fileModel.entity.path;

                                                    return GestureDetector(
                                                      key: key,
                                                      onSecondaryTapDown:
                                                          (TapDownDetails
                                                              details) async {
                                                        if (!fileModel
                                                            .isSelected) {
                                                          provider
                                                              .toggleSelection(
                                                                  fileModel);
                                                        }

                                                        final RenderBox overlay =
                                                            Overlay.of(context)
                                                                    .context
                                                                    .findRenderObject()
                                                                as RenderBox;

                                                        final result =
                                                            await showMenu<
                                                                String>(
                                                          context: context,
                                                          position: RelativeRect
                                                              .fromRect(
                                                            details.globalPosition &
                                                                const Size(
                                                                    40, 40),
                                                            Offset.zero &
                                                                overlay.size,
                                                          ),
                                                          items: [
                                                            PopupMenuItem(
                                                                value:
                                                                    'up_folder',
                                                                child: Text(l10n
                                                                    .labelCtxUpOneFolder)),
                                                            const PopupMenuDivider(),
                                                            PopupMenuItem(
                                                                value: 'rename',
                                                                child: Text(l10n
                                                                    .labelCtxRenameGeneral)),
                                                            PopupMenuItem(
                                                                value:
                                                                    'batch_rename',
                                                                child: Text(l10n
                                                                    .labelCtxBatchRename)),
                                                            const PopupMenuDivider(),
                                                            PopupMenuItem(
                                                                value: 'copy',
                                                                child: Text(l10n
                                                                    .labelCtxCopy)),
                                                            PopupMenuItem(
                                                                value: 'cut',
                                                                child: Text(l10n
                                                                    .labelCtxCut)),
                                                            PopupMenuItem(
                                                                value: 'paste',
                                                                enabled: provider
                                                                    .canPaste,
                                                                child: Text(l10n
                                                                    .labelCtxPaste)),
                                                            PopupMenuItem(
                                                                value:
                                                                    'new_folder',
                                                                child: Text(l10n
                                                                    .labelCtxNewFolder)),
                                                            const PopupMenuDivider(),
                                                            PopupMenuItem(
                                                                value: 'open',
                                                                child: Text(l10n
                                                                    .labelCtxOpenWithAssoc)),
                                                            PopupMenuItem(
                                                                value: 'top',
                                                                child: Text(l10n
                                                                    .labelCtxMoveToTop)),
                                                            PopupMenuItem(
                                                                value: 'bottom',
                                                                child: Text(l10n
                                                                    .labelCtxMoveToBottom)),
                                                            PopupMenuItem(
                                                              value: 'delete',
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Text(
                                                                      l10n
                                                                          .labelCtxDeleteItems,
                                                                      style: TextStyle(
                                                                          color: Theme.of(context)
                                                                              .colorScheme
                                                                              .error)),
                                                                  const Icon(
                                                                      Icons
                                                                          .delete,
                                                                      color: Colors
                                                                          .red,
                                                                      size: 20),
                                                                ],
                                                              ),
                                                            ),
                                                            const PopupMenuDivider(),
                                                            PopupMenuItem(
                                                                value: 'refresh',
                                                                child: Text(l10n
                                                                    .labelCtxRefresh)),
                                                            PopupMenuItem(
                                                                value:
                                                                    'properties',
                                                                child: Text(l10n
                                                                    .labelCtxProperties)),
                                                          ],
                                                        );

                                                        if (!mounted) return;

                                                        switch (result) {
                                                          case 'up_folder':
                                                            await provider
                                                                .goUp();
                                                            break;
                                                          case 'rename':
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
                                                            provider
                                                                .setInlineRenaming(
                                                                    true);
                                                            WidgetsBinding
                                                                .instance
                                                                .addPostFrameCallback(
                                                                    (_) {
                                                              _renameFocusNode
                                                                  .requestFocus();
                                                            });
                                                            break;
                                                          case 'batch_rename':
                                                            await provider
                                                                .executeRename();
                                                            break;
                                                          case 'open':
                                                            await launchUrl(
                                                                Uri.file(
                                                                    fileModel
                                                                        .entity
                                                                        .path));
                                                            break;
                                                          case 'top':
                                                            provider
                                                                .moveSelectedToTop();
                                                            break;
                                                          case 'bottom':
                                                            provider
                                                                .moveSelectedToBottom();
                                                            break;
                                                          case 'refresh':
                                                            await provider
                                                                .refresh();
                                                            break;
                                                          case 'properties':
                                                            if (!context
                                                                .mounted) {
                                                              return;
                                                            }
                                                            _showPropertiesDialog(
                                                                context,
                                                                fileModel);
                                                            break;
                                                          case 'delete':
                                                            if (!context
                                                                .mounted) {
                                                              return;
                                                            }
                                                            final confirm =
                                                                await showDialog<
                                                                    bool>(
                                                              context: context,
                                                              builder: (context) =>
                                                                  AlertDialog(
                                                                title: Text(l10n
                                                                    .labelDialogTrashTitle),
                                                                content: Text(l10n
                                                                    .labelDialogTrashMessage),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.pop(
                                                                            context,
                                                                            false),
                                                                    child: Text(l10n
                                                                        .labelDialogCancel),
                                                                  ),
                                                                  TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.pop(
                                                                            context,
                                                                            true),
                                                                    style: TextButton.styleFrom(
                                                                        foregroundColor:
                                                                            Colors
                                                                                .red),
                                                                    child: Text(l10n
                                                                        .labelDialogDelete),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                            if (confirm == true) {
                                                              await provider
                                                                  .deleteSelectedFiles();
                                                            }
                                                            break;
                                                          case 'copy':
                                                            await provider
                                                                .copySelection();
                                                            break;
                                                          case 'cut':
                                                            await provider
                                                                .cutSelection();
                                                            break;
                                                          case 'paste':
                                                            await provider
                                                                .pasteFromClipboard();
                                                            break;
                                                          case 'new_folder':
                                                            await provider
                                                                .createNewFolder();
                                                            break;
                                                        }
                                                      },
                                                      child: InkWell(
                                                        onTap: () => provider
                                                            .toggleSelection(
                                                          fileModel,
                                                        ),
                                                        onDoubleTap: () {
                                                          if (isDir) {
                                                            provider.setDirectory(
                                                                fileModel.entity
                                                                    as Directory);
                                                          } else {
                                                            launchUrl(Uri.file(
                                                                fileModel.entity
                                                                    .path));
                                                          }
                                                        },
                                                        child: Container(
                                                          margin: const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 8.0,
                                                              vertical: 1.0),
                                                          decoration: BoxDecoration(
                                                            color: isSelected
                                                                ? Theme.of(context)
                                                                    .colorScheme
                                                                    .secondaryContainer
                                                                    .withValues(
                                                                        alpha: 0.5)
                                                                : (index % 2 == 0
                                                                    ? Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .surface
                                                                    : Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .surfaceContainerLow),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(8),
                                                            border: isSelected
                                                                ? Border.all(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primary
                                                                        .withValues(
                                                                            alpha:
                                                                                0.3))
                                                                : null,
                                                          ),
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 8.0,
                                                            vertical: 4.0,
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              SizedBox(
                                                                width:
                                                                    _widthDragHandle,
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
                                                                        : Theme.of(
                                                                                context)
                                                                            .colorScheme
                                                                            .onSurfaceVariant,
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width:
                                                                    _widthCheckbox,
                                                                child: Checkbox(
                                                                  value:
                                                                      isSelected,
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
                                                                  width:
                                                                      _widthSpace),
                                                              SizedBox(
                                                                width:
                                                                    _colWidthOriginal,
                                                                child: isEditing
                                                                    ? Focus(
                                                                        onKeyEvent:
                                                                            (node,
                                                                                event) {
                                                                          if (event
                                                                                  is KeyDownEvent &&
                                                                              event.logicalKey ==
                                                                                  LogicalKeyboardKey.escape) {
                                                                            setState(
                                                                                () {
                                                                              _editingFilePath =
                                                                                  null;
                                                                            });
                                                                            provider
                                                                                .setInlineRenaming(false);
                                                                            return KeyEventResult
                                                                                .handled;
                                                                          }
                                                                          return KeyEventResult
                                                                              .ignored;
                                                                        },
                                                                        child:
                                                                            TextField(
                                                                          controller:
                                                                              _renameController,
                                                                          focusNode:
                                                                              _renameFocusNode,
                                                                          autofocus:
                                                                              true,
                                                                          style: const TextStyle(
                                                                              fontSize:
                                                                                  12),
                                                                          decoration:
                                                                              const InputDecoration(
                                                                            isDense:
                                                                                true,
                                                                            contentPadding:
                                                                                EdgeInsets.all(4),
                                                                            border:
                                                                                OutlineInputBorder(),
                                                                          ),
                                                                          onSubmitted:
                                                                              (val) {
                                                                            provider.renameOneFile(
                                                                                fileModel,
                                                                                val);
                                                                            setState(
                                                                                () {
                                                                              _editingFilePath =
                                                                                  null;
                                                                            });
                                                                            provider
                                                                                .setInlineRenaming(false);
                                                                          },
                                                                        ),
                                                                      )
                                                                    : Row(
                                                                        children: [
                                                                          GestureDetector(
                                                                            onDoubleTap:
                                                                                () async {
                                                                              if (isDir) {
                                                                                await provider.setDirectory(fileModel.entity as Directory);
                                                                              } else {
                                                                                await launchUrl(Uri.file(fileModel.entity.path));
                                                                              }
                                                                            },
                                                                            child:
                                                                                Icon(
                                                                              isDir
                                                                                  ? Icons.folder
                                                                                  : Icons.insert_drive_file,
                                                                              color: isDir
                                                                                  ? Theme.of(context).colorScheme.tertiary
                                                                                  : Theme.of(context).colorScheme.secondary,
                                                                              size:
                                                                                  18,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                              width:
                                                                                  8),
                                                                          Expanded(
                                                                            child:
                                                                                GestureDetector(
                                                                              onDoubleTap:
                                                                                  () {
                                                                                setState(() {
                                                                                  _editingFilePath = fileModel.entity.path;
                                                                                  _renameController.text = fileModel.originalName;
                                                                                });
                                                                                provider.setInlineRenaming(true);
                                                                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                                                                  if (mounted) {
                                                                                    _renameFocusNode.requestFocus();
                                                                                  }
                                                                                });
                                                                              },
                                                                              child:
                                                                                  Text(
                                                                                fileModel.originalName,
                                                                                overflow: TextOverflow.ellipsis,
                                                                                style: TextStyle(
                                                                                  fontSize: 12,
                                                                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                                                  decoration: isSelected ? TextDecoration.underline : null,
                                                                                  decorationColor: Theme.of(context).colorScheme.primary,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                              ),
                                                              SizedBox(
                                                                  width:
                                                                      _widthSpace +
                                                                          16),
                                                              SizedBox(
                                                                width:
                                                                    _colWidthNew,
                                                                child: Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child:
                                                                          RichText(
                                                                        text: _buildDiffTextSpan(
                                                                            context,
                                                                            fileModel
                                                                                .originalName,
                                                                            fileModel
                                                                                .newName,
                                                                            fileModel
                                                                                .hasValidationError),
                                                                        overflow:
                                                                            TextOverflow
                                                                                .ellipsis,
                                                                      ),
                                                                    ),
                                                                    if (fileModel
                                                                        .hasValidationError)
                                                                      Tooltip(
                                                                        message: fileModel
                                                                                .validationErrorMessage ??
                                                                            'エラー',
                                                                        child:
                                                                            const Padding(
                                                                          padding:
                                                                              EdgeInsets.only(left: 4),
                                                                          child: Icon(
                                                                              Icons
                                                                                  .error_outline,
                                                                              color:
                                                                                  Colors.red,
                                                                              size: 16),
                                                                        ),
                                                                      ),
                                                                  ],
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  width:
                                                                      _widthSpace +
                                                                          16),
                                                              _buildCell(
                                                                  fileModel.size,
                                                                  _colWidthSize,
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onSurface),
                                                              SizedBox(
                                                                  width:
                                                                      _widthSpace +
                                                                          16),
                                                              _buildCell(
                                                                  fileModel
                                                                      .displayRelativePath,
                                                                  _colWidthPath,
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onSurfaceVariant),
                                                              SizedBox(
                                                                  width:
                                                                      _widthSpace +
                                                                          16),
                                                              _buildCell(
                                                                  fileModel
                                                                      .fileType,
                                                                  _colWidthType,
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onSurface),
                                                              SizedBox(
                                                                  width:
                                                                      _widthSpace +
                                                                          16),
                                                              _buildCell(
                                                                  fileModel
                                                                      .dateModified,
                                                                  _colWidthDate,
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onSurface),
                                                              SizedBox(
                                                                  width:
                                                                      _widthSpace +
                                                                          16),
                                                              _buildCell(
                                                                  fileModel
                                                                      .attributes,
                                                                  _colWidthAttr,
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onSurfaceVariant),
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

  void _showPropertiesDialog(BuildContext context, FileModel fileModel) {
    PlatformUtils.showPropertiesDialog(context, fileModel);
  }
}
