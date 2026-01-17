import 'package:path/path.dart' as p;
import 'file_model.dart';

enum RenameMode {
  replace,
  append,
  prepend,
  numbering,
  extension,
  upper,
  lower,
  capitalize,
  insert, // 文字列挿入
  // Deletion placeholders
  deleteStart,
  deleteEnd,
  deleteFrom,
  deleteFrontTo,
  deleteBackTo,
}

enum NumberingMode {
  stringNumber, // 文字列 + 連番
  originalNumber, // 現在名 + 連番
  numberString, // 連番 + 文字列
  numberOriginal, // 連番 + 現在名
  baseStringNumber, // 基本フォルダ名 + 文字列 + 連番
  baseStringOriginal, // 基本フォルダ名 + 文字列 + 現在名
  relativeStringNumber, // 相対フォルダ名 + 文字列 + 連番
  relativeStringOriginal, // 相対フォルダ名 + 文字列 + 現在名
  numberStringBase, // 連番 + 文字列 + 基本フォルダ名
  numberStringRelative, // 連番 + 文字列 + 相対フォルダ名
}

enum CaseConversion { none, upper, lower, capitalize }

class RenameEngine {
  /// パラメータに基づいてファイルのプレビュー名を生成します。
  static List<FileModel> generatePreviews(
    List<FileModel> files,
    RenameMode mode, {
    String? findText,
    String? replaceText,
    String? appendText,
    int startNumber = 1, // Used as Index for Insert Mode
    int digits = 3,
    CaseConversion caseConversion = CaseConversion.none,
    bool extensionToLowerCase = false,
    bool useRegex = false,
    NumberingMode numberingMode = NumberingMode.stringNumber,
    String? baseDirName, // Name of the root directory (Base Folder)
  }) {
    int counter = startNumber;

    for (var file in files) {
      String originalBaseName = p.basenameWithoutExtension(file.originalName);
      String extension = p.extension(file.originalName);
      String newBaseName = originalBaseName;

      // 1. Primary Rename Logic
      switch (mode) {
        // ... (previous cases) ...
        case RenameMode.numbering:
          String numberStr = counter.toString().padLeft(digits, '0');
          String text = appendText ?? '';

          // Get Base Folder Name
          // Requirement: "Base Folder Name" = Root Search Directory Name
          String parentName = baseDirName ?? '';
          if (parentName.isEmpty) {
            // Fallback: If not provided, maybe use immediate parent?
            // But strict definition says Base = Current.
            // If we don't have it, empty is safer than wrong context.
            // However, for flat list single file rename, parent might be base.
            // Let's fallback to p.basename(file.parentPath) if baseDirName is null.
            try {
              parentName = p.basename(file.parentPath);
            } catch (_) {}
          }

          // Relative Folder Name
          // Use the calculated relative path from model.
          // If empty (e.g. root file), it handles gracefully as empty string.
          String relativeName = file.relativePath;

          switch (numberingMode) {
            case NumberingMode.stringNumber:
              newBaseName = '$text$numberStr';
              break;
            case NumberingMode.originalNumber:
              newBaseName = '$originalBaseName$numberStr';
              break;
            case NumberingMode.numberString:
              newBaseName = '$numberStr$text';
              break;
            case NumberingMode.numberOriginal:
              newBaseName = '$numberStr$originalBaseName';
              break;
            case NumberingMode.baseStringNumber:
              newBaseName = '$parentName$text$numberStr';
              break;
            case NumberingMode.baseStringOriginal:
              newBaseName = '$parentName$text$originalBaseName';
              break;
            case NumberingMode.relativeStringNumber:
              newBaseName = '$relativeName$text$numberStr';
              break;
            case NumberingMode.relativeStringOriginal:
              newBaseName = '$relativeName$text$originalBaseName';
              break;
            case NumberingMode.numberStringBase:
              newBaseName = '$numberStr$text$parentName';
              break;
            case NumberingMode.numberStringRelative:
              newBaseName = '$numberStr$text$relativeName';
              break;
          }
          counter++;
          break;
        case RenameMode.deleteStart:
          // Remove [digits] characters from the beginning
          int count = digits;
          if (count > 0 && count <= newBaseName.length) {
            newBaseName = newBaseName.substring(count);
          } else if (count > newBaseName.length) {
            newBaseName = '';
          }
          break;
        case RenameMode.deleteEnd:
          // Remove [digits] characters from the end
          int count = digits;
          if (count > 0 && count <= newBaseName.length) {
            newBaseName = newBaseName.substring(0, newBaseName.length - count);
          } else if (count > newBaseName.length) {
            newBaseName = '';
          }
          break;
        case RenameMode.deleteFrom:
          // Remove [digits] characters starting from [startNumber] (1-based index)
          // startNumber 1 = index 0
          int startIdx = startNumber - 1;
          int count = digits;

          if (startIdx >= 0 && startIdx < newBaseName.length && count > 0) {
            int endIdx = startIdx + count;
            if (endIdx > newBaseName.length) endIdx = newBaseName.length;
            newBaseName = newBaseName.replaceRange(startIdx, endIdx, '');
          }
          break;
        case RenameMode.deleteFrontTo:
          // Delete from start UNTIL the string [findText] (INCLUDING findText)
          if (findText != null && findText.isNotEmpty) {
            int idx = newBaseName.indexOf(findText);
            if (idx != -1) {
              // substring(idx + length) removes the delimiter as well.
              // 'original', find 'n' (idx 5). length 1.
              // substring(6) -> 'al'. Correct.
              newBaseName = newBaseName.substring(idx + findText.length);
            }
          }
          break;
        case RenameMode.deleteBackTo:
          // Delete from end BACK TO the string [findText] (INCLUDING findText)
          if (findText != null && findText.isNotEmpty) {
            int idx = newBaseName.lastIndexOf(findText);
            if (idx != -1) {
              // substring(0, idx) keeps content before delimiter.
              // 'original', find 'n' (idx 5).
              // substring(0, 5) -> 'origi'. Correct.
              newBaseName = newBaseName.substring(0, idx);
            }
          }
          break;
        case RenameMode.insert:
          if (appendText != null && appendText.isNotEmpty) {
            // Use startNumber as insertion index (1-based)
            int index = startNumber - 1;
            // Protect bounds
            if (index < 0) index = 0;
            if (index > newBaseName.length) index = newBaseName.length;
            newBaseName = newBaseName.replaceRange(index, index, appendText);
          }
          break;
        // ... (other cases) ...
        case RenameMode.replace:
          if (findText != null && findText.isNotEmpty) {
            String replacement = replaceText ?? '';
            if (useRegex) {
              try {
                final regex = RegExp(findText);
                newBaseName = originalBaseName.replaceAll(regex, replacement);
              } catch (e) {
                // Invalid regex, maybe do nothing or treat as literal?
                // For safety, we might treat as literal or just skip.
                // Let's just skip replacement on error to avoid crashes.
              }
            } else {
              newBaseName = originalBaseName.replaceAll(findText, replacement);
            }
          }
          break;
        case RenameMode.append:
          if (appendText != null) {
            newBaseName = '$originalBaseName$appendText';
          }
          break;
        case RenameMode.prepend:
          if (appendText != null) {
            newBaseName = '$appendText$originalBaseName';
          }
          break;

        case RenameMode.extension:
          if (replaceText != null && replaceText.isNotEmpty) {
            if (replaceText.startsWith('.')) {
              extension = replaceText;
            } else {
              extension = '.$replaceText';
            }
          }
          break;
        case RenameMode.upper:
          newBaseName = newBaseName.toUpperCase();
          break;
        case RenameMode.lower:
          newBaseName = newBaseName.toLowerCase();
          break;
        case RenameMode.capitalize:
          if (newBaseName.isNotEmpty) {
            newBaseName = newBaseName[0].toUpperCase() +
                newBaseName.substring(1).toLowerCase();
          }
          break;
      }

      // 2. Case Conversion (Applied to Base Name)
      switch (caseConversion) {
        case CaseConversion.upper:
          newBaseName = newBaseName.toUpperCase();
          break;
        case CaseConversion.lower:
          newBaseName = newBaseName.toLowerCase();
          break;
        case CaseConversion.capitalize:
          if (newBaseName.isNotEmpty) {
            newBaseName = newBaseName[0].toUpperCase() +
                newBaseName.substring(1).toLowerCase();
          }
          break;
        case CaseConversion.none:
          break;
      }

      // 3. Extension Lowercase
      if (extensionToLowerCase) {
        extension = extension.toLowerCase();
      }

      file.setNewName('$newBaseName$extension');
    }

    return files;
  }
}
