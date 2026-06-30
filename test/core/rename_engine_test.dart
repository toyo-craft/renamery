import 'package:flutter_test/flutter_test.dart';
import 'package:renamery/core/rename_engine.dart';

void main() {
  group('RenameEngine.computeGeneratePreviews', () {
    test('replaces text in the base name and keeps the extension', () {
      final result = _preview(
        mode: RenameMode.replace,
        originalName: 'report_final.txt',
        findText: 'final',
        replaceText: 'draft',
      );

      expect(result['newName'], 'report_draft.txt');
      expect(result['error'], isNull);
    });

    test('supports regex capture replacement in the base name', () {
      final result = _preview(
        mode: RenameMode.replace,
        originalName: 'chapter_12.mp4',
        findText: r'chapter_(\d+)',
        replaceText: r'episode_$1',
        useRegex: true,
      );

      expect(result['newName'], 'episode_12.mp4');
      expect(result['error'], isNull);
    });

    test('changes extension and normalizes a missing dot', () {
      final result = _preview(
        mode: RenameMode.extension,
        originalName: 'photo.JPG',
        replaceText: 'png',
      );

      expect(result['newName'], 'photo.png');
      expect(result['error'], isNull);
    });

    test('prepends a formatted modified date', () {
      final result = _preview(
        mode: RenameMode.appendDate,
        originalName: 'report.txt',
        dateFormat: 'yyyyMMdd_',
        modified: DateTime(2026, 6, 30, 12, 34),
      );

      expect(result['newName'], '20260630_report.txt');
      expect(result['error'], isNull);
    });

    test('reports invalid Windows filename characters', () {
      final result = _preview(
        mode: RenameMode.append,
        originalName: 'report.txt',
        appendText: ':bad',
        validationType: ValidationType.windows,
      );

      expect(result['newName'], 'report:bad.txt');
      expect(result['error'], 'ファイル名に使用できない文字が含まれています');
    });

    test('reports an empty filename after deletion', () {
      final result = _preview(
        mode: RenameMode.deleteStart,
        originalName: 'abc',
        digits: 3,
      );

      expect(result['newName'], '');
      expect(result['error'], 'ファイル名が空です');
    });
  });
}

Map<String, String?> _preview({
  required RenameMode mode,
  required String originalName,
  bool isDirectory = false,
  String? findText,
  String? replaceText,
  String? appendText,
  int startNumber = 1,
  int insertIndex = 1,
  int digits = 3,
  CaseConversion caseConversion = CaseConversion.none,
  bool extensionToLowerCase = false,
  bool useRegex = false,
  String? listText,
  String? dateFormat,
  DatePosition datePosition = DatePosition.front,
  ValidationType validationType = ValidationType.auto,
  DateTime? modified,
  bool isWindows = false,
  bool isMacOS = false,
}) {
  final results = RenameEngine.computeGeneratePreviews({
    'mode': mode,
    'fileData': [
      {
        'originalName': originalName,
        'isDirectory': isDirectory,
        'modified': modified ?? DateTime(2026),
      },
    ],
    'findText': findText,
    'replaceText': replaceText,
    'appendText': appendText,
    'startNumber': startNumber,
    'insertIndex': insertIndex,
    'digits': digits,
    'caseConversion': caseConversion,
    'extensionToLowerCase': extensionToLowerCase,
    'useRegex': useRegex,
    'numberingMode': NumberingMode.stringNumber,
    'listText': listText,
    'dateFormat': dateFormat,
    'datePosition': datePosition,
    'validationType': validationType,
    'isWindows': isWindows,
    'isMacOS': isMacOS,
  });

  return results.single;
}
