import 'dart:io';

import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/special.dart';

class RuleReader {
  Future<(RuleAnalyzer, RenderTheme)> readFile(String filename, {int maxZoomLevel = 20}) async {
    File file = File(filename);
    String content = await file.readAsString();
    return readSource(content, maxZoomLevel: maxZoomLevel);
  }

  Future<(RuleAnalyzer, RenderTheme)> readSource(String content, {int maxZoomLevel = 20}) async {
    DisplayModel displayModel = DisplayModel(maxZoomLevel: maxZoomLevel);
    RenderTheme renderTheme = RenderThemeBuilder.parse(displayModel, content);
    RuleAnalyzer ruleAnalyzer = RuleAnalyzer();
    for (Rule rule in renderTheme.rulesList) {
      ruleAnalyzer.apply(rule);
    }
    return (ruleAnalyzer, renderTheme);
  }
}
