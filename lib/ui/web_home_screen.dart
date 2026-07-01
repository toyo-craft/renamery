import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/directory_provider_platform.dart';
import '../core/web_file_system_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _findController = TextEditingController();
  final _replaceController = TextEditingController();
  final _numberBaseController = TextEditingController(text: 'file_');
  final _numberStartController = TextEditingController(text: '1');
  final _numberDigitsController = TextEditingController(text: '3');

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    _numberBaseController.dispose();
    _numberStartController.dispose();
    _numberDigitsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectoryProvider>();
    final width = MediaQuery.of(context).size.width;
    final narrow = width < 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ReNamery Web'),
        actions: [
          IconButton(
            tooltip: '更新',
            onPressed: provider.currentDirectory == null || provider.isLoading
                ? null
                : provider.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (narrow)
            Column(
              children: [
                SizedBox(height: 220, child: _buildLeftPane(context, provider)),
                Expanded(child: _buildCenterPane(context, provider)),
                SizedBox(
                    height: 280, child: _buildRightPane(context, provider)),
              ],
            )
          else
            Row(
              children: [
                SizedBox(width: 280, child: _buildLeftPane(context, provider)),
                const VerticalDivider(width: 1),
                Expanded(child: _buildCenterPane(context, provider)),
                const VerticalDivider(width: 1),
                SizedBox(width: 320, child: _buildRightPane(context, provider)),
              ],
            ),
          if (provider.isLoading)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildLeftPane(BuildContext context, DirectoryProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed:
                  provider.isLoading ? null : provider.pickLocalDirectory,
              icon: const Icon(Icons.folder_open),
              label: const Text('ローカルフォルダを選択'),
            ),
          ),
          if (!provider.isWebFileSystemSupported)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Card(
                color: colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'このブラウザはフォルダ連携に対応していません。ChromeまたはEdgeのデスクトップ版をご利用ください。',
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                ),
              ),
            ),
          if (provider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Card(
                color: colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    provider.errorMessage!,
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              '許可済みフォルダ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            child: provider.savedDirectories.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('選択済みフォルダはまだありません。'),
                  )
                : ListView.builder(
                    itemCount: provider.savedDirectories.length,
                    itemBuilder: (context, index) {
                      final directory = provider.savedDirectories[index];
                      return _SavedDirectoryTile(directory: directory);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterPane(BuildContext context, DirectoryProvider provider) {
    if (provider.currentDirectory == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Web版では、最初にローカルフォルダを選択してください。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '選択したフォルダ配下だけを左ペインと中央ペインに表示します。前回選択したフォルダはIndexedDBに保存され、次回以降も候補として表示されます。',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed:
                        provider.isLoading ? null : provider.pickLocalDirectory,
                    icon: const Icon(Icons.add),
                    label: const Text('フォルダを選択'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildBreadcrumbs(context, provider),
        _buildFileHeader(context, provider),
        Expanded(
          child: provider.currentFiles.isEmpty
              ? const Center(child: Text('ファイルがありません'))
              : ListView.builder(
                  itemCount: provider.currentFiles.length,
                  itemBuilder: (context, index) {
                    final entry = provider.currentFiles[index];
                    return _FileEntryRow(
                      entry: entry,
                      onRenameTap: () => _showManualRenameDialog(
                        context,
                        provider,
                        entry,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBreadcrumbs(BuildContext context, DirectoryProvider provider) {
    final breadcrumbs = provider.breadcrumbs;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: '一つ上のフォルダへ',
            onPressed: breadcrumbs.length > 1 && !provider.isLoading
                ? provider.goUp
                : null,
            icon: const Icon(Icons.arrow_upward),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < breadcrumbs.length; i++) ...[
                    TextButton(
                      onPressed: provider.isLoading
                          ? null
                          : () => provider.openBreadcrumb(i),
                      child: Text(breadcrumbs[i].name),
                    ),
                    if (i < breadcrumbs.length - 1)
                      const Icon(Icons.chevron_right, size: 18),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileHeader(BuildContext context, DirectoryProvider provider) {
    final selectedCount = provider.selectedFilesCount;
    final allSelected = provider.currentFiles.isNotEmpty &&
        selectedCount == provider.currentFiles.length;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Row(
        children: [
          Checkbox(
            value: allSelected,
            onChanged: (value) => provider.selectAll(value ?? false),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              '現在の名前',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '新しい名前',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const SizedBox(width: 110, child: Text('サイズ')),
          const SizedBox(width: 128, child: Text('更新日')),
          const SizedBox(width: 96),
        ],
      ),
    );
  }

  Widget _buildRightPane(BuildContext context, DirectoryProvider provider) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildExecuteCard(context, provider),
          const SizedBox(height: 12),
          _buildReplaceCard(provider),
          const SizedBox(height: 12),
          _buildNumberingCard(provider),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'フォルダーリネームは後続対応です。まずファイルリネームの安全性と権限復元を安定させてから、小規模フォルダー限定で追加します。',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecuteCard(BuildContext context, DirectoryProvider provider) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('実行', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('選択中: ${provider.selectedFilesCount} 件'),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: provider.canExecute && !provider.isLoading
                  ? () => _executeRename(context, provider)
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('ファイルリネームを実行'),
            ),
            TextButton(
              onPressed: provider.currentFiles.isEmpty
                  ? null
                  : () => provider.resetPreview(selectedOnly: false),
              child: const Text('プレビューをリセット'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplaceCard(DirectoryProvider provider) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('文字列置換', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _findController,
              decoration: const InputDecoration(labelText: '検索文字列'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _replaceController,
              decoration: const InputDecoration(labelText: '置換後文字列'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => provider.applyReplacePreview(
                find: _findController.text,
                replace: _replaceController.text,
                selectedOnly: true,
              ),
              child: const Text('選択中に適用'),
            ),
            OutlinedButton(
              onPressed: () => provider.applyReplacePreview(
                find: _findController.text,
                replace: _replaceController.text,
                selectedOnly: false,
              ),
              child: const Text('全件に適用'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberingCard(DirectoryProvider provider) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('連番', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _numberBaseController,
              decoration: const InputDecoration(labelText: 'ベース名'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _numberStartController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '開始'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _numberDigitsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '桁数'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _applyNumbering(provider, selectedOnly: true),
              child: const Text('選択中に適用'),
            ),
            OutlinedButton(
              onPressed: () => _applyNumbering(provider, selectedOnly: false),
              child: const Text('全件に適用'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showManualRenameDialog(
    BuildContext context,
    DirectoryProvider provider,
    WebFileEntry entry,
  ) async {
    final controller = TextEditingController(text: entry.newName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.isDirectory ? 'フォルダー名' : 'ファイル名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          enabled: entry.isFile,
          decoration: InputDecoration(
            helperText: entry.isDirectory ? 'Web版のフォルダーリネームは後続対応です。' : null,
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: entry.isFile
                ? () => Navigator.pop(context, controller.text)
                : null,
            child: const Text('反映'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) provider.setNewName(entry, result);
  }

  Future<void> _executeRename(
    BuildContext context,
    DirectoryProvider provider,
  ) async {
    final count = await provider.executeRename();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$count 件のファイル名を変更しました。')),
    );
  }

  void _applyNumbering(DirectoryProvider provider,
      {required bool selectedOnly}) {
    provider.applyNumberingPreview(
      baseName: _numberBaseController.text,
      startNumber: int.tryParse(_numberStartController.text) ?? 1,
      digits: int.tryParse(_numberDigitsController.text) ?? 3,
      selectedOnly: selectedOnly,
    );
  }
}

class _SavedDirectoryTile extends StatelessWidget {
  const _SavedDirectoryTile({required this.directory});

  final WebSavedDirectory directory;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DirectoryProvider>();
    return ListTile(
      leading: Icon(
        directory.isGranted ? Icons.folder : Icons.lock_outline,
      ),
      title: Text(directory.name, overflow: TextOverflow.ellipsis),
      subtitle: Text(directory.isGranted ? '許可済み' : '再許可が必要'),
      onTap: () => provider.openSavedDirectory(directory),
    );
  }
}

class _FileEntryRow extends StatelessWidget {
  const _FileEntryRow({required this.entry, required this.onRenameTap});

  final WebFileEntry entry;
  final VoidCallback onRenameTap;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DirectoryProvider>();
    final changed = entry.name != entry.newName;
    final hasError = entry.errorMessage != null;
    return Material(
      color: entry.isSelected
          ? Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.35)
          : null,
      child: InkWell(
        onDoubleTap:
            entry.isDirectory ? () => provider.openDirectory(entry) : null,
        onTap: () => provider.toggleSelection(entry),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              Checkbox(
                value: entry.isSelected,
                onChanged: (_) => provider.toggleSelection(entry),
              ),
              Icon(
                entry.isDirectory ? Icons.folder : Icons.insert_drive_file,
                color: entry.isDirectory ? Colors.amber : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Text(entry.name, overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                flex: 3,
                child: Tooltip(
                  message: entry.errorMessage ?? entry.newName,
                  child: Text(
                    entry.newName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasError
                          ? Theme.of(context).colorScheme.error
                          : changed
                              ? Theme.of(context).colorScheme.primary
                              : null,
                      fontWeight: changed ? FontWeight.bold : null,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 110, child: Text(_formatSize(entry))),
              SizedBox(
                  width: 128, child: Text(_formatDate(entry.lastModified))),
              SizedBox(
                width: 96,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (entry.isDirectory)
                      IconButton(
                        tooltip: '開く',
                        onPressed: () => provider.openDirectory(entry),
                        icon: const Icon(Icons.chevron_right),
                      )
                    else
                      IconButton(
                        tooltip: '名前を編集',
                        onPressed: onRenameTap,
                        icon: const Icon(Icons.edit),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSize(WebFileEntry entry) {
    if (entry.isDirectory) return '';
    final size = entry.size;
    if (size == null) return '';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).ceil()} KB';
    return '${(size / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
