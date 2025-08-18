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
  });

  void apply(RuleVisitor v) {
    v.apply(this);
  }

  /// Returns true if this rule can be applied for the given zoomLevel.
  bool matchesForZoomLevel(int zoomLevel);

  Rule? matchForZoomlevel(int zoomlevel) {
    if (!matchesForZoomLevel(zoomlevel)) {
      return null;
    }

    // todo is this necessary?
    List<Rule> subs = [];
    for (var element in subRules) {
      Rule? sub = element.matchForZoomlevel(zoomlevel);
      if (sub != null) subs.add(sub);
    }

    return this;
  }

  bool matches(List<Tag> tags, int indoorLevel);

  bool matchesForZoomlevelRange(List<Tag> tags);

  /// Returns the widest possible zoomrange which may accept the given argument.
  /// Returns null if if the argument will never accepted.
  ZoomlevelRange? getZoomlevelRangeNode(PointOfInterest pointOfInterest) {
    // tag not accepted by this rule.
    if (!matchesForZoomlevelRange(pointOfInterest.tags)) return null;

    ZoomlevelRange? result;
    for (var element in subRules) {
      ZoomlevelRange? range = element.getZoomlevelRangeNode(pointOfInterest);
      if (range != null) {
        if (result == null) {
          result = range;
        } else {
          result = result.widenTo(range);
        }
      }
    }
    return result;
  }

  /// Returns the widest possible zoomrange which may accept the given argument.
  /// Returns null if if the argument will never accepted.
  ZoomlevelRange? getZoomlevelRangeOpenWay(List<Tag> tags) {
    if (!matchesForZoomlevelRange(tags)) return null;

    ZoomlevelRange? result;
    for (var element in subRules) {
      ZoomlevelRange? range = element.getZoomlevelRangeOpenWay(tags);
      if (range != null) {
        if (result == null) {
          result = range;
        } else {
          result = result.widenTo(range);
        }
      }
    }
    return result;
  }

  /// Returns the widest possible zoomrange which may accept the given argument.
  /// Returns null if if the argument will never accepted.
  ZoomlevelRange? getZoomlevelRangeClosedWay(List<Tag> tags) {
    if (!matchesForZoomlevelRange(tags)) return null;

    ZoomlevelRange? result;
    for (var element in subRules) {
      ZoomlevelRange? range = element.getZoomlevelRangeClosedWay(tags);
      if (range != null) {
        if (result == null) {
          result = range;
        } else {
          result = result.widenTo(range);
        }
      }
    }
    return result;
  }

  void onComplete() {
    for (int i = 0, n = subRules.length; i < n; ++i) {
      subRules.elementAt(i).onComplete();
    }
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
