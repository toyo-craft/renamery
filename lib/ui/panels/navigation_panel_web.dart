import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

import '../../core/directory_provider_platform.dart';
import '../../core/file_model.dart';
import '../../core/web_file_system_types.dart';
import 'navigation_panel_shell.dart';

class NavigationPanel extends StatefulWidget {
  const NavigationPanel({super.key});

  @override
  State<NavigationPanel> createState() => _NavigationPanelState();
}

class _NavigationPanelState extends State<NavigationPanel> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DirectoryProvider>().loadSavedDirectories();
    });
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavigationPanelShell(treeBuilder: (_) => _buildTreeSection());
  }

  Widget _buildTreeSection() {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<DirectoryProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final folders = provider.directoryEntries
        .where((file) => file.isDirectory)
        .toList(growable: false);

    return NavigationTreeView.sections(
      horizontalController: _horizontalController,
      verticalController: _verticalScrollController,
      header: NavigationSectionHeader(l10n.labelNavQuickAccess),
      sections: [
        NavigationSection(
          items: [_localDirectoryPickerItem(provider)],
          children: [
            if (!provider.isWebFileSystemSupported)
              const NavigationMessageCard(
                'このブラウザはフォルダ連携に対応していません。ChromeまたはEdgeのデスクトップ版をご利用ください。',
                error: true,
              ),
            if (provider.errorMessage != null)
              NavigationMessageCard(
                provider.errorMessage!,
                error: true,
              ),
            if (provider.savedDirectories.isEmpty)
              const NavigationEmptyText('選択済みフォルダはまだありません。')
            else
              ..._savedDirectoryTiles(provider, colorScheme),
          ],
        ),
        NavigationSection(
          title: l10n.labelNavPC,
          items: const [
            NavigationItem.disabled(
              icon: Symbols.desktop_windows,
              title: 'このPC',
              subtitle: 'OSドライブ一覧はブラウザ制約により利用できません',
            ),
            NavigationItem.disabled(
              icon: Symbols.input,
              title: 'パスを入力',
              subtitle: '任意パス移動はWeb版では利用できません',
            ),
          ],
        ),
        if (provider.currentDirectory != null)
          NavigationSection(
            title: '現在のフォルダ',
            children: [
              NavigationBreadcrumbs(
                emptyText: 'フォルダは選択されていません。',
                items: _breadcrumbItems(provider),
              ),
              if (folders.isEmpty)
                const NavigationEmptyText('子フォルダはありません。')
              else
                ..._directoryTiles(folders, colorScheme),
            ],
          ),
      ],
      trailingChildren: const [SizedBox(height: 8)],
    );
  }

  NavigationItem _localDirectoryPickerItem(DirectoryProvider provider) {
    return NavigationItem(
      icon: Symbols.folder_open,
      title: 'ローカルフォルダを選択',
      subtitle: 'Chrome/Edgeでフォルダを開く',
      enabled: !provider.isLoading && provider.isWebFileSystemSupported,
      onTap: provider.pickLocalDirectory,
    );
  }

  NavigationItem _savedDirectoryItem(
    DirectoryProvider provider,
    WebSavedDirectory directory, {
    required ColorScheme colorScheme,
    required int depth,
  }) {
    final current = provider.currentDirectory?.name == directory.name &&
        provider.breadcrumbs.length == 1;
    final subtitle = directory.isGranted ? 'アクセス許可済み' : 'クリックして許可';

    return NavigationItem(
      icon: directory.isGranted ? Symbols.folder : Symbols.lock,
      title: directory.name,
      subtitle: subtitle,
      depth: depth,
      enabled: !provider.isLoading,
      selected: current,
      iconColor: directory.isGranted ? Colors.amber : colorScheme.error,
      semanticLabel: '${directory.name} $subtitle',
      onTap: () => context.read<DirectoryProvider>().openSavedDirectory(
            directory,
          ),
    );
  }

  List<Widget> _savedDirectoryTiles(
    DirectoryProvider provider,
    ColorScheme colorScheme,
  ) {
    return [
      for (final directory in provider.savedDirectories)
        NavigationInfoTile.item(
          _savedDirectoryItem(
            provider,
            directory,
            colorScheme: colorScheme,
            depth: 1,
          ),
        ),
    ];
  }

  List<NavigationBreadcrumbItem> _breadcrumbItems(DirectoryProvider provider) {
    return [
      for (var i = 0; i < provider.breadcrumbs.length; i++)
        NavigationBreadcrumbItem(
          label: provider.breadcrumbs[i].name,
          onPressed: provider.isLoading
              ? null
              : () => context.read<DirectoryProvider>().openBreadcrumb(i),
        ),
    ];
  }

  NavigationItem _directoryItem(
    FileModel folder, {
    required ColorScheme colorScheme,
    required int depth,
  }) {
    return NavigationItem.folder(
      title: folder.originalName,
      subtitle: folder.displayRelativePath.isEmpty
          ? 'フォルダ'
          : folder.displayRelativePath,
      depth: depth,
      enabled: folder.handle != null,
      trailing: Icon(
        Symbols.chevron_right,
        size: 18,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: () => context.read<DirectoryProvider>().openDirectory(folder),
    );
  }

  List<Widget> _directoryTiles(
    List<FileModel> folders,
    ColorScheme colorScheme,
  ) {
    return [
      for (final folder in folders)
        NavigationInfoTile.item(
          _directoryItem(folder, colorScheme: colorScheme, depth: 1),
        ),
    ];
  }
}
