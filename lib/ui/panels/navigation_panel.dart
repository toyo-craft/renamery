import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../../core/directory_provider.dart';

class NavigationPanel extends StatefulWidget {
  const NavigationPanel({super.key});

  @override
  State<NavigationPanel> createState() => _NavigationPanelState();
}

class _NavigationPanelState extends State<NavigationPanel> {
  List<Directory> _drives = [];
  bool _loadingDrives = true;

  @override
  void initState() {
    super.initState();
    _loadDrives();
  }

  Future<void> _loadDrives() async {
    final drives = await DirectoryProvider.getLogicalDrives();
    setState(() {
      _drives = drives;
      _loadingDrives = false;
    });
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
        Container(
          padding: const EdgeInsets.all(8.0),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Text(
            'Navigation',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: _loadingDrives
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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: _drives
                                    .map(
                                      (dir) => _DirectoryTile(directory: dir),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        // Preview area place holder
        Container(
          height: 150,
          color: Colors.black12,
          child: const Center(child: Text('Image Preview Area')),
        ),
      ],
    );
  }
}

class _DirectoryTile extends StatefulWidget {
  final Directory directory;

  const _DirectoryTile({required this.directory});

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
        final List<FileSystemEntity> entities = await widget.directory
            .list()
            .toList();
        final List<Directory> subDirs = entities
            .whereType<Directory>()
            .toList();
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
        // Handle access denied etc.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Access Denied: ${p.basename(widget.directory.path)}',
              ),
            ),
          );
          setState(() => _isExpanded = false);
        }
      }
    }
  }

  void _onTap() {
    // Set current directory in Provider
    context.read<DirectoryProvider>().setDirectory(widget.directory);
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.directory.path.endsWith(':\\'))
        ? widget.directory.path
        : p.basename(widget.directory.path);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: true,
          leading: Icon(
            _isExpanded ? Icons.folder_open : Icons.folder,
            color: Colors.amber,
          ),
          title: Text(name, softWrap: false, overflow: TextOverflow.visible),
          trailing: IconButton(
            icon: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 16,
            ),
            onPressed: _toggleExpand,
          ),
          onTap: _onTap,
          selected:
              context.watch<DirectoryProvider>().currentDirectory?.path ==
              widget.directory.path,
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
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
