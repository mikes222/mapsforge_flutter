import 'dart:io';

import 'package:dart_rendertheme/rendertheme.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  late Rendertheme renderTheme;

  setUpAll(() async {
    _initLogging();
    renderTheme = await RenderThemeBuilder.createFromFile("test/defaultrender.xml");
  });

  test('should load defaultrender.xml and create RenderTheme', () {
    // Verify that the RenderTheme was created successfully
    expect(renderTheme, isNotNull);

    // Verify that rules were loaded
    expect(renderTheme.rulesList, isNotEmpty);

    // Verify some basic properties from the default render theme
    expect(renderTheme.baseStrokeWidth, 1.0);
    expect(renderTheme.baseTextSize, 1.0);

    // Verify that the theme has multiple levels (zoom levels)
    expect(renderTheme.maxLevels, greaterThan(0));
  });

  test('should contain expected rules', () {
    // Find some specific rules that should be present in the default render theme
    final ruleTypes = renderTheme.rulesList.map((r) => r.runtimeType.toString()).toSet();

    // Verify that we have rules for different element types
    expect(ruleTypes, contains('PositiveRule'));
    expect(ruleTypes, contains('NegativeRule'));

    // Verify that we have rules for different zoom levels by checking the zoomlevelRange
    final zoomLevelRanges = renderTheme.rulesList.map((r) => r.zoomlevelRange).toSet();
    expect(zoomLevelRanges.length, greaterThan(1));
  });

  test('should handle invalid file path', () async {
    expect(() => RenderThemeBuilder.createFromFile("nonexistent.xml"), throwsA(isA<FileSystemException>()));
  });
}

void _initLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}
