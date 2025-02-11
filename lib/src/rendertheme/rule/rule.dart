import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/datastore/way.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/instruction_instructions.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/shape_instructions.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/rulebuilder.dart';

import '../../model/tag.dart';
import '../nodeproperties.dart';
import 'closedmatcher.dart';
import 'elementmatcher.dart';
import 'instructions.dart';

abstract class Rule {
  final Instructions instructions;
  final String? cat;
  final ClosedMatcher? closedMatcher;
  final ElementMatcher elementMatcher;
  final int zoomMax;
  final int zoomMin;
  final List<Rule> subRules;

  Rule(RuleBuilder ruleBuilder)
      : closedMatcher = ruleBuilder.getClosedMatcher(),
        elementMatcher = ruleBuilder.getElementMatcher(),
        zoomMax = ruleBuilder.zoomMax,
        zoomMin = ruleBuilder.zoomMin,
        instructions = InstructionInstructions(
            renderInstructionNodes: ruleBuilder.renderInstructionNodes,
            renderInstructionOpenWays: ruleBuilder.renderInstructionOpenWays,
            renderInstructionClosedWays:
                ruleBuilder.renderInstructionClosedWays),
        subRules = [],
        cat = ruleBuilder.cat {
    ruleBuilder.ruleBuilderStack.forEach((ruleBuilder) {
      Rule rule = ruleBuilder.build();
      subRules.add(rule);
    });
  }

  Rule.create(
      Rule oldRule, List<Rule> subs, ShapeInstructions shapeInstructions)
      : cat = oldRule.cat,
        closedMatcher = oldRule.closedMatcher,
        elementMatcher = oldRule.elementMatcher,
        instructions = shapeInstructions,
        subRules = subs,
        zoomMin = oldRule.zoomMin,
        zoomMax = oldRule.zoomMax;

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

    ShapeInstructions shapeInstructions =
        (instructions as InstructionInstructions)
            .createShapeInstructions(zoomlevel);

    if (shapeInstructions.isEmpty() && subs.isEmpty) return null;

    Rule rule = createRule(subs, shapeInstructions);
    return rule;
  }

  bool matchesNode(List<Tag> tags, int indoorLevel);

  bool matchesOpenWay(List<Tag> tags, int indoorLevel);

  bool matchesClosedWay(List<Tag> tags, int indoorLevel);

  bool matches(List<Tag> tags, int indoorLevel);

  /// finds all Shapes for a given node but does NOT check if the rul
  void matchNode(
      final Tile tile, List<Shape> matchingList, NodeProperties container) {
    if (matches(container.tags, tile.indoorLevel)) {
      matchingList.addAll((instructions as ShapeInstructions).shapeNodes);
      subRules.forEach((element) {
        element.matchNode(tile, matchingList, container);
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

  void onComplete() {
//    this.renderInstructions.trimToSize();
//    this.subRules.trimToSize();
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
