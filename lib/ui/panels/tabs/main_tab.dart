import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/directory_provider.dart';
import '../../../core/rename_engine.dart'; // To access RenameMode enum directly if strict typing needed

class MainTab extends StatefulWidget {
  const MainTab({super.key});

  @override
  State<MainTab> createState() => _MainTabState();
}

class _MainTabState extends State<MainTab> {
  late TextEditingController _findController;
  late TextEditingController _replaceController;
  late TextEditingController _appendController;
  late TextEditingController _startController;
  late TextEditingController _digitController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DirectoryProvider>();
    _findController = TextEditingController(text: provider.findText);
    _replaceController = TextEditingController(text: provider.replaceText);
    _appendController = TextEditingController(text: provider.appendText);
    _startController = TextEditingController(
      text: provider.startNumber.toString(),
    );
    _digitController = TextEditingController(text: provider.digits.toString());
  }

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    _appendController.dispose();
    _startController.dispose();
    _digitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectoryProvider>();

    // Update controllers if provider changes externally (e.g. undo/reset)
    // Note: We need to be careful not to overwrite user typing.
    // Ideally, we only update if the value is different and not currently focused,
    // but for MVP this simple sync might be enough if we rely on the provider as source of truth.
    if (provider.findText != _findController.text) {
      _findController.text = provider.findText ?? '';
    }
    if (provider.replaceText != _replaceController.text) {
      _replaceController.text = provider.replaceText ?? '';
    }
    // ... similarly for others if needed, but 'onChanged' updates provider immediately so loop is risk.
    // A better approach for MVP is just to use the controller for the UI and push to provider.

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionTitle(context, '基本操作'),

        Wrap(
          spacing: 8.0,
          children: [
            _buildModeChip(context, RenameMode.replace, '置換', provider),
            _buildModeChip(context, RenameMode.append, '後ろに追加', provider),
            _buildModeChip(context, RenameMode.prepend, '前に追加', provider),
            _buildModeChip(context, RenameMode.numbering, '連番', provider),
          ],
        ),

        const Divider(height: 32),

        if (provider.renameMode == RenameMode.replace) ...[
          const Text('文字列置換'),
          const SizedBox(height: 8),
          TextField(
            controller: _findController,
            decoration: const InputDecoration(
              labelText: '検索文字列 (Find)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (val) => context
                .read<DirectoryProvider>()
                .updateRenameSettings(find: val),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _replaceController,
            decoration: const InputDecoration(
              labelText: '置換文字列 (Replace)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (val) => context
                .read<DirectoryProvider>()
                .updateRenameSettings(replace: val),
          ),
        ],

        if (provider.renameMode == RenameMode.append ||
            provider.renameMode == RenameMode.prepend) ...[
          Text(provider.renameMode == RenameMode.append ? '後ろに追加' : '前に追加'),
          const SizedBox(height: 8),
          TextField(
            controller: _appendController,
            decoration: const InputDecoration(
              labelText: '追加文字列',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (val) => context
                .read<DirectoryProvider>()
                .updateRenameSettings(append: val),
          ),
        ],

        if (provider.renameMode == RenameMode.numbering) ...[
          const Text('連番処理'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _startController,
                  decoration: const InputDecoration(
                    labelText: '開始番号',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => context
                      .read<DirectoryProvider>()
                      .updateRenameSettings(start: int.tryParse(val)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _digitController,
                  decoration: const InputDecoration(
                    labelText: '桁数 (0埋め)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => context
                      .read<DirectoryProvider>()
                      .updateRenameSettings(digit: int.tryParse(val)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }

  Widget _buildModeChip(
    BuildContext context,
    RenameMode mode,
    String label,
    DirectoryProvider provider,
  ) {
    final selected = provider.renameMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (bool selected) {
        if (selected) {
          context.read<DirectoryProvider>().updateRenameSettings(mode: mode);
        }
      },
    );
  }
}
