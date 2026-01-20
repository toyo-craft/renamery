import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/directory_provider.dart';
import '../../../../core/rename_engine.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

class ExtraTab extends StatefulWidget {
  const ExtraTab({super.key});

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
              _buildDateSection(
                  context, provider, provider.renameMode, spacing, l10n),
              Divider(
                  height: blockSpacing,
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outlineVariant),
              _buildConversionSection(
                  context, provider, provider.renameMode, spacing, l10n),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateSection(BuildContext context, DirectoryProvider provider,
      RenameMode mode, double spacing, AppLocalizations l10n) {
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
              Text(l10n.labelExtraAppendDate),
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
                decoration: InputDecoration(
                  labelText: l10n.labelExtraDateFormatHint,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (val) {
                  if (mode == RenameMode.appendDate) {
                    _updateSettings(context,
                        dateFormat: val, immediate: false); // Debounce
                  } else {
                    _updateSettings(context, dateFormat: val, immediate: false);
                  }
                },
              ),
              const SizedBox(height: 8),

              // Position Radios (Front / Back)
              Text(l10n.labelExtraPosition,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              SegmentedButton<DatePosition>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: DatePosition.front,
                    label: Text(l10n.labelExtraFront),
                  ),
                  ButtonSegment(
                    value: DatePosition.back,
                    label: Text(l10n.labelExtraBack),
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

  Widget _buildConversionSection(
      BuildContext context,
      DirectoryProvider provider,
      RenameMode mode,
      double spacing,
      AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSimpleRadio(context, RenameMode.convHalfToFull,
            l10n.labelExtraConvHalfToFull, mode),
        _buildSimpleRadio(context, RenameMode.convFullToHalf,
            l10n.labelExtraConvFullToHalf, mode),
        _buildSimpleRadio(context, RenameMode.convFullKataToHira,
            l10n.labelExtraConvKataToHira, mode),
        _buildSimpleRadio(context, RenameMode.convHiraToFullKata,
            l10n.labelExtraConvHiraToKata, mode),
        _buildSimpleRadio(context, RenameMode.convFullAlphaToHalfAlpha,
            l10n.labelExtraConvFullAlphaToHalf, mode),
        _buildSimpleRadio(context, RenameMode.convNumToHalf,
            l10n.labelExtraConvNumToHalf, mode),
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
