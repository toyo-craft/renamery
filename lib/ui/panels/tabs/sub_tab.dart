import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/directory_provider.dart';
import '../../../core/rename_engine.dart';

class SubTab extends StatelessWidget {
  const SubTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectoryProvider>();
    final isCompact = provider.isCompactMode;

    final TextEditingController replaceController = TextEditingController(
      text: provider.replaceText,
    ); // Simple controller for now. Detailed sync is tricky in StatelessWidget.

    return ListView(
      padding: EdgeInsets.all(isCompact ? 8.0 : 16.0),
      children: [
        _buildSectionTitle(context, '拡張子 (Extensions)'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // "Extension Change" Mode Switch
                SwitchListTile(
                  title: const Text('拡張子を変更する'),
                  subtitle: const Text('モード: 拡張子変更'),
                  value: provider.renameMode == RenameMode.extension,
                  onChanged: (val) {
                    if (val) {
                      provider.updateRenameSettings(mode: RenameMode.extension);
                    } else {
                      provider.updateRenameSettings(
                        mode: RenameMode.replace,
                      ); // Revert to default
                    }
                  },
                  dense: isCompact,
                ),
                if (provider.renameMode == RenameMode.extension) ...[
                  const Divider(),
                  const Text('新しい拡張子 (例: jpg)'),
                  SizedBox(height: isCompact ? 4.0 : 8.0),
                  TextField(
                    controller: replaceController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isCompact ? 8.0 : 12.0,
                        horizontal: 8.0,
                      ),
                    ),
                    onChanged: (val) =>
                        provider.updateRenameSettings(replace: val),
                  ),
                ],
                // Removed CheckboxListTile as it's now in the footer
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
