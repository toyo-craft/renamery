import 'dart:io';
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
      setState(() {
        _drives = drives;
        _quickAccess = quick;
        _loading = false;
      });
    }
  }

  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _splitterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

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
    final provider = context.watch<DirectoryProvider>(); // provider を監視
    return SafeArea(
      top: true,
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed Header for Quick Access
          if (_quickAccess.isNotEmpty)
            _buildSectionHeader(
              l10n.labelNavQuickAccess,
              onAction: () => provider.resetNavTree(), // Provider のメソッドを呼ぶ
              actionIcon: Symbols.collapse_all,
            ),
          
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Scrollbar(
                  controller: _horizontalController,
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: IntrinsicWidth(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Quick Access Items
                              if (_quickAccess.isNotEmpty)
                                KeyedSubtree(
                                  // Provider のカウンタを Key に含めることで確実に再生成
                                  key: ValueKey('qa_${provider.navTreeResetTick}'),
                                  child: Column(
                                    children: _quickAccess.map((dir) => _DirectoryTile(
                                      directory: dir,
                                      customIcon: _getIconForPath(dir.path),
                                      isRoot: true,
                                      isQuickAccess: true,
                                      contextRoot: dir.path,
                                      // 抑制フラグも Provider 側の状態で管理可能
                                    )).toList(),
                                  ),
                                ),
                              
                              // PC Section
                              _buildSectionHeader(l10n.labelNavPC),
                              ..._drives.map((dir) => _DirectoryTile(
                                directory: dir,
                                customIcon: Icons.computer,
                                isRoot: true,
                                isQuickAccess: false,
                              )),
                            ],
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
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
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
              file: provider.currentFiles.where((f) => f.isSelected).length == 1
                  ? provider.currentFiles.firstWhere((f) => f.isSelected)
                  : null,
              selectedFiles: provider.currentFiles.where((f) => f.isSelected).toList(),
            ),
          ),
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
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (onAction != null && actionIcon != null)
            IconButton(
              icon: Icon(actionIcon, size: 16),
              onPressed: onAction,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              tooltip: '全て折りたたむ',
            ),
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
    // Check if it looks like a user home
    if (!path.contains(p.separator)) return Symbols.home; // Fallback
    return null; // Default folder
  }
}
class _FilterTextDialog extends StatefulWidget {
  final String initialValue;
  final bool isSpecific;
  const _FilterTextDialog(
      {required this.initialValue, required this.isSpecific});

  @override
  State<_FilterTextDialog> createState() => _FilterTextDialogState();
}

class _FilterTextDialogState extends State<_FilterTextDialog> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title:
          Text(l10n.labelFilterSpecific, style: const TextStyle(fontSize: 14)),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: InputDecoration(
          hintText: '*.png, *.txt ...',
          isDense: true,
          suffixIcon: IconButton(
            icon: const Icon(Symbols.clear, size: 16),
            onPressed: () => _ctrl.clear(),
          ),
        ),
        onSubmitted: (val) => Navigator.of(context).pop(val),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(''),
          child: Text(l10n.labelFilterAll),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _DirectoryTile extends StatefulWidget {
  final Directory directory;
  final IconData? customIcon;
  final bool isRoot;
  final bool isQuickAccess;
  final String? contextRoot;
  final bool isSuppressingAutoExpand;

  const _DirectoryTile({
    required this.directory,
    this.customIcon,
    this.isRoot = false,
    this.isQuickAccess = false,
    this.contextRoot,
    this.isSuppressingAutoExpand = false,
  });

  @override
  State<_DirectoryTile> createState() => _DirectoryTileState();
}

class _DirectoryTileState extends State<_DirectoryTile> {
  bool _isExpanded = false;
  List<Directory> _subDirectories = [];
  bool _loaded = false;

  Future<void> _toggleExpand() async {
    if (_isExpanded) {
      setState(() => _isExpanded = false);
      return;
    }

    setState(() => _isExpanded = true);

    if (!_loaded) {
      try {
        final List<FileSystemEntity> entities =
            await widget.directory.list().toList();
        
        // Android 等では typeSync で明示的に Directory かを確認する必要がある
        final List<Directory> subDirs = entities.where((entity) {
          try {
            return FileSystemEntity.typeSync(entity.path) == FileSystemEntityType.directory;
          } catch (_) {
            return entity is Directory; // Fallback
          }
        }).map((e) => Directory(e.path)).toList();

        // Sort
        subDirs.sort(
          (a, b) => p
              .basename(a.path)
              .toLowerCase()
              .compareTo(p.basename(b.path).toLowerCase()),
        );

        if (mounted) {
          setState(() {
            _subDirectories = subDirs;
            _loaded = true;
          });
        }
      } catch (e) {
        if (mounted) {
          // Silent fail or small indication, avoid popup spam for loose permissions
          setState(() => _isExpanded = false);
        }
      }
    }
  }

  void _onTap() {
    // Determine the Context Root for this interaction
    // If I am a QA Root, I establish the context using my own path.
    // If I am a child, I use the inherited context.
    String? myContextRoot = widget.contextRoot;
    if (widget.isQuickAccess && widget.isRoot) {
      myContextRoot = widget.directory.path;
    }

    context.read<DirectoryProvider>().setDirectory(
          widget.directory,
          source: widget.isQuickAccess ? 'quick_access' : 'tree',
          contextRoot: myContextRoot,
        );

    if (!_isExpanded) {
      _toggleExpand();
    }
  }

  @override
  void initState() {
    super.initState();
    // モバイル版のドロワーなど、マウント時に現在の選択箇所まで展開させるため、
    // ここで _lastHandledSelectionVersion を現在のバージョンに設定せず、初期値のままにする。
    _lastHandledSelectionVersion = -1; 
  }

  // State to track the last selection path we handled for auto-expansion.
  String? _lastHandledSelectionPath;
  int _lastHandledSelectionVersion = -1;
  int _lastTreeVersion = -1;
  int _lastResetTick = -1;

  @override
  Widget build(BuildContext context) {
    // Check if tree needs to be refreshed
    final provider = context.watch<DirectoryProvider>();
    
    // 一括折りたたみ（リセット）の検知
    if (_lastResetTick != -1 && provider.navTreeResetTick != _lastResetTick) {
      _isExpanded = false;
    }
    _lastResetTick = provider.navTreeResetTick;

    if (_loaded &&
        provider.treeVersion != _lastTreeVersion &&
        _lastTreeVersion != -1) {
      _loaded = false;
      if (_isExpanded) {
        _toggleExpand(); // Reload subdirectories
      }
    }
    _lastTreeVersion = provider.treeVersion;

    // Determine Display Name
    String name = p.basename(widget.directory.path);
    if (widget.directory.path.endsWith(':\\')) {
      name = widget.directory.path.replaceAll('\\', ''); // e.g. "C:"
      // TODO: Get volume label if possible, but package:win32 is heavy.
    }

    // Determine Icon
    IconData icon =
        widget.customIcon ?? (_isExpanded ? Icons.folder_open : Icons.folder);
    Color iconColor =
        widget.customIcon != null ? Colors.blueGrey : Colors.amber;
    if (widget.directory.path.endsWith(':\\')) {
      icon = Icons.storage; // Hard Drive
      iconColor = Colors.grey;
    }

    final currentDir = provider.currentDirectory;
    bool isSelected = currentDir?.path == widget.directory.path;

    // Strict Selection Logic using Context Root
    if (isSelected) {
      final source = provider.navigationSource;
      final activeContextRoot = provider.navigationContextRoot;

      if (source == 'quick_access') {
        // If navigating in QA, we must match the Context Root.
        // My context root is: Inherited (if child) OR Self (if root).
        String? myContextRoot = widget.contextRoot;
        if (widget.isQuickAccess && widget.isRoot) {
          myContextRoot = widget.directory.path;
        }

        // Only select if I am a Quick Access tile AND my context matches active context
        if (!widget.isQuickAccess) {
          isSelected = false;
        } else if (activeContextRoot != null &&
            myContextRoot != activeContextRoot) {
          isSelected = false;
        }
      } else if (source == 'tree') {
        isSelected = !widget.isQuickAccess;
      }
    }

    // Auto-expand Logic
    // 新しい選択イベントが発生したときのみ自動展開を試みる
    if (currentDir != null && provider.selectionVersion != _lastHandledSelectionVersion) {
      // Allow expansion check
      bool shouldAutoExpand = false;
      bool isDescendant = false;

      try {
        // Android/Linux ではパスの正規化が重要
        final String canonicalCurrent = p.canonicalize(currentDir.path);
        final String canonicalMine = p.canonicalize(widget.directory.path);
        
        isDescendant = p.isWithin(canonicalMine, canonicalCurrent);
        isSelected = canonicalCurrent == canonicalMine;
      } catch (e) {
        // Ignore path parsing errors
      }

      final source = provider.navigationSource;
      final activeContextRoot = provider.navigationContextRoot;
      String? myContextRoot = widget.contextRoot;
      if (widget.isQuickAccess && widget.isRoot) {
        myContextRoot = widget.directory.path;
      }

      // 1. If Source is QA
      if (source == 'quick_access') {
        if (widget.isQuickAccess) {
          if (myContextRoot == activeContextRoot && isDescendant) shouldAutoExpand = true;
        }
      }
      // 2. If Source is Tree
      else if (source == 'tree') {
        if (!widget.isQuickAccess && isDescendant) shouldAutoExpand = true;
      }
      // 3. Unknown Source (External / Address Bar / Breadcrumb)
      else {
        // 外部（アドレスバー等）からの入力時は無条件に展開を試みる
        if (isDescendant) shouldAutoExpand = true;
      }

      // Exact match expand
      if (isSelected) shouldAutoExpand = true;

      if (shouldAutoExpand && !_isExpanded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _toggleExpand();
            // 展開後にこのバージョンを「処理済み」として更新
            setState(() {
              _lastHandledSelectionVersion = provider.selectionVersion;
              _lastHandledSelectionPath = currentDir.path;
            });
          }
        });
      } else {
        // 展開不要な場合も、このバージョンを「処理済み」とする
        _lastHandledSelectionVersion = provider.selectionVersion;
        _lastHandledSelectionPath = currentDir.path;
      }

      if (isSelected) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final verticalScrollable = Scrollable.maybeOf(context, axis: Axis.vertical);
            final renderObject = context.findRenderObject();
            if (verticalScrollable != null && renderObject != null) {
              verticalScrollable.position.ensureVisible(renderObject, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            }
          }
        });
      }
    } else if (currentDir == null) {
      _lastHandledSelectionPath = null;
      _lastHandledSelectionVersion = -1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              right: 8.0, bottom: 2.0), // Margin for rounded
          child: InkWell(
            onTap: _onTap,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Container(
              decoration: isSelected
                  ? BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    )
                  : null,
              padding: EdgeInsets.symmetric(
                vertical: provider.touchMode ? 10.0 : 4.0, // タッチモードで行の高さを確保
              ),
              child: Row(
                children: [
                  // Indent / Expand Button
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
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  // Folder Icon
                  Icon(icon, size: provider.touchMode ? 28 : 20, color: iconColor),
                  const SizedBox(width: 12),
                  // Text
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow
                          .visible, // Let it expand in IntrinsicWidth
                      style: TextStyle(
                        fontSize: provider.touchMode ? 15 : 13,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onSecondaryContainer
                            : null,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
        if (_isExpanded)
          Container(
            margin:
                EdgeInsets.only(left: provider.touchMode ? 15.0 : 11.0), // アイコンサイズに合わせて調整
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                  width: 1.0,
                ),
              ),
            ),
            padding: EdgeInsets.only(left: provider.touchMode ? 16.0 : 12.0), // Tree Indentation
            child: Column(
              children: _subDirectories.where((dir) {
                if (provider.hideSystemFiles) {
                  return !p.basename(dir.path).startsWith('.');
                }
                return true;
              }).map((dir) {
                // Pass context root down
                String? childContext = widget.contextRoot;
                if (widget.isQuickAccess && widget.isRoot) {
                  childContext = widget.directory.path;
                }
                return _DirectoryTile(
                  directory: dir,
                  isQuickAccess: widget.isQuickAccess,
                  contextRoot: childContext,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
