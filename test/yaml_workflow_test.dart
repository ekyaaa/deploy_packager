import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('GitHub Actions Workflow YAML validation', () {
    test('all workflow YAML files are valid', () {
      final workflows = [
        '.github/workflows/build-windows-installer.yaml',
        '.github/workflows/build-windows.yaml',
        '.github/workflows/release-please.yaml',
      ];

      for (final path in workflows) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: '$path should exist');
        final content = file.readAsStringSync();
        final doc = loadYaml(content);
        expect(doc, isNotNull, reason: '$path should be valid YAML');
      }
    });

    test('version extraction regex works on pubspec.yaml', () {
      final pubspecContent = File('pubspec.yaml').readAsStringSync();
      final lines = pubspecContent.split('\n');
      final versionLine = lines.firstWhere((line) => line.trim().startsWith('version:'));

      final ver = versionLine.replaceAll(RegExp(r'^version:\s*'), '').trim();
      final semver = ver.split('+')[0].trim();
      final build = ver.contains('+') ? ver.split('+')[1].trim() : '1';

      expect(ver, equals('1.0.0+1'));
      expect(semver, equals('1.0.0'));
      expect(build, equals('1'));

      // Test without build suffix
      const rawNoBuild = 'version: 2.3.4';
      final verNoBuild = rawNoBuild.replaceAll(RegExp(r'^version:\s*'), '').trim();
      final semverNoBuild = verNoBuild.split('+')[0].trim();
      expect(semverNoBuild, equals('2.3.4'));
    });

    test('release-please manifest matches pubspec semver', () {
      final pubspecContent = File('pubspec.yaml').readAsStringSync();
      final lines = pubspecContent.split('\n');
      final versionLine = lines.firstWhere((line) => line.trim().startsWith('version:'));
      final semver = versionLine.replaceAll(RegExp(r'^version:\s*'), '').trim().split('+')[0].trim();

      final manifestContent = File('.release-please-manifest.json').readAsStringSync();
      expect(manifestContent, contains('"$semver"'));
    });
  });
}
