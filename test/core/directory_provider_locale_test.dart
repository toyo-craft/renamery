import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:renamery/core/directory_provider.dart';

void main() {
  group('DirectoryProvider.defaultMenuLabelTypeForLocale', () {
    test('uses the matching supported language for first launch', () {
      expect(
        DirectoryProvider.defaultMenuLabelTypeForLocale(const Locale('ja')),
        MenuLabelType.standard,
      );
      expect(
        DirectoryProvider.defaultMenuLabelTypeForLocale(const Locale('en')),
        MenuLabelType.english,
      );
      expect(
        DirectoryProvider.defaultMenuLabelTypeForLocale(const Locale('zh')),
        MenuLabelType.chinese,
      );
      expect(
        DirectoryProvider.defaultMenuLabelTypeForLocale(const Locale('es')),
        MenuLabelType.spanish,
      );
    });

    test('falls back to English for unsupported languages', () {
      expect(
        DirectoryProvider.defaultMenuLabelTypeForLocale(const Locale('fr')),
        MenuLabelType.english,
      );
    });
  });
}
