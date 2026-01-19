import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/directory_provider.dart';
import '../../../core/rename_engine.dart';
import '../../widgets/history_text_field.dart';

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
  late TextEditingController _insertController; // For Insert Index
  late TextEditingController _digitController;

  late FocusNode _findFocus;
  late FocusNode _replaceFocus;
  late FocusNode _appendFocus;
  late FocusNode _deleteToFocus;
  late FocusNode _startFocus; // For Start/Digit spinner
  late FocusNode _startInsertFocus; // For Insert mode spinner
  late FocusNode _digitFocus;

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
    _insertController = TextEditingController(
      text: provider.insertIndex.toString(),
    );
    _digitController = TextEditingController(text: provider.digits.toString());

    _findFocus = FocusNode();
    _replaceFocus = FocusNode();
    _appendFocus = FocusNode();
    _deleteToFocus = FocusNode();
    _startFocus = FocusNode();
    _startInsertFocus = FocusNode();
    _digitFocus = FocusNode();
  }

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    _appendController.dispose();
    _deleteToController.dispose();
    _startController.dispose();
    _insertController.dispose();
    _digitController.dispose();

    _findFocus.dispose();
    _replaceFocus.dispose();
    _appendFocus.dispose();
    _deleteToFocus.dispose();
    _startFocus.dispose();
    _startInsertFocus.dispose();
    _digitFocus.dispose();
    super.dispose();
  }

  // Removed _buildHistoryTextField helper in favor of HistoryTextField widget

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectoryProvider>();
    final isCompact = provider.isCompactMode;
    final double spacing = isCompact ? 2.0 : 4.0;
    final double blockSpacing = isCompact ? 8.0 : 16.0;

    // Sync controllers if NOT focused
    if (provider.findText != _findController.text && !_findFocus.hasFocus) {
      _findController.text = provider.findText ?? '';
    }
    if (provider.replaceText != _replaceController.text &&
        !_replaceFocus.hasFocus) {
      _replaceController.text = provider.replaceText ?? '';
    }
    if (provider.appendText != _appendController.text &&
        !_appendFocus.hasFocus) {
      _appendController.text = provider.appendText ?? '';
    }
    if (provider.deleteToText != _deleteToController.text &&
        !_deleteToFocus.hasFocus) {
      _deleteToController.text = provider.deleteToText ?? '';
    }
    // Sync start number
    if (provider.startNumber.toString() != _startController.text &&
        !_startFocus.hasFocus) {
      _startController.text = provider.startNumber.toString();
    }
    // Sync insert index
    if (provider.insertIndex.toString() != _insertController.text &&
        !_startInsertFocus.hasFocus) {
      _insertController.text = provider.insertIndex.toString();
    }
    // Sync digits
    if (provider.digits.toString() != _digitController.text &&
        !_digitFocus.hasFocus) {
      _digitController.text = provider.digits.toString();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 4.0 : 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Top Section: Common Inputs ---
          // String Input with History
          HistoryTextField(
              controller: _appendController,
              history: provider.appendHistory,
              onChanged: (val) {
                final provider = context.read<DirectoryProvider>();
                final current = provider.renameMode;
                final isStringMode = current == RenameMode.append ||
                    current == RenameMode.prepend ||
                    current == RenameMode.insert ||
                    current == RenameMode.numbering;
                provider.updateRenameSettings(
                    append: val,
                    mode: isStringMode ? null : provider.lastStringMode);
              },
              label: '文字列',
              focusNode: _appendFocus,
              isCompact: isCompact),

          SizedBox(height: spacing),
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
                      .updateRenameSettings(start: val, immediate: true),
                  focusNode: _startFocus,
                  isCompact: isCompact,
                ),
                const SizedBox(width: 8),
                _buildSpinner(
                  context,
                  _digitController,
                  (val) => context
                      .read<DirectoryProvider>()
                      .updateRenameSettings(digits: val, immediate: true),
                  focusNode: _digitFocus,
                  isCompact: isCompact,
                ),
              ],
            ),
          ),
          Divider(
            thickness: 1,
            height: blockSpacing,
            color: Colors.green,
          ), // Green header line

          // --- Mode Radio Group ---
          // 1. Numbering with Dropdown
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing),
            child: Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Radio<RenameMode>(
                    value: RenameMode.numbering,
                    groupValue: provider.renameMode,
                    onChanged: (val) => context
                        .read<DirectoryProvider>()
                        .updateRenameSettings(mode: val, immediate: true),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: isCompact ? 32 : null,
                    child: DropdownButton<NumberingMode>(
                      value: provider.numberingMode,
                      isDense: true,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 13, color: Colors.black),
                      underline: Container(
                        height: 1,
                        color: Colors.grey,
                      ),
                      items: [
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
                          child: Text('基本${provider.termFolder}名 + 文字列 + 連番'),
                        ),
                        DropdownMenuItem(
                          value: NumberingMode.baseStringOriginal,
                          child: Text('基本${provider.termFolder}名 + 文字列 + 現在名'),
                        ),
                        DropdownMenuItem(
                          value: NumberingMode.relativeStringNumber,
                          child: Text('相対${provider.termFolder}名 + 文字列 + 連番'),
                        ),
                        DropdownMenuItem(
                          value: NumberingMode.relativeStringOriginal,
                          child: Text('相対${provider.termFolder}名 + 文字列 + 現在名'),
                        ),
                        DropdownMenuItem(
                          value: NumberingMode.numberStringBase,
                          child: Text('連番 + 文字列 + 基本${provider.termFolder}名'),
                        ),
                        DropdownMenuItem(
                          value: NumberingMode.numberStringRelative,
                          child: Text('連番 + 文字列 + 相対${provider.termFolder}名'),
                        ),
                      ],
                      onChanged: (val) {
                        context.read<DirectoryProvider>().updateRenameSettings(
                            mode: RenameMode.numbering, numberingMode: val);
                      },
                    ),
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
            spacing: spacing,
          ),
          _buildRadioTile(context, provider, RenameMode.append, 'Suffix(後方追加)',
              spacing: spacing),
          _buildRadioTile(
            context,
            provider,
            RenameMode.capitalize,
            '先頭文字を大文字化',
            spacing: spacing,
          ),
          _buildRadioTile(context, provider, RenameMode.upper, '大文字化',
              spacing: spacing),
          _buildRadioTile(context, provider, RenameMode.lower, '小文字化',
              spacing: spacing),

          // String Insertion
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing),
            child: Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Radio<RenameMode>(
                    value: RenameMode.insert,
                    groupValue: provider.renameMode,
                    onChanged: (val) => context
                        .read<DirectoryProvider>()
                        .updateRenameSettings(mode: val, immediate: true),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('文字列挿入', style: TextStyle(fontSize: 13)),
                const Spacer(),
                // Re-use StartController/Spinner or create new?
                // RenameEngine uses startNumber as index.
                // So we bind the spinner to startNumber, but visually associate it here.
                _buildSpinner(
                  context,
                  _insertController, // Separate controller
                  (val) => context
                      .read<DirectoryProvider>()
                      .updateRenameSettings(insertIndex: val, immediate: true),
                  focusNode: _startInsertFocus,
                  isCompact: isCompact,
                ),
              ],
            ),
          ),

          Divider(thickness: 1, height: blockSpacing, color: Colors.green),

          // --- Delete Section ---
          // 1. Delete Start
          _buildRadioTile(
            context,
            provider,
            RenameMode.deleteStart,
            '先頭から桁数分削除',
            spacing: spacing,
          ),
          // 2. Delete End
          _buildRadioTile(
            context,
            provider,
            RenameMode.deleteEnd,
            '後ろから桁数分削除',
            spacing: spacing,
          ),
          // 3. Delete From (Index)
          _buildRadioTile(
            context,
            provider,
            RenameMode.deleteFrom,
            '開始数字から桁数削除',
            spacing: spacing,
          ),

          // 4. Delete To (String/Complex)
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing),
            child: Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Radio<bool>(
                    value: true,
                    groupValue:
                        (provider.renameMode == RenameMode.deleteFrontTo ||
                            provider.renameMode == RenameMode.deleteBackTo),
                    onChanged: (val) {
                      if (val == true) {
                        // Default to Front if switching into this mode
                        context.read<DirectoryProvider>().updateRenameSettings(
                            mode: RenameMode.deleteFrontTo);
                      }
                    },
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      // Dropdown for Direction
                      SizedBox(
                        height: isCompact ? 32 : null,
                        child: DropdownButton<RenameMode>(
                          value:
                              (provider.renameMode == RenameMode.deleteBackTo)
                                  ? RenameMode.deleteBackTo
                                  : RenameMode.deleteFrontTo,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black),
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
                      ),
                      const SizedBox(width: 8),
                      // Input Field
                      Expanded(
                        child: HistoryTextField(
                            controller: _deleteToController,
                            history: provider.deleteToHistory,
                            onChanged: (val) => context
                                .read<DirectoryProvider>()
                                .updateRenameSettings(
                                    deleteTo: val,
                                    mode: provider.renameMode ==
                                            RenameMode.deleteBackTo
                                        ? RenameMode.deleteBackTo
                                        : RenameMode.deleteFrontTo),
                            label: '', // No label
                            focusNode: _deleteToFocus,
                            isCompact: isCompact),
                      ),
                      const SizedBox(width: 8),
                      const Text('まで削除'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(thickness: 1, height: blockSpacing, color: Colors.green),

          // --- Replace Section ---
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing),
            child: Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Radio<RenameMode>(
                    value: RenameMode.replace,
                    groupValue: provider.renameMode,
                    onChanged: (val) => context
                        .read<DirectoryProvider>()
                        .updateRenameSettings(mode: val, immediate: true),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: HistoryTextField(
                          focusNode: _findFocus,
                          controller: _findController,
                          history: provider.findHistory,
                          hintText: '検索 (Find)',
                          isCompact: isCompact,
                          onChanged: (val) => context
                              .read<DirectoryProvider>()
                              .updateRenameSettings(
                                  find: val, mode: RenameMode.replace),
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
            padding: EdgeInsets.only(
              left: 32.0,
              top: spacing,
            ), // Indent to align with radio
            child: Row(
              children: [
                Expanded(
                  child: HistoryTextField(
                    focusNode: _replaceFocus,
                    controller: _replaceController,
                    history: provider.replaceHistory,
                    hintText: '置換 (Replace)',
                    isCompact: isCompact,
                    onChanged: (val) => context
                        .read<DirectoryProvider>()
                        .updateRenameSettings(
                            replace: val, mode: RenameMode.replace),
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
            onTap: () => context.read<DirectoryProvider>().updateRenameSettings(
                useRegex: !provider.useRegex, immediate: true),
            borderRadius: BorderRadius.circular(4.0),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: spacing),
              child: Row(
                children: [
                  Checkbox(
                    value: provider.useRegex,
                    onChanged: (val) => context
                        .read<DirectoryProvider>()
                        .updateRenameSettings(useRegex: val, immediate: true),
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

  Widget _buildSpinner(
    BuildContext context,
    TextEditingController controller,
    Function(int) onChanged, {
    FocusNode? focusNode,
    bool isCompact = false,
  }) {
    return SizedBox(
      width: 80,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              focusNode: focusNode,
              controller: controller,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: isCompact ? 6 : 8,
                  horizontal: 4,
                ),
                border: const OutlineInputBorder(),
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
                  focusNode?.requestFocus();
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
                  focusNode?.requestFocus();
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
