import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/directory_provider.dart';
import '../../../core/rename_engine.dart';
import '../../widgets/history_text_field.dart';

class SubTab extends StatefulWidget {
  const SubTab({super.key});

  @override
  State<SubTab> createState() => _SubTabState();
}

class _SubTabState extends State<SubTab> {
  late TextEditingController _extensionChangeController;
  late TextEditingController _extensionAddController;
  late TextEditingController _listController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DirectoryProvider>();
    _extensionChangeController =
        TextEditingController(text: provider.extensionChangeText);
    _extensionAddController =
        TextEditingController(text: provider.extensionAddText);
    _listController = TextEditingController(text: provider.listRenameText);
  }

  @override
  void dispose() {
    _extensionChangeController.dispose();
    _extensionAddController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectoryProvider>();
    final isCompact = provider.isCompactMode;
    final double spacing = isCompact ? 4.0 : 8.0; // 4dp grid
    final double blockSpacing = isCompact ? 12.0 : 20.0; // 4dp grid

    // Sync controllers
    // Sync controllers
    if (provider.extensionChangeText != _extensionChangeController.text) {
      _extensionChangeController.text = provider.extensionChangeText;
    }
    if (provider.extensionAddText != _extensionAddController.text) {
      _extensionAddController.text = provider.extensionAddText;
    }
    if (provider.listRenameText != _listController.text) {
      _listController.text = provider.listRenameText;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 4.0 : 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Extension Section ---
          Text(provider.labelSubExtChangeTitle,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: spacing),

          // Extension Change (with input)
          _buildRadioWithInput(
            context,
            provider,
            RenameMode.extension,
            provider.labelOpExtChange,
            _extensionChangeController,
            (val) => context.read<DirectoryProvider>().updateRenameSettings(
                extensionChangeText: val, mode: RenameMode.extension),
            hint: 'txt',
            isCompact: isCompact,
            history: provider.extensionHistory, // Pass history
          ),

          // ... (Extension Add block is fine with labelOpExtAdd) ...
          _buildRadioWithInput(
            context,
            provider,
            RenameMode.extensionAdd,
            provider.labelOpExtAdd,
            _extensionAddController,
            (val) => context.read<DirectoryProvider>().updateRenameSettings(
                extensionAddText: val, mode: RenameMode.extensionAdd),
            hint: 'bak',
            isCompact: isCompact,
            history: provider.extensionHistory, // Shared history
          ),

          _buildRadioTile(
            context,
            provider,
            RenameMode.extensionRemove,
            provider.labelOpExtRemove,
            spacing: spacing,
          ),

          Row(
            children: [
              Expanded(
                child: _buildRadioTile(
                  context,
                  provider,
                  RenameMode.extensionUpper,
                  provider.labelOpExtUpper,
                  spacing: spacing,
                ),
              ),
              Expanded(
                child: _buildRadioTile(
                  context,
                  provider,
                  RenameMode.extensionLower,
                  provider.labelOpExtLower,
                  spacing: spacing,
                ),
              ),
            ],
          ),

          Divider(thickness: 1, height: blockSpacing, color: Colors.green),

          // ...

          // --- Format Words Section ---
          Text(provider.labelSubFormatTitle,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: spacing),
          _buildRadioTile(
            context,
            provider,
            RenameMode.formatProperCase,
            provider.labelSubFormatProperCase,
            spacing: spacing,
          ),

          Divider(thickness: 1, height: blockSpacing, color: Colors.green),

          // --- List Rename Section ---
          Text(provider.labelSubListTitle,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: spacing),

          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Radio<RenameMode>(
                  value: RenameMode.listRename,
                  groupValue: provider.renameMode,
                  onChanged: (val) => context
                      .read<DirectoryProvider>()
                      .updateRenameSettings(mode: val, immediate: true),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              // Dropdown Mockup
              Expanded(
                child: DropdownButton<String>(
                  value: 'text_input',
                  isDense: true,
                  isExpanded: true,
                  style: Theme.of(context).textTheme.bodyMedium,
                  underline: Container(
                    height: 1,
                    color: Colors.grey,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'text_input',
                      child: Text(provider.labelSubListModeText),
                    ),
                    DropdownMenuItem(
                      value: 'sample_chapter',
                      child: Text(provider.labelSubListSample1),
                    ),
                    DropdownMenuItem(
                      value: 'sample_ext',
                      child: Text(provider.labelSubListSample2),
                    ),
                    DropdownMenuItem(
                      value: 'sample_replace',
                      child: Text(provider.labelSubListSample3),
                    ),
                    const DropdownMenuItem(
                      value: 'file_read',
                      enabled: false,
                      child: Text('File Read (Coming Soon)',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val == 'text_input' || val == null) return;

                    String sampleText = '';
                    switch (val) {
                      case 'sample_chapter':
                        sampleText =
                            '01_chapter_intro.mp4\t01_chapter_intro.mp4\n02_chapter_main.mp4\t02_chapter_main.mp4\n03_chapter_end.mp4\t03_chapter_end.mp4';
                        // User manual says: list rename is "Original [TAB] New".
                        // Actually the user sample "01_chapter_intro.mp4" (single column) implies "Target" or "New"?
                        // If single column, it usually implies "Original" to remain "Original"? Or "New" if matching by index?
                        // Let's re-read the engine logic or assume Tab separated.
                        // Wait, list rename usually maps Original -> New.
                        // If the user wants to *rename to* chapter files, they probably providing target names?
                        // Let's use the exact sample the user gave previously for the default text area: "01_chapter_intro.mp4\n..."
                        // Maybe simpler: just put the text.
                        sampleText =
                            '01_chapter_intro.mp4\n02_chapter_main.mp4\n03_chapter_end.mp4';
                        break;
                      case 'sample_ext':
                        sampleText =
                            'image01.jpg\timage01.png\nimage02.jpg\timage02.png\nimage03.jpg\timage03.png';
                        break;
                      case 'sample_replace':
                        sampleText =
                            'old_report.docx\tnew_report.docx\ndraft_v1.txt\tdraft_final.txt';
                        break;
                    }

                    if (sampleText.isNotEmpty) {
                      context.read<DirectoryProvider>().updateRenameSettings(
                          listText: sampleText,
                          mode: RenameMode.listRename,
                          immediate: true);
                      _listController.text = sampleText;
                    }
                  },
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(left: 32.0, top: 4.0),
            child: TextField(
              controller: _listController,
              maxLines: 8,
              minLines: 3,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontFamily: 'Consolas'),
              decoration: InputDecoration(
                hintText: provider.labelSubListHint,
                // border: OutlineInputBorder(), // Removed for global theme
                isDense: true,
              ),
              onChanged: (val) => context
                  .read<DirectoryProvider>()
                  .updateRenameSettings(
                      listText: val, mode: RenameMode.listRename),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioTile(
    BuildContext context,
    DirectoryProvider provider,
    RenameMode mode,
    String label, {
    double spacing = 4.0,
  }) {
    return InkWell(
      onTap: () => context
          .read<DirectoryProvider>()
          .updateRenameSettings(mode: mode, immediate: true),
      borderRadius: BorderRadius.circular(4.0),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: spacing),
        child: Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Radio<RenameMode>(
                value: mode,
                groupValue: provider.renameMode,
                onChanged: (val) => context
                    .read<DirectoryProvider>()
                    .updateRenameSettings(mode: val, immediate: true),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioWithInput(
    BuildContext context,
    DirectoryProvider provider,
    RenameMode mode,
    String label,
    TextEditingController controller,
    Function(String) onChanged, {
    String? hint,
    bool isCompact = false,
    List<String> history = const [],
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isCompact ? 2.0 : 4.0),
      child: Row(
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Radio<RenameMode>(
              value: mode,
              groupValue: provider.renameMode,
              onChanged: (val) => context
                  .read<DirectoryProvider>()
                  .updateRenameSettings(mode: val, immediate: true),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 8),
          Expanded(
            child: HistoryTextField(
              controller: controller,
              history: history,
              hintText: hint,
              isCompact: isCompact,
              onChanged: onChanged,
              onTap: () {
                context
                    .read<DirectoryProvider>()
                    .updateRenameSettings(mode: mode, immediate: true);
              },
            ),
          ),
        ],
      ),
    );
  }
}
