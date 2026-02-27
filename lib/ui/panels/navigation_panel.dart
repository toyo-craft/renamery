import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../../core/directory_provider.dart';
import 'filter_settings_panel.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

class NavigationPanel extends StatefulWidget {
  const NavigationPanel({super.key});

  @override
  State<NavigationPanel> createState() => _NavigationPanelState();
}

class _NavigationPanelState extends State<NavigationPanel> {
  List<Directory> _drives = [];
  List<Directory> _quickAccess = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<DirectoryProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Text(
            l10n.labelNavTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return Scrollbar(
                      controller: _horizontalController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: SingleChildScrollView(
                        controller: _horizontalController,
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: IntrinsicWidth(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Quick Access Section
                                  if (_quickAccess.isNotEmpty) ...[
                                    _buildSectionHeader(
                                        l10n.labelNavQuickAccess),
                                    ..._quickAccess.map(
                                      (dir) => _DirectoryTile(
                                        directory: dir,
                                        customIcon: _getIconForPath(dir.path),
                                        isRoot: true,
                                        isQuickAccess: true,
                                        contextRoot:
                                            dir.path, // I am the root context!
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],

                                  // PC Section
                                  _buildSectionHeader(l10n.labelNavPC),
                                  ..._drives.map(
                                    (dir) => _DirectoryTile(
                                      directory: dir,
                                      customIcon: Icons.computer,
                                      isRoot: true,
                                      isQuickAccess: false,
                                      // Tree nodes don't use contextRoot for now (or could use drive?)
                                    ),
                                  ),
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
        // Filter & Preview Panel
        const FilterSettingsPanel(),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(16, 12, 16, 4), // Increased top padding
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary, // Use primary color
        ),
      ),
    );
  }

  IconData? _getIconForPath(String path) {
    final name = p.basename(path).toLowerCase();
    if (name == 'desktop') return Icons.desktop_windows;
    if (name == 'downloads') return Icons.download;
    if (name == 'documents') return Icons.description;
    if (name == 'pictures') return Icons.image;
    if (name == 'music') return Icons.music_note;
    if (name == 'videos') return Icons.movie;
    if (name == 'onedrive') return Icons.cloud;
    // Check if it looks like a user home
    if (!path.contains(p.separator)) return Icons.home; // Fallback
    return null; // Default folder
  }
}

class _DirectoryTile extends StatefulWidget {
  final Directory directory;
  final IconData? customIcon;
  final bool isRoot;
  final bool isQuickAccess; // New flag
  final String?
      contextRoot; // The root path of the current navigation context (for QA)

  const _DirectoryTile({
    required this.directory,
    this.customIcon,
    this.isRoot = false,
    this.isQuickAccess = false,
    this.contextRoot,
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
        final List<Directory> subDirs =
            entities.whereType<Directory>().toList();

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

  // State to track the last selection path we handled for auto-expansion.
  // This prevents re-expanding a node if the user manually collapses it while the selection is still inside.
  String? _lastHandledSelectionPath;

  @override
  Widget build(BuildContext context) {
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

    final provider = context.watch<DirectoryProvider>();
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
    // We only check for auto-expansion if the current selection hash has changed from what we last handled.
    if (currentDir != null && currentDir.path != _lastHandledSelectionPath) {
      // Allow expansion check
      bool shouldAutoExpand = false;
      bool isDescendant = false;

      try {
        isDescendant = p.isWithin(widget.directory.path, currentDir.path);
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
        // If I am a Tree Node -> Suppress
        if (!widget.isQuickAccess) {
          // Suppress
        }
        // If I am a QA Node
        else {
          // If I am Root, match Context Root
          if (widget.isRoot) {
            if (myContextRoot == activeContextRoot) {
              // I am the Active Root (or containing it?)
              if (isDescendant) shouldAutoExpand = true;
            } else {
              // I am NOT the active root. Suppress.
            }
          } else {
            // I am a Child. My Context Root should match active context root.
            if (myContextRoot == activeContextRoot) {
              if (isDescendant) shouldAutoExpand = true;
            }
          }
        }
      }
      // 2. If Source is Tree
      else if (source == 'tree') {
        // Only expand Tree Nodes
        if (!widget.isQuickAccess && isDescendant) {
          shouldAutoExpand = true;
        }
      }
      // 3. Unknown Source (External/Initial)
      else {
        if (isDescendant) shouldAutoExpand = true;
      }

      // Also expand if Selected (Exact Match) AND valid context
      // Note: Usually exact match doesn't need to expand *itself* (it has no children visible inside it in the tree view usually, unless we want to see subfolders)
      // Standard tree behavior is usually to expand *parents* of selected.
      // But if we want to show children of selected, we expand.
      if (isSelected) {
        shouldAutoExpand = true;
      }

      if (shouldAutoExpand && !_isExpanded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _toggleExpand();
          }
        });
      }

      if (isSelected) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
            );
          }
        });
      }

      // Update the last handled path so we don't force-expand again for this selection
      // We do this inside a post frame callback usually to avoid side effects during build,
      // but since it's just a local state tracker for this build logic, we can set it here
      // (but generally setting state in build is bad).
      // Actually, we should just update the member variable directly without setState since we are IN build.
      _lastHandledSelectionPath = currentDir.path;
    } else if (currentDir == null) {
      _lastHandledSelectionPath = null;
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
              padding: const EdgeInsets.symmetric(
                vertical: 4.0, // Increased vertical padding for touch target
              ),
              child: Row(
                children: [
                  // Indent / Expand Button
                  // We use a fixed width container for alignment
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: InkWell(
                      onTap: _toggleExpand,
                      child: Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  // Folder Icon
                  Icon(icon, size: 20, color: iconColor), // Increased icon size
                  const SizedBox(width: 12), // More gap
                  // Text
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow
                          .visible, // Let it expand in IntrinsicWidth
                      style: TextStyle(
                        fontSize: 13,
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
                const EdgeInsets.only(left: 11.0), // Align with arrow center
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                  width: 1.0,
                ),
              ),
            ),
            padding: const EdgeInsets.only(left: 12.0), // Tree Indentation
            child: Column(
              children: _subDirectories.map((dir) {
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
