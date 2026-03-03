import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/directory_provider.dart';
import '../../../../core/rename_engine.dart';
import 'package:renamery/ui/widgets/number_spin_box.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';
import '../../widgets/history_text_field.dart';

class CategoryAddText extends StatefulWidget {
  const CategoryAddText({super.key});

  @override
  State<CategoryAddText> createState() => _CategoryAddTextState();
}

class _CategoryAddTextState extends State<CategoryAddText> {
  late TextEditingController _appendController;
  late TextEditingController _insertController;
  late TextEditingController _dateFormatController;

  late FocusNode _appendFocus;
  late FocusNode _insertFocus;
  late FocusNode _dateFormatFocus;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DirectoryProvider>();
    _appendController = TextEditingController(text: provider.appendText);
    _insertController =
        TextEditingController(text: provider.insertIndex.toString());
    _dateFormatController = TextEditingController(text: provider.dateFormat);

    _appendFocus = FocusNode();
    _insertFocus = FocusNode();
    _dateFormatFocus = FocusNode();
  }

  @override
  void dispose() {
    _appendController.dispose();
    _insertController.dispose();
    _dateFormatController.dispose();
    _appendFocus.dispose();
    _insertFocus.dispose();
    _dateFormatFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<DirectoryProvider>();
    final isCompact = provider.isCompactMode;
    final double spacing = isCompact ? 4.0 : 8.0;

    // Sync controllers if NOT focused
    if (provider.appendText != _appendController.text &&
        !_appendFocus.hasFocus) {
      _appendController.text = provider.appendText ?? '';
    }
    if (provider.insertIndex.toString() != _insertController.text &&
        !_insertFocus.hasFocus) {
      _insertController.text = provider.insertIndex.toString();
    }
    if (provider.dateFormat != _dateFormatController.text &&
        !_dateFormatFocus.hasFocus) {
      _dateFormatController.text = provider.dateFormat;
    }

    return Padding(
      padding: EdgeInsets.all(spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Prepend
          RadioListTile<RenameMode>(
            title:
                Text(l10n.labelOpPrefix, style: const TextStyle(fontSize: 14)),
            value: RenameMode.prepend,
            groupValue: provider.renameMode,
            onChanged: (val) => provider.updateRenameSettings(mode: val!),
            contentPadding: EdgeInsets.zero,
            dense: isCompact,
            visualDensity: isCompact ? VisualDensity.compact : null,
          ),

          // Append
          RadioListTile<RenameMode>(
            title:
                Text(l10n.labelOpSuffix, style: const TextStyle(fontSize: 14)),
            value: RenameMode.append,
            groupValue: provider.renameMode,
            onChanged: (val) => provider.updateRenameSettings(mode: val!),
            contentPadding: EdgeInsets.zero,
            dense: isCompact,
            visualDensity: isCompact ? VisualDensity.compact : null,
          ),

          Padding(
            padding: const EdgeInsets.only(left: 32.0, bottom: 8.0, right: 8.0),
            child: HistoryTextField(
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
          ),

          // Insert at specified index
          RadioListTile<RenameMode>(
            title:
                Text(l10n.labelOpInsert, style: const TextStyle(fontSize: 14)),
            value: RenameMode.insert,
            groupValue: provider.renameMode,
            onChanged: (val) => provider.updateRenameSettings(mode: val!),
            contentPadding: EdgeInsets.zero,
            dense: isCompact,
            visualDensity: isCompact ? VisualDensity.compact : null,
          ),
          if (provider.renameMode == RenameMode.insert)
            Padding(
              padding:
                  const EdgeInsets.only(left: 32.0, bottom: 8.0, right: 8.0),
              child: Row(
                children: [
                  Text(l10n.labelStartDigit),
                  const SizedBox(width: 8),
                  NumberSpinBox(
                    value: provider.insertIndex,
                    isCompact: isCompact,
                    width: 48,
                    onChanged: (v) =>
                        provider.updateRenameSettings(insertIndex: v),
                  ),
                ],
              ),
            ),

          const Divider(),

          // Append Date feature (originally from Extra Tab)
          RadioListTile<RenameMode>(
            title: Text(l10n.labelExtraAppendDate,
                style: const TextStyle(fontSize: 14)),
            value: RenameMode.appendDate,
            groupValue: provider.renameMode,
            onChanged: (val) => provider.updateRenameSettings(mode: val!),
            contentPadding: EdgeInsets.zero,
            dense: isCompact,
            visualDensity: isCompact ? VisualDensity.compact : null,
          ),

          if (provider.renameMode == RenameMode.appendDate)
            Padding(
              padding:
                  const EdgeInsets.only(left: 32.0, bottom: 8.0, right: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _dateFormatController,
                    focusNode: _dateFormatFocus,
                    decoration: InputDecoration(
                      labelText: l10n.labelExtraDateFormatHint,
                      border: const OutlineInputBorder(),
                      isDense: isCompact,
                    ),
                    onChanged: (val) =>
                        provider.updateRenameSettings(dateFormat: val),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('${l10n.labelExtraPosition}:',
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      // Front string
                      InkWell(
                        onTap: () => provider.updateRenameSettings(
                            datePosition: DatePosition.front),
                        child: Row(
                          children: [
                            Radio<DatePosition>(
                              value: DatePosition.front,
                              groupValue: provider.datePosition,
                              onChanged: (val) => provider.updateRenameSettings(
                                  datePosition: val!),
                              visualDensity: VisualDensity.compact,
                            ),
                            Text(l10n.labelExtraFront,
                                style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Back string
                      InkWell(
                        onTap: () => provider.updateRenameSettings(
                            datePosition: DatePosition.back),
                        child: Row(
                          children: [
                            Radio<DatePosition>(
                              value: DatePosition.back,
                              groupValue: provider.datePosition,
                              onChanged: (val) => provider.updateRenameSettings(
                                  datePosition: val!),
                              visualDensity: VisualDensity.compact,
                            ),
                            Text(l10n.labelExtraBack,
                                style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
