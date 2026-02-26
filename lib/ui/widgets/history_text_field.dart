import 'package:flutter/material.dart';

class HistoryTextField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        if (label.isNotEmpty) ...[
          SizedBox(
              width: 60, child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: TextField(
            focusNode: focusNode,
            controller: controller,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              isDense: true,
              hintText: hintText,
              contentPadding: EdgeInsets.symmetric(
                vertical: isCompact ? 6 : 8,
                horizontal: 8,
              ),
              // filled and border are inherited from InputDecorationTheme
            ),
            onChanged: (val) => onChanged(val),
            onTap: onTap,
            onSubmitted: (val) {
              if (onSubmitted != null) {
                onSubmitted!(val, history);
              }
            },
          ),
        ),
        // MD3: trailing icon as independent touch target (min 48dp)
        // Placed outside TextField to avoid Flutter desktop tap interception bug
        SizedBox(
          width: 48,
          height: 48,
          child: PopupMenuButton<String>(
            icon: Icon(Icons.arrow_drop_down,
                color: colorScheme.onSurfaceVariant),
            splashRadius: 20,
            padding: EdgeInsets.zero,
            onSelected: (String value) {
              controller.text = value;
              onChanged(value);
            },
            enabled: history.isNotEmpty,
            itemBuilder: (BuildContext context) {
              return history.map((String value) {
                return PopupMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList();
            },
          ),
        ),
      ],
    );
  }
}
