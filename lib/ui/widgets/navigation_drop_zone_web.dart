import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

import '../../core/directory_provider_platform.dart';
import '../../core/web_file_system_types.dart';

class NavigationDropZone extends StatefulWidget {
  const NavigationDropZone({super.key, required this.child});

  final Widget child;

  @override
  State<NavigationDropZone> createState() => _NavigationDropZoneState();
}

class _NavigationDropZoneState extends State<NavigationDropZone> {
  final GlobalKey _zoneKey = GlobalKey();
  late final JSFunction _dropCallback;

  @override
  void initState() {
    super.initState();
    _dropCallback = ((JSObject result) {
      _handleExternalDrop(_JsExternalDropResult(result));
    }).toJS;
    _configureDropCallback();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateBounds());
  }

  @override
  void didUpdateWidget(covariant NavigationDropZone oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateBounds());
  }

  @override
  void dispose() {
    try {
      _clearDropCallback(_dropCallback);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateBounds());
    return KeyedSubtree(key: _zoneKey, child: widget.child);
  }

  void _configureDropCallback() {
    try {
      _setDropCallback(_dropCallback);
    } catch (_) {}
  }

  void _updateBounds() {
    if (!mounted) return;
    final renderObject =
        _zoneKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderObject == null || !renderObject.hasSize) return;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    final bottomRight = renderObject.localToGlobal(
      Offset(renderObject.size.width, renderObject.size.height),
    );
    try {
      _setDropBounds(
        topLeft.dx,
        topLeft.dy,
        bottomRight.dx,
        bottomRight.dy,
      );
    } catch (_) {}
  }

  void _handleExternalDrop(_JsExternalDropResult result) {
    if (!mounted) return;
    Future<void>(() async {
      if (!mounted) return;
      final status = result.status;
      if (status == 'accepted') {
        final directory = result.directory;
        if (directory == null) return;
        await context.read<DirectoryProvider>().openDroppedDirectory(
              _savedDirectoryFromJs(directory),
            );
        return;
      }
      final message = _dropMessage(context, result.reason, result.message);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  WebSavedDirectory _savedDirectoryFromJs(_JsDroppedDirectory value) {
    final lastUsedRaw = value.lastUsedAt;
    return WebSavedDirectory(
      id: value.id,
      name: value.name,
      handle: value.handle,
      permission: value.permission,
      lastUsedAt: lastUsedRaw == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastUsedRaw.toInt()),
    );
  }

  String _dropMessage(BuildContext context, String? reason, String? fallback) {
    final l10n = AppLocalizations.of(context)!;
    switch (reason) {
      case 'oneFolder':
        return l10n.labelDropOneFolder;
      case 'unsupported':
        return l10n.labelDropUnsupported;
      case 'folderNotFile':
        return l10n.labelDropFolderNotFile;
      case 'openFailed':
        return fallback?.isNotEmpty == true
            ? fallback!
            : l10n.labelDropOpenFailed;
      default:
        return fallback?.isNotEmpty == true
            ? fallback!
            : l10n.labelDropOneFolder;
    }
  }
}

extension type _JsExternalDropResult(JSObject _) implements JSObject {
  external String get status;
  external String? get reason;
  external String? get message;
  external _JsDroppedDirectory? get directory;
}

extension type _JsDroppedDirectory(JSObject _) implements JSObject {
  external String get id;
  external String get name;
  external JSObject get handle;
  external String get permission;
  external double? get lastUsedAt;
}

@JS('renameryExternalDrop.setBounds')
external void _setDropBounds(
    double left, double top, double right, double bottom);

@JS('renameryExternalDrop.setDropCallback')
external void _setDropCallback(JSFunction callback);

@JS('renameryExternalDrop.clearDropCallback')
external void _clearDropCallback(JSFunction callback);
