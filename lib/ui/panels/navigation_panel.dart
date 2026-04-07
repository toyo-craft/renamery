import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;
import '../../core/directory_provider.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';
import '../widgets/preview_window.dart';

class NavigationPanel extends StatefulWidget {
  const NavigationPanel({super.key});

  @override
  State<NavigationPanel> createState() => _NavigationPanelState();
}

class _NavigationPanelState extends State<NavigationPanel> {
  List<Directory> _drives = [];
  List<Directory> _quickAccess = [];
  bool _loading = true;

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
    _loadData();
  }

  Future<void> _loadData() async {
    final drives = await DirectoryProvider.getLogicalDrives();
    final quick = await DirectoryProvider.getQuickAccessDirectories();
    if (mounted) {
      setState(() { _drives = drives; _quickAccess = quick; _loading = false; });
    }
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
    if (_loading) return const Center(child: CircularProgressIndicator());
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
    return SafeArea(
      top: true,
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_quickAccess.isNotEmpty)
            _buildSectionHeader(
              l10n.labelNavQuickAccess,
              onAction: () => provider.resetNavTree(),
              actionIcon: Symbols.collapse_all,
            ),
          
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Scrollbar(
                  controller: _verticalScrollController,
                  thumbVisibility: true,
                  child: Scrollbar(
                    controller: _horizontalController,
                    notificationPredicate: (n) => n.depth == 1,
                    child: SingleChildScrollView(
                      controller: _horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: IntrinsicWidth(
                          child: SingleChildScrollView(
                            controller: _verticalScrollController,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_quickAccess.isNotEmpty)
                                  KeyedSubtree(
                                    key: ValueKey('qa_${provider.navTreeResetTick}'),
                                    child: Column(
                                      children: _quickAccess.map((dir) => _DirectoryTile(
                                        directory: dir,
                                        customIcon: _getIconForPath(dir.path),
                                        isRoot: true,
                                        isQuickAccess: true,
                                        contextRoot: dir.path,
                                        depth: 1,
                                        quickAccessRoots: _quickAccess.map((d) => d.path).toList(),
                                        scrollController: _verticalScrollController,
                                      )).toList(),
                                    ),
                                  ),
                                _buildSectionHeader(l10n.labelNavPC),
                                ..._drives.map((dir) => _DirectoryTile(
                                  directory: dir,
                                  customIcon: Icons.computer,
                                  isRoot: true,
                                  isQuickAccess: false,
                                  contextRoot: dir.path,
                                  depth: 1,
                                  quickAccessRoots: _quickAccess.map((d) => d.path).toList(),
                                  scrollController: _verticalScrollController,
                                )),
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
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 4), child: Text(l10n.labelFilterPreview, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(child: PreviewWindow(file: provider.currentFiles.where((f) => f.isSelected).length == 1 ? provider.currentFiles.firstWhere((f) => f.isSelected) : null, selectedFiles: provider.currentFiles.where((f) => f.isSelected).toList())),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onAction, IconData? actionIcon}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          if (onAction != null && actionIcon != null)
            IconButton(icon: Icon(actionIcon, size: 16), onPressed: onAction, padding: EdgeInsets.zero, constraints: const BoxConstraints(), visualDensity: VisualDensity.compact, color: Theme.of(context).colorScheme.onSurfaceVariant, tooltip: '全て折りたたむ'),
        ],
      ),
    );
  }

  IconData? _getIconForPath(String path) {
    final name = p.basename(path).toLowerCase();
    if (name == 'desktop') return Symbols.desktop_windows;
    if (name == 'downloads') return Symbols.download;
    if (name == 'documents') return Symbols.description;
    if (name == 'pictures') return Symbols.image;
    if (name == 'music') return Symbols.music_note;
    if (name == 'videos') return Symbols.movie;
    if (name == 'onedrive') return Symbols.cloud;
    if (!path.contains(p.separator)) return Symbols.home;
    return null;
  }
}

class _DirectoryTile extends StatefulWidget {
  final Directory directory;
  final IconData? customIcon;
  final bool isRoot;
  final bool isQuickAccess;
  final String? contextRoot;
  final bool isSuppressingAutoExpand;
  final int depth;
  final List<String> quickAccessRoots;
  final ScrollController scrollController;

  const _DirectoryTile({
    required this.directory,
    this.customIcon,
    this.isRoot = false,
    this.isQuickAccess = false,
    this.contextRoot,
    this.isSuppressingAutoExpand = false,
    required this.depth,
    required this.quickAccessRoots,
    required this.scrollController,
  });

  @override
  State<_DirectoryTile> createState() => _DirectoryTileState();
}

class _DirectoryTileState extends State<_DirectoryTile> {
  bool _isExpanded = false;
  List<Directory> _subDirectories = [];
  bool _loaded = false;

  Future<void> _toggleExpand() async {
    if (_isExpanded) { setState(() => _isExpanded = false); return; }
    setState(() => _isExpanded = true);
    if (!_loaded) {
      try {
        final List<FileSystemEntity> entities = await widget.directory.list().toList();
        final List<Directory> subDirs = entities.where((e) {
          try { return FileSystemEntity.typeSync(e.path) == FileSystemEntityType.directory; } catch (_) { return e is Directory; }
        }).map((e) => Directory(e.path)).toList();
        subDirs.sort((a, b) => p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase()));
        if (mounted) setState(() { _subDirectories = subDirs; _loaded = true; });
      } catch (e) { if (mounted) setState(() => _isExpanded = false); }
    }
  }

  void _onTap() {
    context.read<DirectoryProvider>().setDirectory(widget.directory, source: 'tree', contextRoot: widget.contextRoot);
    if (!_isExpanded) _toggleExpand();
  }

  @override
  void initState() {
    super.initState();
    final provider = context.read<DirectoryProvider>();
    _lastHandledSelectionVersion = provider.selectionVersion;
  }

  int _lastHandledSelectionVersion = -1;
  int _lastTreeVersion = -1;
  int _lastResetTick = -1;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectoryProvider>();
    final currentDir = provider.currentDirectory;
    final source = provider.navigationSource;

    if (_lastResetTick != -1 && provider.navTreeResetTick != _lastResetTick) {
      _isExpanded = false; _lastHandledSelectionVersion = provider.selectionVersion;
    }
    _lastResetTick = provider.navTreeResetTick;
    if (_loaded && provider.treeVersion != _lastTreeVersion && _lastTreeVersion != -1) {
      _loaded = false; if (_isExpanded) _toggleExpand();
    }
    _lastTreeVersion = provider.treeVersion;

    String name = p.basename(widget.directory.path);
    if (widget.directory.path.endsWith(':\\')) name = widget.directory.path.replaceAll('\\', '');
    IconData icon = widget.customIcon ?? (_isExpanded ? Icons.folder_open : Icons.folder);
    Color iconColor = widget.customIcon != null ? Colors.blueGrey : Colors.amber;
    if (widget.directory.path.endsWith(':\\')) { icon = Icons.storage; iconColor = Colors.grey; }

    bool isSelected = currentDir?.path == widget.directory.path;
    bool isDescendant = false;
    if (currentDir != null) {
      try {
        final canC = p.canonicalize(currentDir.path);
        final canM = p.canonicalize(widget.directory.path);
        if (canC == canM) isSelected = true;
        isDescendant = p.isWithin(canM, canC);
      } catch (_) {}
    }

    if (isSelected || isDescendant) {
      if (source == 'address_bar' || source == null) {
        final bestResult = _calculateBestRouteForPath(currentDir!.path);
        bool isWinningRoute = (widget.isQuickAccess == bestResult.isQuickAccess && widget.contextRoot == bestResult.winningRootPath);
        if (!isWinningRoute || widget.depth > bestResult.depth) {
          isSelected = false; isDescendant = false;
        }
      } else if (provider.navigationContextRoot != null && widget.contextRoot != provider.navigationContextRoot) {
        isSelected = false; isDescendant = false;
      }
    }

    if (currentDir != null && provider.selectionVersion != _lastHandledSelectionVersion) {
      bool shouldAutoExpand = isDescendant || isSelected;
      if (shouldAutoExpand && !_isExpanded && !widget.isSuppressingAutoExpand) {
        WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _toggleExpand(); });
      }
      if (isSelected && source == 'address_bar') {
        WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _ensureVisibleWithRetry(0); });
      }
      _lastHandledSelectionVersion = provider.selectionVersion;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0, bottom: 2.0),
          child: InkWell(
            onTap: _onTap,
            borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
            child: Container(
              decoration: isSelected ? BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16))) : null,
              padding: EdgeInsets.symmetric(vertical: provider.touchMode ? 10.0 : 4.0),
              child: Row(
                children: [
                  SizedBox(width: provider.touchMode ? 32 : 24, height: provider.touchMode ? 32 : 24, child: InkWell(onTap: _toggleExpand, child: Icon(_isExpanded ? Symbols.keyboard_arrow_down : Symbols.keyboard_arrow_right, size: provider.touchMode ? 24 : 16, color: Colors.grey))),
                  Icon(icon, size: provider.touchMode ? 28 : 20, color: iconColor),
                  const SizedBox(width: 12),
                  Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.visible, style: TextStyle(fontSize: provider.touchMode ? 15 : 13, color: isSelected ? Theme.of(context).colorScheme.onSecondaryContainer : null, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
        if (_isExpanded)
          Container(
            margin: EdgeInsets.only(left: provider.touchMode ? 15.0 : 11.0),
            decoration: BoxDecoration(border: Border(left: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.5), width: 1.0))),
            padding: EdgeInsets.only(left: provider.touchMode ? 16.0 : 12.0),
            child: Column(
              children: _subDirectories.where((dir) => provider.hideSystemFiles ? !p.basename(dir.path).startsWith('.') : true).map((dir) {
                return _DirectoryTile(directory: dir, isQuickAccess: widget.isQuickAccess, contextRoot: widget.contextRoot, depth: widget.depth + 1, quickAccessRoots: widget.quickAccessRoots, scrollController: widget.scrollController);
              }).toList(),
            ),
          ),
      ],
    );
  }

  _RouteResult _calculateBestRouteForPath(String targetPath) {
    final canonicalTarget = p.canonicalize(targetPath);
    _RouteResult? bestQA;
    for (final root in widget.quickAccessRoots) {
      final canonicalRoot = p.canonicalize(root);
      if (canonicalTarget == canonicalRoot) { bestQA = _RouteResult(depth: 1, isQuickAccess: true, winningRootPath: root); break; }
      if (p.isWithin(canonicalRoot, canonicalTarget)) {
        final depth = p.split(p.relative(canonicalTarget, from: canonicalRoot)).length + 1;
        if (bestQA == null || depth < bestQA.depth) bestQA = _RouteResult(depth: depth, isQuickAccess: true, winningRootPath: root);
      }
    }
    if (bestQA != null) return bestQA;
    return _RouteResult(depth: p.split(canonicalTarget).length, isQuickAccess: false, winningRootPath: p.rootPrefix(canonicalTarget));
  }

  void _ensureVisibleWithRetry(int retryCount) {
    if (!mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject == null) {
      if (retryCount < 5) Future.delayed(const Duration(milliseconds: 200), () => _ensureVisibleWithRetry(retryCount + 1));
      return;
    }
    Future.delayed(Duration(milliseconds: retryCount == 0 ? 400 : 200), () {
      if (!mounted) return;
      final vs = widget.scrollController;
      if (vs.hasClients) vs.position.ensureVisible(renderObject, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic, alignment: 0.5);
      if (retryCount < 2) _ensureVisibleWithRetry(retryCount + 1);
    });
  }
}

class _RouteResult {
  final int depth;
  final bool isQuickAccess;
  final String winningRootPath;
  _RouteResult({required this.depth, required this.isQuickAccess, required this.winningRootPath});
}
