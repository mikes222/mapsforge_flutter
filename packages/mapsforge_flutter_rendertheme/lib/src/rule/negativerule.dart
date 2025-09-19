import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/attributematcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/indoornotationmatcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/renderinstruction_node.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/renderinstruction_way.dart';

import 'rule.dart';

class NegativeRule extends Rule {
  final AttributeMatcher attributeMatcher;

  NegativeRule({
    required this.attributeMatcher,
    required super.zoomlevelRange,
    required super.subRules,
    required super.renderinstructionNodes,
    required super.renderinstructionOpenWays,
    required super.renderinstructionClosedWays,
  });

  @override
  NegativeRule? forZoomlevel(int zoomlevel, int Function() getMaxLevel) {
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
    return NegativeRule(
      attributeMatcher: attributeMatcher,
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
