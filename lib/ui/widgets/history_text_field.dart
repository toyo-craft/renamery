import 'package:flutter/material.dart';

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
            return MenuAnchor(
              controller: _menuController,
              style: MenuStyle(
                minimumSize:
                    WidgetStateProperty.all(Size(constraints.maxWidth, 0)),
              ),
              menuChildren: widget.history.map((String value) {
                // Force menu item (and thus the menu) to have the exact width of the TextField
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
                // We use a Stack to place the dropdown icon visually inside the TextField.
                // This completely avoids the Flutter Desktop TextField.suffixIcon tap interception bug,
                // while preserving the perfect MD3 "Exposed Dropdown Menu" visual design.
                return Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    TextField(
                      focusNode: widget.focusNode,
                      controller: widget.controller,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: widget.hintText,
                        contentPadding: EdgeInsets.only(
                          top: widget.isCompact ? 6 : 8,
                          bottom: widget.isCompact ? 6 : 8,
                          left: 8,
                          right: 48, // Padding so text doesn't overlap the icon
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
                        icon: const Icon(Icons.arrow_drop_down),
                        tooltip: '履歴を表示',
                        onPressed: widget.history.isNotEmpty
                            ? () {
                                if (controller.isOpen) {
                                  controller.close();
                                } else {
                                  controller.open();
                                }
                              }
                            : null,
                      ),
                    ),
                  ],
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
