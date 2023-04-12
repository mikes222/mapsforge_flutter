import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/datastore/way.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/rulebuilder.dart';

import '../../model/tag.dart';
import '../../model/tile.dart';
import '../../rendertheme/renderinstruction/renderinstruction.dart';
import '../nodeproperties.dart';
import 'attributematcher.dart';
import 'closed.dart';
import 'closedmatcher.dart';
import 'elementmatcher.dart';

abstract class Rule {
  static final Map<List<String>, AttributeMatcher> MATCHERS_CACHE_KEY = {};
  static final Map<List<String>, AttributeMatcher> MATCHERS_CACHE_VALUE = {};

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

  Rule.create(
      Rule oldRule, List<Rule> subs, List<RenderInstruction> renderInstructions)
      : cat = oldRule.cat,
        closedMatcher = oldRule.closedMatcher,
        elementMatcher = oldRule.elementMatcher,
        this.renderInstructions = renderInstructions,
        subRules = subs,
        zoomMin = oldRule.zoomMin,
        zoomMax = oldRule.zoomMax;

  Rule createRule(List<Rule> subs, List<RenderInstruction> renderInstructions);

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

  /// Returns true if this rule would apply for the given zoomLevel.
  bool matchesForZoomLevel(int zoomLevel);

  Rule? matchForZoomLevel(int zoomLevel) {
    if (matchesForZoomLevel(zoomLevel)) {
      List<Rule> subs = [];
      subRules.forEach((element) {
        Rule? sub = element.matchForZoomLevel(zoomLevel);
        if (sub != null) subs.add(sub);
      });
      // we do not have subrules AND we do not have instructions, so this is a no-op
      List<RenderInstruction> newRenderInstructions = [];
      for (RenderInstruction ri in renderInstructions) {
        RenderInstruction? newRi = ri.prepareScale(zoomLevel);
        if (newRi != null) newRenderInstructions.add(newRi);
      }
      if (newRenderInstructions.isEmpty && subs.isEmpty) return null;
      Rule rule = createRule(subs, newRenderInstructions);
      return rule;
    }
    return null;
  }

  bool matchesNode(List<Tag> tags, int indoorLevel);

  bool matchesWay(List<Tag> tags, int indoorLevel, Closed closed);

  void matchNode(final Tile tile, List<RenderInstruction> matchingList,
      NodeProperties container) {
    if (matchesNode(container.tags, tile.indoorLevel)) {
      matchingList.addAll(renderInstructions);
      subRules.forEach((element) {
        element.matchNode(tile, matchingList, container);
      });
    }
  }

  void matchWay(
      Way way, Tile tile, Closed closed, List<RenderInstruction> matchingList) {
    if (matchesWay(way.tags, tile.indoorLevel, closed)) {
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
