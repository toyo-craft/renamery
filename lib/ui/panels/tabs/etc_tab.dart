import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/directory_provider.dart';
import '../../../../core/rename_engine.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EtcTab extends StatefulWidget {
  const EtcTab({super.key});

  @override
  State<EtcTab> createState() => _EtcTabState();
}

class _EtcTabState extends State<EtcTab> {
  final TextEditingController _timestampController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<DirectoryProvider>();
    _timestampController.text = provider.etcTimestamp;
  }

  @override
  void dispose() {
    _timestampController.dispose();
    super.dispose();
  }

  void _updateSettings(
    BuildContext context, {
    RenameMode? mode,
    String? timestamp,
    bool? readOnly,
    bool? hidden,
    bool? archive,
    bool? system,
    bool immediate = false,
  }) {
    context.read<DirectoryProvider>().updateRenameSettings(
          mode: mode,
          etcTimestamp: timestamp,
          etcAttribReadOnly: readOnly,
          etcAttribHidden: hidden,
          etcAttribArchive: archive,
          etcAttribSystem: system,
          immediate: immediate,
        );
  }

  Future<void> _pickDateTime(
      BuildContext context, AppLocalizations l10n) async {
    DateTime initialDate = DateTime.now();
    try {
      if (_timestampController.text.isNotEmpty) {
        // Try parsing current text "yyyy/MM/dd HH:mm"
        final parts = _timestampController.text.split(' ');
        if (parts.length == 2) {
          final dateParts = parts[0].split('/');
          final timeParts = parts[1].split(':');
          if (dateParts.length == 3 && timeParts.length == 2) {
            initialDate = DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
            );
          }
        }
      }
    } catch (_) {
      // Ignore parse errors, use now
    }

    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );

    if (date != null && context.mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
        helpText: l10n.labelEtcPickTime,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          );
        },
      );

      if (time != null && context.mounted) {
        final DateTime result = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        final String formatted = DateFormat('yyyy/MM/dd HH:mm').format(result);
        _timestampController.text = formatted;
        _updateSettings(
          context,
          timestamp: formatted,
          mode: RenameMode.changeTimestamp,
          immediate: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<DirectoryProvider>(
      builder: (context, provider, child) {
        final isCompact = provider.isCompactMode;
        final double spacing = isCompact ? 4.0 : 8.0; // 4dp grid
        final double blockSpacing = isCompact ? 12.0 : 20.0; // 4dp grid

        return SingleChildScrollView(
          padding: EdgeInsets.all(isCompact ? 4.0 : 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timestamp Section
              _buildTimestampSection(
                  context, provider, provider.renameMode, spacing, l10n),

              Divider(
                  height: blockSpacing,
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outlineVariant),

              // Attribute Section
              _buildAttributeSection(
                  context, provider, provider.renameMode, spacing, l10n),

              const SizedBox(height: 24),

              // Caution Message
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.amber.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.labelEtcCautionTitle,
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.labelEtcCautionMessage,
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimestampSection(
      BuildContext context,
      DirectoryProvider provider,
      RenameMode mode,
      double spacing,
      AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            _updateSettings(context,
                mode: RenameMode.changeTimestamp, immediate: true);
          },
          child: Row(
            children: [
              Radio<RenameMode>(
                value: RenameMode.changeTimestamp,
                groupValue: mode,
                onChanged: (val) {
                  _updateSettings(context,
                      mode: RenameMode.changeTimestamp, immediate: true);
                },
              ),
              Text(l10n.labelEtcTimestampChange),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 32, right: 8, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _timestampController,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'yyyy/MM/dd HH:mm',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () => _pickDateTime(context, l10n),
                    tooltip: l10n.labelEtcPickDateTooltip,
                  ),
                ),
                onChanged: (val) {
                  _updateSettings(context,
                      timestamp: val,
                      mode: RenameMode.changeTimestamp, // Auto-select mode
                      immediate: false);
                },
              ),
              const SizedBox(height: 4),
              Text(
                l10n.labelEtcTimestampNote,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttributeSection(
      BuildContext context,
      DirectoryProvider provider,
      RenameMode mode,
      double spacing,
      AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            _updateSettings(context,
                mode: RenameMode.changeAttributes, immediate: true);
          },
          child: Row(
            children: [
              Radio<RenameMode>(
                value: RenameMode.changeAttributes,
                groupValue: mode,
                onChanged: (val) {
                  _updateSettings(context,
                      mode: RenameMode.changeAttributes, immediate: true);
                },
              ),
              Text(l10n.labelEtcAttributeChange),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 32, right: 8, bottom: 8),
          child: Column(
            children: [
              _buildCheckbox(
                  l10n.labelEtcAttribReadOnly, provider.etcAttribReadOnly,
                  (val) {
                _updateSettings(context,
                    readOnly: val,
                    mode: RenameMode.changeAttributes, // Auto-select mode
                    immediate: true);
              }),
              _buildCheckbox(
                  l10n.labelEtcAttribHidden, provider.etcAttribHidden, (val) {
                _updateSettings(context,
                    hidden: val,
                    mode: RenameMode.changeAttributes, // Auto-select mode
                    immediate: true);
              }),
              _buildCheckbox(
                  l10n.labelEtcAttribArchive, provider.etcAttribArchive, (val) {
                _updateSettings(context,
                    archive: val,
                    mode: RenameMode.changeAttributes, // Auto-select mode
                    immediate: true);
              }),
              _buildCheckbox(
                  l10n.labelEtcAttribSystem, provider.etcAttribSystem, (val) {
                _updateSettings(context,
                    system: val,
                    mode: RenameMode.changeAttributes, // Auto-select mode
                    immediate: true);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: value,
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
