import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/directory_provider.dart';
import '../../../core/rename_engine.dart'; // To access RenameMode enum directly if strict typing needed

class MainTab extends StatefulWidget {
  const MainTab({super.key});

  @override
  State<MainTab> createState() => _MainTabState();
}

class _MainTabState extends State<MainTab> {
  late TextEditingController _findController;
  late TextEditingController _replaceController;
  late TextEditingController _appendController;
  late TextEditingController _deleteToController;
  late TextEditingController _startController;
  late TextEditingController _digitController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DirectoryProvider>();
    _findController = TextEditingController(text: provider.findText);
    _replaceController = TextEditingController(text: provider.replaceText);
    _appendController = TextEditingController(text: provider.appendText);
    _deleteToController = TextEditingController(text: provider.deleteToText);
    _startController = TextEditingController(
      text: provider.startNumber.toString(),
    );
    _digitController = TextEditingController(text: provider.digits.toString());
  }

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    _appendController.dispose();
    _deleteToController.dispose();
    _startController.dispose();
    _digitController.dispose();
    super.dispose();
  }

  Widget _buildHistoryTextField(
    BuildContext context,
    TextEditingController controller,
    List<String> history,
    Function(String) onChanged,
    String label,
  ) {
    return Row(
      children: [
        if (label.isNotEmpty) SizedBox(width: 60, child: Text(label)),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 8,
              ),
              border: const OutlineInputBorder(),
              suffixIcon: PopupMenuButton<String>(
                icon: const Icon(Icons.arrow_drop_down),
                onSelected: (String value) {
                  controller.text = value;
                  onChanged(value);
                },
                itemBuilder: (BuildContext context) {
                  return history.map((String value) {
                    return PopupMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList();
                },
              ),
            ),
            onChanged: (val) => onChanged(val),
            onSubmitted: (val) {
              // Add to history
              if (val.isNotEmpty) {
                context.read<DirectoryProvider>().addToHistory(history, val);
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectoryProvider>();

    // Sync controllers
    if (provider.findText != _findController.text) {
      _findController.text = provider.findText ?? '';
    }
    if (provider.replaceText != _replaceController.text) {
      _replaceController.text = provider.replaceText ?? '';
    }
    if (provider.appendText != _appendController.text) {
      _appendController.text = provider.appendText ?? '';
    }
    if (provider.deleteToText != _deleteToController.text) {
      _deleteToController.text = provider.deleteToText ?? '';
    }
    // Sync start number (important for Pin feature)
    if (provider.startNumber.toString() != _startController.text) {
      _startController.text = provider.startNumber.toString();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Top Section: Common Inputs ---
          // String Input with History
          _buildHistoryTextField(
              context,
              _appendController,
              provider.appendHistory,
              (val) => context
                  .read<DirectoryProvider>()
                  .updateRenameSettings(append: val),
              '文字列'),

          const SizedBox(height: 4),
          // --- Numbering Inputs (Spinner Style) ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Pin Icon
                Tooltip(
                  message: '変更後の連番数字を保存（次回リネーム時に連番を継続）',
                  child: InkWell(
                    onTap: () => context
                        .read<DirectoryProvider>()
                        .updateRenameSettings(
                            saveSequenceNumber: !context
                                .read<DirectoryProvider>()
                                .saveSequenceNumber),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(
                        context.watch<DirectoryProvider>().saveSequenceNumber
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                        size: 20,
                        color: context
                                .watch<DirectoryProvider>()
                                .saveSequenceNumber
                            ? Colors.amber
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 60, child: Text('開始/桁')),
                _buildSpinner(
                  context,
                  _startController,
                  (val) => context
                      .read<DirectoryProvider>()
                      .updateRenameSettings(start: val),
                ),
                const SizedBox(width: 8),
                _buildSpinner(
                  context,
                  _digitController,
                  (val) => context
                      .read<DirectoryProvider>()
                      .updateRenameSettings(digit: val),
                ),
              ],
            ),
          ),
          const Divider(
            thickness: 1,
            height: 16,
            color: Colors.green,
          ), // Green header line

          // --- Mode Radio Group ---
          // 1. Numbering with Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Radio<RenameMode>(
                  value: RenameMode.numbering,
                  groupValue: provider.renameMode,
                  onChanged: (val) => context
                      .read<DirectoryProvider>()
                      .updateRenameSettings(mode: val),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<NumberingMode>(
                    value: provider.numberingMode,
                    isDense: true,
                    isExpanded: true,
                    underline: Container(
                      height: 1,
                      color: Colors.grey,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: NumberingMode.stringNumber,
                        child: Text('文字列 + 連番'),
                      ),
                      DropdownMenuItem(
                        value: NumberingMode.originalNumber,
                        child: Text('現在名 + 連番'),
                      ),
                      DropdownMenuItem(
                        value: NumberingMode.numberString,
                        child: Text('連番 + 文字列'),
                      ),
                      DropdownMenuItem(
                        value: NumberingMode.numberOriginal,
                        child: Text('連番 + 現在名'),
                      ),
                      DropdownMenuItem(
                        value: NumberingMode.baseStringNumber,
                        child: Text('基本フォルダ名 + 文字列 + 連番'),
                      ),
                      DropdownMenuItem(
                        value: NumberingMode.baseStringOriginal,
                        child: Text('基本フォルダ名 + 文字列 + 現在名'),
                      ),
                      DropdownMenuItem(
                        value: NumberingMode.relativeStringNumber,
                        child: Text('相対フォルダ名 + 文字列 + 連番'),
                      ),
                      DropdownMenuItem(
                        value: NumberingMode.relativeStringOriginal,
                        child: Text('相対フォルダ名 + 文字列 + 現在名'),
                      ),
                      DropdownMenuItem(
                        value: NumberingMode.numberStringBase,
                        child: Text('連番 + 文字列 + 基本フォルダ名'),
                      ),
                      DropdownMenuItem(
                        value: NumberingMode.numberStringRelative,
                        child: Text('連番 + 文字列 + 相対フォルダ名'),
                      ),
                    ],
                    onChanged: (val) {
                      context.read<DirectoryProvider>().updateRenameSettings(
                          mode: RenameMode.numbering, numberingMode: val);
                    },
                  ),
                ),
              ],
            ),
          ),

          _buildRadioTile(
            context,
            provider,
            RenameMode.prepend,
            'Prefix(前方追加)',
          ),
          _buildRadioTile(context, provider, RenameMode.append, 'Suffix(後方追加)'),
          _buildRadioTile(
            context,
            provider,
            RenameMode.capitalize,
            '先頭文字を大文字化',
          ),
          _buildRadioTile(context, provider, RenameMode.upper, '大文字化'),
          _buildRadioTile(context, provider, RenameMode.lower, '小文字化'),

          // String Insertion
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Radio<RenameMode>(
                  value: RenameMode.insert,
                  groupValue: provider.renameMode,
                  onChanged: (val) => context
                      .read<DirectoryProvider>()
                      .updateRenameSettings(mode: val),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                const Text('文字列挿入', style: TextStyle(fontSize: 13)),
                const Spacer(),
                // Re-use StartController/Spinner or create new?
                // RenameEngine uses startNumber as index.
                // So we bind the spinner to startNumber, but visually associate it here.
                _buildSpinner(
                    context,
                    _startController, // Re-using start controller as index
                    (val) => context
                        .read<DirectoryProvider>()
                        .updateRenameSettings(start: val)),
              ],
            ),
          ),

          const Divider(thickness: 1, height: 16, color: Colors.green),

          // --- Delete Section ---
          // 1. Delete Start
          _buildRadioTile(
              context, provider, RenameMode.deleteStart, '先頭から桁数分削除'),
          // 2. Delete End
          _buildRadioTile(context, provider, RenameMode.deleteEnd, '後ろから桁数分削除'),
          // 3. Delete From (Index)
          _buildRadioTile(
            context,
            provider,
            RenameMode.deleteFrom,
            '開始数字から桁数削除',
          ),

          // 4. Delete To (String/Complex)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue:
                      (provider.renameMode == RenameMode.deleteFrontTo ||
                          provider.renameMode == RenameMode.deleteBackTo),
                  onChanged: (val) {
                    if (val == true) {
                      // Default to Front if switching into this mode
                      context
                          .read<DirectoryProvider>()
                          .updateRenameSettings(mode: RenameMode.deleteFrontTo);
                    }
                  },
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      // Dropdown for Direction
                      DropdownButton<RenameMode>(
                        value: (provider.renameMode == RenameMode.deleteBackTo)
                            ? RenameMode.deleteBackTo
                            : RenameMode.deleteFrontTo,
                        items: const [
                          DropdownMenuItem(
                            value: RenameMode.deleteFrontTo,
                            child: Text('前から'),
                          ),
                          DropdownMenuItem(
                            value: RenameMode.deleteBackTo,
                            child: Text('後から'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            context
                                .read<DirectoryProvider>()
                                .updateRenameSettings(mode: val);
                          }
                        },
                        underline: Container(
                          height: 1,
                          color: Colors.grey,
                        ),
                        isDense: true,
                      ),
                      const SizedBox(width: 8),
                      // Input Field
                      Expanded(
                        child: _buildHistoryTextField(
                          context,
                          _deleteToController,
                          provider.deleteToHistory,
                          (val) => context
                              .read<DirectoryProvider>()
                              .updateRenameSettings(deleteTo: val),
                          '', // No label needed
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('まで削除'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(thickness: 1, height: 16, color: Colors.green),

          // --- Replace Section ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Radio<RenameMode>(
                  value: RenameMode.replace,
                  groupValue: provider.renameMode,
                  onChanged: (val) => context
                      .read<DirectoryProvider>()
                      .updateRenameSettings(mode: val),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _findController,
                          decoration: const InputDecoration(
                            hintText: '検索 (Find)',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) => context
                              .read<DirectoryProvider>()
                              .updateRenameSettings(find: val),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text('を'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 32.0,
              top: 4.0,
            ), // Indent to align with radio
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replaceController,
                    decoration: const InputDecoration(
                      hintText: '置換 (Replace)',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => context
                        .read<DirectoryProvider>()
                        .updateRenameSettings(replace: val),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text('に置換'),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => context
                .read<DirectoryProvider>()
                .updateRenameSettings(useRegex: !provider.useRegex),
            borderRadius: BorderRadius.circular(4.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Checkbox(
                    value: provider.useRegex,
                    onChanged: (val) => context
                        .read<DirectoryProvider>()
                        .updateRenameSettings(useRegex: val),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8),
                  const Text('正規表現', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods

  Widget _buildRadioTile(
    BuildContext context,
    DirectoryProvider provider,
    RenameMode mode,
    String label,
  ) {
    return InkWell(
      onTap: () =>
          context.read<DirectoryProvider>().updateRenameSettings(mode: mode),
      borderRadius: BorderRadius.circular(4.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Radio<RenameMode>(
              value: mode,
              groupValue: provider.renameMode,
              onChanged: (val) => context
                  .read<DirectoryProvider>()
                  .updateRenameSettings(mode: val),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildSpinner(
    BuildContext context,
    TextEditingController controller,
    Function(int) onChanged,
  ) {
    return SizedBox(
      width: 80,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 4,
                ),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                final n = int.tryParse(val);
                if (n != null) onChanged(n);
                int? value = int.tryParse(val);
                if (value != null) {
                  if (value < 1) {
                    value = 1; // Enforce min 1
                    controller.text = '1';
                    // Cursor position fix might be needed but simple set is safe for valid int
                  }
                  onChanged(value);
                }
              },
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  int current = int.tryParse(controller.text) ?? 1;
                  current++;
                  controller.text = current.toString();
                  // onChanged(current); // Controller listener or manual?
                  // TextField controller doesn't trigger onChanged when text is set programmatically.
                  onChanged(current);
                },
                child: const Icon(Icons.arrow_drop_up, size: 18),
              ),
              InkWell(
                onTap: () {
                  int current = int.tryParse(controller.text) ?? 1;
                  if (current > 1) {
                    current--;
                    controller.text = current.toString();
                    onChanged(current);
                  }
                },
                child: const Icon(Icons.arrow_drop_down, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
