import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../../core/directory_provider.dart';
import 'filter_settings_panel.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Text(
            'Navigation',
            style: TextStyle(fontWeight: FontWeight.bold),
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
                                    _buildSectionHeader('クイックアクセス'),
                                    ..._quickAccess.map(
                                      (dir) => _DirectoryTile(
                                        directory: dir,
                                        customIcon: _getIconForPath(dir.path),
                                        isRoot:
                                            true, // Special handling usually not needed but good for styling
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],

                                  // PC Section
                                  _buildSectionHeader('PC'),
                                  ..._drives.map(
                                    (dir) => _DirectoryTile(
                                      directory: dir,
                                      customIcon: Icons
                                          .computer, // Drive Icon replacement
                                      isRoot: true,
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

  const _DirectoryTile({
    required this.directory,
    this.customIcon,
    this.isRoot = false,
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
    context.read<DirectoryProvider>().setDirectory(widget.directory);
  }

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

    final isSelected =
        context.watch<DirectoryProvider>().currentDirectory?.path ==
            widget.directory.path;

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
              children: _subDirectories
                  .map((dir) => _DirectoryTile(directory: dir))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
