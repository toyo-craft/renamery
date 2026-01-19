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
    return Row(
      children: [
        if (label.isNotEmpty) ...[
          SizedBox(
              width: 60,
              child:
                  Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: TextField(
            focusNode: focusNode,
            controller: controller,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              isDense: true,
              hintText: hintText,
              contentPadding: EdgeInsets.symmetric(
                vertical: isCompact ? 6 : 8,
                horizontal: 8,
              ),
              suffixIcon: PopupMenuButton<String>(
                icon: const Icon(Icons.arrow_drop_down),
                onSelected: (String value) {
                  controller.text = value;
                  onChanged(value);
                },
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
            onChanged: (val) => onChanged(val),
            onTap: onTap,
            onSubmitted: (val) {
              if (onSubmitted != null) {
                onSubmitted!(val, history);
              }
            },
          ),
        ),
      ],
    );
  }
}
