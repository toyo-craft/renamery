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

          // Get Parent Directory Name (Base Folder)
          String parentName = '';
          try {
            // We can get parent dir name from file.originalName's parent path?
            // But FileModel.originalName is usually just basename if we set it so?
            // Actually, FileModel typically stores full path or we have context.
            // Wait, file.originalName in generatePreviews:
            // "String originalBaseName = p.basenameWithoutExtension(file.originalName);"
            // This implies file.originalName might be full path or just name.
            // Let's assume file.originalName is currently just name because that's how it's usually used in previews.
            // HOWEVER, DirectoryProvider lists files and stores them.
            // Let's check FileModel logic: "FileModel(entity: e)".
            // If file.originalName is name only, we can't get parent.
            // But file.parentPath exists? It's not in the loop variable.
            // We need to access file.parentPath.
            // FileModel usually has this. Let's check FileModel definition if needed,
            // but assuming p.dirname(file.entity.path) or similar is available or we pass it.
            // Wait, file.originalName IS the property we use.
            // Let's look at DirectoryProvider line 121: "final oldPath = p.join(file.parentPath, file.originalName);"
            // So file.originalName is just the name.
            // file.parentPath is available in FileModel.
            parentName = p.basename(file.parentPath);
          } catch (_) {}

          // Relative Folder: For now, same as Base Folder or empty if not implemented
          // Requirement: "Relative Folder Name" + String + ...
          String relativeName = parentName; // Placeholder

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
          // Delete from start UNTIL the string [findText]
          // Usually means: remove everything BEFORE the found string.
          // Or remove everything UP TO AND INCLUDING?
          // "まで削除" (Delete until) usually includes the target in "deletion" scope if it's the "boundary".
          // But safely, let's assume removing everything BEFORE the first match, keeping the match?
          // Or removing the match too?
          // Let's assume removing everything BEFORE.
          // Wait, if I say "Delete until 'A'", 'BCA' -> 'A'.
          if (findText != null && findText.isNotEmpty) {
            int idx = newBaseName.indexOf(findText);
            if (idx != -1) {
              // Remove 0 to idx
              newBaseName = newBaseName.substring(idx);
              // If we want to remove the delimiter too: newBaseName = newBaseName.substring(idx + findText.length);
              // "まで削除" might imply "delete the range ending at X".
              // Let's stick to "Remove Preceding Text".
            }
          }
          break;
        case RenameMode.deleteBackTo:
          // Delete from end BACK TO the string [findText]
          // Remove everything AFTER the last match?
          if (findText != null && findText.isNotEmpty) {
            int idx = newBaseName.lastIndexOf(findText);
            if (idx != -1) {
              // Keep 0 to idx + length (or just idx?)
              // "Back to": e.g. "ABC_DEF", delete back to "_" => "ABC_"
              newBaseName = newBaseName.substring(0, idx + findText.length);
            }
          }
          break;
        case RenameMode.insert:
          if (appendText != null && appendText.isNotEmpty) {
            // Use startNumber as insertion index
            int index = startNumber;
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
