import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/directory_provider.dart';
import '../../../../core/rename_engine.dart';
import 'package:intl/intl.dart';

class EtcTab extends StatefulWidget {
  const EtcTab({Key? key}) : super(key: key);

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

  Future<void> _pickDateTime(BuildContext context) async {
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
      locale: const Locale(
          'ja', 'JP'), // Optional: Localize if needed, usually auto
    );

    if (date != null && context.mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
        helpText: '時刻を選択してください',
        builder: (context, child) {
          return Localizations.override(
            context: context,
            locale: const Locale('ja', 'JP'),
            child: MediaQuery(
              data:
                  MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            ),
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
    return Consumer<DirectoryProvider>(
      builder: (context, provider, child) {
        final mode = provider.renameMode;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timestamp Section
              _buildTimestampSection(context, provider, mode),

              const Divider(height: 24, thickness: 1),

              // Attribute Section
              _buildAttributeSection(context, provider, mode),

              const SizedBox(height: 24),

              // Caution Message
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
                            '取り消し操作不能',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'このカテゴリ（タイムスタンプ・属性）の変更は、アンドゥ機能で元に戻すことができません。慎重に操作してください。',
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
      BuildContext context, DirectoryProvider provider, RenameMode mode) {
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
              const Text('タイムスタンプを変更する'),
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
                    onPressed: () => _pickDateTime(context),
                    tooltip: '日付と時刻を選択',
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
              const Text(
                '(Ex 2002/03/30 17:30 のように指定します。)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttributeSection(
      BuildContext context, DirectoryProvider provider, RenameMode mode) {
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
              const Text('属性を変更する'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 32, right: 8, bottom: 8),
          child: Column(
            children: [
              _buildCheckbox('ReadOnly', provider.etcAttribReadOnly, (val) {
                _updateSettings(context,
                    readOnly: val,
                    mode: RenameMode.changeAttributes, // Auto-select mode
                    immediate: true);
              }),
              _buildCheckbox('Hidden', provider.etcAttribHidden, (val) {
                _updateSettings(context,
                    hidden: val,
                    mode: RenameMode.changeAttributes, // Auto-select mode
                    immediate: true);
              }),
              _buildCheckbox('Archive', provider.etcAttribArchive, (val) {
                _updateSettings(context,
                    archive: val,
                    mode: RenameMode.changeAttributes, // Auto-select mode
                    immediate: true);
              }),
              _buildCheckbox('System', provider.etcAttribSystem, (val) {
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
