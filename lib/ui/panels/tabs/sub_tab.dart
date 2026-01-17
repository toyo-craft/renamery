import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/directory_provider.dart';
import '../../../core/rename_engine.dart';

class SubTab extends StatefulWidget {
  const SubTab({super.key});

  @override
  State<SubTab> createState() => _SubTabState();
}

class _SubTabState extends State<SubTab> {
  late TextEditingController _extensionController;
  late TextEditingController _listController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DirectoryProvider>();
    _extensionController =
        TextEditingController(text: provider.subTabExtensionText);
    _listController = TextEditingController(text: provider.listRenameText);
  }

  @override
  void dispose() {
    _extensionController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectoryProvider>();
    final isCompact = provider.isCompactMode;
    final double spacing = isCompact ? 2.0 : 4.0;
    final double blockSpacing = isCompact ? 8.0 : 16.0;

    // Sync controllers
    if (provider.subTabExtensionText != _extensionController.text) {
      _extensionController.text = provider.subTabExtensionText;
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
          const Text('拡張子変更', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: spacing),

          // Extension Change (with input)
          _buildRadioWithInput(
            context,
            provider,
            RenameMode.extension,
            '拡張子を変更',
            _extensionController,
            (val) => context.read<DirectoryProvider>().updateRenameSettings(
                extensionText: val, mode: RenameMode.extension),
            hint: 'txt',
            isCompact: isCompact,
          ),

          // Extension Add (with input or reuse?)
          // Usually Add is also just text input.
          // Let's use the SAME input for simplicity, or should we switch inputs?
          // The provider has one 'extensionText'. Using same input is fine.

          _buildRadioWithInput(
            context,
            provider,
            RenameMode.extensionAdd,
            '拡張子を追加',
            _extensionController, // Shared controller
            (val) => context.read<DirectoryProvider>().updateRenameSettings(
                extensionText: val, mode: RenameMode.extensionAdd),
            hint: 'bak',
            isCompact: isCompact,
          ),

          _buildRadioTile(
            context,
            provider,
            RenameMode.extensionRemove,
            '拡張子を削除',
            spacing: spacing,
          ),

          Row(
            children: [
              Expanded(
                child: _buildRadioTile(
                  context,
                  provider,
                  RenameMode.extensionUpper,
                  '大文字化',
                  spacing: spacing,
                ),
              ),
              Expanded(
                child: _buildRadioTile(
                  context,
                  provider,
                  RenameMode.extensionLower,
                  '小文字化',
                  spacing: spacing,
                ),
              ),
            ],
          ),

          Divider(thickness: 1, height: blockSpacing, color: Colors.green),

          // --- Format Words Section ---
          const Text('英単語整形', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: spacing),
          _buildRadioTile(
            context,
            provider,
            RenameMode.formatProperCase,
            '単語の先頭を大文字化 (Space/Hyphen/Underscore)',
            spacing: spacing,
          ),

          Divider(thickness: 1, height: blockSpacing, color: Colors.green),

          // --- List Rename Section ---
          const Text('リストリネーム', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  style: const TextStyle(fontSize: 13, color: Colors.black),
                  underline: Container(
                    height: 1,
                    color: Colors.grey,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'text_input',
                      child: Text('テキスト入力 (Original[TAB]New)'),
                    ),
                    DropdownMenuItem(
                      value: 'file_read',
                      enabled: false,
                      child: Text('ファイル読込 (Coming Soon)',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                  onChanged: (val) {},
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
              style: const TextStyle(fontSize: 12, fontFamily: 'Consolas'),
              decoration: const InputDecoration(
                hintText: 'old_name.txt\tnew_name.txt\nfile01.png\timage01.png',
                border: OutlineInputBorder(),
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
            Text(label, style: const TextStyle(fontSize: 13)),
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
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller:
                  controller, // Note: Shared controller usage might be tricky if fields are distinct?
              // Here we use one 'extensionText' for both rename/add, so shared is fine.
              // But confusing if user switches mode?
              // Namery usually shares the input area?
              // In Namery manual image, there is ONE input field next to the radio group?
              // No, the image shows input field next to "Extension Change".
              // If I click "Remove", input might be disabled or irrelevant.
              // If I click "Add", input is relevant.
              // Let's use ONE shared input for all extension logic if possible or just use this widget.
              // If I use the same controller for both widgets, text duplicates in both fields UI-wise?
              // Yes.
              // So better to have ONE input field or sync them.
              // Here I am rendering TWO rows each with an input.
              // Better UI: Radio Group + Single Input?
              // Or: Radio Row ... Input
              // Radio Row ...
              // Let's stick to simple implementation: Input next to Radio.
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: hint,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: isCompact ? 6 : 8,
                  horizontal: 8,
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: onChanged,
              onTap: () {
                // Auto-switch mode on focus?
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
