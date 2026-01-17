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

    if (_filterController.text != provider.filterText) {
      _filterController.text = provider.filterText;
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey, width: 1.0),
        ),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min, // Hug content
        children: [
          // Header / Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            color: Colors.amber.shade100, // Mimic yellow folder-ish header
            child: Row(
              children: [
                const Text('表示設定 (フィルタ)',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const Spacer(),
                Tooltip(
                  message: 'リストにフォルダを表示',
                  child: InkWell(
                    onTap: () => context
                        .read<DirectoryProvider>()
                        .updateFilterSettings(
                            showFolders:
                                !context.read<DirectoryProvider>().showFolders),
                    child: Icon(
                      Icons.folder,
                      size: 16,
                      color: context.watch<DirectoryProvider>().showFolders
                          ? Colors.amber
                          : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Mode Radio: All vs Specify
                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: provider.filterText.isEmpty,
                      onChanged: (val) {
                        context
                            .read<DirectoryProvider>()
                            .updateFilterSettings(filter: '');
                      },
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const Text('全てのファイル', style: TextStyle(fontSize: 12)),
                  ],
                ),
                // Radio "Specify" + TextField
                Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: provider.filterText.isEmpty,
                      onChanged: (val) {
                        // Focus text field?
                      },
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const Text('指定', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SizedBox(
                        height: 24,
                        child: TextField(
                          controller: _filterController,
                          style: const TextStyle(fontSize: 12),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 4, vertical: 0),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (val) {
                            context
                                .read<DirectoryProvider>()
                                .updateFilterSettings(filter: val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Checkboxes
                _buildCheckbox(
                  'システムファイルを非表示',
                  provider.hideSystemFiles,
                  (val) => context
                      .read<DirectoryProvider>()
                      .updateFilterSettings(hideSystem: val),
                ),
                _buildCheckbox(
                  '下位フォルダ検索',
                  provider.recursiveSearch,
                  (val) => context
                      .read<DirectoryProvider>()
                      .updateFilterSettings(recursive: val),
                ),
                _buildCheckbox(
                  'プレビュー表示',
                  provider.showPreview,
                  (val) => context
                      .read<DirectoryProvider>()
                      .updateFilterSettings(preview: val),
                ),
              ],
            ),
          ),
          // Preview Area
          if (provider.showPreview)
            Container(
              height: 150,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey)),
                color: Colors.white,
              ),
              child: _buildPreviewContent(provider),
            ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: value,
            onChanged: (val) => onChanged(val ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
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
