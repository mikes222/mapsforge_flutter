import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/anymatcher.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/attributematcher.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/closedwaymatcher.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/elementnodematcher.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/elementwaymatcher.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/instruction_instructions.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/keymatcher.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/linearwaymatcher.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/negativematcher.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/negativerule.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/positiverule.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/rule.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/shape_instructions.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/valuematcher.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_caption.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_pathtext.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/renderinstruction/renderinstruction_caption.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/renderinstruction/renderinstruction_node.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/renderinstruction/renderinstruction_pathtext.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/renderinstruction/renderinstruction_way.dart';

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
    RuleVisitorImpl ruleVisitorImpl = RuleVisitorImpl();
    for (Rule rule in renderTheme.rulesList) {
      ruleVisitorImpl.apply(rule);
    }

    print("================================================================");
    print("Keys used in renderInstructions: ");
    ruleVisitorImpl.keys.forEach((key) => print("  $key"));
    print("================================================================");
    print("Nodes:");
    printValueInfos(ruleVisitorImpl.nodes.matchers);
    print(".......... Negation rules");
    printValueInfos(ruleVisitorImpl.nodes.negativeMatchers);
    print("================================================================");
    print("Openways:");
    printValueInfos(ruleVisitorImpl.openWays.matchers);
    print(".......... Negation rules");
    printValueInfos(ruleVisitorImpl.openWays.negativeMatchers);
    print("================================================================");
    print("Closedways:");
    printValueInfos(ruleVisitorImpl.closedWays.matchers);
    print(".......... Negation rules");
    printValueInfos(ruleVisitorImpl.closedWays.negativeMatchers);
    print("================================================================");
    print("Overall summary:");
    Map<String, ValueInfo> values = createSummary(ruleVisitorImpl);
    printValueInfos(values);
    print(".......... Keys only");
    print("${values.keys.toSet().sorted().join(",")}");
    print("  You should also keep: layer,type");
    print(".......... Keys in renderInstructions");
    print("${ruleVisitorImpl.keys.join(",")}");
  });
}

void printValueInfos(Map<String, ValueInfo> values) {
  for (MapEntry<String, ValueInfo> entry in values.entries) {
    print("  ${entry.key}=${entry.value.values.join(",")}");
  }
}

ValueInfo append(Map<String, ValueInfo> values, String key) {
  ValueInfo? valueInfo = values[key];
  if (valueInfo == null) {
    valueInfo = ValueInfo();
    values[key] = valueInfo;
  }
  return valueInfo;
}

Map<String, ValueInfo> createSummary(RuleVisitorImpl ruleVisitorImpl) {
  Map<String, ValueInfo> values = {};
  // do not add keys since they are from instructions and not from rules
  // ruleVisitorImpl.keys.forEach((key) {
  //   ValueInfo? valueInfo = append(values, key);
  //   valueInfo.values.add("*");
  // });
  for (MapEntry<String, ValueInfo> entry
      in ruleVisitorImpl.nodes.matchers.entries) {
    ValueInfo? valueInfo = append(values, entry.key);
    valueInfo.values.addAll(entry.value.values);
  }
  for (MapEntry<String, ValueInfo> entry
      in ruleVisitorImpl.nodes.negativeMatchers.entries) {
    ValueInfo? valueInfo = append(values, entry.key);
    valueInfo.values.addAll(entry.value.values);
  }
  for (MapEntry<String, ValueInfo> entry
      in ruleVisitorImpl.openWays.matchers.entries) {
    ValueInfo? valueInfo = append(values, entry.key);
    valueInfo.values.addAll(entry.value.values);
  }
  for (MapEntry<String, ValueInfo> entry
      in ruleVisitorImpl.openWays.negativeMatchers.entries) {
    ValueInfo? valueInfo = append(values, entry.key);
    valueInfo.values.addAll(entry.value.values);
  }
  for (MapEntry<String, ValueInfo> entry
      in ruleVisitorImpl.closedWays.matchers.entries) {
    ValueInfo? valueInfo = append(values, entry.key);
    valueInfo.values.addAll(entry.value.values);
  }
  for (MapEntry<String, ValueInfo> entry
      in ruleVisitorImpl.closedWays.negativeMatchers.entries) {
    ValueInfo? valueInfo = append(values, entry.key);
    valueInfo.values.addAll(entry.value.values);
  }
  return values;
}

//////////////////////////////////////////////////////////////////////////////

class RuleVisitorImpl extends RuleVisitor {
  final ElementInfo closedWays = ElementInfo();
  final ElementInfo openWays = ElementInfo();
  final ElementInfo nodes = ElementInfo();

  final Set<String> keys = {};

  @override
  void apply(Rule rule) {
    analyzeRule(rule, 0);
    //    super.apply(rule);
  }

  void analyzeRule(Rule rule, int level) {
    if (rule.elementMatcher is ElementWayMatcher) {
      if (rule.closedMatcher is ClosedWayMatcher) {
        addClosedWay(rule);
      } else if (rule.closedMatcher is LinearWayMatcher) {
        addOpenWay(rule);
      } else if (rule.closedMatcher is AnyMatcher) {
        addClosedWay(rule);
        addOpenWay(rule);
      } else {
        print("Unknown closedMatcher ${rule.closedMatcher} for ways");
      }
    } else if (rule.elementMatcher is ElementNodeMatcher) {
      if (rule.closedMatcher is ClosedWayMatcher) {
        print("Unknown closedMatcher ${rule.closedMatcher} for closed node");
      } else if (rule.closedMatcher is LinearWayMatcher) {
        print("Unknown closedMatcher ${rule.closedMatcher} for open node");
      } else if (rule.closedMatcher is AnyMatcher) {
        addNode(rule);
      } else {
        print("Unknown closedMatcher ${rule.closedMatcher} for nodes");
      }
    } else if (rule.elementMatcher is AnyMatcher) {
      if (rule.closedMatcher is ClosedWayMatcher) {
        addClosedWay(rule);
      } else if (rule.closedMatcher is LinearWayMatcher) {
        addOpenWay(rule);
      } else if (rule.closedMatcher is AnyMatcher) {
        addClosedWay(rule);
        addOpenWay(rule);
        addNode(rule);
      } else {
        print("Unknown closedMatcher ${rule.closedMatcher} for any");
      }
    } else {
      print("Unknown elementMatcher ${rule.elementMatcher}");
    }
    if (rule is PositiveRule) {
      print(
          "${' ' * level * 2}Zoom: ${rule.zoomMin} - ${rule.zoomMax}, ${rule.elementMatcher is ElementWayMatcher ? "Way" : rule.elementMatcher is ElementNodeMatcher ? "Node" : "Any Element"}, ${rule.closedMatcher is ClosedWayMatcher ? "Closed" : rule.closedMatcher is LinearWayMatcher ? "Open" : rule.closedMatcher is AnyMatcher ? "OpenOrClosed" : "Unknown"}, keyMatcher: ${rule.keyMatcher}, valueMatcher: ${rule.valueMatcher}");
    } else if (rule is NegativeRule) {
      print(
          "${' ' * level * 2}Zoom: ${rule.zoomMin} - ${rule.zoomMax}, ${rule.elementMatcher is ElementWayMatcher ? "Way" : rule.elementMatcher is ElementNodeMatcher ? "Node" : "Any Element"}, ${rule.closedMatcher is ClosedWayMatcher ? "Closed" : rule.closedMatcher is LinearWayMatcher ? "Open" : rule.closedMatcher is AnyMatcher ? "OpenOrClosed" : "Unknown"}, attributeMatcher: ${rule.attributeMatcher}");
    } else {
      print("${' ' * level * 2}Unknown rule ${rule.runtimeType}");
    }
    if (rule.instructions is InstructionInstructions) {
      for (RenderInstructionNode renderInstruction
          in (rule.instructions as InstructionInstructions)
              .renderInstructionNodes) {
        print("${' ' * level * 2}--> Node ${renderInstruction.runtimeType}");
        if (renderInstruction is RenderinstructionCaption) {
          String? textKey = renderInstruction.base.textKey?.key;
          if (textKey != null) keys.add(textKey);
        }
      }
      for (RenderInstructionWay renderInstruction
          in (rule.instructions as InstructionInstructions)
              .renderInstructionOpenWays) {
        print(
            "${' ' * level * 2}--> Open Way ${renderInstruction.runtimeType}");
        if (renderInstruction is RenderinstructionCaption) {
          String? textKey = renderInstruction.base.textKey?.key;
          if (textKey != null) keys.add(textKey);
        } else if (renderInstruction is RenderinstructionPathtext) {
          String? textKey = renderInstruction.base.textKey?.key;
          if (textKey != null) keys.add(textKey);
        }
      }
      for (RenderInstructionWay renderInstruction
          in (rule.instructions as InstructionInstructions)
              .renderInstructionClosedWays) {
        print(
            "${' ' * level * 2}--> Closed Way ${renderInstruction.runtimeType}");
        if (renderInstruction is RenderinstructionCaption) {
          String? textKey = renderInstruction.base.textKey?.key;
          if (textKey != null) keys.add(textKey);
        } else if (renderInstruction is RenderinstructionPathtext) {
          String? textKey = renderInstruction.base.textKey?.key;
          if (textKey != null) keys.add(textKey);
        }
      }
    } else {
      for (Shape shape in (rule.instructions as ShapeInstructions).shapeNodes) {
        print(
            "${' ' * level * 2}--> Node ${shape.runtimeType}, level ${shape.level}");
        if (shape is ShapeCaption) {
          String? textKey = shape.textKey?.key;
          if (textKey != null) keys.add(textKey);
        }
      }
      for (Shape shape
          in (rule.instructions as ShapeInstructions).shapeOpenWays) {
        print(
            "${' ' * level * 2}--> Open Way ${shape.runtimeType}, level ${shape.level}");
        if (shape is ShapeCaption) {
          String? textKey = shape.textKey?.key;
          if (textKey != null) keys.add(textKey);
        } else if (shape is ShapePathtext) {
          String? textKey = shape.textKey?.key;
          if (textKey != null) keys.add(textKey);
        }
      }
      for (Shape shape
          in (rule.instructions as ShapeInstructions).shapeClosedWays) {
        print(
            "${' ' * level * 2}--> Closed Way ${shape.runtimeType}, level ${shape.level}");
        if (shape is ShapeCaption) {
          String? textKey = shape.textKey?.key;
          if (textKey != null) keys.add(textKey);
        } else if (shape is ShapePathtext) {
          String? textKey = shape.textKey?.key;
          if (textKey != null) keys.add(textKey);
        }
      }
    }
    for (Rule subRule in rule.subRules) {
      analyzeRule(subRule, level + 2);
    }
  }

  void addClosedWay(Rule rule) {
    if (rule is PositiveRule) {
      closedWays.addKeyValue(rule.keyMatcher, rule.valueMatcher);
    } else if (rule is NegativeRule) {
      closedWays.addAttribute(rule.attributeMatcher);
    } else {
      print("Unknown rule ${rule.runtimeType}");
    }
  }

  void addOpenWay(Rule rule) {
    if (rule is PositiveRule) {
      openWays.addKeyValue(rule.keyMatcher, rule.valueMatcher);
    } else if (rule is NegativeRule) {
      openWays.addAttribute(rule.attributeMatcher);
    } else {
      print("Unknown rule ${rule.runtimeType}");
    }
  }

  void addNode(Rule rule) {
    if (rule is PositiveRule) {
      nodes.addKeyValue(rule.keyMatcher, rule.valueMatcher);
    } else if (rule is NegativeRule) {
      nodes.addAttribute(rule.attributeMatcher);
    } else {
      print("Unknown rule ${rule.runtimeType}");
    }
  }
}

//////////////////////////////////////////////////////////////////////////////

class ElementInfo {
  Map<String, ValueInfo> matchers = {};

  Map<String, ValueInfo> negativeMatchers = {};

  bool any = false;

  void addKeyValue(AttributeMatcher keyMatcher, AttributeMatcher valueMatcher) {
    if (keyMatcher is KeyMatcher) {
      for (String key in keyMatcher.keys) {
        ValueInfo? valueInfo = matchers[key];
        if (valueInfo == null) {
          valueInfo = ValueInfo();
          matchers[key] = valueInfo;
        }
        valueInfo.addValues(valueMatcher);
      }
    } else if (keyMatcher is AnyMatcher) {
      if (valueMatcher is AnyMatcher) {
        // if (any == true) {
        //   print("any is already true");
        // }
        any = true;
      } else {
        print(
            "Unknown valueMatcher ${valueMatcher.runtimeType} for keyMatcher AnyMatcher");
      }
    } else {
      print("Unknown keyMatcher ${keyMatcher.runtimeType}");
    }
  }

  void addAttribute(AttributeMatcher attributeMatcher) {
    if (attributeMatcher is NegativeMatcher) {
      for (String key in attributeMatcher.keys) {
        ValueInfo? valueInfo = negativeMatchers[key];
        if (valueInfo == null) {
          valueInfo = ValueInfo();
          negativeMatchers[key] = valueInfo;
        }
        valueInfo.addValues(attributeMatcher);
      }
    } else {
      print("Unknown attributeMatcher ${attributeMatcher.runtimeType}");
    }
  }
}

//////////////////////////////////////////////////////////////////////////////

class ValueInfo {
  Set<String> values = {};

  bool _any = false;

  void addValues(AttributeMatcher valueMatcher) {
    if (valueMatcher is ValueMatcher) {
      values.addAll(valueMatcher.values);
    } else if (valueMatcher is NegativeMatcher) {
      values.addAll(valueMatcher.values);
    } else if (valueMatcher is AnyMatcher) {
      _any = true;
      values.add("*");
    } else {
      print("Unknown matcher ${valueMatcher.runtimeType}");
    }
  }
}

//////////////////////////////////////////////////////////////////////////////

void _initLogging() {
// Print output to console.
  Logger.root.onRecord.listen((LogRecord r) {
    print('${r.time}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
  });
  Logger.root.level = Level.FINEST;
}
