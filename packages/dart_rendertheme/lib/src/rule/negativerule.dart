import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/src/matcher/attributematcher.dart';
import 'package:dart_rendertheme/src/matcher/indoornotationmatcher.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_node.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_way.dart';

import 'rule.dart';

class NegativeRule extends Rule {
  final AttributeMatcher attributeMatcher;

  NegativeRule({
    required this.attributeMatcher,
    required super.zoomlevelRange,
    required super.subRules,
    required super.renderInstructionNodes,
    required super.renderInstructionOpenWays,
    required super.renderInstructionClosedWays,
  });

  @override
  NegativeRule? forZoomlevel(int zoomlevel) {
    if (!matchesForZoomLevel(zoomlevel)) {
      return null;
    }

    List<RenderInstructionNode> renderInstructionNodes = [];
    for (var renderInstruction in super.renderInstructionNodes) {
      renderInstructionNodes.add(renderInstruction.forZoomlevel(zoomlevel));
    }
    List<RenderInstructionWay> renderInstructionOpenWays = [];
    for (var renderInstruction in super.renderInstructionOpenWays) {
      renderInstructionOpenWays.add(renderInstruction.forZoomlevel(zoomlevel));
    }
    List<RenderInstructionWay> renderInstructionClosedWays = [];
    for (var renderInstruction in super.renderInstructionClosedWays) {
      renderInstructionClosedWays.add(renderInstruction.forZoomlevel(zoomlevel));
    }
    List<Rule> subRules = [];
    for (var subRule in super.subRules) {
      Rule? rule = subRule.forZoomlevel(zoomlevel);
      if (rule != null) subRules.add(rule);
    }

    return NegativeRule(
      attributeMatcher: attributeMatcher,
      zoomlevelRange: ZoomlevelRange(zoomlevel, zoomlevel),
      subRules: subRules,
      renderInstructionNodes: renderInstructionNodes,
      renderInstructionOpenWays: renderInstructionOpenWays,
      renderInstructionClosedWays: renderInstructionClosedWays,
    );
  }

  @override
  bool matchesForZoomLevel(int zoomlevel) {
    return zoomlevelRange.matches(zoomlevel);
  }

  @override
  bool matches(List<Tag> tags, int indoorLevel) {
    return IndoorNotationMatcher.isOutdoorOrMatchesIndoorLevel(tags, indoorLevel) && attributeMatcher.matchesTagList(tags);
  }

  @override
  bool matchesTags(List<Tag> tags) {
    return attributeMatcher.matchesTagList(tags);
  }

  @override
  String toString() {
    return 'NegativeRule{attributeMatcher: $attributeMatcher, super: ${super.toString()}}';
  }
}
