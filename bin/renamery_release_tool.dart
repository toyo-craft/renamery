import 'dart:io';

/// 名前を renamery_release_tool.dart に変更して他プラグイン(cargokit等)との競合を回避
void main(List<String> args) {
  print('--- ReNamery Release Tool (Unified) ---');
  
  if (args.contains('--validate-version')) {
    _validateVersion();
  } else {
    print('Usage: dart bin/renamery_release_tool.dart [--validate-version]');
  }
}

void _validateVersion() {
  print('Validating version consistency...');
  
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found.');
    exit(1);
  }
  
  final pubspecContent = pubspecFile.readAsStringSync();
  final versionMatch = RegExp(r'^version:\s*([^\s+]+)', multiLine: true).firstMatch(pubspecContent);
  if (versionMatch == null) {
    print('Error: Could not find version in pubspec.yaml');
    exit(1);
  }
  final pubspecVersion = versionMatch.group(1);
  
  final changelogFile = File('CHANGELOG.md');
  if (!changelogFile.existsSync()) {
    print('Error: CHANGELOG.md not found.');
    exit(1);
  }
  
  final changelogContent = changelogFile.readAsStringSync();
  final changelogVersionMatch = RegExp(r'##\s*\[([^\]]+)\]').firstMatch(changelogContent);
  if (changelogVersionMatch == null) {
    print('Error: Could not find latest version in CHANGELOG.md');
    exit(1);
  }
  final changelogVersion = changelogVersionMatch.group(1);
  
  print('Pubspec version: $pubspecVersion');
  print('Changelog version: $changelogVersion');
  
  if (pubspecVersion != changelogVersion) {
    print('Error: Version mismatch! pubspec.yaml ($pubspecVersion) != CHANGELOG.md ($changelogVersion)');
    exit(1);
  }
  
  print('Version validation successful.');
}
