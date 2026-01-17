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
  // Sub Tab
  extensionRemove,
  extensionAdd,
  extensionUpper,
  extensionLower,
  formatProperCase,
  listRename,
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
    String? listText, // For List Rename
  }) {
    int counter = startNumber;

    // Pre-parse List Rename Map if needed (Performance optimization)
    Map<String, String> renameMap = {};
    if (mode == RenameMode.listRename &&
        listText != null &&
        listText.isNotEmpty) {
      // Parse lines: Old New
      // Separator: Tab or Pipe or " -> " or just loose?
      // Namery manual: "Original<TAB>New"
      final lines = listText.split('\n');
      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        // Try tab first
        var parts = line.split('\t');
        if (parts.length < 2) {
          // Try comma? manual says Tab. Let's stick to Tab or maybe format "Old<Tab>New".
          // If user pastes from Excel, it's Tab separated.
          continue;
        }
        if (parts.length >= 2) {
          renameMap[parts[0].trim()] = parts[1].trim();
        }
      }
    }

    for (var file in files) {
      String originalBaseName = p.basenameWithoutExtension(file.originalName);
      String extension = p.extension(file.originalName);
      String newBaseName = originalBaseName;

      // 1. Primary Rename Logic
      switch (mode) {
        // ... (previous cases) ...
        case RenameMode.numbering:
          // ... (existing logic) ...
          String numberStr = counter.toString().padLeft(digits, '0');
          String text = appendText ?? '';

          // Get Base Folder Name
          String parentName = baseDirName ?? '';
          if (parentName.isEmpty) {
            try {
              parentName = p.basename(file.parentPath);
            } catch (_) {}
          }

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
          int count = digits;
          if (count > 0 && count <= newBaseName.length) {
            newBaseName = newBaseName.substring(count);
          } else if (count > newBaseName.length) {
            newBaseName = '';
          }
          break;
        case RenameMode.deleteEnd:
          int count = digits;
          if (count > 0 && count <= newBaseName.length) {
            newBaseName = newBaseName.substring(0, newBaseName.length - count);
          } else if (count > newBaseName.length) {
            newBaseName = '';
          }
          break;
        case RenameMode.deleteFrom:
          int startIdx = startNumber - 1;
          int count = digits;

          if (startIdx >= 0 && startIdx < newBaseName.length && count > 0) {
            int endIdx = startIdx + count;
            if (endIdx > newBaseName.length) endIdx = newBaseName.length;
            newBaseName = newBaseName.replaceRange(startIdx, endIdx, '');
          }
          break;
        case RenameMode.deleteFrontTo:
          if (findText != null && findText.isNotEmpty) {
            int idx = newBaseName.indexOf(findText);
            if (idx != -1) {
              newBaseName = newBaseName.substring(idx + findText.length);
            }
          }
          break;
        case RenameMode.deleteBackTo:
          if (findText != null && findText.isNotEmpty) {
            int idx = newBaseName.lastIndexOf(findText);
            if (idx != -1) {
              newBaseName = newBaseName.substring(0, idx);
            }
          }
          break;
        case RenameMode.insert:
          if (appendText != null && appendText.isNotEmpty) {
            int index = startNumber - 1;
            if (index < 0) index = 0;
            if (index > newBaseName.length) index = newBaseName.length;
            newBaseName = newBaseName.replaceRange(index, index, appendText);
          }
          break;
        case RenameMode.replace:
          if (findText != null && findText.isNotEmpty) {
            String replacement = replaceText ?? '';
            if (useRegex) {
              try {
                final regex = RegExp(findText);
                newBaseName = originalBaseName.replaceAll(regex, replacement);
              } catch (e) {
                // Ignore invalid regex
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
        case RenameMode.listRename:
          // Use parsed map
          // Keys are original NAMES (with or without extension? Usually full name or base name?)
          // Namery manual doesn't specify deeply but "Change Old Name to New Name".
          // Usually full name match or base name match.
          // Let's assume Base Name match for now as extensions are handled separately in Namery logic usually,
          // BUT if list provides extensions, it might be full name.
          // Let's try matching Original Full Name first.
          if (renameMap.containsKey(file.originalName)) {
            String? mapped = renameMap[file.originalName];
            if (mapped != null) {
              // Mapped Name might include extension.
              // If so, we should update extension too?
              // Or does it replace the base name only?
              // If mapped has extension, use it.
              if (p.extension(mapped).isNotEmpty) {
                newBaseName = p.basenameWithoutExtension(mapped);
                extension = p.extension(mapped);
              } else {
                newBaseName = mapped;
              }
            }
          } else if (renameMap.containsKey(originalBaseName)) {
            // Fallback to base name match
            newBaseName = renameMap[originalBaseName]!;
          }
          break;
        default:
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

      // 3. Extension Lowercase (Legacy flag - keep for compatibility if needed, but SubTab uses specific modes)
      if (extensionToLowerCase) {
        extension = extension.toLowerCase();
      }

      // --- Sub Tab Features ---
      switch (mode) {
        case RenameMode.extensionRemove:
          extension = '';
          break;
        case RenameMode.extensionAdd:
          if (replaceText != null && replaceText.isNotEmpty) {
            // Add to END of existing extension, or append if none?
            // Usually "Add Extension" means appending another extension like .bak
            // Original Namery manual says "Add".
            // If original is .txt and adding .bak -> .txt.bak
            if (replaceText.startsWith('.')) {
              extension += replaceText;
            } else {
              extension += '.$replaceText';
            }
          }
          break;
        case RenameMode.extensionUpper:
          extension = extension.toUpperCase();
          break;
        case RenameMode.extensionLower:
          extension = extension.toLowerCase();
          break;
        case RenameMode.formatProperCase:
          // Split by space, hyphen, underscore
          // Capitalize first letter of each part, lower others.
          newBaseName = newBaseName.replaceAllMapped(
            RegExp(r'([ \-_]+|^)([a-zA-Z0-9]+)'),
            (match) {
              String separator = match.group(1) ?? '';
              String word = match.group(2) ?? '';
              if (word.isNotEmpty) {
                word = word[0].toUpperCase() + word.substring(1).toLowerCase();
              }
              return '$separator$word';
            },
          );
          break;
        // List Rename is handled outside or via specific lookup?
        // Usually List Rename maps Original Name -> New Name.
        // If handled here, we need the map.
        // Since generatePreviews is static, we might pass the map?
        // Or handle it as a special case where "replaceText" might logically hold the map? NO.
        // Let's add an optional map parameter to generatePreviews?
        default:
          break;
      }

      if (mode == RenameMode.listRename) {
        // Implementation for List Rename
        // Needs a lookup map.
        // Assuming 'findText' or similar passed somehow?
        // Better to add a parameter `Map<String, String>? listMap`
        // But we need to update signature.
      }

      file.setNewName('$newBaseName$extension');
    }

    return files;
  }
}
