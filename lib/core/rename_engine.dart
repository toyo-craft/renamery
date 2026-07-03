import 'dart:io';
import 'dart:isolate';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'file_model.dart';
import 'rename_options.dart';

export 'rename_options.dart';

class RenameEngine {
  /// 究極の高速化: バイト列から直接パッキングする Isolate 関数
  /// メインスレッドでの文字列生成負荷を排除
  static List<Map<String, dynamic>> computeScanBytes(
      Map<String, dynamic> params) {
    final List<int> stdoutBytes = params['bytes'];
    final String rootPath = params['rootPath'];
    final bool recursive = params['recursive'];
    final List<Map<String, dynamic>> results = [];

    final output = systemEncoding.decode(stdoutBytes);
    final lines = output.split('\r\n');

    for (var line in lines) {
      if (line.isEmpty) continue;
      final fullPath = recursive ? line : p.join(rootPath, line);
      final name = p.basename(fullPath);

      results.add({
        'path': fullPath,
        'name': name,
        'isDir': FileSystemEntity.isDirectorySync(fullPath), // I/O を最小化しつつ判定
        'isHidden': name.startsWith('.'),
        'rel': recursive
            ? (p.dirname(fullPath).length > rootPath.length
                ? p
                    .dirname(fullPath)
                    .substring(rootPath.length)
                    .replaceFirst(RegExp(r'^[\\/]+'), '')
                : '')
            : '',
      });
    }
    return results;
  }

  static List<Map<String, dynamic>> computeScan(Map<String, dynamic> params) {
    final String rootPath = params['rootPath'];
    final bool recursive = params['recursive'];
    final List<Map<String, dynamic>> results = [];
    try {
      final entities = Directory(rootPath)
          .listSync(recursive: recursive, followLinks: false);
      for (final entity in entities) {
        final path = entity.path;
        final name = p.basename(path);
        results.add({
          'path': path,
          'name': name,
          'isDir': entity is Directory,
          'isHidden': name.startsWith('.'),
          'rel': recursive
              ? (p.dirname(path).length > rootPath.length
                  ? p
                      .dirname(path)
                      .substring(rootPath.length)
                      .replaceFirst(RegExp(r'^[\\/]+'), '')
                  : '')
              : '',
        });
      }
    } catch (_) {}
    return results;
  }

  static void computeScanStream(Map<String, dynamic> params) async {
    final SendPort sendPort = params['sendPort'];
    final String rootPath = params['rootPath'];
    final bool recursive = params['recursive'];
    final int batchSize = params['batchSize'] ?? 512;
    final int batchIntervalMs = params['batchIntervalMs'] ?? 150;

    try {
      final stream =
          Directory(rootPath).list(recursive: recursive, followLinks: false);
      final batch = <Map<String, dynamic>>[];
      var lastSend = DateTime.now();

      void flush() {
        if (batch.isEmpty) return;
        sendPort.send(List<Map<String, dynamic>>.from(batch));
        batch.clear();
        lastSend = DateTime.now();
      }

      await for (final entity in stream) {
        final path = entity.path;
        final name = p.basename(path);
        batch.add({
          'path': path,
          'name': name,
          'isDir': entity is Directory,
          'isHidden': name.startsWith('.'),
          'rel': recursive
              ? (p.dirname(path).length > rootPath.length
                  ? p
                      .dirname(path)
                      .substring(rootPath.length)
                      .replaceFirst(RegExp(r'^[\\/]+'), '')
                  : '')
              : '',
        });
        if (batch.length >= batchSize ||
            DateTime.now().difference(lastSend).inMilliseconds >=
                batchIntervalMs) {
          flush();
          await Future<void>.delayed(Duration.zero);
        }
      }
      flush();
      sendPort.send('done');
    } catch (e) {
      sendPort.send('error: $e');
    }
  }

  static TextSpan buildDiffTextSpan(
      BuildContext context, String oldText, String newText, bool hasError,
      {TextStyle? style, RenameMode? mode, int? startNumber, int? digits}) {
    final baseTextStyle = (style ?? const TextStyle()).copyWith(
        fontSize: 12,
        color: hasError
            ? Theme.of(context).colorScheme.error
            : style?.color ?? Theme.of(context).colorScheme.onSurface);
    if (oldText == newText || hasError) {
      return TextSpan(text: newText, style: baseTextStyle);
    }

    if (mode == RenameMode.deleteStart ||
        mode == RenameMode.deleteEnd ||
        mode == RenameMode.deleteFrom) {
      int delStart = 0;
      int delCount = digits ?? 0;
      if (mode == RenameMode.deleteStart) {
        delStart = 0;
      } else if (mode == RenameMode.deleteEnd)
        delStart = oldText.length - delCount;
      else if (mode == RenameMode.deleteFrom) delStart = (startNumber ?? 1) - 1;
      delStart = delStart.clamp(0, oldText.length);
      int delEnd = (delStart + delCount).clamp(0, oldText.length);
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
                  decoration: TextDecoration.lineThrough)),
        if (suffix.isNotEmpty) TextSpan(text: suffix),
      ]);
    }

    int prefixLen = 0;
    while (prefixLen < oldText.length &&
        prefixLen < newText.length &&
        oldText[prefixLen] == newText[prefixLen]) {
      prefixLen++;
    }
    int suffixLen = 0;
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
                decoration: TextDecoration.lineThrough)),
      if (added.isNotEmpty)
        TextSpan(
            text: added,
            style: const TextStyle(
                color: Colors.green, fontWeight: FontWeight.bold)),
      if (suffix.isNotEmpty) TextSpan(text: suffix),
    ]);
  }

  static void generatePreviews(List<FileModel> files, RenameMode mode,
      {String? findText,
      String? replaceText,
      String? appendText,
      int startNumber = 1,
      int insertIndex = 1,
      int digits = 3,
      CaseConversion caseConversion = CaseConversion.none,
      bool extensionToLowerCase = false,
      bool useRegex = false,
      NumberingMode numberingMode = NumberingMode.stringNumber,
      String? baseDirName,
      String? listText,
      String? dateFormat,
      DatePosition datePosition = DatePosition.front,
      ValidationType validationType = ValidationType.auto}) {
    final input = {
      'mode': mode,
      'fileData': files
          .map((f) => {
                'originalName': f.originalName,
                'isDirectory': f.entity is Directory,
                'modified': f.entity.statSync().modified
              })
          .toList(),
      'findText': findText,
      'replaceText': replaceText,
      'appendText': appendText,
      'startNumber': startNumber,
      'insertIndex': insertIndex,
      'digits': digits,
      'caseConversion': caseConversion,
      'extensionToLowerCase': extensionToLowerCase,
      'useRegex': useRegex,
      'numberingMode': numberingMode,
      'baseDirName': baseDirName,
      'listText': listText,
      'dateFormat': dateFormat,
      'datePosition': datePosition,
      'validationType': validationType,
      'isWindows': !kIsWeb && Platform.isWindows,
      'isMacOS': !kIsWeb && Platform.isMacOS,
    };
    final results = computeGeneratePreviews(input);
    for (int i = 0; i < files.length; i++) {
      final f = files[i];
      final res = results[i];
      f.setNewName(res['newName']!, notify: false);
      f.setValidationError(res['error'], notify: false);
    }
  }

  static List<Map<String, String?>> computeGeneratePreviews(
      Map<String, dynamic> params) {
    final RenameMode mode = params['mode'];
    final List<dynamic> fileData = params['fileData'];
    final String? findText = params['findText'];
    final String? replaceText = params['replaceText'];
    final String? appendText = params['appendText'];
    final int startNumber = params['startNumber'];
    final int insertIndex = params['insertIndex'];
    final int digits = params['digits'];
    final CaseConversion caseConversion = params['caseConversion'];
    final bool extensionToLowerCase = params['extensionToLowerCase'];
    final bool useRegex = params['useRegex'];
    final String? listText = params['listText'];
    final String? dateFormat = params['dateFormat'];
    final DatePosition datePosition = params['datePosition'];
    final ValidationType validationType = params['validationType'];
    final bool isWindows = params['isWindows'];
    final bool isMacOS = params['isMacOS'];

    Map<String, String> renameMap = {};
    if (mode == RenameMode.listRename &&
        listText != null &&
        listText.isNotEmpty) {
      final lines = listText.split('\n');
      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        var parts = line.split('\t');
        if (parts.length >= 2) renameMap[parts[0].trim()] = parts[1].trim();
      }
    }

    final results = <Map<String, String?>>[];
    for (int i = 0; i < fileData.length; i++) {
      final data = fileData[i];
      final String originalName = data['originalName'];
      final bool isDirectory = data['isDirectory'];
      final DateTime modified = data['modified'];

      String originalBaseName;
      String extension;
      String newBaseName;
      if (isDirectory) {
        originalBaseName = originalName;
        extension = '';
      } else {
        originalBaseName = p.basenameWithoutExtension(originalName);
        extension = p.extension(originalName);
      }
      newBaseName = originalBaseName;

      switch (mode) {
        case RenameMode.deleteStart:
          if (digits > 0) {
            newBaseName = digits >= newBaseName.length
                ? ''
                : newBaseName.substring(digits);
          }
          break;
        case RenameMode.deleteEnd:
          if (digits > 0) {
            newBaseName = digits >= newBaseName.length
                ? ''
                : newBaseName.substring(0, newBaseName.length - digits);
          }
          break;
        case RenameMode.deleteFrom:
          int startIdx = startNumber - 1;
          if (startIdx >= 0 && startIdx < newBaseName.length && digits > 0) {
            int endIdx = (startIdx + digits).clamp(0, newBaseName.length);
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
            if (idx != -1) newBaseName = newBaseName.substring(0, idx);
          }
          break;
        case RenameMode.insert:
          if (appendText != null && appendText.isNotEmpty) {
            int index = (insertIndex - 1).clamp(0, newBaseName.length);
            newBaseName = newBaseName.replaceRange(index, index, appendText);
          }
          break;
        case RenameMode.replace:
          if (findText != null && findText.isNotEmpty) {
            String replacement = replaceText ?? '';
            if (useRegex) {
              try {
                final regex = RegExp(findText);
                newBaseName = originalBaseName.replaceAllMapped(regex, (match) {
                  return replacement.replaceAllMapped(RegExp(r'(?:\$|\\)(\d+)'),
                      (m) {
                    int groupIdx = int.parse(m.group(1)!);
                    if (groupIdx <= match.groupCount) {
                      return match.group(groupIdx) ?? '';
                    }
                    return m.group(0)!;
                  });
                });
              } catch (_) {}
            } else {
              newBaseName = originalBaseName.replaceAll(findText, replacement);
            }
          }
          break;
        case RenameMode.append:
          if (appendText != null) newBaseName = '$originalBaseName$appendText';
          break;
        case RenameMode.prepend:
          if (appendText != null) newBaseName = '$appendText$originalBaseName';
          break;
        case RenameMode.extension:
          if (replaceText != null && replaceText.isNotEmpty) {
            extension =
                replaceText.startsWith('.') ? replaceText : '.$replaceText';
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
          if (renameMap.containsKey(originalName)) {
            String mapped = renameMap[originalName]!;
            if (p.extension(mapped).isNotEmpty) {
              newBaseName = p.basenameWithoutExtension(mapped);
              extension = p.extension(mapped);
            } else {
              newBaseName = mapped;
            }
          } else if (renameMap.containsKey(originalBaseName))
            newBaseName = renameMap[originalBaseName]!;
          break;
        default:
          break;
      }

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

      if (extensionToLowerCase) extension = extension.toLowerCase();

      switch (mode) {
        case RenameMode.extensionRemove:
          extension = '';
          break;
        case RenameMode.extensionAdd:
          if (replaceText != null && replaceText.isNotEmpty) {
            extension +=
                replaceText.startsWith('.') ? replaceText : '.$replaceText';
          }
          break;
        case RenameMode.extensionUpper:
          extension = extension.toUpperCase();
          break;
        case RenameMode.extensionLower:
          extension = extension.toLowerCase();
          break;
        case RenameMode.formatProperCase:
          newBaseName = newBaseName
              .replaceAllMapped(RegExp(r'([ \-_]+|^)([a-zA-Z0-9]+)'), (match) {
            String separator = match.group(1) ?? '';
            String word = match.group(2) ?? '';
            if (word.isNotEmpty) {
              word = word[0].toUpperCase() + word.substring(1).toLowerCase();
            }
            return '$separator$word';
          });
          break;
        default:
          break;
      }

      switch (mode) {
        case RenameMode.appendDate:
          if (dateFormat != null && dateFormat.isNotEmpty) {
            try {
              final dateStr = DateFormat(dateFormat).format(modified);
              newBaseName = datePosition == DatePosition.front
                  ? '$dateStr$newBaseName'
                  : '$newBaseName$dateStr';
            } catch (_) {}
          }
          break;
        case RenameMode.convHalfToFull:
          newBaseName = JpTextConverter.toFullWidth(newBaseName);
          break;
        case RenameMode.convFullToHalf:
          newBaseName = JpTextConverter.toHalfWidth(newBaseName);
          break;
        case RenameMode.convFullKataToHira:
          newBaseName = JpTextConverter.kataToHira(newBaseName);
          break;
        case RenameMode.convHiraToFullKata:
          newBaseName = JpTextConverter.hiraToKata(newBaseName);
          break;
        case RenameMode.convFullAlphaToHalfAlpha:
          newBaseName = JpTextConverter.fullAlphaToHalf(newBaseName);
          break;
        case RenameMode.convNumToHalf:
          newBaseName = JpTextConverter.fullNumToHalf(newBaseName);
          break;
        default:
          break;
      }

      final String newName = '$newBaseName$extension';
      RegExp invalidChars;
      switch (validationType) {
        case ValidationType.windows:
          invalidChars = RegExp(r'[\\/:*?"<>|]');
          break;
        case ValidationType.mac:
        case ValidationType.ios:
          invalidChars = RegExp(r'[:/]');
          break;
        case ValidationType.linux:
        case ValidationType.android:
          invalidChars = RegExp(r'[/]');
          break;
        case ValidationType.auto:
          if (isWindows) {
            invalidChars = RegExp(r'[\\/:*?"<>|]');
          } else if (isMacOS)
            invalidChars = RegExp(r'[:/]');
          else
            invalidChars = RegExp(r'[/]');
          break;
      }

      String? error;
      if (invalidChars.hasMatch(newName)) {
        error = 'ファイル名に使用できない文字が含まれています';
      } else if (RegExp(r'[\x00-\x1f]').hasMatch(newName))
        error = '制御文字が含まれています';
      else if (newName.trim().isEmpty || newName == '.') error = 'ファイル名が空です';
      results.add({'newName': newName, 'error': error});
    }
    return results;
  }
}

class JpTextConverter {
  static const String _halfKana =
      'ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜｦﾝｧｨｩｪｫｬｭｮｯｰﾞﾟ';
  static const List<String> _fullKana = [
    'ア',
    'イ',
    'ウ',
    'エ',
    'オ',
    'カ',
    'キ',
    'ク',
    'ケ',
    'コ',
    'サ',
    'シ',
    'ス',
    'セ',
    'ソ',
    'タ',
    'チ',
    'ツ',
    'テ',
    'ト',
    'ナ',
    'ニ',
    'ヌ',
    'ネ',
    'ノ',
    'ハ',
    'ヒ',
    'フ',
    'ヘ',
    'ホ',
    'マ',
    'ミ',
    'ム',
    'メ',
    'モ',
    'ヤ',
    'ユ',
    'ヨ',
    'ラ',
    'リ',
    'ル',
    'レ',
    'ロ',
    'ワ',
    'ヲ',
    'ン',
    'ァ',
    'ィ',
    'ゥ',
    'ェ',
    'ォ',
    'ャ',
    'ュ',
    'ョ',
    'ッ',
    'ー',
    '゛',
    '゜'
  ];
  static const Map<String, String> _halfToFullMap = {
    'ｶﾞ': 'ガ',
    'ｷﾞ': 'ギ',
    'ｸﾞ': 'グ',
    'ｹﾞ': 'ゲ',
    'ｺﾞ': 'ゴ',
    'ｻﾞ': 'ザ',
    'ｼﾞ': 'ジ',
    'ｽﾞ': 'ズ',
    'ｾﾞ': 'ゼ',
    'ｿﾞ': 'ゾ',
    'ﾀﾞ': 'ダ',
    'ﾁﾞ': 'ヂ',
    'ﾂﾞ': 'ヅ',
    'ﾃﾞ': 'デ',
    'ﾄﾞ': 'ド',
    'ﾊﾞ': 'バ',
    'ﾋﾞ': 'ビ',
    'ﾌﾞ': 'ブ',
    'ﾍﾞ': 'ベ',
    'ﾎﾞ': 'ボ',
    'ﾊﾟ': 'パ',
    'ﾋﾟ': 'ピ',
    'ﾌﾟ': 'プ',
    'ﾍﾟ': 'ペ',
    'ﾎﾟ': 'ポ',
    'ｳﾞ': 'ヴ'
  };
  static String toFullWidth(String text) {
    String result = text;
    _halfToFullMap.forEach((k, v) => result = result.replaceAll(k, v));
    for (int i = 0; i < _halfKana.length; i++) {
      result = result.replaceAll(_halfKana[i], _fullKana[i]);
    }
    return result.runes
        .map((r) =>
            r == 0x20 ? 0x3000 : (r >= 0x21 && r <= 0x7E ? r + 0xFEE0 : r))
        .map((c) => String.fromCharCode(c))
        .join();
  }

  static String toHalfWidth(String text) {
    String result = text.runes
        .map((r) =>
            r == 0x3000 ? 0x20 : (r >= 0xFF01 && r <= 0xFF5E ? r - 0xFEE0 : r))
        .map((c) => String.fromCharCode(c))
        .join();
    _halfToFullMap
        .map((k, v) => MapEntry(v, k))
        .forEach((k, v) => result = result.replaceAll(k, v));
    for (int i = 0; i < _fullKana.length; i++) {
      result = result.replaceAll(_fullKana[i], _halfKana[i]);
    }
    return result;
  }

  static String kataToHira(String text) => text.runes
      .map((r) => (r >= 0x30A1 && r <= 0x30F6) ? r - 0x60 : r)
      .map((c) => String.fromCharCode(c))
      .join();
  static String hiraToKata(String text) => text.runes
      .map((r) => (r >= 0x3041 && r <= 0x3096) ? r + 0x60 : r)
      .map((c) => String.fromCharCode(c))
      .join();
  static String fullAlphaToHalf(String text) => text.runes
      .map((r) => (r >= 0xFF21 && r <= 0xFF3A || r >= 0xFF41 && r <= 0xFF5A)
          ? r - 0xFEE0
          : r)
      .map((c) => String.fromCharCode(c))
      .join();
  static String fullNumToHalf(String text) => text.runes
      .map((r) => (r >= 0xFF10 && r <= 0xFF19) ? r - 0xFEE0 : r)
      .map((c) => String.fromCharCode(c))
      .join();
}
