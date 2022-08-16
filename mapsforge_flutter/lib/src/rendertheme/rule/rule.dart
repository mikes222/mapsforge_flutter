import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/datastore/way.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/rulebuilder.dart';

import '../../datastore/pointofinterest.dart';
import '../../model/tag.dart';
import '../../model/tile.dart';
import '../../rendertheme/renderinstruction/renderinstruction.dart';
import 'attributematcher.dart';
import 'closed.dart';
import 'closedmatcher.dart';
import 'elementmatcher.dart';

abstract class Rule {
  static final Map<List<String>, AttributeMatcher> MATCHERS_CACHE_KEY =
      new Map();
  static final Map<List<String>, AttributeMatcher> MATCHERS_CACHE_VALUE =
      new Map<List<String>, AttributeMatcher>();

  final String? cat;
  final ClosedMatcher? closedMatcher;
  final ElementMatcher? elementMatcher;
  final int zoomMax;
  final int zoomMin;
  final List<RenderInstruction>
      renderInstructions; // NOSONAR NOPMD we need specific interface
  final List<Rule> subRules; // NOSONAR NOPMD we need specific interface

  Rule(RuleBuilder ruleBuilder)
      : closedMatcher = ruleBuilder.closedMatcher,
        elementMatcher = ruleBuilder.elementMatcher,
        zoomMax = ruleBuilder.zoomMax,
        zoomMin = ruleBuilder.zoomMin,
        renderInstructions = [],
        subRules = [],
        cat = ruleBuilder.cat {
    this.renderInstructions.addAll(ruleBuilder.renderInstructions);
    ruleBuilder.ruleBuilderStack.forEach((ruleBuilder) {
      Rule rule = ruleBuilder.build();
      subRules.add(rule);
    });
  }

  void addRenderingInstruction(RenderInstruction renderInstruction) {
    this.renderInstructions.add(renderInstruction);
  }

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

  bool matchesNode(List<Tag> tags, int zoomLevel, int indoorLevel);

  bool matchesWay(
      List<Tag> tags, int zoomLevel, int indoorLevel, Closed closed);

  void matchNode(final Tile tile, List<RenderInstruction> matchingList,
      PointOfInterest pointOfInterest) {
    if (matchesNode(pointOfInterest.tags, tile.zoomLevel, tile.indoorLevel)) {
      matchingList.addAll(renderInstructions);
      subRules.forEach((element) {
        element.matchNode(tile, matchingList, pointOfInterest);
      });
    }
  }

  void matchWay(
      Way way, Tile tile, Closed closed, List<RenderInstruction> matchingList) {
    if (matchesWay(way.tags, tile.zoomLevel, tile.indoorLevel, closed)) {
      matchingList.addAll(renderInstructions);
      subRules.forEach((element) {
        element.matchWay(way, tile, closed, matchingList);
      });
    }
  }

  void onComplete() {
    MATCHERS_CACHE_KEY.clear();
    MATCHERS_CACHE_VALUE.clear();

//    this.renderInstructions.trimToSize();
//    this.subRules.trimToSize();
    for (int i = 0, n = this.subRules.length; i < n; ++i) {
      this.subRules.elementAt(i).onComplete();
    }
  }

  void prepareScale(int zoomLevel) {
    for (int i = 0, n = this.renderInstructions.length; i < n; ++i) {
      this.renderInstructions.elementAt(i).prepareScale(zoomLevel);
    }
    for (int i = 0, n = this.subRules.length; i < n; ++i) {
      this.subRules.elementAt(i).prepareScale(zoomLevel);
    }
  }

  @override
  String toString() {
    return 'Rule{cat: $cat, closedMatcher: $closedMatcher, elementMatcher: $elementMatcher, zoomMax: $zoomMax, zoomMin: $zoomMin, renderInstructions: $renderInstructions, subRules: $subRules}';
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
