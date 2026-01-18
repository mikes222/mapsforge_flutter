import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/anymatcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/attributematcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/keymatcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/negativematcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/valuematcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/renderinstruction_caption.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/renderinstruction_node.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/renderinstruction_polyline_text.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/renderinstruction_way.dart';
import 'package:mapsforge_flutter_rendertheme/src/rule/negativerule.dart';
import 'package:mapsforge_flutter_rendertheme/src/rule/positiverule.dart';

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
  void apply(Rule r) {
    analyzeRule(r, 0);
    //    super.apply(rule);
  }

  void analyzeRule(Rule rule, int level) {
    if (debug) print("${' ' * level * 2}Rule $rule");
    for (RenderinstructionNode renderInstruction in rule.renderinstructionNodes) {
      if (debug) print("${' ' * level * 2}--> Node ${renderInstruction.runtimeType} ${renderInstruction.level}");
      addNode(rule);
      if (renderInstruction is RenderinstructionCaption) {
        String? textKey = renderInstruction.textKey?.key;
        if (textKey != null) keys.add(textKey);
      }
    }
    for (RenderinstructionWay renderInstruction in rule.renderinstructionOpenWays) {
      if (debug) print("${' ' * level * 2}--> Open Way ${renderInstruction.runtimeType} ${renderInstruction.level}");
      addOpenWay(rule);
      if (renderInstruction is RenderinstructionCaption) {
        String? textKey = renderInstruction.textKey?.key;
        if (textKey != null) keys.add(textKey);
      } else if (renderInstruction is RenderinstructionPolylineText) {
        String? textKey = renderInstruction.textKey?.key;
        if (textKey != null) keys.add(textKey);
      }
    }
    for (RenderinstructionWay renderInstruction in rule.renderinstructionClosedWays) {
      if (debug) print("${' ' * level * 2}--> Closed Way ${renderInstruction.runtimeType} ${renderInstruction.level}");
      addClosedWay(rule);
      if (renderInstruction is RenderinstructionCaption) {
        String? textKey = renderInstruction.textKey?.key;
        if (textKey != null) keys.add(textKey);
      } else if (renderInstruction is RenderinstructionPolylineText) {
        String? textKey = renderInstruction.textKey?.key;
        if (textKey != null) keys.add(textKey);
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

  void addValues(AttributeMatcher valueMatcher) {
    if (valueMatcher is ValueMatcher) {
      values.addAll(valueMatcher.values);
    } else if (valueMatcher is NegativeMatcher) {
      values.addAll(valueMatcher.values);
    } else if (valueMatcher is AnyMatcher) {
      values.add("*");
    } else {
      print("Unknown matcher ${valueMatcher.runtimeType}");
    }
  }

  @override
  String toString() {
    return 'ValueInfo{values: $values}';
  }
}
