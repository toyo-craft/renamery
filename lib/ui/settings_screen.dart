import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/directory_provider.dart';
import '../../core/rename_engine.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: Consumer<DirectoryProvider>(
        builder: (context, provider, child) {
          return ListView(
            children: [
              _buildSectionHeader(context, '表示設定'),
              SwitchListTile(
                title: const Text('タッチモード (ゆったり表示)'),
                subtitle: const Text('リストやボタンの間隔を広げます'),
                value: !provider.isCompactMode,
                onChanged: (val) {
                  provider.setCompactMode(!val);
                },
              ),
              const Divider(),
              const Divider(),
              _buildSectionHeader(context, '動作モード (OS設定)'),
              ListTile(
                title: const Text('OSモード'),
                subtitle: Text(
                    'ファイル名の文字制限や、アプリ内での用語（${provider.termFolder}）をOSに合わせて切り替えます'),
                trailing: DropdownButton<ValidationType>(
                  value: provider.validationType,
                  onChanged: (ValidationType? newValue) {
                    if (newValue != null) {
                      provider.updateRenameSettings(validationType: newValue);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: ValidationType.auto,
                      child: Text('自動 (現在のOS)'),
                    ),
                    DropdownMenuItem(
                      value: ValidationType.windows,
                      child: Text('Windows'),
                    ),
                    DropdownMenuItem(
                      value: ValidationType.mac,
                      child: Text('Mac (Finder互換)'),
                    ),
                    DropdownMenuItem(
                      value: ValidationType.linux,
                      child: Text('Linux'),
                    ),
                    DropdownMenuItem(
                      value: ValidationType.ios,
                      child: Text('iOS (iPhone/iPad)'),
                    ),
                    DropdownMenuItem(
                      value: ValidationType.android,
                      child: Text('Android'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              _buildSectionHeader(context, '初期${provider.termFolder}'),
              ListTile(
                title: Text('起動時の${provider.termFolder}'),
                trailing: DropdownButton<InitialDirectoryMode>(
                  value: provider.initialDirectoryMode,
                  onChanged: (InitialDirectoryMode? newValue) {
                    if (newValue != null) {
                      provider.updateInitialDirectorySettings(
                          newValue, provider.fixedInitialDirectory);
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: InitialDirectoryMode.lastUsed,
                      child: const Text('前回終了時の場所'),
                    ),
                    DropdownMenuItem(
                      value: InitialDirectoryMode.fixed,
                      child: Text('指定した${provider.termFolder}'),
                    ),
                  ],
                ),
              ),
              if (provider.initialDirectoryMode == InitialDirectoryMode.fixed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: provider.fixedInitialDirectory,
                          decoration: InputDecoration(
                            hintText: '${provider.termFolder}パスを入力',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          onChanged: (val) {
                            // Simple debounce or update on editing complete might be better but onChanged is responsive
                            provider.updateInitialDirectorySettings(
                                provider.initialDirectoryMode, val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.folder_open),
                        onPressed: () async {
                          final String? directoryPath =
                              await getDirectoryPath();
                          if (directoryPath != null) {
                            provider.updateInitialDirectorySettings(
                                provider.initialDirectoryMode, directoryPath);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              const Divider(),
              _buildSectionHeader(context, 'リセット'),
              ListTile(
                title: const Text('入力履歴を削除'),
                subtitle: const Text('文字列補完などの入力履歴を削除します'),
                leading: const Icon(Icons.history, color: Colors.orange),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('入力履歴の削除'),
                      content: const Text('すべての入力履歴を削除しますか？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('削除'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    provider.clearInputHistory();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('入力履歴を削除しました')),
                      );
                    }
                  }
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('全設定をリセット'),
                subtitle: const Text('リネーム設定やフィルター設定を初期状態に戻します'),
                leading: const Icon(Icons.restore, color: Colors.red),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('設定のリセット'),
                      content: const Text('すべての設定を初期化しますか？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('リセット'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    provider.resetSettings();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('設定をリセットしました')),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
