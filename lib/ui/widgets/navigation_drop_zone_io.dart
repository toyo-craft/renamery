import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/directory_provider.dart';

class NavigationDropZone extends StatefulWidget {
  const NavigationDropZone({super.key, required this.child});

  final Widget child;

  @override
  State<NavigationDropZone> createState() => _NavigationDropZoneState();
}

class _NavigationDropZoneState extends State<NavigationDropZone> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectoryProvider>();
    if (!provider.supportsExternalFolderDrop) return widget.child;

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        if (mounted) setState(() => _isDragging = false);
        final message = await _handleDrop(context, details.files);
        if (message == null || !context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_isDragging) const _DropOverlay(),
        ],
      ),
    );
  }

  Future<String?> _handleDrop(BuildContext context, List<dynamic> files) async {
    if (files.length != 1) {
      return 'フォルダを1つだけドロップしてください。';
    }
    final path = files.single.path as String?;
    if (path == null || path.isEmpty) {
      return 'ファイルではなくフォルダを1つだけドロップしてください。';
    }
    return context.read<DirectoryProvider>().openDroppedDirectoryPath(path);
  }
}

class _DropOverlay extends StatelessWidget {
  const _DropOverlay();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.08),
          border: Border.all(color: colorScheme.primary, width: 2),
        ),
        child: Center(
          child: Card(
            color: colorScheme.surface,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text('ここにフォルダをドロップして開く'),
            ),
          ),
        ),
      ),
    );
  }
}
