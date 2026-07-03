import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/directory_provider_platform.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

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
        final l10n = AppLocalizations.of(context)!;
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
                      l10n.labelSettingsFilterTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12, // Compact
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    // Toggle Button (Folder Icon)
                    IconButton(
                      icon: const Icon(Icons.folder, size: 16),
                      padding: EdgeInsets.zero,
                      color: provider.showFolders
                          ? Colors.amber[700]
                          : Colors.grey,
                      tooltip: provider.showFolders
                          ? l10n.labelFilterHideFolders
                          : l10n.labelFilterShowFolders,
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
                child: RadioGroup<bool>(
                  groupValue: provider.isFilterSpecific,
                  onChanged: (val) {
                    if (val != null) {
                      context
                          .read<DirectoryProvider>()
                          .updateFilterSettings(isSpecific: val);
                    }
                  },
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
                              child: const Radio<bool>(
                                value: false,
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            Text(l10n.labelFilterAll,
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
                              child: const Radio<bool>(
                                value: true,
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            Text(l10n.labelFilterSpecific,
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
                                      color: Colors.grey.withValues(alpha: 0.5),
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
                        l10n.labelFilterHideSystem,
                        provider.hideSystemFiles,
                        (val) => context
                            .read<DirectoryProvider>()
                            .updateFilterSettings(hideSystem: val),
                        isCompact,
                      ),
                      _buildCheckbox(
                        context,
                        l10n.labelFilterRecursive,
                        provider.recursiveSearch,
                        (val) => context
                            .read<DirectoryProvider>()
                            .updateFilterSettings(recursive: val),
                        isCompact,
                      ),
                      _buildCheckbox(
                        context,
                        l10n.labelFilterPreview,
                        provider.showPreview,
                        (val) => context
                            .read<DirectoryProvider>()
                            .updateFilterSettings(preview: val),
                        isCompact,
                      ),
                    ],
                  ),
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
                  child: _buildPreviewContent(provider, l10n),
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

  Widget _buildPreviewContent(
      DirectoryProvider provider, AppLocalizations l10n) {
    final selected = provider.currentFiles.where((f) => f.isSelected).toList();

    if (selected.isEmpty) {
      return Center(
          child: Text(l10n.labelPreviewNoSelection,
              style: const TextStyle(color: Colors.grey)));
    }

    if (selected.length > 1) {
      return Center(
          child: Text(l10n.labelPreviewSelectedCount(selected.length),
              style: const TextStyle(color: Colors.grey)));
    }

    final file = selected.first;
    final path = file.path;
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
              Center(child: Text(l10n.labelPreviewImageLoadFailed)),
        ),
      );
    }

    // Text Preview
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: FutureBuilder<String>(
        future: _readTextPreview(File(path), l10n),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2));
          }
          final text = snapshot.data ?? l10n.labelPreviewUnavailable;
          return SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(fontSize: 11, fontFamily: 'Consolas'),
            ),
          );
        },
      ),
    );
  }

  Future<String> _readTextPreview(File file, AppLocalizations l10n) async {
    try {
      final len = await file.length();
      const int limit = 50 * 1024; // 50KB

      if (len > limit) {
        final stream = file.openRead(0, limit);
        final chunks = await stream.toList();
        final bytes = chunks.expand((element) => element).toList();
        String content = utf8.decode(bytes, allowMalformed: true);
        final sizeStr = (len / 1024).toStringAsFixed(1);
        return '$content\n\n${l10n.labelPreviewOmitted(sizeStr)}';
      }
      return await file.readAsString();
    } catch (e) {
      return l10n.labelPreviewBinaryError;
    }
  }
}
