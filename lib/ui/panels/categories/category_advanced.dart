import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/directory_provider_platform.dart';
import '../../../../core/rename_options.dart';
import 'package:intl/intl.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';

class CategoryAdvanced extends StatefulWidget {
  const CategoryAdvanced({super.key});

  @override
  State<CategoryAdvanced> createState() => _CategoryAdvancedState();
}

class _CategoryAdvancedState extends State<CategoryAdvanced> {
  late TextEditingController _listRenameController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DirectoryProvider>();
    _listRenameController =
        TextEditingController(text: provider.listRenameText);
  }

  @override
  void dispose() {
    _listRenameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<DirectoryProvider>();
    final isCompact = provider.isCompactMode;
    final double spacing = isCompact ? 4.0 : 8.0;

    if (provider.listRenameText != _listRenameController.text) {
      _listRenameController.text = provider.listRenameText;
    }

    return Padding(
      padding: EdgeInsets.all(spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // List Rename (Beta feature)
          if (provider.enableBetaFeatures) ...[
            RadioListTile<RenameMode>(
              title: Text(l10n.labelSubListTitle,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: Text(l10n.labelBetaListRenameHint,
                  style: const TextStyle(fontSize: 11, color: Colors.orange)),
              value: RenameMode.listRename,
              groupValue: provider.renameMode,
              onChanged: (val) => provider.updateRenameSettings(mode: val!),
              contentPadding: EdgeInsets.zero,
              dense: isCompact,
            ),
            if (provider.renameMode == RenameMode.listRename)
              Padding(
                padding:
                    const EdgeInsets.only(left: 32.0, bottom: 8.0, right: 8.0),
                child: TextField(
                  controller: _listRenameController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: l10n.labelSubListModeText,
                    hintText: l10n.labelSubListHint,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (val) =>
                      provider.updateRenameSettings(listText: val),
                ),
              ),
            const Divider(),
          ],

          // Change Timestamp
          RadioListTile<RenameMode>(
            title: Text(l10n.labelEtcTimestampChange,
                style: const TextStyle(fontSize: 14)),
            value: RenameMode.changeTimestamp,
            groupValue: provider.renameMode,
            onChanged: (val) => provider.updateRenameSettings(mode: val!),
            contentPadding: EdgeInsets.zero,
            dense: isCompact,
          ),
          if (provider.renameMode == RenameMode.changeTimestamp)
            Padding(
              padding:
                  const EdgeInsets.only(left: 32.0, bottom: 8.0, right: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      provider.etcTimestamp.isNotEmpty
                          ? provider.etcTimestamp
                          : l10n.labelEtcPickTime,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Symbols.date_range),
                    tooltip: l10n.labelEtcPickDateTooltip,
                    onPressed: () async {
                      DateTime initialDate = DateTime.now();
                      try {
                        if (provider.etcTimestamp.isNotEmpty) {
                          final parts = provider.etcTimestamp.split(' ');
                          if (parts.length == 2) {
                            final dateParts = parts[0].split('/');
                            final timeParts = parts[1].split(':');
                            initialDate = DateTime(
                                int.parse(dateParts[0]),
                                int.parse(dateParts[1]),
                                int.parse(dateParts[2]),
                                int.parse(timeParts[0]),
                                int.parse(timeParts[1]));
                          }
                        }
                      } catch (_) {}

                      final date = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: DateTime(1980),
                        lastDate: DateTime(2100),
                      );
                      if (date != null && context.mounted) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(initialDate),
                        );
                        if (time != null) {
                          final DateTime result = DateTime(date.year,
                              date.month, date.day, time.hour, time.minute);
                          final String formatted =
                              DateFormat('yyyy/MM/dd HH:mm').format(result);
                          provider.updateRenameSettings(
                              etcTimestamp: formatted, immediate: true);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),

          const Divider(),

          // Change Attributes
          RadioListTile<RenameMode>(
            title: Text(l10n.labelEtcAttributeChange,
                style: const TextStyle(fontSize: 14)),
            value: RenameMode.changeAttributes,
            groupValue: provider.renameMode,
            onChanged: (val) => provider.updateRenameSettings(mode: val!),
            contentPadding: EdgeInsets.zero,
            dense: isCompact,
          ),
          if (provider.renameMode == RenameMode.changeAttributes)
            Padding(
              padding:
                  const EdgeInsets.only(left: 32.0, bottom: 8.0, right: 8.0),
              child: Column(
                children: [
                  _buildCheckbox(
                      context,
                      provider,
                      l10n.labelEtcAttribReadOnly,
                      provider.etcAttribReadOnly,
                      (v) => provider.updateRenameSettings(
                          etcAttribReadOnly: v, immediate: true)),
                  _buildCheckbox(
                      context,
                      provider,
                      l10n.labelEtcAttribHidden,
                      provider.etcAttribHidden,
                      (v) => provider.updateRenameSettings(
                          etcAttribHidden: v, immediate: true)),
                  _buildCheckbox(
                      context,
                      provider,
                      l10n.labelEtcAttribArchive,
                      provider.etcAttribArchive,
                      (v) => provider.updateRenameSettings(
                          etcAttribArchive: v, immediate: true)),
                  _buildCheckbox(
                      context,
                      provider,
                      l10n.labelEtcAttribSystem,
                      provider.etcAttribSystem,
                      (v) => provider.updateRenameSettings(
                          etcAttribSystem: v, immediate: true)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(BuildContext context, DirectoryProvider provider,
      String title, bool value, Function(bool) onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: value,
                onChanged: (val) => onChanged(val!),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
