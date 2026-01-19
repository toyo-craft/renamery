import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/directory_provider.dart';
import '../../../../core/rename_engine.dart';

class ExtraTab extends StatefulWidget {
  const ExtraTab({Key? key}) : super(key: key);

  @override
  State<ExtraTab> createState() => _ExtraTabState();
}

class _ExtraTabState extends State<ExtraTab> {
  final TextEditingController _dateFormatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<DirectoryProvider>();
    _dateFormatController.text = provider.dateFormat;

    // Listen to provider updates if needed, usage of Consumer handles rebuilds.
    // If provider updates externally, we might want to sync controller.
    // But usually user inputs here.
  }

  @override
  void dispose() {
    _dateFormatController.dispose();
    super.dispose();
  }

  void _updateSettings(
    BuildContext context, {
    RenameMode? mode,
    String? dateFormat,
    DatePosition? datePosition,
    bool immediate = false,
  }) {
    context.read<DirectoryProvider>().updateRenameSettings(
          mode: mode,
          dateFormat: dateFormat,
          datePosition: datePosition,
          immediate: immediate,
        );
  }

  @override
  Widget build(BuildContext context) {
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
              _buildDateSection(
                  context, provider, provider.renameMode, spacing),
              Divider(
                  height: blockSpacing,
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outlineVariant),
              _buildConversionSection(
                  context, provider, provider.renameMode, spacing),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateSection(BuildContext context, DirectoryProvider provider,
      RenameMode mode, double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Radio for Date Append
        InkWell(
          onTap: () {
            _updateSettings(context,
                mode: RenameMode.appendDate, immediate: true);
          },
          child: Row(
            children: [
              Radio<RenameMode>(
                value: RenameMode.appendDate,
                groupValue: mode,
                onChanged: (val) {
                  _updateSettings(context, mode: val, immediate: true);
                },
              ),
              const Text('ファイルの日付を付加'),
            ],
          ),
        ),

        // Indented Config Area
        Padding(
          padding: const EdgeInsets.only(left: 32, right: 8, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Format Input
              TextField(
                controller: _dateFormatController,
                enabled:
                    true, // Use enabled/disabled based on mode? Or always allow edit?
                // Usually Namery allows edit even if not selected, but highlights when selected.
                // Let's keep enabled.
                decoration: const InputDecoration(
                  labelText: '日付フォーマット (例: yyyymmdd_)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  // If mode is active, update immediate?
                  // Or assume typing implies wanting to use this mode?
                  // Namery behavior: Typing doesn't force mode unless maybe focused?
                  // But usually we update settings.
                  if (mode == RenameMode.appendDate) {
                    _updateSettings(context,
                        dateFormat: val, immediate: false); // Debounce
                  } else {
                    // Just update the stored text without activating mode?
                    // DirectoryProvider stores it regardless.
                    _updateSettings(context, dateFormat: val, immediate: false);
                    // If we want to Auto-Activate:
                    // _updateSettings(context, mode: RenameMode.appendDate, dateFormat: val);
                  }
                },
              ),
              const SizedBox(height: 8),

              // Position Radios (Front / Back)
              Text('位置', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              SegmentedButton<DatePosition>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: DatePosition.front,
                    label: Text('前方'),
                  ),
                  ButtonSegment(
                    value: DatePosition.back,
                    label: Text('後方'),
                  ),
                ],
                selected: {provider.datePosition},
                onSelectionChanged: (Set<DatePosition> newSelection) {
                  _updateSettings(context,
                      datePosition: newSelection.first,
                      mode: RenameMode.appendDate,
                      immediate: true);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConversionSection(BuildContext context,
      DirectoryProvider provider, RenameMode mode, double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSimpleRadio(context, RenameMode.convHalfToFull, '半角を全角にする', mode),
        _buildSimpleRadio(context, RenameMode.convFullToHalf, '全角を半角にする', mode),
        _buildSimpleRadio(
            context, RenameMode.convFullKataToHira, '全角カナをひらがなにする', mode),
        _buildSimpleRadio(
            context, RenameMode.convHiraToFullKata, 'ひらがなを全角カナにする', mode),
        _buildSimpleRadio(
            context, RenameMode.convFullAlphaToHalfAlpha, '全角英字を半角にする', mode),
        _buildSimpleRadio(context, RenameMode.convNumToHalf, '数字を半角にする', mode),
      ],
    );
  }

  Widget _buildSimpleRadio(BuildContext context, RenameMode targetMode,
      String label, RenameMode currentMode) {
    return InkWell(
      onTap: () {
        _updateSettings(context, mode: targetMode, immediate: true);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Radio<RenameMode>(
              value: targetMode,
              groupValue: currentMode,
              visualDensity: VisualDensity.compact,
              onChanged: (val) {
                _updateSettings(context, mode: targetMode, immediate: true);
              },
            ),
            Text(label),
          ],
        ),
      ),
    );
  }
}
