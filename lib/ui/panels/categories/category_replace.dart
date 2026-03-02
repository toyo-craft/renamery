import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/directory_provider.dart';
import '../../../../core/rename_engine.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

class CategoryReplaceConvert extends StatefulWidget {
  const CategoryReplaceConvert({super.key});

  @override
  State<CategoryReplaceConvert> createState() => _CategoryReplaceConvertState();
}

class _CategoryReplaceConvertState extends State<CategoryReplaceConvert> {
  late TextEditingController _findController;
  late TextEditingController _replaceController;

  late FocusNode _findFocus;
  late FocusNode _replaceFocus;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DirectoryProvider>();
    _findController = TextEditingController(text: provider.findText);
    _replaceController = TextEditingController(text: provider.replaceText);

    _findFocus = FocusNode();
    _replaceFocus = FocusNode();
  }

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    _findFocus.dispose();
    _replaceFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<DirectoryProvider>();
    final isCompact = provider.isCompactMode;
    final double spacing = isCompact ? 4.0 : 8.0;

    // Sync controllers if NOT focused
    if (provider.findText != _findController.text && !_findFocus.hasFocus) {
      _findController.text = provider.findText ?? '';
    }
    if (provider.replaceText != _replaceController.text &&
        !_replaceFocus.hasFocus) {
      _replaceController.text = provider.replaceText ?? '';
    }

    return Padding(
      padding: EdgeInsets.all(spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // String Replace
          RadioListTile<RenameMode>(
            title: Text(l10n.labelStringInput,
                style: const TextStyle(fontSize: 14)),
            value: RenameMode.replace,
            groupValue: provider.renameMode,
            onChanged: (val) => provider.updateRenameSettings(mode: val!),
            contentPadding: EdgeInsets.zero,
            dense: isCompact,
            visualDensity: isCompact ? VisualDensity.compact : null,
          ),

          if (provider.renameMode == RenameMode.replace)
            Padding(
              padding:
                  const EdgeInsets.only(left: 32.0, bottom: 8.0, right: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _findController,
                          focusNode: _findFocus,
                          decoration: InputDecoration(
                            labelText: l10n.labelFindHint,
                            border: const OutlineInputBorder(),
                            isDense: isCompact,
                          ),
                          onChanged: (val) =>
                              provider.updateRenameSettings(findText: val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(l10n.labelReplaceFrom),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replaceController,
                          focusNode: _replaceFocus,
                          decoration: InputDecoration(
                            labelText: l10n.labelReplaceHint,
                            border: const OutlineInputBorder(),
                            isDense: isCompact,
                          ),
                          onChanged: (val) =>
                              provider.updateRenameSettings(replaceText: val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(l10n.labelReplaceTo),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => provider.updateRenameSettings(
                        useRegex: !provider.useRegex, immediate: true),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: provider.useRegex,
                            onChanged: (val) => provider.updateRenameSettings(
                                useRegex: val, immediate: true),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.labelRegex,
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const Divider(),

          // Case Conversions
          RadioListTile<RenameMode>(
            title:
                Text(l10n.labelOpUpper, style: const TextStyle(fontSize: 14)),
            value: RenameMode.upper,
            groupValue: provider.renameMode,
            onChanged: (val) => provider.updateRenameSettings(mode: val!),
            contentPadding: EdgeInsets.zero,
            dense: isCompact,
          ),
          RadioListTile<RenameMode>(
            title:
                Text(l10n.labelOpLower, style: const TextStyle(fontSize: 14)),
            value: RenameMode.lower,
            groupValue: provider.renameMode,
            onChanged: (val) => provider.updateRenameSettings(mode: val!),
            contentPadding: EdgeInsets.zero,
            dense: isCompact,
          ),
          RadioListTile<RenameMode>(
            title: Text(l10n.labelOpCapitalize,
                style: const TextStyle(fontSize: 14)),
            value: RenameMode.capitalize,
            groupValue: provider.renameMode,
            onChanged: (val) => provider.updateRenameSettings(mode: val!),
            contentPadding: EdgeInsets.zero,
            dense: isCompact,
          ),
          RadioListTile<RenameMode>(
            title: Text(l10n.labelSubFormatProperCase,
                style: const TextStyle(fontSize: 14)),
            value: RenameMode.formatProperCase,
            groupValue: provider.renameMode,
            onChanged: (val) => provider.updateRenameSettings(mode: val!),
            contentPadding: EdgeInsets.zero,
            dense: isCompact,
          ),

          const Divider(),

          // Text Type Conversions (from ExtraTab)
          _buildExtraRadio(context, provider, l10n.labelExtraConvHalfToFull,
              RenameMode.convHalfToFull),
          _buildExtraRadio(context, provider, l10n.labelExtraConvFullToHalf,
              RenameMode.convFullToHalf),
          _buildExtraRadio(context, provider, l10n.labelExtraConvKataToHira,
              RenameMode.convFullKataToHira),
          _buildExtraRadio(context, provider, l10n.labelExtraConvHiraToKata,
              RenameMode.convHiraToFullKata),
          _buildExtraRadio(
              context,
              provider,
              l10n.labelExtraConvFullAlphaToHalf,
              RenameMode.convFullAlphaToHalfAlpha),
          _buildExtraRadio(context, provider, l10n.labelExtraConvNumToHalf,
              RenameMode.convNumToHalf),
        ],
      ),
    );
  }

  Widget _buildExtraRadio(BuildContext context, DirectoryProvider provider,
      String title, RenameMode targetMode) {
    return RadioListTile<RenameMode>(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: targetMode,
      groupValue: provider.renameMode,
      onChanged: (val) => provider.updateRenameSettings(mode: val!),
      contentPadding: EdgeInsets.zero,
      dense: provider.isCompactMode,
      visualDensity: provider.isCompactMode ? VisualDensity.compact : null,
    );
  }
}
