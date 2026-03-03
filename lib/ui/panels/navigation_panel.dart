import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;
import '../../core/directory_provider.dart';
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
        // Tree view
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

        // Preview Panel (ExpansionTile)
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: ExpansionTile(
            key: const ValueKey('preview_expansion'),
            initiallyExpanded: provider.showPreview,
            onExpansionChanged: (expanded) {
              context
                  .read<DirectoryProvider>()
                  .updateFilterSettings(preview: expanded);
            },
            dense: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 12.0),
            title: Text(
              l10n.labelFilterPreview,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            children: [
              SizedBox(
                height: 150,
                child: _buildPreviewContent(provider, l10n),
              ),
            ],
          ),
        ),
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

  Widget _buildPreviewContent(
      DirectoryProvider provider, AppLocalizations l10n) {
    final selected = provider.currentFiles.where((f) => f.isSelected).toList();

    if (selected.isEmpty) {
      return Center(
          child: Text(l10n.labelPreviewNoSelection,
              style: const TextStyle(color: Colors.grey)));
    }

    if (selected.length > 1) {
      return Center(
          child: Text(l10n.labelPreviewSelectedCount(selected.length),
              style: const TextStyle(color: Colors.grey)));
    }

    final file = selected.first;
    final path = file.entity.path;
    final ext = path.split('.').last.toLowerCase();
    final hasExt = path.contains('.');

    if (hasExt &&
        ['png', 'jpg', 'jpeg', 'bmp', 'gif', 'webp', 'ico'].contains(ext)) {
      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: Image.file(
          File(path),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              Center(child: Text(l10n.labelPreviewImageLoadFailed)),
        ),
      );
    }

    // Text Preview
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: FutureBuilder<String>(
        future: _readTextPreview(File(path), l10n),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2));
          }
          final text = snapshot.data ?? l10n.labelPreviewUnavailable;
          return SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(fontSize: 11, fontFamily: 'Consolas'),
            ),
          );
        },
      ),
    );
  }

  Future<String> _readTextPreview(File file, AppLocalizations l10n) async {
    try {
      final len = await file.length();
      const int limit = 50 * 1024; // 50KB

      if (len > limit) {
        final stream = file.openRead(0, limit);
        final chunks = await stream.toList();
        final bytes = chunks.expand((element) => element).toList();
        String content = utf8.decode(bytes, allowMalformed: true);
        final sizeStr = (len / 1024).toStringAsFixed(1);
        return '$content\n\n${l10n.labelPreviewOmitted(sizeStr)}';
      }
      return await file.readAsString();
    } catch (e) {
      return l10n.labelPreviewBinaryError;
    }
  }
}

// A simple dialog to input a file type filter or clear it
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
            final verticalScrollable =
                Scrollable.maybeOf(context, axis: Axis.vertical);
            final renderObject = context.findRenderObject();
            if (verticalScrollable != null && renderObject != null) {
              verticalScrollable.position.ensureVisible(
                renderObject,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
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
                            ? Symbols.keyboard_arrow_down
                            : Symbols.keyboard_arrow_right,
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
