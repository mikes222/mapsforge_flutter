import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/rule.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/rule_analyzer.dart';

import '../testassetbundle.dart';

/// analyzes the rendertheme.xml and prints a lot of summaries. This can be used to filter mapfiles so only used tags are included.
main() async {
  test("MultimapDatastore without maps", () async {
    _initLogging();
    DisplayModel displayModel = DisplayModel();

    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder();
    String content = await TestAssetBundle().loadString("lightrender.xml");
    renderThemeBuilder.parseXml(displayModel, content);
    RenderTheme renderTheme = renderThemeBuilder.build();
    int zoomLevel = 18;
    RenderthemeLevel renderthemeLevel = renderTheme.prepareZoomlevel(zoomLevel);
    RuleAnalyzer ruleAnalyzer = RuleAnalyzer();
    for (Rule rule in renderTheme.rulesList) {
      ruleAnalyzer.apply(rule);
    }

    print("================================================================");
    print("Keys used in renderInstructions: ");
    ruleAnalyzer.keys.forEach((key) => print("  $key"));
    print("================================================================");
    print("Nodes:");
    printValueInfos(ruleAnalyzer.nodes.matchers);
    print(".......... Negation rules");
    printValueInfos(ruleAnalyzer.nodes.negativeMatchers);
    print("================================================================");
    print("Openways:");
    printValueInfos(ruleAnalyzer.openWays.matchers);
    print(".......... Negation rules");
    printValueInfos(ruleAnalyzer.openWays.negativeMatchers);
    print("================================================================");
    print("Closedways:");
    printValueInfos(ruleAnalyzer.closedWays.matchers);
    print(".......... Negation rules");
    printValueInfos(ruleAnalyzer.closedWays.negativeMatchers);
    print("================================================================");
    print("Overall summary:");
    Map<String, ValueInfo> values = createSummary(ruleAnalyzer);
    printValueInfos(values);
    print(".......... Keys only");
    print("${values.keys.toSet().sorted().join(",")}");
    print("  You should also keep: layer,type");
    print(".......... Keys in renderInstructions");
    print("${ruleAnalyzer.keys.join(",")}");
  });
}

void printValueInfos(Map<String, ValueInfo> values) {
  for (MapEntry<String, ValueInfo> entry in values.entries) {
    print("  ${entry.key}=${entry.value.values.join(",")}");
  }
}

Map<String, ValueInfo> createSummary(RuleAnalyzer ruleAnalyzer) {
  Map<String, ValueInfo> values = {};
  // do not add keys since they are from instructions and not from rules
  // ruleVisitorImpl.keys.forEach((key) {
  //   ValueInfo? valueInfo = append(values, key);
  //   valueInfo.values.add("*");
  // });
  values.addAll(ruleAnalyzer.nodeValueinfos());
  values.addAll(ruleAnalyzer.openWayValueinfos());
  values.addAll(ruleAnalyzer.closedWayValueinfos());
  return values;
}

//////////////////////////////////////////////////////////////////////////////

void _initLogging() {
// Print output to console.
  Logger.root.onRecord.listen((LogRecord r) {
    print('${r.time}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
  });
  Logger.root.level = Level.FINEST;
}
