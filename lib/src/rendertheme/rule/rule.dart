import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/model/zoomlevel_range.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/instruction_instructions.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/shape_instructions.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/rulebuilder.dart';

import '../../../datastore.dart';
import '../nodeproperties.dart';
import 'closedmatcher.dart';
import 'elementmatcher.dart';
import 'instructions.dart';

abstract class Rule {
  final Instructions instructions;
  final String? cat;
  final ClosedMatcher? closedMatcher;
  final ElementMatcher elementMatcher;
  final ZoomlevelRange zoomlevelRange;
  final List<Rule> subRules;

  Rule(RuleBuilder ruleBuilder)
      : closedMatcher = ruleBuilder.getClosedMatcher(),
        elementMatcher = ruleBuilder.getElementMatcher(),
        zoomlevelRange = ruleBuilder.zoomlevelRange,
        instructions = InstructionInstructions(
            renderInstructionNodes: ruleBuilder.renderInstructionNodes,
            renderInstructionOpenWays: ruleBuilder.renderInstructionOpenWays,
            renderInstructionClosedWays: ruleBuilder.renderInstructionClosedWays),
        subRules = [],
        cat = ruleBuilder.cat {
    ruleBuilder.ruleBuilderStack.forEach((ruleBuilder) {
      Rule rule = ruleBuilder.build();
      subRules.add(rule);
    });
  }

  Rule.create(Rule oldRule, List<Rule> subs, ShapeInstructions shapeInstructions)
      : cat = oldRule.cat,
        closedMatcher = oldRule.closedMatcher,
        elementMatcher = oldRule.elementMatcher,
        instructions = shapeInstructions,
        subRules = subs,
        zoomlevelRange = oldRule.zoomlevelRange;

  Rule createRule(List<Rule> subs, ShapeInstructions shapeInstructions);

  void addSubRule(Rule rule) {
    this.subRules.add(rule);
  }

  void apply(RuleVisitor v) {
    v.apply(this);
  }

  void dispose() {
    for (Rule sr in this.subRules) {
      sr.dispose();
    }
  }

  /// Returns true if this rule would apply for the given zoomLevel.
  bool matchesForZoomLevel(int zoomLevel);

  Rule? matchForZoomlevel(int zoomlevel) {
    if (!matchesForZoomLevel(zoomlevel)) {
      return null;
    }

    List<Rule> subs = [];
    subRules.forEach((element) {
      Rule? sub = element.matchForZoomlevel(zoomlevel);
      if (sub != null) subs.add(sub);
    });

    ShapeInstructions shapeInstructions = (instructions as InstructionInstructions).createShapeInstructions(zoomlevel);

    if (shapeInstructions.isEmpty() && subs.isEmpty) return null;

    Rule rule = createRule(subs, shapeInstructions);
    return rule;
  }

  bool matches(List<Tag> tags, int indoorLevel);

  bool matchesForZoomlevelRange(List<Tag> tags);

  /// finds all Shapes for a given node but does NOT check if the rul
  void matchNode(final Tile tile, List<Shape> matchingList, NodeProperties nodeProperties) {
    if (matches(nodeProperties.tags, tile.indoorLevel)) {
      matchingList.addAll((instructions as ShapeInstructions).shapeNodes);
      subRules.forEach((element) {
        element.matchNode(tile, matchingList, nodeProperties);
      });
    }
  }

  void matchOpenWay(Way way, Tile tile, List<Shape> matchingList) {
    if (matches(way.tags, tile.indoorLevel)) {
      matchingList.addAll((instructions as ShapeInstructions).shapeOpenWays);
      subRules.forEach((element) {
        element.matchOpenWay(way, tile, matchingList);
      });
    }
  }

  void matchClosedWay(Way way, Tile tile, List<Shape> matchingList) {
    if (matches(way.tags, tile.indoorLevel)) {
      matchingList.addAll((instructions as ShapeInstructions).shapeClosedWays);
      subRules.forEach((element) {
        element.matchClosedWay(way, tile, matchingList);
      });
    }
  }

  /// Returns the widest possible zoomrange which may accept the given argument.
  /// Returns null if if the argument will never accepted.
  ZoomlevelRange? getZoomlevelRangeNode(PointOfInterest pointOfInterest) {
    // tag not accepted by this rule.
    if (!matchesForZoomlevelRange(pointOfInterest.tags)) return null;

    bool supported = instructions.hasInstructionsNodes();
    // this rule supports the argument. Returns this zoomlevel range which is
    // the widest possible range.
    if (supported) return zoomlevelRange;
    ZoomlevelRange? result;
    subRules.forEach((element) {
      ZoomlevelRange? range = element.getZoomlevelRangeNode(pointOfInterest);
      if (range != null) {
        if (result == null) {
          result = range;
        } else {
          result = result!.widenTo(range);
        }
      }
    });
    return result;
  }

  /// Returns the widest possible zoomrange which may accept the given argument.
  /// Returns null if if the argument will never accepted.
  ZoomlevelRange? getZoomlevelRangeOpenWay(List<Tag> tags) {
    if (!matchesForZoomlevelRange(tags)) return null;

    bool supported = instructions.hasInstructionsOpenWays();
    // this rule supports the argument. Return this subrule which is the
    // widest subrule which supports the argument
    if (supported) return zoomlevelRange;
    ZoomlevelRange? result;
    subRules.forEach((element) {
      ZoomlevelRange? range = element.getZoomlevelRangeOpenWay(tags);
      if (range != null) {
        if (result == null) {
          result = range;
        } else {
          result = result!.widenTo(range);
        }
      }
    });
    return result;
  }

  /// Returns the widest possible zoomrange which may accept the given argument.
  /// Returns null if if the argument will never accepted.
  ZoomlevelRange? getZoomlevelRangeClosedWay(List<Tag> tags) {
    if (!matchesForZoomlevelRange(tags)) return null;

    bool supported = instructions.hasInstructionsClosedWays();
    // this rule supports the argument. Return this subrule which is the
    // widest subrule which supports the argument
    if (supported) {
      return zoomlevelRange;
    }
    ZoomlevelRange? result;
    subRules.forEach((element) {
      ZoomlevelRange? range = element.getZoomlevelRangeClosedWay(tags);
      if (range != null) {
        if (result == null) {
          result = range;
        } else {
          result = result!.widenTo(range);
        }
      }
    });
    return result;
  }

  void onComplete() {
    for (int i = 0, n = this.subRules.length; i < n; ++i) {
      this.subRules.elementAt(i).onComplete();
    }
  }
}

/////////////////////////////////////////////////////////////////////////////

class RuleVisitor {
  void apply(Rule r) {
    for (Rule subRule in r.subRules) {
      this.apply(subRule);
    }
  }
}
