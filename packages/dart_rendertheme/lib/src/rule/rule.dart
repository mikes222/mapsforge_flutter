import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_node.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_way.dart';

abstract class Rule {
  final String? cat;
  final ZoomlevelRange zoomlevelRange;
  final List<Rule> subRules;

  final List<RenderInstructionNode> renderInstructionNodes;

  final List<RenderInstructionWay> renderInstructionOpenWays;

  final List<RenderInstructionWay> renderInstructionClosedWays;

  Rule({
    this.cat,
    required this.zoomlevelRange,
    required this.subRules,
    required this.renderInstructionNodes,
    required this.renderInstructionOpenWays,
    required this.renderInstructionClosedWays,
  }) : assert(
         subRules.isNotEmpty ||
             (subRules.isEmpty && (renderInstructionNodes.isNotEmpty || renderInstructionOpenWays.isNotEmpty || renderInstructionClosedWays.isNotEmpty)),
       );

  Rule? forZoomlevel(int zoomlevel);

  void apply(RuleVisitor v) {
    v.apply(this);
  }

  /// Returns true if this rule can be applied for the given zoomLevel.
  bool matchesForZoomLevel(int zoomLevel);

  /// Returns true if the rule matches the given tags and inddor level
  bool matches(List<Tag> tags, int indoorLevel);

  /// Checks the tags if the rule matches, does NOT take the indoorLevel into account.
  bool matchesTags(List<Tag> tags);

  /// Returns the widest possible zoomrange which may accept the given argument.
  /// Returns null if if the argument will never accepted.
  ZoomlevelRange? getZoomlevelRangeNode(PointOfInterest pointOfInterest) {
    // tag not accepted by this rule.
    if (!matchesTags(pointOfInterest.tags)) return null;
    if (renderInstructionNodes.isNotEmpty) {
      // this rule supports the argument. Returns this zoomlevel range which is
      // the widest possible range.
      return zoomlevelRange;
    }

    ZoomlevelRange? result;
    for (var rule in subRules) {
      ZoomlevelRange? range = rule.getZoomlevelRangeNode(pointOfInterest);
      if (range != null) {
        result = result?.widenTo(range) ?? range;
      }
    }
    return result;
  }

  /// Returns the widest possible zoomrange which may accept the given argument.
  /// Returns null if if the argument will never accepted.
  ZoomlevelRange? getZoomlevelRangeOpenWay(List<Tag> tags) {
    if (!matchesTags(tags)) return null;

    if (renderInstructionOpenWays.isNotEmpty) return zoomlevelRange;

    ZoomlevelRange? result;
    for (var element in subRules) {
      ZoomlevelRange? range = element.getZoomlevelRangeOpenWay(tags);
      if (range != null) {
        result = result?.widenTo(range) ?? range;
      }
    }
    return result;
  }

  /// Returns the widest possible zoomrange which may accept the given argument.
  /// Returns null if if the argument will never accepted.
  ZoomlevelRange? getZoomlevelRangeClosedWay(List<Tag> tags) {
    if (!matchesTags(tags)) return null;

    if (renderInstructionClosedWays.isNotEmpty) return zoomlevelRange;

    ZoomlevelRange? result;
    for (var element in subRules) {
      ZoomlevelRange? range = element.getZoomlevelRangeClosedWay(tags);
      if (range != null) {
        result = result?.widenTo(range) ?? range;
      }
    }
    return result;
  }

  void onComplete() {
    for (int i = 0, n = subRules.length; i < n; ++i) {
      subRules.elementAt(i).onComplete();
    }
  }

  @override
  String toString() {
    return 'Rule{zoomlevelRange: $zoomlevelRange, renderInstructionNodes: $renderInstructionNodes, renderInstructionOpenWays: $renderInstructionOpenWays, renderInstructionClosedWays: $renderInstructionClosedWays}';
  }
}

/////////////////////////////////////////////////////////////////////////////

class RuleVisitor {
  void apply(Rule r) {
    for (Rule subRule in r.subRules) {
      apply(subRule);
    }
  }
}
