import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/directory_provider.dart';
import '../../../../core/rename_engine.dart';
import 'package:renamery/ui/widgets/number_spin_box.dart';
import 'package:renamery/ui/widgets/history_text_field.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

class CategoryNumbering extends StatefulWidget {
  const CategoryNumbering({super.key});

  @override
  State<CategoryNumbering> createState() => _CategoryNumberingState();
}

class _CategoryNumberingState extends State<CategoryNumbering> {
  late TextEditingController
      _appendController; // Used as the 'string' part in Numbering
  late TextEditingController _startController;
  late TextEditingController _digitController;

  late FocusNode _appendFocus;
  late FocusNode _startFocus;
  late FocusNode _digitFocus;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DirectoryProvider>();
    _appendController = TextEditingController(
        text: provider
            .appendText); // string input acts as string part for numbering
    _startController =
        TextEditingController(text: provider.startNumber.toString());
    _digitController = TextEditingController(text: provider.digits.toString());

    _appendFocus = FocusNode();
    _startFocus = FocusNode();
    _digitFocus = FocusNode();
  }

  @override
  void dispose() {
    _appendController.dispose();
    _startController.dispose();
    _digitController.dispose();
    _appendFocus.dispose();
    _startFocus.dispose();
    _digitFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<DirectoryProvider>();
    final isCompact = provider.isCompactMode;
    final double spacing = isCompact ? 4.0 : 8.0;

    if (provider.appendText != _appendController.text &&
        !_appendFocus.hasFocus) {
      _appendController.text = provider.appendText ?? '';
    }
    if (provider.startNumber.toString() != _startController.text &&
        !_startFocus.hasFocus) {
      _startController.text = provider.startNumber.toString();
    }
    if (provider.digits.toString() != _digitController.text &&
        !_digitFocus.hasFocus) {
      _digitController.text = provider.digits.toString();
    }

    return Padding(
      padding: EdgeInsets.all(spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 文字列入力を最上段へ (UX改善: 最も重要な項目を最初に)
              HistoryTextField(
                controller: _appendController,
                focusNode: _appendFocus,
                history: provider.appendHistory,
                hintText: l10n.labelStringInput,
                isCompact: isCompact,
                onChanged: (val) =>
                    provider.updateRenameSettings(appendText: val),
                onSubmitted: (val, _) =>
                    provider.addHistory(HistoryType.add, val),
              ),

              const SizedBox(height: 12),

              // 2. 連番の詳細設定（開始番号・桁数）を文字列の直下へ
              Row(
                children: [
                  Text(l10n.labelStart, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  NumberSpinBox(
                    value: provider.startNumber,
                    isCompact: isCompact,
                    width: 48,
                    onChanged: (v) =>
                        provider.updateRenameSettings(startNumber: v),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      provider.saveSequenceNumber
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                      color: provider.saveSequenceNumber
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    iconSize: 18,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    tooltip: l10n.labelNumSaveSequenceTooltip,
                    onPressed: () => provider.updateRenameSettings(
                        saveSequenceNumber: !provider.saveSequenceNumber,
                        immediate: true),
                  ),
                  const Spacer(),
                  Text(l10n.labelDigit, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  NumberSpinBox(
                    value: provider.digits,
                    min: 1,
                    max: 10,
                    isCompact: isCompact,
                    width: 48,
                    onChanged: (v) =>
                        provider.updateRenameSettings(digits: v),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 3. 挿入パターンの選択（最後に決定する構成）
              const Divider(),
              const SizedBox(height: 4),
              _buildRadio(context, provider, l10n.labelNumStringNumber,
                  NumberingMode.stringNumber),
              _buildRadio(context, provider, l10n.labelNumOriginalNumber,
                  NumberingMode.originalNumber),
              _buildRadio(context, provider, l10n.labelNumNumberString,
                  NumberingMode.numberString),
              _buildRadio(context, provider, l10n.labelNumNumberOriginal,
                  NumberingMode.numberOriginal),
              _buildRadio(context, provider, l10n.labelNumBaseStringNumber,
                  NumberingMode.baseStringNumber),
              _buildRadio(
                  context,
                  provider,
                  l10n.labelNumBaseStringOriginal,
                  NumberingMode.baseStringOriginal),
              _buildRadio(
                  context,
                  provider,
                  l10n.labelNumRelativeStringNumber,
                  NumberingMode.relativeStringNumber),
              _buildRadio(
                  context,
                  provider,
                  l10n.labelNumRelativeStringOriginal,
                  NumberingMode.relativeStringOriginal),
              _buildRadio(context, provider, l10n.labelNumNumberStringBase,
                  NumberingMode.numberStringBase),
              _buildRadio(
                  context,
                  provider,
                  l10n.labelNumNumberStringRelative,
                  NumberingMode.numberStringRelative),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadio(BuildContext context, DirectoryProvider provider,
      String title, NumberingMode targetMode) {
    return InkWell(
      onTap: () => provider.updateRenameSettings(numberingMode: targetMode),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Radio<NumberingMode>(
              value: targetMode,
              groupValue: provider.numberingMode,
              onChanged: (val) =>
                  provider.updateRenameSettings(numberingMode: val!),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }
}
