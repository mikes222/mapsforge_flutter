import 'dart:io';

import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';
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

  test('should parse stylemenu', () {
    final xml = '''<?xml version="1.0" encoding="UTF-8"?>
<rendertheme xmlns="http://mapsforge.org/renderTheme" version="6">
  <stylemenu id="menu" defaultvalue="main" defaultlang="en">
    <layer id="overlay1" enabled="true">
      <name lang="en" value="Overlay" />
      <cat id="c1" />
      <cat id="c2" />
    </layer>
    <layer id="main" parent="base" visible="true">
      <name lang="en" value="Main" />
      <overlay id="overlay1" />
    </layer>
  </stylemenu>
  <rule e="way" k="natural" v="sea"><area fill="#ffffff" /></rule>
</rendertheme>
''';

    final theme = RenderThemeBuilder.createFromString(xml);
    expect(theme.styleMenu, isNotNull);
    expect(theme.styleMenu!.id, 'menu');
    expect(theme.styleMenu!.defaultValue, 'main');
    expect(theme.styleMenu!.defaultLang, 'en');

    final overlay = theme.styleMenu!.layerById('overlay1');
    expect(overlay, isNotNull);
    expect(overlay!.enabled, isTrue);
    expect(overlay.categories, containsAll(['c1', 'c2']));
    expect(overlay.nameForLang('en'), 'Overlay');

    final main = theme.styleMenu!.layerById('main');
    expect(main, isNotNull);
    expect(main!.visible, isTrue);
    expect(main.parent, 'base');
    expect(main.overlays, ['overlay1']);
  });
}

void _initLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}
