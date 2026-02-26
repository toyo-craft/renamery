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
  late FocusNode _internalFocusNode;
  bool _isFocused = false;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _effectiveFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChanged);
    _internalFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _effectiveFocusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        if (widget.label.isNotEmpty) ...[
          SizedBox(
              width: 60,
              child: Text(widget.label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _isFocused ? colorScheme.primary : colorScheme.outline,
                width: _isFocused ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    focusNode: _effectiveFocusNode,
                    controller: widget.controller,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: widget.hintText,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: widget.isCompact ? 6 : 8,
                        horizontal: 8,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onChanged: (val) => widget.onChanged(val),
                    onTap: widget.onTap,
                    onSubmitted: (val) {
                      if (widget.onSubmitted != null) {
                        widget.onSubmitted!(val, widget.history);
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: PopupMenuButton<String>(
                    icon: Icon(Icons.arrow_drop_down,
                        size: 20, color: colorScheme.onSurfaceVariant),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (String value) {
                      widget.controller.text = value;
                      widget.onChanged(value);
                    },
                    enabled: widget.history.isNotEmpty,
                    itemBuilder: (BuildContext context) {
                      return widget.history.map((String value) {
                        return PopupMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList();
                    },
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
