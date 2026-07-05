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

    return NavigationTreeView.sections(
      horizontalController: _horizontalController,
      verticalController: _verticalScrollController,
      enableHorizontalScroll: false,
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
              for (final directory in provider.savedDirectories)
                _WebDirectoryTile(
                  key: ValueKey('web-nav-root-${directory.id}'),
                  root: directory,
                ),
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
}

class _WebDirectoryTile extends StatefulWidget {
  const _WebDirectoryTile({
    super.key,
    required this.root,
    this.locations = const [],
  });

  final WebSavedDirectory root;
  final List<WebDirectoryLocation> locations;

  bool get isRoot => locations.isEmpty;
  WebDirectoryLocation? get location => isRoot ? null : locations.last;
  String get title => location?.name ?? root.name;
  String get relativePath => location?.relativePath ?? '';
  Object get handle => location?.handle ?? root.handle;

  @override
  State<_WebDirectoryTile> createState() => _WebDirectoryTileState();
}

class _WebDirectoryTileState extends State<_WebDirectoryTile> {
  bool _isExpanded = false;
  bool _isLoadingChildren = false;
  bool _loaded = false;
  String? _errorMessage;
  List<FileModel> _children = [];
  int _lastResetTick = -1;

  Future<void> _toggleExpand() async {
    if (_isExpanded) {
      setState(() => _isExpanded = false);
      return;
    }
    await _expand();
  }

  Future<void> _expand() async {
    if (_isExpanded && (_loaded || _isLoadingChildren)) return;
    if (mounted) {
      setState(() {
        _isExpanded = true;
        _errorMessage = null;
      });
    }
    if (_loaded || _isLoadingChildren) return;

    final provider = context.read<DirectoryProvider>();
    if (mounted) setState(() => _isLoadingChildren = true);
    try {
      final children = await provider.listNavigationDirectoryChildren(
        handle: widget.handle,
        rootPath: widget.root.name,
        relativePath: widget.relativePath,
      );
      if (!mounted) return;
      setState(() {
        _children = children;
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'フォルダを読み込めませんでした。';
        _loaded = false;
      });
    } finally {
      if (mounted) setState(() => _isLoadingChildren = false);
    }
  }

  Future<void> _open() async {
    final provider = context.read<DirectoryProvider>();
    await provider.openNavigationDirectory(widget.root, widget.locations);
    if (!mounted) return;
    if (!_isExpanded) await _expand();
  }

  Future<void> _forgetRoot() async {
    if (!widget.isRoot) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('クイックアクセスから解除しますか？'),
        content: Text(
          '「${widget.root.name}」をReNameryのクイックアクセスから解除します。\n\n'
          'フォルダやファイル自体は削除されません。\n'
          '再度利用する場合は「ローカルフォルダを選択」から追加してください。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('解除'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    final provider = context.read<DirectoryProvider>();
    final success = await provider.forgetSavedDirectory(widget.root);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(success
            ? 'クイックアクセスから解除しました。ファイルは削除されていません。'
            : 'クイックアクセスから解除できませんでした。'),
      ),
    );
  }

  Future<void> _showRootMenu() async {
    if (!widget.isRoot) return;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final box = context.findRenderObject() as RenderBox?;
    if (overlay == null || box == null) return;
    final offset = box.localToGlobal(Offset.zero, ancestor: overlay);
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        offset & box.size,
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem(
          value: 'forget',
          child: Row(
            children: [
              Icon(Icons.link_off, size: 18),
              SizedBox(width: 8),
              Text('解除'),
            ],
          ),
        ),
      ],
    );
    if (result == 'forget') await _forgetRoot();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectoryProvider>();
    final rootIsActive = provider.navigationContextRoot == widget.root.id;
    final currentRelativePath = provider.currentDirectory?.relativePath ?? '';
    final relativePath = widget.relativePath;
    final isSelected = rootIsActive && currentRelativePath == relativePath;
    final isDescendant = rootIsActive &&
        (relativePath.isEmpty
            ? currentRelativePath.isNotEmpty
            : currentRelativePath.startsWith('$relativePath/'));

    if (_lastResetTick != -1 && provider.navTreeResetTick != _lastResetTick) {
      _isExpanded = false;
      _isLoadingChildren = false;
      _loaded = false;
      _children = [];
      _errorMessage = null;
    }
    _lastResetTick = provider.navTreeResetTick;

    if ((isSelected || isDescendant) && !_isExpanded && !_isLoadingChildren) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _expand();
      });
    }

    final rootNeedsPermission = widget.isRoot && !widget.root.isGranted;
    return NavigationExpandableItem(
      title: widget.title,
      icon: rootNeedsPermission ? Symbols.lock : Symbols.folder,
      expandedIcon: Symbols.folder_open,
      enabled: !provider.isLoading,
      selected: isSelected,
      isExpanded: _isExpanded,
      isLoading: _isLoadingChildren,
      iconColor: rootNeedsPermission
          ? Theme.of(context).colorScheme.error
          : Colors.amber,
      semanticLabel: '${widget.title} フォルダ',
      trailing: widget.isRoot
          ? IconButton(
              icon: const Icon(Icons.link_off, size: 16),
              tooltip: 'クイックアクセスから解除',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              onPressed: provider.isLoading ? null : _forgetRoot,
            )
          : null,
      errorMessage: _errorMessage,
      onTap: _open,
      onSecondaryTap: widget.isRoot ? _showRootMenu : null,
      onLongPress: widget.isRoot ? _showRootMenu : null,
      onToggle: _toggleExpand,
      children: [
        for (final child in _children)
          if (child.handle != null)
            _WebDirectoryTile(
              key: ValueKey('web-nav-${widget.root.id}-${child.relativePath}'),
              root: widget.root,
              locations: [
                ...widget.locations,
                WebDirectoryLocation(
                  name: child.originalName,
                  relativePath: child.relativePath,
                  handle: child.handle!,
                ),
              ],
            ),
      ],
    );
  }
}
