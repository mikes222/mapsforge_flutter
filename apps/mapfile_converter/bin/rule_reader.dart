import 'dart:io';

import 'package:dart_rendertheme/rendertheme.dart';
import 'package:dart_rendertheme/src/rule/rule_analyzer.dart';

class RuleReader {
  Future<(RuleAnalyzer, RenderTheme)> readFile(String filename) async {
    File file = File(filename);
    String content = await file.readAsString();
    return readSource(content);
  }

  Future<(RuleAnalyzer, RenderTheme)> readSource(String content) async {
    RenderTheme renderTheme = RenderThemeBuilder.createFromString(content);
    RuleAnalyzer ruleAnalyzer = RuleAnalyzer();
    for (Rule rule in renderTheme.rulesList) {
      ruleAnalyzer.apply(rule);
    }
    return (ruleAnalyzer, renderTheme);
  }
}
