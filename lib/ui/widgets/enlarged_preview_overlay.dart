import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/directory_provider.dart';
import 'preview_window.dart';

class EnlargedPreviewOverlay extends StatefulWidget {
  final bool isMobile;

  const EnlargedPreviewOverlay({super.key, required this.isMobile});

  @override
  State<EnlargedPreviewOverlay> createState() => _EnlargedPreviewOverlayState();
}

class _EnlargedPreviewOverlayState extends State<EnlargedPreviewOverlay> {
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    setState(() {
      _currentScale = _transformationController.value.getMaxScaleOnAxis();
    });
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectoryProvider>();
    final file = provider.enlargedPreviewFile;

    if (!provider.isEnlargedPreviewOpen || file == null) {
      return const SizedBox.shrink();
    }

    if (widget.isMobile) {
      return _buildMobileQuickLook(context, provider);
    } else {
      return _buildDesktopSideSheet(context, provider);
    }
  }

  // 1. Mobile: Quick Look Style
  Widget _buildMobileQuickLook(BuildContext context, DirectoryProvider provider) {
    final file = provider.enlargedPreviewFile!;
    final ext = file.entity.path.contains('.') ? file.entity.path.split('.').last.toLowerCase() : '';
    final bool isDocument = ['txt', 'csv', 'json', 'ini', 'log', 'dart', 'yaml', 'md', 'html', 'xml', 'sql', 'js', 'py', 'css', 'zip'].contains(ext);

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.9),
        child: SafeArea(
          child: Stack(
            children: [
              // Content Layer
              Column(
                children: [
                  // Header
                  _buildHeader(context, provider, isLight: false, isDocument: isDocument),
                  // Main Content Area
                  Expanded(
                    child: GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (_currentScale > 1.1) return; // ズーム中はスワイプによる切り替えを抑制
                        if (details.primaryVelocity! < -500) {
                          provider.nextEnlargedPreview();
                          _resetZoom();
                        } else if (details.primaryVelocity! > 500) {
                          provider.prevEnlargedPreview();
                          _resetZoom();
                        }
                      },
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Hero(
                            tag: 'preview_${file.entity.path}',
                            child: isDocument 
                              ? PreviewWindow(file: file)
                              : InteractiveViewer(
                                  transformationController: _transformationController,
                                  panEnabled: true, 
                                  boundaryMargin: const EdgeInsets.all(100),
                                  minScale: 0.5,
                                  maxScale: 5.0,
                                  child: PreviewWindow(file: file),
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Footer
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '${provider.enlargedPreviewSelectedListIndex + 1} / ${provider.selectedFilesCount}',
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Navigation Buttons Layer (Always at the very front)
              _buildNavButton(
                left: 8,
                icon: Symbols.chevron_left,
                onPressed: () { provider.prevEnlargedPreview(); _resetZoom(); },
                isMobile: true,
              ),
              _buildNavButton(
                right: 8,
                icon: Symbols.chevron_right,
                onPressed: () { provider.nextEnlargedPreview(); _resetZoom(); },
                isMobile: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Desktop: Side Sheet Style
  Widget _buildDesktopSideSheet(BuildContext context, DirectoryProvider provider) {
    final file = provider.enlargedPreviewFile!;
    final ext = file.entity.path.contains('.') ? file.entity.path.split('.').last.toLowerCase() : '';
    final bool isDocument = ['txt', 'csv', 'json', 'ini', 'log', 'dart', 'yaml', 'md', 'html', 'xml', 'sql', 'js', 'py', 'css', 'zip'].contains(ext);

    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(color: Theme.of(context).dividerColor),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(context, provider, isLight: true, isDocument: isDocument),
          // Main Content Area
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: isDocument
                      ? PreviewWindow(file: file)
                      : InteractiveViewer(
                          transformationController: _transformationController,
                          panEnabled: true,
                          boundaryMargin: const EdgeInsets.all(100),
                          minScale: 0.5,
                          maxScale: 5.0,
                          child: PreviewWindow(file: file),
                        ),
                  ),
                ),
                // Navigation Buttons (Arrows)
                _buildNavButton(
                  left: 8,
                  icon: Symbols.chevron_left,
                  onPressed: () { provider.prevEnlargedPreview(); _resetZoom(); },
                  isMobile: false,
                ),
                _buildNavButton(
                  right: 8,
                  icon: Symbols.chevron_right,
                  onPressed: () { provider.nextEnlargedPreview(); _resetZoom(); },
                  isMobile: false,
                ),
              ],
            ),
          ),
          // Info Footer
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${provider.enlargedPreviewSelectedListIndex + 1} / ${provider.selectedFilesCount}',
                  style: const TextStyle(fontSize: 11),
                ),
                Text(
                  file.size,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({double? left, double? right, required IconData icon, required VoidCallback onPressed, required bool isMobile}) {
    // デザインをデスクトップ版に統一しつつ、モバイルでの視認性を考慮
    final Color bgColor = isMobile 
        ? Colors.black.withValues(alpha: 0.4) // モバイル黒背景用：少し濃いめの半透明
        : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    
    final Color iconColor = isMobile ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return Positioned(
      left: left,
      right: right,
      top: 0,
      bottom: 0,
      child: Center(
        child: IconButton(
          icon: Icon(icon, color: iconColor, size: isMobile ? 32 : 24),
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: bgColor,
            shape: const CircleBorder(),
            elevation: isMobile ? 4 : 0,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DirectoryProvider provider, {required bool isLight, required bool isDocument}) {
    final color = isLight ? Theme.of(context).colorScheme.onSurface : Colors.white;
    final shadows = isLight ? null : const [
      Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Symbols.close, color: color),
            onPressed: () => provider.closeEnlargedPreview(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.enlargedPreviewFile?.originalName ?? '',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                shadows: shadows,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildScaleIndicator(context, provider, color, isDocument),
        ],
      ),
    );
  }

  Widget _buildScaleIndicator(BuildContext context, DirectoryProvider provider, Color color, bool isDocument) {
    if (isDocument) {
      return TextButton.icon(
        onPressed: () => provider.setTextPreviewFontSize(13.0),
        icon: Icon(Symbols.text_fields, size: 16, color: color),
        label: Text(
          '${provider.textPreviewFontSize.toInt()}px',
          style: TextStyle(color: color, fontSize: 12),
        ),
      );
    } else {
      if (_currentScale == 1.0) return const SizedBox.shrink();
      return TextButton.icon(
        onPressed: _resetZoom,
        icon: Icon(Symbols.zoom_in, size: 16, color: color),
        label: Text(
          '${(_currentScale * 100).toInt()}%',
          style: TextStyle(color: color, fontSize: 12),
        ),
      );
    }
  }
}
