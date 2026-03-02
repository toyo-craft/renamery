import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/directory_provider.dart';
import '../../../../core/rename_engine.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

class CategoryNumbering extends StatefulWidget {
  const CategoryNumbering({super.key});

  @override
  State<CategoryNumbering> createState() => _CategoryNumberingState();
}

class _CategoryNumberingState extends State<CategoryNumbering> {
  late TextEditingController
      _findController; // Used as the 'string' part in Numbering
  late TextEditingController _startController;
  late TextEditingController _digitController;

  late FocusNode _findFocus;
  late FocusNode _startFocus;
  late FocusNode _digitFocus;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DirectoryProvider>();
    _findController = TextEditingController(
        text: provider
            .findText); // string input acts as string part for numbering
    _startController =
        TextEditingController(text: provider.startNumber.toString());
    _digitController = TextEditingController(text: provider.digits.toString());

    _findFocus = FocusNode();
    _startFocus = FocusNode();
    _digitFocus = FocusNode();
  }

  @override
  void dispose() {
    _findController.dispose();
    _startController.dispose();
    _digitController.dispose();
    _findFocus.dispose();
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

    if (provider.findText != _findController.text && !_findFocus.hasFocus) {
      _findController.text = provider.findText ?? '';
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
          // Numbering Enable Switch
          RadioListTile<RenameMode>(
            title: Text(l10n.labelCategoryNumbering,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            value: RenameMode.numbering,
            groupValue: provider.renameMode,
            onChanged: (val) => provider.updateRenameSettings(mode: val!),
            contentPadding: EdgeInsets.zero,
            dense: isCompact,
          ),

          if (provider.renameMode == RenameMode.numbering)
            Padding(
              padding:
                  const EdgeInsets.only(left: 32.0, bottom: 8.0, right: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(l10n.labelStartDigit),
                      const SizedBox(width: 8),
                      // Start Number
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _startController,
                          focusNode: _startFocus,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            isDense: isCompact,
                          ),
                          onChanged: (val) {
                            final v = int.tryParse(val);
                            if (v != null) {
                              provider.updateRenameSettings(startNumber: v);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text("/"),
                      const SizedBox(width: 8),
                      // Digits
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _digitController,
                          focusNode: _digitFocus,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            isDense: isCompact,
                          ),
                          onChanged: (val) {
                            final v = int.tryParse(val);
                            if (v != null) {
                              provider.updateRenameSettings(digits: v);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Save Sequence Number Toolkit (Optional feature some apps have)
                  InkWell(
                    onTap: () => provider.updateRenameSettings(
                        saveSequenceNumber: !provider.saveSequenceNumber,
                        immediate: true),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: provider.saveSequenceNumber,
                            onChanged: (val) => provider.updateRenameSettings(
                                saveSequenceNumber: val, immediate: true),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.labelNumSaveSequenceTooltip,
                            style: const TextStyle(fontSize: 12),
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Numbering Pattern List
                  const Divider(),
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

                  const SizedBox(height: 16),
                  TextField(
                    controller: _findController,
                    focusNode: _findFocus,
                    decoration: InputDecoration(
                      labelText: l10n.labelStringInput,
                      border: const OutlineInputBorder(),
                      isDense: isCompact,
                    ),
                    onChanged: (val) =>
                        provider.updateRenameSettings(findText: val),
                  ),
                ],
              ),
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
