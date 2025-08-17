import 'package:mapsforge_flutter/src/rendertheme/rule/keymatcher.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/positiverule.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/rule.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/shape_instructions.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/valuematcher.dart';

import '../../../core.dart';
import '../shape/shape_caption.dart';
import '../shape/shape_pathtext.dart';
import '../xml/renderinstruction/renderinstruction_caption.dart';
import '../xml/renderinstruction/renderinstruction_node.dart';
import '../xml/renderinstruction/renderinstruction_pathtext.dart';
import '../xml/renderinstruction/renderinstruction_way.dart';
import 'anymatcher.dart';
import 'attributematcher.dart';
import 'closedwaymatcher.dart';
import 'elementnodematcher.dart';
import 'elementwaymatcher.dart';
import 'instruction_instructions.dart';
import 'linearwaymatcher.dart';
import 'negativematcher.dart';
import 'negativerule.dart';

/// Analyzes the given rules to identify the specific tags that influence the
/// output. Put another way, if a node or way does not possess these identified
/// tags, it will not be considered for rendering.
class RuleAnalyzer extends RuleVisitor {
  final ElementInfo closedWays = ElementInfo();
  final ElementInfo openWays = ElementInfo();
  final ElementInfo nodes = ElementInfo();

  final Set<String> keys = {};

  final bool debug = false;

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
      if (debug)
        print(
            "${' ' * level * 2}Zoom: ${rule.zoomlevelRange.zoomlevelMin} - ${rule.zoomlevelRange.zoomlevelMax}, ${rule.elementMatcher is ElementWayMatcher ? "Way" : rule.elementMatcher is ElementNodeMatcher ? "Node" : "Any Element"}, ${rule.closedMatcher is ClosedWayMatcher ? "Closed" : rule.closedMatcher is LinearWayMatcher ? "Open" : rule.closedMatcher is AnyMatcher ? "OpenOrClosed" : "Unknown"}, keyMatcher: ${rule.keyMatcher}, valueMatcher: ${rule.valueMatcher}");
    } else if (rule is NegativeRule) {
      if (debug)
        print(
            "${' ' * level * 2}Zoom: ${rule.zoomlevelRange.zoomlevelMin} - ${rule.zoomlevelRange.zoomlevelMax}, ${rule.elementMatcher is ElementWayMatcher ? "Way" : rule.elementMatcher is ElementNodeMatcher ? "Node" : "Any Element"}, ${rule.closedMatcher is ClosedWayMatcher ? "Closed" : rule.closedMatcher is LinearWayMatcher ? "Open" : rule.closedMatcher is AnyMatcher ? "OpenOrClosed" : "Unknown"}, attributeMatcher: ${rule.attributeMatcher}");
    } else {
      print("${' ' * level * 2}Unknown rule ${rule.runtimeType}");
    }
    if (rule.instructions is InstructionInstructions) {
      for (RenderInstructionNode renderInstruction in (rule.instructions as InstructionInstructions).renderInstructionNodes) {
        if (debug) print("${' ' * level * 2}--> Node ${renderInstruction.runtimeType}");
        if (renderInstruction is RenderinstructionCaption) {
          String? textKey = renderInstruction.base.textKey?.key;
          if (textKey != null) keys.add(textKey);
        }
      }
      for (RenderInstructionWay renderInstruction in (rule.instructions as InstructionInstructions).renderInstructionOpenWays) {
        if (debug) print("${' ' * level * 2}--> Open Way ${renderInstruction.runtimeType}");
        if (renderInstruction is RenderinstructionCaption) {
          String? textKey = renderInstruction.base.textKey?.key;
          if (textKey != null) keys.add(textKey);
        } else if (renderInstruction is RenderinstructionPathtext) {
          String? textKey = renderInstruction.base.textKey?.key;
          if (textKey != null) keys.add(textKey);
        }
      }
      for (RenderInstructionWay renderInstruction in (rule.instructions as InstructionInstructions).renderInstructionClosedWays) {
        if (debug) print("${' ' * level * 2}--> Closed Way ${renderInstruction.runtimeType}");
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
        if (debug) print("${' ' * level * 2}--> Node ${shape.runtimeType}, level ${shape.level}");
        if (shape is ShapeCaption) {
          String? textKey = shape.textKey?.key;
          if (textKey != null) keys.add(textKey);
        }
      }
      for (Shape shape in (rule.instructions as ShapeInstructions).shapeOpenWays) {
        if (debug) print("${' ' * level * 2}--> Open Way ${shape.runtimeType}, level ${shape.level}");
        if (shape is ShapeCaption) {
          String? textKey = shape.textKey?.key;
          if (textKey != null) keys.add(textKey);
        } else if (shape is ShapePathtext) {
          String? textKey = shape.textKey?.key;
          if (textKey != null) keys.add(textKey);
        }
      }
      for (Shape shape in (rule.instructions as ShapeInstructions).shapeClosedWays) {
        if (debug) print("${' ' * level * 2}--> Closed Way ${shape.runtimeType}, level ${shape.level}");
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

  Map<String, ValueInfo> nodeValueinfos() {
    Map<String, ValueInfo> values = {};
    for (MapEntry<String, ValueInfo> entry in nodes.matchers.entries) {
      ValueInfo? valueInfo = _append(values, entry.key);
      valueInfo.values.addAll(entry.value.values);
    }
    return values;
  }

  Map<String, ValueInfo> nodeNegativeValueinfos() {
    Map<String, ValueInfo> values = {};
    for (MapEntry<String, ValueInfo> entry in nodes.negativeMatchers.entries) {
      ValueInfo? valueInfo = _append(values, entry.key);
      valueInfo.values.addAll(entry.value.values);
    }
    return values;
  }

  Map<String, ValueInfo> openWayValueinfos() {
    Map<String, ValueInfo> values = {};
    for (MapEntry<String, ValueInfo> entry in openWays.matchers.entries) {
      ValueInfo? valueInfo = _append(values, entry.key);
      valueInfo.values.addAll(entry.value.values);
    }
    return values;
  }

  Map<String, ValueInfo> openWayNegativeValueinfos() {
    Map<String, ValueInfo> values = {};
    for (MapEntry<String, ValueInfo> entry in openWays.negativeMatchers.entries) {
      ValueInfo? valueInfo = _append(values, entry.key);
      valueInfo.values.addAll(entry.value.values);
    }
    return values;
  }

  Map<String, ValueInfo> closedWayValueinfos() {
    Map<String, ValueInfo> values = {};
    for (MapEntry<String, ValueInfo> entry in closedWays.matchers.entries) {
      ValueInfo? valueInfo = _append(values, entry.key);
      valueInfo.values.addAll(entry.value.values);
    }
    return values;
  }

  Map<String, ValueInfo> closedWayNegativeValueinfos() {
    Map<String, ValueInfo> values = {};
    for (MapEntry<String, ValueInfo> entry in closedWays.negativeMatchers.entries) {
      ValueInfo? valueInfo = _append(values, entry.key);
      valueInfo.values.addAll(entry.value.values);
    }
    return values;
  }

  Map<String, ValueInfo> wayValueinfos() {
    Map<String, ValueInfo> values = {};
    values.addAll(closedWayValueinfos());
    values.addAll(openWayValueinfos());
    return values;
  }

  Map<String, ValueInfo> wayNegativeValueinfos() {
    Map<String, ValueInfo> values = {};
    values.addAll(closedWayNegativeValueinfos());
    values.addAll(openWayNegativeValueinfos());
    return values;
  }

  ValueInfo _append(Map<String, ValueInfo> values, String key) {
    ValueInfo? valueInfo = values[key];
    if (valueInfo == null) {
      valueInfo = ValueInfo();
      values[key] = valueInfo;
    }
    return valueInfo;
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
        print("Unknown valueMatcher ${valueMatcher.runtimeType} for keyMatcher AnyMatcher");
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

  @override
  String toString() {
    return 'ValueInfo{values: $values, _any: $_any}';
  }
}
