import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/directory_provider.dart';

class FilterSettingsPanel extends StatefulWidget {
  const FilterSettingsPanel({super.key});

  @override
  State<FilterSettingsPanel> createState() => _FilterSettingsPanelState();
}

class _FilterSettingsPanelState extends State<FilterSettingsPanel> {
  late TextEditingController _filterController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DirectoryProvider>();
    _filterController = TextEditingController(text: provider.filterText);
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectoryProvider>();
    final isCompact = provider.isCompactMode;
    final double spacing = isCompact ? 2.0 : 4.0;

    if (_filterController.text != provider.filterText) {
      _filterController.text = provider.filterText;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Handle unbounded width (e.g. inside ScrollView)
        final width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;

        return Container(
          width: width,
          decoration: BoxDecoration(
            border: const Border(
              top: BorderSide(color: Colors.grey, width: 1.0),
            ),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min, // Hug content
            children: [
              // Header / Toggle
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 8.0, vertical: isCompact ? 2.0 : 4.0),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    // Title
                    Text(
                      provider.labelSettingsFilterTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12, // Compact
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    // Toggle Button (Folder Icon)
                    // "Yellow fill and grey fill" -> Using Stack to layer icons or just Amber folder
                    // User requested specific colors.
                    IconButton(
                      icon: const Icon(Icons.folder,
                          size: 16), // Always filled folder
                      padding: EdgeInsets.zero,
                      color: provider.showFolders
                          ? Colors.amber[700]
                          : Colors.grey, // Active: Amber, Inactive: Grey
                      tooltip: provider.showFolders
                          ? 'Hide Folders'
                          : 'Show Folders',
                      onPressed: () {
                        context.read<DirectoryProvider>().updateFilterSettings(
                            showFolders: !provider.showFolders);
                      },
                    ),
                  ],
                ),
              ),
              // Filter Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. All Files Radio
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: spacing),
                      child: Row(
                        children: [
                          Container(
                            height: 24,
                            width: 24,
                            margin: const EdgeInsets.only(right: 8),
                            child: Radio<bool>(
                              value: false,
                              groupValue: provider.isFilterSpecific,
                              onChanged: (val) {
                                context
                                    .read<DirectoryProvider>()
                                    .updateFilterSettings(isSpecific: false);
                              },
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          Text(provider.labelFilterAll,
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    // 2. Specify Radio + TextField
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: spacing),
                      child: Row(
                        children: [
                          Container(
                            height: 24,
                            width: 24,
                            margin: const EdgeInsets.only(right: 8),
                            child: Radio<bool>(
                              value: true,
                              groupValue: provider.isFilterSpecific,
                              onChanged: (val) {
                                context
                                    .read<DirectoryProvider>()
                                    .updateFilterSettings(isSpecific: true);
                                // Focus logic usually handled by tap or just enabling logic
                              },
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          Text(provider.labelFilterSpecific,
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _filterController,
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                isDense: true,
                                filled: true,
                                fillColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow,
                              ),
                              onTap: () {
                                // Auto-select Specify if tapped
                                if (!provider.isFilterSpecific) {
                                  context
                                      .read<DirectoryProvider>()
                                      .updateFilterSettings(isSpecific: true);
                                }
                              },
                              onChanged: (val) {
                                context
                                    .read<DirectoryProvider>()
                                    .updateFilterSettings(filter: val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spacing),
                    // Checkboxes
                    _buildCheckbox(
                      context,
                      provider.labelFilterHideSystem,
                      provider.hideSystemFiles,
                      (val) => context
                          .read<DirectoryProvider>()
                          .updateFilterSettings(hideSystem: val),
                      isCompact,
                    ),
                    _buildCheckbox(
                      context,
                      provider.labelFilterRecursive,
                      provider.recursiveSearch,
                      (val) => context
                          .read<DirectoryProvider>()
                          .updateFilterSettings(recursive: val),
                      isCompact,
                    ),
                    _buildCheckbox(
                      context,
                      provider.labelFilterPreview,
                      provider.showPreview,
                      (val) => context
                          .read<DirectoryProvider>()
                          .updateFilterSettings(preview: val),
                      isCompact,
                    ),
                  ],
                ),
              ),
              // Preview Area
              if (provider.showPreview)
                Container(
                  height: 150,
                  decoration: const BoxDecoration(
                    border:
                        Border(top: BorderSide(color: Colors.grey, width: 0.5)),
                  ),
                  child: _buildPreviewContent(provider),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCheckbox(
    BuildContext context,
    String label,
    bool value,
    Function(bool) onChanged,
    bool isCompact,
  ) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isCompact ? 2.0 : 4.0),
        child: Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: value,
                onChanged: (val) => onChanged(val ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent(DirectoryProvider provider) {
    final selected = provider.currentFiles.where((f) => f.isSelected).toList();

    if (selected.isEmpty) {
      return const Center(
          child: Text('No selection', style: TextStyle(color: Colors.grey)));
    }

    if (selected.length > 1) {
      return Center(
          child: Text('${selected.length} files selected',
              style: const TextStyle(color: Colors.grey)));
    }

    final file = selected.first;
    final path = file.entity.path;
    final ext = path.split('.').last.toLowerCase();
    final hasExt = path.contains('.');

    if (hasExt &&
        ['png', 'jpg', 'jpeg', 'bmp', 'gif', 'webp', 'ico'].contains(ext)) {
      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: Image.file(
          File(path),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Center(child: Text('Image load failed')),
        ),
      );
    }

    // Text Preview
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: FutureBuilder<String>(
        future: _readTextPreview(File(path)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2));
          }
          final text = snapshot.data ?? 'Preview unavailable';
          return SingleChildScrollView(
            child: SelectableText(
              // Copyable
              text,
              style: const TextStyle(fontSize: 11, fontFamily: 'Consolas'),
            ),
          );
        },
      ),
    );
  }

  Future<String> _readTextPreview(File file) async {
    try {
      final len = await file.length();
      const int limit = 50 * 1024; // 50KB

      if (len > limit) {
        // Partial Read logic
        final stream = file.openRead(0, limit);
        final chunks = await stream.toList();
        final bytes = chunks.expand((element) => element).toList();

        // Decode with allowMalformed to avoid crashes on cut multi-byte chars or binary data
        String content = utf8.decode(bytes, allowMalformed: true);
        return '$content\n\n... (省略されました: 全 ${(len / 1024).toStringAsFixed(1)} KB)';
      }

      // Small file: standard read
      return await file.readAsString();
    } catch (e) {
      return 'Preview unavailable: Binary or unknown encoding';
    }
  }
}
