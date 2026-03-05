import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:renamery/l10n/generated/app_localizations.dart';

class HistoryTextField extends StatefulWidget {
  final TextEditingController controller;
  final List<String> history;
  final Function(String) onChanged;
  final Function(String, List<String>)? onSubmitted;
  final String label;
  final FocusNode? focusNode;
  final bool isCompact;
  final String? hintText;
  final VoidCallback? onTap;

  const HistoryTextField({
    super.key,
    required this.controller,
    required this.history,
    required this.onChanged,
    this.onSubmitted,
    this.label = '',
    this.focusNode,
    this.isCompact = false,
    this.hintText,
    this.onTap,
  });

  @override
  State<HistoryTextField> createState() => _HistoryTextFieldState();
}

class _HistoryTextFieldState extends State<HistoryTextField> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        if (widget.label.isNotEmpty) ...[
          SizedBox(
              width: 60,
              child: Text(widget.label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: 8),
        ],
        // MenuAnchor is the official Material Design 3 menu component.
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            // We use a Stack to place the MenuAnchor and the TextField as siblings.
            // This is crucial: if TextField is inside MenuAnchor's builder, MenuAnchor
            // intercepts arrow keys (Focus/Shortcuts issue in Flutter Desktop).
            return Stack(
              alignment: Alignment.centerRight,
              children: [
                Positioned.fill(
                  child: MenuAnchor(
                    controller: _menuController,
                    style: MenuStyle(
                      minimumSize: WidgetStateProperty.all(
                          Size(constraints.maxWidth, 0)),
                    ),
                    menuChildren: widget.history.map((String value) {
                      return SizedBox(
                        width: constraints.maxWidth,
                        child: MenuItemButton(
                          onPressed: () {
                            widget.controller.text = value;
                            widget.onChanged(value);
                          },
                          child: Text(value),
                        ),
                      );
                    }).toList(),
                    builder: (BuildContext context, MenuController controller,
                        Widget? child) {
                      return const SizedBox();
                    },
                  ),
                ),
                TextField(
                  focusNode: widget.focusNode,
                  controller: widget.controller,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: widget.hintText,
                    border: const OutlineInputBorder(),
                    contentPadding: EdgeInsets.only(
                      top: widget.isCompact ? 8 : 12,
                      bottom: widget.isCompact ? 8 : 12,
                      left: 8,
                      right: 36, // Padding so text doesn't overlap the icon
                    ),
                  ),
                  onChanged: (val) => widget.onChanged(val),
                  onTap: widget.onTap,
                  onSubmitted: (val) {
                    if (widget.onSubmitted != null) {
                      widget.onSubmitted!(val, widget.history);
                    }
                  },
                ),
                Positioned(
                  right: 4,
                  child: IconButton(
                    icon: const Icon(Symbols.arrow_drop_down),
                    tooltip: l10n.labelHistoryTooltip,
                    onPressed: widget.history.isNotEmpty
                        ? () {
                            if (_menuController.isOpen) {
                              _menuController.close();
                            } else {
                              _menuController.open();
                            }
                          }
                        : null,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
