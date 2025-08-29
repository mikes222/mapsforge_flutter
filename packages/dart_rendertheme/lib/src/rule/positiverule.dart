import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/src/matcher/attributematcher.dart';
import 'package:dart_rendertheme/src/matcher/indoornotationmatcher.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_node.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_way.dart';

import 'rule.dart';

class PositiveRule extends Rule {
  final AttributeMatcher keyMatcher;
  final AttributeMatcher valueMatcher;

  PositiveRule({
    required this.keyMatcher,
    required this.valueMatcher,
    required super.zoomlevelRange,
    required super.subRules,
    required super.renderinstructionNodes,
    required super.renderinstructionOpenWays,
    required super.renderinstructionClosedWays,
  });

  @override
  PositiveRule? forZoomlevel(int zoomlevel, int getMaxLevel()) {
    if (!matchesForZoomLevel(zoomlevel)) {
      return null;
    }

    List<RenderinstructionNode> renderinstructionNodes = [];
    List<RenderinstructionWay> renderinstructionOpenWays = [];
    List<RenderinstructionWay> renderinstructionClosedWays = [];
    if (super.renderinstructionNodes.isNotEmpty || super.renderinstructionOpenWays.isNotEmpty || super.renderinstructionClosedWays.isNotEmpty) {
      // only retrieve a new level if we need it
      int maxLevel = getMaxLevel();
      for (var renderInstruction in super.renderinstructionNodes) {
        renderinstructionNodes.add(renderInstruction.forZoomlevel(zoomlevel, maxLevel));
      }
      for (var renderInstruction in super.renderinstructionOpenWays) {
        renderinstructionOpenWays.add(renderInstruction.forZoomlevel(zoomlevel, maxLevel));
      }
      for (var renderInstruction in super.renderinstructionClosedWays) {
        renderinstructionClosedWays.add(renderInstruction.forZoomlevel(zoomlevel, maxLevel));
      }
    }
    List<Rule> subRules = [];
    for (var subRule in super.subRules) {
      Rule? rule = subRule.forZoomlevel(zoomlevel, getMaxLevel);
      if (rule != null) subRules.add(rule);
    }

    if (subRules.isEmpty && renderinstructionNodes.isEmpty && renderinstructionOpenWays.isEmpty && renderinstructionClosedWays.isEmpty) return null;
    return PositiveRule(
      keyMatcher: keyMatcher,
      valueMatcher: valueMatcher,
      zoomlevelRange: ZoomlevelRange(zoomlevel, zoomlevel),
      subRules: subRules,
      renderinstructionNodes: renderinstructionNodes,
      renderinstructionOpenWays: renderinstructionOpenWays,
      renderinstructionClosedWays: renderinstructionClosedWays,
    );
  }

  @override
  bool matchesForZoomLevel(int zoomlevel) {
    return zoomlevelRange.matches(zoomlevel);
  }

  @override
  bool matches(List<Tag> tags, int indoorLevel) {
    return IndoorNotationMatcher.isOutdoorOrMatchesIndoorLevel(tags, indoorLevel) && keyMatcher.matchesTagList(tags) && valueMatcher.matchesTagList(tags);
  }

  @override
  bool matchesTags(List<Tag> tags) {
    return keyMatcher.matchesTagList(tags) && valueMatcher.matchesTagList(tags);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PositiveRule && runtimeType == other.runtimeType && keyMatcher == other.keyMatcher && valueMatcher == other.valueMatcher;

  @override
  int get hashCode => keyMatcher.hashCode ^ valueMatcher.hashCode;

  @override
  String toString() {
    return 'PositiveRule{keyMatcher: $keyMatcher, valueMatcher: $valueMatcher, super: ${super.toString()}}';
  }
}
