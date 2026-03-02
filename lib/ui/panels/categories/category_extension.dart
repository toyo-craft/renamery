import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/directory_provider.dart';
import '../../../../core/rename_engine.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

class CategoryExtension extends StatefulWidget {
  const CategoryExtension({super.key});

  @override
  State<CategoryExtension> createState() => _CategoryExtensionState();
}

class _CategoryExtensionState extends State<CategoryExtension> {
  late TextEditingController _replaceController;

  late FocusNode _replaceFocus;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DirectoryProvider>();
    _replaceController = TextEditingController(
        text: provider.replaceText); // Used for Extension replace
    _replaceFocus = FocusNode();
  }

  @override
  void dispose() {
    _replaceController.dispose();
    _replaceFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<DirectoryProvider>();
    final isCompact = provider.isCompactMode;
    final double spacing = isCompact ? 4.0 : 8.0;

    if (provider.replaceText != _replaceController.text &&
        !_replaceFocus.hasFocus) {
      _replaceController.text = provider.replaceText ?? '';
    }

    return Padding(
      padding: EdgeInsets.all(spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Change Extension
          RadioListTile<RenameMode>(
            title: Text(l10n.labelOpExtChange,
                style: const TextStyle(fontSize: 14)),
            value: RenameMode.extension,
            groupValue: provider.renameMode,
            onChanged: (val) => provider.updateRenameSettings(mode: val!),
            contentPadding: EdgeInsets.zero,
            dense: isCompact,
          ),

          if (provider.renameMode == RenameMode.extension)
            Padding(
              padding:
                  const EdgeInsets.only(left: 32.0, bottom: 8.0, right: 8.0),
              child: TextField(
                controller: _replaceController,
                focusNode: _replaceFocus,
                decoration: const InputDecoration(
                  labelText: "New Extension (e.g. txt, .png)",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (val) =>
                    provider.updateRenameSettings(replaceText: val),
              ),
            ),

          const Divider(),

          // Add / Remove Extension
          RadioListTile<RenameMode>(
            title:
                Text(l10n.labelOpExtAdd, style: const TextStyle(fontSize: 14)),
            value: RenameMode.extensionAdd,
            groupValue: provider.renameMode,
            onChanged: (val) => provider.updateRenameSettings(mode: val!),
            contentPadding: EdgeInsets.zero,
            dense: isCompact,
          ),

          if (provider.renameMode == RenameMode.extensionAdd)
            Padding(
              padding:
                  const EdgeInsets.only(left: 32.0, bottom: 8.0, right: 8.0),
              child: TextField(
                controller: _replaceController,
                focusNode: _replaceFocus,
                decoration: const InputDecoration(
                  labelText: "Extension to Add",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (val) =>
                    provider.updateRenameSettings(replaceText: val),
              ),
            ),

          RadioListTile<RenameMode>(
            title: Text(l10n.labelOpExtRemove,
                style: const TextStyle(fontSize: 14)),
            value: RenameMode.extensionRemove,
            groupValue: provider.renameMode,
            onChanged: (val) => provider.updateRenameSettings(mode: val!),
            contentPadding: EdgeInsets.zero,
            dense: isCompact,
          ),

          const Divider(),

          // Case Conversions limit to Extension
          RadioListTile<RenameMode>(
            title: Text(l10n.labelOpExtUpper,
                style: const TextStyle(fontSize: 14)),
            value: RenameMode.extensionUpper,
            groupValue: provider.renameMode,
            onChanged: (val) => provider.updateRenameSettings(mode: val!),
            contentPadding: EdgeInsets.zero,
            dense: isCompact,
          ),
          RadioListTile<RenameMode>(
            title: Text(l10n.labelOpExtLower,
                style: const TextStyle(fontSize: 14)),
            value: RenameMode.extensionLower,
            groupValue: provider.renameMode,
            onChanged: (val) => provider.updateRenameSettings(mode: val!),
            contentPadding: EdgeInsets.zero,
            dense: isCompact,
          ),

          const Divider(),

          // extensionToLowerCase Option
          InkWell(
            onTap: () => provider.updateRenameSettings(
                extensionToLowerCase: !provider.extensionToLowerCase,
                immediate: true),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: provider.extensionToLowerCase,
                      onChanged: (val) => provider.updateRenameSettings(
                          extensionToLowerCase: val, immediate: true),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.labelExtensionLower,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
