import 'package:mapsforge_flutter/src/rendertheme/xml/rulebuilder.dart';

import '../../datastore/pointofinterest.dart';
import '../../model/tag.dart';
import '../../model/tile.dart';
import '../../renderer/polylinecontainer.dart';
import '../../rendertheme/renderinstruction/renderinstruction.dart';
import '../rendercallback.dart';
import '../rendercontext.dart';
import 'attributematcher.dart';
import 'closed.dart';
import 'closedmatcher.dart';
import 'elementmatcher.dart';

abstract class Rule {
  static final Map<List<String>, AttributeMatcher> MATCHERS_CACHE_KEY = new Map();
  static final Map<List<String>, AttributeMatcher> MATCHERS_CACHE_VALUE = new Map<List<String>, AttributeMatcher>();

  String? cat;
  final ClosedMatcher? closedMatcher;
  final ElementMatcher? elementMatcher;
  final int zoomMax;
  final int zoomMin;
  final List<RenderInstruction> renderInstructions; // NOSONAR NOPMD we need specific interface
  final List<Rule> subRules; // NOSONAR NOPMD we need specific interface

  Rule(RuleBuilder ruleBuilder)
      : closedMatcher = ruleBuilder.closedMatcher,
        elementMatcher = ruleBuilder.elementMatcher,
        zoomMax = ruleBuilder.zoomMax,
        zoomMin = ruleBuilder.zoomMin,
        renderInstructions = [],
        subRules = [] {
    this.cat = ruleBuilder.cat;
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
    for (RenderInstruction ri in this.renderInstructions) {
      ri.dispose();
    }
    for (Rule sr in this.subRules) {
      sr.dispose();
    }
  }

  bool matchesNode(List<Tag> tags, int zoomLevel, int indoorLevel);

  bool matchesWay(List<Tag> tags, int zoomLevel, int indoorLevel, Closed closed);

  void matchNode(RenderCallback renderCallback, final RenderContext renderContext, List<RenderInstruction>? matchingList,
      PointOfInterest pointOfInterest, List<RenderInstruction> initPendings) {
    if (matchesNode(pointOfInterest.tags, renderContext.job.tile.zoomLevel, renderContext.job.tile.indoorLevel)) {
      matchingList!.addAll(renderInstructions);
      // for (int i = 0, n = this.renderInstructions.length; i < n; ++i) {
      //   matchingList!.add(this.renderInstructions.elementAt(i));
      // }
      subRules.forEach((element) {
        element.matchNode(renderCallback, renderContext, matchingList, pointOfInterest, initPendings);
      });
      // for (int i = 0, n = this.subRules.length; i < n; ++i) {
      //   this.subRules.elementAt(i).matchNode(renderCallback, renderContext, matchingList, pointOfInterest, initPendings);
      // }
    }
  }

  void matchWay(RenderCallback renderCallback, PolylineContainer way, Tile tile, Closed closed, List<RenderInstruction>? matchingList,
      final RenderContext renderContext, List<RenderInstruction> initPendings) {
    if (matchesWay(way.getTags(), tile.zoomLevel, tile.indoorLevel, closed)) {
      matchingList!.addAll(renderInstructions);
      // for (int i = 0, n = this.renderInstructions.length; i < n; ++i) {
      //   matchingList!.add(this.renderInstructions.elementAt(i));
      // }
      subRules.forEach((element) {
        element.matchWay(renderCallback, way, tile, closed, matchingList, renderContext, initPendings);
      });
      // for (int i = 0, n = this.subRules.length; i < n; ++i) {
      //   this.subRules.elementAt(i).matchWay(renderCallback, way, tile, closed, matchingList, renderContext, initPendings);
      // }
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

  void scaleStrokeWidth(double scaleFactor, int zoomLevel) {
    for (int i = 0, n = this.renderInstructions.length; i < n; ++i) {
      this.renderInstructions.elementAt(i).scaleStrokeWidth(scaleFactor, zoomLevel);
    }
    for (int i = 0, n = this.subRules.length; i < n; ++i) {
      this.subRules.elementAt(i).scaleStrokeWidth(scaleFactor, zoomLevel);
    }
  }

  void scaleTextSize(double scaleFactor, int zoomLevel) {
    for (int i = 0, n = this.renderInstructions.length; i < n; ++i) {
      this.renderInstructions.elementAt(i).scaleTextSize(scaleFactor, zoomLevel);
    }
    for (int i = 0, n = this.subRules.length; i < n; ++i) {
      this.subRules.elementAt(i).scaleTextSize(scaleFactor, zoomLevel);
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
