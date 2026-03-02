import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/directory_provider.dart';
import '../../../../core/rename_engine.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

class CategoryRemoveText extends StatefulWidget {
  const CategoryRemoveText({super.key});

  @override
  State<CategoryRemoveText> createState() => _CategoryRemoveTextState();
}

class _CategoryRemoveTextState extends State<CategoryRemoveText> {
  late TextEditingController _deleteToController;
  late TextEditingController _startController;
  late TextEditingController _digitController;

  late FocusNode _deleteToFocus;
  late FocusNode _startFocus;
  late FocusNode _digitFocus;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DirectoryProvider>();
    _deleteToController = TextEditingController(text: provider.deleteToText);
    _startController =
        TextEditingController(text: provider.startNumber.toString());
    _digitController = TextEditingController(text: provider.digits.toString());

    _deleteToFocus = FocusNode();
    _startFocus = FocusNode();
    _digitFocus = FocusNode();
  }

  @override
  void dispose() {
    _deleteToController.dispose();
    _startController.dispose();
    _digitController.dispose();
    _deleteToFocus.dispose();
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

    // Sync controllers if NOT focused
    if (provider.deleteToText != _deleteToController.text &&
        !_deleteToFocus.hasFocus) {
      _deleteToController.text = provider.deleteToText ?? '';
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
          // Delete from Start
          RadioListTile<RenameMode>(
            title: Text(l10n.labelOpDeleteStart,
                style: const TextStyle(fontSize: 14)),
            value: RenameMode.deleteStart,
            groupValue: provider.renameMode,
            onChanged: (val) => provider.updateRenameSettings(mode: val!),
            contentPadding: EdgeInsets.zero,
            dense: isCompact,
            visualDensity: isCompact ? VisualDensity.compact : null,
          ),

          // Delete from End
          RadioListTile<RenameMode>(
            title: Text(l10n.labelOpDeleteEnd,
                style: const TextStyle(fontSize: 14)),
            value: RenameMode.deleteEnd,
            groupValue: provider.renameMode,
            onChanged: (val) => provider.updateRenameSettings(mode: val!),
            contentPadding: EdgeInsets.zero,
            dense: isCompact,
            visualDensity: isCompact ? VisualDensity.compact : null,
          ),

          // Digits to delete (for Start/End)
          if (provider.renameMode == RenameMode.deleteStart ||
              provider.renameMode == RenameMode.deleteEnd)
            Padding(
              padding:
                  const EdgeInsets.only(left: 32.0, bottom: 8.0, right: 8.0),
              child: Row(
                children: [
                  Text(l10n.labelStartDigit),
                  const SizedBox(width: 8),
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
            ),

          const Divider(),

          // Delete From Position (Index to Digits)
          RadioListTile<RenameMode>(
            title: Text(l10n.labelOpDeleteFrom,
                style: const TextStyle(fontSize: 14)),
            value: RenameMode.deleteFrom,
            groupValue: provider.renameMode,
            onChanged: (val) => provider.updateRenameSettings(mode: val!),
            contentPadding: EdgeInsets.zero,
            dense: isCompact,
            visualDensity: isCompact ? VisualDensity.compact : null,
          ),

          if (provider.renameMode == RenameMode.deleteFrom)
            Padding(
              padding:
                  const EdgeInsets.only(left: 32.0, bottom: 8.0, right: 8.0),
              child: Row(
                children: [
                  Text(l10n.labelStartDigit),
                  const SizedBox(width: 8),
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
                  Text(l10n
                      .labelStartDigit), // Reusing this string for digits, ideally "Digits"
                  const SizedBox(width: 8),
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
            ),

          const Divider(),

          // Delete text until specified string (Delete Front To -> labelDeleteFront)
          RadioListTile<RenameMode>(
            title: Text(l10n.labelDeleteFront,
                style: const TextStyle(fontSize: 14)),
            value: RenameMode.deleteFrontTo,
            groupValue: provider.renameMode,
            onChanged: (val) => provider.updateRenameSettings(mode: val!),
            contentPadding: EdgeInsets.zero,
            dense: isCompact,
            visualDensity: isCompact ? VisualDensity.compact : null,
          ),

          // Delete text from back until specified string (Delete Back To -> labelDeleteBack)
          RadioListTile<RenameMode>(
            title: Text(l10n.labelDeleteBack,
                style: const TextStyle(fontSize: 14)),
            value: RenameMode.deleteBackTo,
            groupValue: provider.renameMode,
            onChanged: (val) => provider.updateRenameSettings(mode: val!),
            contentPadding: EdgeInsets.zero,
            dense: isCompact,
            visualDensity: isCompact ? VisualDensity.compact : null,
          ),

          if (provider.renameMode == RenameMode.deleteFrontTo ||
              provider.renameMode == RenameMode.deleteBackTo)
            Padding(
              padding:
                  const EdgeInsets.only(left: 32.0, bottom: 8.0, right: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _deleteToController,
                      focusNode: _deleteToFocus,
                      decoration: InputDecoration(
                        labelText: l10n.labelStringInput,
                        border: const OutlineInputBorder(),
                        isDense: isCompact,
                      ),
                      onChanged: (val) =>
                          provider.updateRenameSettings(deleteToText: val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.labelDeleteUntil),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
