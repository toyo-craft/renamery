import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:provider/provider.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

import '../../core/directory_provider_platform.dart';
import '../../core/file_model.dart';
import '../../core/web_file_system_types.dart';
import '../widgets/preview_window.dart';

class NavigationPanel extends StatefulWidget {
  const NavigationPanel({super.key});

  @override
  State<NavigationPanel> createState() => _NavigationPanelState();
}

class _NavigationPanelState extends State<NavigationPanel> {
  late final MultiSplitViewController _splitterController;
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _splitterController = MultiSplitViewController(
      areas: [
        Area(flex: 0.7, builder: (context, area) => _buildTreeSection()),
        Area(flex: 0.3, builder: (context, area) => _buildPreviewSection()),
      ],
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DirectoryProvider>().loadSavedDirectories();
    });
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalScrollController.dispose();
    _splitterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiSplitViewTheme(
      data: MultiSplitViewThemeData(
        dividerThickness: 6,
        dividerPainter: DividerPainters.grooved1(
          color: Theme.of(context).dividerColor,
          highlightedColor: Theme.of(context).colorScheme.primary,
        ),
      ),
      child: MultiSplitView(
        axis: Axis.vertical,
        controller: _splitterController,
      ),
    );
  }

  Widget _buildTreeSection() {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<DirectoryProvider>();
    final folders = provider.currentFiles
        .where((file) => file.isDirectory)
        .toList(growable: false);

    return SafeArea(
      top: true,
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(l10n.labelNavQuickAccess),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Scrollbar(
                  controller: _verticalScrollController,
                  thumbVisibility: true,
                  child: Scrollbar(
                    controller: _horizontalController,
                    notificationPredicate: (notification) =>
                        notification.depth == 1,
                    child: SingleChildScrollView(
                      controller: _horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minWidth: constraints.maxWidth),
                        child: IntrinsicWidth(
                          child: SingleChildScrollView(
                            controller: _verticalScrollController,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildNavigationTile(
                                  icon: Symbols.folder_open,
                                  title: 'ローカルフォルダを選択',
                                  subtitle: 'Chrome/Edgeでフォルダを開く',
                                  depth: 1,
                                  enabled: !provider.isLoading &&
                                      provider.isWebFileSystemSupported,
                                  onTap: provider.pickLocalDirectory,
                                ),
                                if (!provider.isWebFileSystemSupported)
                                  _buildMessageCard(
                                    'このブラウザはフォルダ連携に対応していません。ChromeまたはEdgeのデスクトップ版をご利用ください。',
                                    error: true,
                                  ),
                                if (provider.errorMessage != null)
                                  _buildMessageCard(
                                    provider.errorMessage!,
                                    error: true,
                                  ),
                                if (provider.savedDirectories.isEmpty)
                                  _buildEmptyText('選択済みフォルダはまだありません。')
                                else
                                  ...provider.savedDirectories.map(
                                    (directory) => _buildSavedDirectoryTile(
                                      directory,
                                      depth: 1,
                                    ),
                                  ),
                                _buildSectionHeader(l10n.labelNavPC),
                                _buildDisabledSystemTile(
                                  icon: Symbols.desktop_windows,
                                  title: 'このPC',
                                  subtitle: 'OSドライブ一覧はブラウザ制約により利用できません',
                                ),
                                _buildDisabledSystemTile(
                                  icon: Symbols.input,
                                  title: 'パスを入力',
                                  subtitle: '任意パス移動はWeb版では利用できません',
                                ),
                                if (provider.currentDirectory != null) ...[
                                  _buildSectionHeader('現在のフォルダ'),
                                  _buildBreadcrumbs(provider),
                                  if (folders.isEmpty)
                                    _buildEmptyText('子フォルダはありません。')
                                  else
                                    ...folders.map(
                                      (folder) => _buildDirectoryTile(
                                        folder,
                                        depth: 1,
                                      ),
                                    ),
                                ],
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<DirectoryProvider>();
    final selected = provider.currentFiles
        .where((file) => file.isSelected)
        .toList(growable: false);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              l10n.labelFilterPreview,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: PreviewWindow(
              file: selected.length == 1 ? selected.first : null,
              selectedFiles: selected,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required int depth,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: enabled,
      label: title,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: EdgeInsets.only(left: 8.0 + depth * 12, right: 8),
              child: SizedBox(
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: enabled
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                enabled ? null : colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          subtitle,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedDirectoryTile(
    WebSavedDirectory directory, {
    required int depth,
  }) {
    final provider = context.watch<DirectoryProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final current = provider.currentDirectory?.name == directory.name &&
        provider.breadcrumbs.length == 1;

    return Material(
      color: current
          ? colorScheme.primaryContainer.withValues(alpha: 0.35)
          : Colors.transparent,
      child: InkWell(
        onTap: provider.isLoading
            ? null
            : () => context.read<DirectoryProvider>().openSavedDirectory(
                  directory,
                ),
        child: Padding(
          padding: EdgeInsets.only(left: 8.0 + depth * 12, right: 8),
          child: SizedBox(
            height: 44,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  directory.isGranted ? Symbols.folder : Symbols.lock,
                  size: 20,
                  color: directory.isGranted ? Colors.amber : colorScheme.error,
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      directory.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      directory.isGranted ? 'アクセス許可済み' : 'クリックして許可',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs(DirectoryProvider provider) {
    if (provider.breadcrumbs.isEmpty) {
      return _buildEmptyText('フォルダは選択されていません。');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 6),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (var i = 0; i < provider.breadcrumbs.length; i++)
            ActionChip(
              avatar: const Icon(Symbols.folder, size: 16),
              label: Text(
                provider.breadcrumbs[i].name,
                overflow: TextOverflow.ellipsis,
              ),
              visualDensity: VisualDensity.compact,
              onPressed: provider.isLoading
                  ? null
                  : () => context.read<DirectoryProvider>().openBreadcrumb(i),
            ),
        ],
      ),
    );
  }

  Widget _buildDirectoryTile(
    FileModel folder, {
    required int depth,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: folder.handle == null
            ? null
            : () => context.read<DirectoryProvider>().openDirectory(folder),
        child: Padding(
          padding: EdgeInsets.only(left: 8.0 + depth * 12, right: 8),
          child: SizedBox(
            height: 40,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Symbols.folder, size: 20, color: Colors.amber),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.originalName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      folder.displayRelativePath.isEmpty
                          ? 'フォルダ'
                          : folder.displayRelativePath,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  Symbols.chevron_right,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyText(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 8, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMessageCard(String message, {required bool error}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        color: error
            ? colorScheme.errorContainer
            : colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            message,
            style: TextStyle(
              color:
                  error ? colorScheme.onErrorContainer : colorScheme.onSurface,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledSystemTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      dense: true,
      enabled: false,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
