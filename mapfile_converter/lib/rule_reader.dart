import 'dart:io';

import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/special.dart';

class RuleReader {
  Future<(RuleAnalyzer, RenderTheme)> readFile(String filename) async {
    File file = File(filename);
    String content = await file.readAsString();
    return readSource(content);
  }

  Future<(RuleAnalyzer, RenderTheme)> readSource(String content) async {
    DisplayModel displayModel = DisplayModel(maxZoomLevel: 20);
    RenderTheme renderTheme = RenderThemeBuilder.parse(displayModel, content);
    RuleAnalyzer ruleAnalyzer = RuleAnalyzer();
    for (Rule rule in renderTheme.rulesList) {
      ruleAnalyzer.apply(rule);
    }
    return (ruleAnalyzer, renderTheme);
  }
}
