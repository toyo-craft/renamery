import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumberSpinBox extends StatefulWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final bool isCompact;
  final double width;

  const NumberSpinBox({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 9999999,
    this.isCompact = false,
    this.width = 48.0,
  });

  @override
  State<NumberSpinBox> createState() => _NumberSpinBoxState();
}

class _NumberSpinBoxState extends State<NumberSpinBox> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _validateAndNotify(_controller.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant NumberSpinBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_focusNode.hasFocus) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _validateAndNotify(String text) {
    int? parsed = int.tryParse(text);
    if (parsed == null) {
      parsed = widget.min;
    } else if (parsed < widget.min) {
      parsed = widget.min;
    } else if (parsed > widget.max) {
      parsed = widget.max;
    }

    if (parsed != widget.value) {
      widget.onChanged(parsed);
    }

    final newText = parsed.toString();
    if (_controller.text != newText) {
      _controller.text = newText;
    }
  }

  void _increment() {
    final current = int.tryParse(_controller.text) ?? widget.min;
    if (current < widget.max) {
      final newValue = current + 1;
      _controller.text = newValue.toString();
      widget.onChanged(newValue);
    }
  }

  void _decrement() {
    final current = int.tryParse(_controller.text) ?? widget.min;
    if (current > widget.min) {
      final newValue = current - 1;
      _controller.text = newValue.toString();
      widget.onChanged(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double iconSize = widget.isCompact ? 14 : 16;
    final double btnHeight = widget.isCompact ? 20 : 24;
    final double fontSize = widget.isCompact ? 13 : 14;
    final borderColor = theme.colorScheme.outline;

    return SizedBox(
      width: widget.width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Plus button (top)
            InkWell(
              onTap: _increment,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
              child: SizedBox(
                width: double.infinity,
                height: btnHeight,
                child: Icon(Icons.add, size: iconSize),
              ),
            ),
            // Horizontal divider
            Divider(height: 1, thickness: 1, color: borderColor),
            // Text field (middle)
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: fontSize),
              maxLines: 1,
              onSubmitted: _validateAndNotify,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
            // Horizontal divider
            Divider(height: 1, thickness: 1, color: borderColor),
            // Minus button (bottom)
            InkWell(
              onTap: _decrement,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(3),
                bottomRight: Radius.circular(3),
              ),
              child: SizedBox(
                width: double.infinity,
                height: btnHeight,
                child: Icon(Icons.remove, size: iconSize),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
