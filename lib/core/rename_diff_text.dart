import 'package:flutter/material.dart';

import 'rename_options.dart';

class RenameDiffText {
  static TextSpan build(
    BuildContext context,
    String oldText,
    String newText,
    bool hasError, {
    TextStyle? style,
    RenameMode? mode,
    int? startNumber,
    int? digits,
  }) {
    final baseTextStyle = (style ?? const TextStyle()).copyWith(
      fontSize: 12,
      color: hasError
          ? Theme.of(context).colorScheme.error
          : style?.color ?? Theme.of(context).colorScheme.onSurface,
    );
    if (oldText == newText || hasError) {
      return TextSpan(text: newText, style: baseTextStyle);
    }

    if (mode == RenameMode.deleteStart ||
        mode == RenameMode.deleteEnd ||
        mode == RenameMode.deleteFrom) {
      var delStart = 0;
      final delCount = digits ?? 0;
      if (mode == RenameMode.deleteEnd) {
        delStart = oldText.length - delCount;
      } else if (mode == RenameMode.deleteFrom) {
        delStart = (startNumber ?? 1) - 1;
      }
      delStart = delStart.clamp(0, oldText.length);
      final delEnd = (delStart + delCount).clamp(0, oldText.length);
      final prefix = oldText.substring(0, delStart);
      final deleted = oldText.substring(delStart, delEnd);
      final suffix = oldText.substring(delEnd);
      return TextSpan(style: baseTextStyle, children: [
        if (prefix.isNotEmpty) TextSpan(text: prefix),
        if (deleted.isNotEmpty)
          TextSpan(
            text: deleted,
            style: TextStyle(
              color: Colors.red.withValues(alpha: 0.7),
              decoration: TextDecoration.lineThrough,
            ),
          ),
        if (suffix.isNotEmpty) TextSpan(text: suffix),
      ]);
    }

    var prefixLen = 0;
    while (prefixLen < oldText.length &&
        prefixLen < newText.length &&
        oldText[prefixLen] == newText[prefixLen]) {
      prefixLen++;
    }
    var suffixLen = 0;
    while (suffixLen < oldText.length - prefixLen &&
        suffixLen < newText.length - prefixLen &&
        oldText[oldText.length - 1 - suffixLen] ==
            newText[newText.length - 1 - suffixLen]) {
      suffixLen++;
    }
    final prefix = oldText.substring(0, prefixLen);
    final deleted = oldText.substring(prefixLen, oldText.length - suffixLen);
    final added = newText.substring(prefixLen, newText.length - suffixLen);
    final suffix = oldText.substring(oldText.length - suffixLen);
    return TextSpan(style: baseTextStyle, children: [
      if (prefix.isNotEmpty) TextSpan(text: prefix),
      if (deleted.isNotEmpty)
        TextSpan(
          text: deleted,
          style: TextStyle(
            color: Colors.red.withValues(alpha: 0.7),
            decoration: TextDecoration.lineThrough,
          ),
        ),
      if (added.isNotEmpty)
        TextSpan(
          text: added,
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      if (suffix.isNotEmpty) TextSpan(text: suffix),
    ]);
  }
}
