import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
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
    void revealTree() {
      if (mounted && _loading) setState(() => _loading = false);
    }

    final watchdog = Timer(const Duration(seconds: 2), revealTree);

    final drivesTask = DirectoryProvider.getLogicalDrives()
        .timeout(const Duration(seconds: 8), onTimeout: () {
      debugPrint('[NavPanel] Timeout loading logical drives');
      return <Directory>[];
    }).catchError((e, st) {
      debugPrint('[NavPanel] Failed loading logical drives: $e\n$st');
      return <Directory>[];
    }).then((drives) {
      if (!mounted) return;
      setState(() => _drives = drives);
      debugPrint('[NavPanel] Drives: ${drives.map((d) => d.path).toList()}');
      revealTree();
    });

    final quickTask = DirectoryProvider.getQuickAccessDirectories()
        .timeout(const Duration(seconds: 8), onTimeout: () {
      debugPrint('[NavPanel] Timeout loading quick access directories');
      return <Directory>[];
    }).catchError((e, st) {
      debugPrint('[NavPanel] Failed loading quick access directories: $e\n$st');
      return <Directory>[];
    }).then((quick) {
      if (!mounted) return;
      setState(() => _quickAccess = quick);
      revealTree();
    });

    try {
      await Future.wait([drivesTask, quickTask]);
    } catch (e, st) {
      debugPrint('[NavPanel] Failed to load navigation roots: $e\n$st');
    } finally {
      watchdog.cancel();
      revealTree();
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
                        constraints:
                            BoxConstraints(minWidth: constraints.maxWidth),
                        child: IntrinsicWidth(
                          child: SingleChildScrollView(
                            controller: _verticalScrollController,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_quickAccess.isNotEmpty)
                                  Column(
                                    children: _quickAccess
                                        .map((dir) => _DirectoryTile(
                                              directory: dir,
                                              customIcon:
                                                  _getIconForPath(dir.path),
                                              isRoot: true,
                                              isQuickAccess: true,
                                              contextRoot: dir.path,
                                              depth: 1,
                                              quickAccessRoots: _quickAccess
                                                  .map((d) => d.path)
                                                  .toList(),
                                              scrollController:
                                                  _verticalScrollController,
                                            ))
                                        .toList(),
                                  ),
                                _buildSectionHeader(l10n.labelNavPC),
                                ..._drives.map((dir) => _DirectoryTile(
                                      directory: dir,
                                      customIcon: Icons.computer,
                                      isRoot: true,
                                      isQuickAccess: false,
                                      contextRoot: dir.path,
                                      depth: 1,
                                      quickAccessRoots: _quickAccess
                                          .map((d) => d.path)
                                          .toList(),
                                      scrollController:
                                          _verticalScrollController,
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
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: Theme.of(context).dividerColor, width: 0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text(l10n.labelFilterPreview,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(
              child: PreviewWindow(
                  file: provider.currentFiles
                              .where((f) => f.isSelected)
                              .length ==
                          1
                      ? provider.currentFiles.firstWhere((f) => f.isSelected)
                      : null,
                  selectedFiles: provider.currentFiles
                      .where((f) => f.isSelected)
                      .toList())),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title,
      {VoidCallback? onAction, IconData? actionIcon}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary)),
          if (onAction != null && actionIcon != null)
            IconButton(
                icon: Icon(actionIcon, size: 16),
                onPressed: onAction,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                tooltip: '全て折りたたむ'),
        ],
      ),
    );
  }

  IconData? _getIconForPath(String path) {
    final name = p.basename(path).toLowerCase();
    if (name == 'desktop') return Symbols.desktop_windows;
    if (name == 'downloads' || name == 'download') return Symbols.download;
    if (name == 'documents') return Symbols.description;
    if (name == 'pictures' || name == 'dcim') return Symbols.image;
    if (name == 'music') return Symbols.music_note;
    if (name == 'videos' || name == 'movies') return Symbols.movie;
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
  final bool isSuppressingAutoExpand = false;
  final int depth;
  final List<String> quickAccessRoots;
  final ScrollController scrollController;
  final bool forceExpansion;

  const _DirectoryTile({
    required this.directory,
    this.customIcon,
    this.isRoot = false,
    this.isQuickAccess = false,
    this.contextRoot,
    required this.depth,
    required this.quickAccessRoots,
    required this.scrollController,
    this.forceExpansion = false,
  });

  @override
  State<_DirectoryTile> createState() => _DirectoryTileState();
}

class _DirectoryTileState extends State<_DirectoryTile> {
  bool _isExpanded = false;
  List<Directory> _subDirectories = [];
  bool _loaded = false;
  bool _isLoadingChildren = false;

  Future<void> _toggleExpand() async {
    if (_isExpanded) {
      setState(() => _isExpanded = false);
      return;
    }
    setState(() => _isExpanded = true);
    if (!_loaded && !_isLoadingChildren) {
      setState(() => _isLoadingChildren = true);
      try {
        final List<FileSystemEntity> entities =
            await widget.directory.list().timeout(
          const Duration(seconds: 5),
          onTimeout: (sink) {
            debugPrint('[NavDebug] Timeout listing ${widget.directory.path}');
            sink.close();
          },
        ).toList();
        final List<Directory> subDirs = entities
            .where((e) {
              try {
                return FileSystemEntity.typeSync(e.path) ==
                    FileSystemEntityType.directory;
              } catch (_) {
                return e is Directory;
              }
            })
            .map((e) => Directory(e.path))
            .toList();

        subDirs.sort((a, b) => p
            .basename(a.path)
            .toLowerCase()
            .compareTo(p.basename(b.path).toLowerCase()));

        if (mounted) {
          setState(() {
            _subDirectories = subDirs;
            _loaded = true;
          });
        }
      } catch (e) {
        debugPrint('[NavDebug] ERROR listing ${widget.directory.path}: $e');
        if (mounted) {
          setState(() {
            _isExpanded = false;
            _loaded = false;
          });
        }
      } finally {
        if (mounted) {
          setState(() => _isLoadingChildren = false);
        } else {
          _isLoadingChildren = false;
        }
      }
    }
  }

  void _onTap() {
    context.read<DirectoryProvider>().setDirectory(widget.directory,
        source: 'tree', contextRoot: widget.contextRoot);
    if (!_isExpanded) _toggleExpand();
  }

  @override
  void initState() {
    super.initState();
    // Android/ドロワー対策: 初回ビルド時に必ず展開判定が行われるようにバージョンをリセット状態で開始
    _lastHandledSelectionVersion = -1;
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
      _isExpanded = false;
      _lastHandledSelectionVersion = provider.selectionVersion;
    }
    _lastResetTick = provider.navTreeResetTick;
    if (_loaded &&
        provider.treeVersion != _lastTreeVersion &&
        _lastTreeVersion != -1) {
      _loaded = false;
      if (_isExpanded) _toggleExpand();
    }
    _lastTreeVersion = provider.treeVersion;

    String name = p.basename(widget.directory.path);
    if (widget.directory.path.endsWith(':\\')) {
      name = widget.directory.path.replaceAll('\\', '');
    }
    IconData icon =
        widget.customIcon ?? (_isExpanded ? Icons.folder_open : Icons.folder);
    Color iconColor =
        widget.customIcon != null ? Colors.blueGrey : Colors.amber;
    if (widget.directory.path.endsWith(':\\')) {
      icon = Icons.storage;
      iconColor = Colors.grey;
    }

    bool isSelected = false;
    bool isDescendant = false;

    if (currentDir != null) {
      final canC = p.canonicalize(currentDir.path);
      final canM = p.canonicalize(widget.directory.path);

      // パス一致の判定を強化（equalsを使用）
      isSelected = p.equals(canC, canM);
      isDescendant = p.isWithin(canM, canC);

      // Androidのルート /storage/emulated/0 の特殊判定
      if (!isSelected && Platform.isAndroid) {
        if (p.equals(canM, '/storage/emulated/0') &&
            p.equals(canC, '/storage/emulated/0')) {
          isSelected = true;
        }
      }
    }

    if (isSelected || isDescendant) {
      if (source == 'address_bar' || source == null) {
        final bestResult = _calculateBestRouteForPath(currentDir!.path);
        final String myNormalizedRoot = widget.contextRoot != null
            ? p.canonicalize(widget.contextRoot!)
            : '';
        final String bestNormalizedRoot =
            p.canonicalize(bestResult.winningRootPath);
        bool isWinningRoute =
            (widget.isQuickAccess == bestResult.isQuickAccess &&
                p.equals(myNormalizedRoot, bestNormalizedRoot));
        if (!isWinningRoute || widget.depth > bestResult.depth) {
          isSelected = false;
          isDescendant = false;
        }
      } else if (provider.navigationContextRoot != null) {
        final String myNormalizedRoot = widget.contextRoot != null
            ? p.canonicalize(widget.contextRoot!)
            : '';
        final String activeNormalizedRoot =
            p.canonicalize(provider.navigationContextRoot!);
        if (!p.equals(myNormalizedRoot, activeNormalizedRoot)) {
          isSelected = false;
          isDescendant = false;
        }
      }
    }

    // 自動展開のトリガー
    if (currentDir != null &&
        (provider.selectionVersion != _lastHandledSelectionVersion ||
            widget.forceExpansion)) {
      bool shouldAutoExpand = isDescendant || isSelected;
      debugPrint(
          '[NavDebug] Tile: ${widget.directory.path} | isSelected: $isSelected | isDescendant: $isDescendant | shouldAutoExpand: $shouldAutoExpand');

      if (shouldAutoExpand && !_isExpanded && !widget.isSuppressingAutoExpand) {
        debugPrint('[NavDebug] Auto-expanding: ${widget.directory.path}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _toggleExpand();
        });
      }
      if (isSelected && (source == 'address_bar' || source == null)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _ensureVisibleWithRetry(0);
        });
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
            borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16)),
            child: Container(
              decoration: isSelected
                  ? BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16)))
                  : null,
              padding: EdgeInsets.symmetric(
                  vertical: provider.touchMode ? 10.0 : 4.0),
              child: Row(
                children: [
                  SizedBox(
                      width: provider.touchMode ? 32 : 24,
                      height: provider.touchMode ? 32 : 24,
                      child: InkWell(
                          onTap: _toggleExpand,
                          child: Icon(
                              _isExpanded
                                  ? Symbols.keyboard_arrow_down
                                  : Symbols.keyboard_arrow_right,
                              size: provider.touchMode ? 24 : 16,
                              color: Colors.grey))),
                  Icon(icon,
                      size: provider.touchMode ? 28 : 20, color: iconColor),
                  const SizedBox(width: 12),
                  Flexible(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                              fontSize: provider.touchMode ? 15 : 13,
                              color: isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer
                                  : null,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal))),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
        if (_isExpanded)
          Container(
            margin: EdgeInsets.only(left: provider.touchMode ? 15.0 : 11.0),
            decoration: BoxDecoration(
                border: Border(
                    left: BorderSide(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.5),
                        width: 1.0))),
            padding: EdgeInsets.only(left: provider.touchMode ? 16.0 : 12.0),
            child: Column(
              children: [
                if (_isLoadingChildren)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ..._subDirectories
                    .where((dir) => provider.hideSystemFiles
                        ? !p.basename(dir.path).startsWith('.')
                        : true)
                    .map((dir) {
                  // 子に対しても強制展開の必要性を伝える
                  bool childMightExpand = isDescendant || isSelected;
                  return _DirectoryTile(
                      directory: dir,
                      isQuickAccess: widget.isQuickAccess,
                      contextRoot: widget.contextRoot,
                      depth: widget.depth + 1,
                      quickAccessRoots: widget.quickAccessRoots,
                      scrollController: widget.scrollController,
                      forceExpansion: childMightExpand);
                }),
              ],
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
      if (p.equals(canonicalTarget, canonicalRoot)) {
        bestQA =
            _RouteResult(depth: 1, isQuickAccess: true, winningRootPath: root);
        break;
      }
      if (p.isWithin(canonicalRoot, canonicalTarget)) {
        final depth =
            p.split(p.relative(canonicalTarget, from: canonicalRoot)).length +
                1;
        if (bestQA == null || depth < bestQA.depth) {
          bestQA = _RouteResult(
              depth: depth, isQuickAccess: true, winningRootPath: root);
        }
      }
    }
    if (bestQA != null) return bestQA;

    const androidRoot = '/storage/emulated/0';
    String winningRoot = p.rootPrefix(canonicalTarget);
    int depth = p.split(canonicalTarget).length;

    if (!kIsWeb && Platform.isAndroid) {
      if (p.equals(canonicalTarget, androidRoot) ||
          p.isWithin(androidRoot, canonicalTarget)) {
        final relative = p.relative(canonicalTarget, from: androidRoot);
        depth = (p.equals(relative, '.') ? 0 : p.split(relative).length) + 1;
        winningRoot = androidRoot;
      }
    }

    return _RouteResult(
        depth: depth, isQuickAccess: false, winningRootPath: winningRoot);
  }

  void _ensureVisibleWithRetry(int retryCount) {
    if (!mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject == null) {
      if (retryCount < 5) {
        Future.delayed(const Duration(milliseconds: 200),
            () => _ensureVisibleWithRetry(retryCount + 1));
      }
      return;
    }
    Future.delayed(Duration(milliseconds: retryCount == 0 ? 400 : 200), () {
      if (!mounted) return;
      final vs = widget.scrollController;
      if (vs.hasClients) {
        vs.position.ensureVisible(renderObject,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            alignment: 0.5);
      }
      if (retryCount < 2) _ensureVisibleWithRetry(retryCount + 1);
    });
  }
}

class _RouteResult {
  final int depth;
  final bool isQuickAccess;
  final String winningRootPath;
  _RouteResult(
      {required this.depth,
      required this.isQuickAccess,
      required this.winningRootPath});
}
