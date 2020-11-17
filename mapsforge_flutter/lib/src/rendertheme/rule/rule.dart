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

import 'dart:math';

abstract class Rule {
  static final Map<List<String>, AttributeMatcher> MATCHERS_CACHE_KEY = new Map();
  static final Map<List<String>, AttributeMatcher> MATCHERS_CACHE_VALUE = new Map<List<String>, AttributeMatcher>();

  String cat;
  final ClosedMatcher closedMatcher;
  final ElementMatcher elementMatcher;
  final int zoomMax;
  final int zoomMin;
  final List<RenderInstruction> renderInstructions; // NOSONAR NOPMD we need specific interface
  final List<Rule> subRules; // NOSONAR NOPMD we need specific interface

  Rule(RuleBuilder ruleBuilder)
      : closedMatcher = ruleBuilder.closedMatcher,
        elementMatcher = ruleBuilder.elementMatcher,
        zoomMax = ruleBuilder.zoomMax,
        zoomMin = ruleBuilder.zoomMin,
        renderInstructions = new List(),
        subRules = new List() {
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

  void destroy() {
    for (RenderInstruction ri in this.renderInstructions) {
      ri.destroy();
    }
    for (Rule sr in this.subRules) {
      sr.destroy();
    }
  }

  bool matchesNode(List<Tag> tags, int zoomLevel, int indoorLevel);

  bool matchesWay(List<Tag> tags, int zoomLevel, int indoorLevel, Closed closed);


  bool matchesIndoorLevel (List<Tag> tags, int level) {
    Tag levelTag = tags.firstWhere((Tag element) {
      return element.key == "level";
    }, orElse: () => null);

    // if no level key exists search for repeat_on key and treat its value as the level
    if (levelTag == null) levelTag = tags.firstWhere((Tag element) {
      return element.key == "repeat_on";
    }, orElse: () => null);

    // return true if no level tag exists
    if (levelTag == null || level == null) return true;

    // TODO
    // do not create regex on each function call
    // move function out of this class

    // match value range notation : 1-2 or -1--5
    final RegExp matchRangeNotation = new RegExp(r"^-?\d+(\.\d+)?--?\d+(\.\d+)?$");
    // match multiple values notation : 1;3;4 or 1.4;-4;2
    final RegExp matchMultipleNotation = new RegExp(r"^(-?\d+(\.\d+)?)(;-?\d+(\.\d+)?)+$");
    // match single value : 1 or -1.5
    final RegExp matchSingleNotation = new RegExp(r"^-?\d+(\.\d+)?$");

    if (matchSingleNotation.hasMatch(levelTag.value)) {
      final double levelValue = double.parse(levelTag.value);
      return (levelValue == level || levelValue.ceil() == level || levelValue.floor() == level);
    }
    else if (matchMultipleNotation.hasMatch(levelTag.value)) {
      // split on ";" and convert values to double
      final Iterable <double> levelValues = levelTag.value.split(";").map(double.parse);
      // check if at least one value matches the current level
      return levelValues.any((levelValue) => (levelValue == level || levelValue.ceil() == level || levelValue.floor() == level));
    }
    else if (matchRangeNotation.hasMatch(levelTag.value)) {
      // split on "-" if number precedes and convert to double
      final Iterable <double> levelRange = levelTag.value.split(RegExp(r"(?<=\d)-")).map(double.parse);
      // separate into max and min value
      double lowerLevelValue = levelRange.reduce(min);
      double upperLevelValue = levelRange.reduce(max);
      // if level is in range return true else false
      return (lowerLevelValue.floor() <= level && upperLevelValue.ceil() >= level);
    }

    return false;
  }

  void matchNode(RenderCallback renderCallback, final RenderContext renderContext, List<RenderInstruction> matchingList,
      PointOfInterest pointOfInterest, List<RenderInstruction> initPendings) {
    if (matchesNode(pointOfInterest.tags, renderContext.job.tile.zoomLevel, renderContext.job.tile.indoorLevel)) {
      for (int i = 0, n = this.renderInstructions.length; i < n; ++i) {
        matchingList.add(this.renderInstructions.elementAt(i));
      }
      for (int i = 0, n = this.subRules.length; i < n; ++i) {
        this.subRules.elementAt(i).matchNode(renderCallback, renderContext, matchingList, pointOfInterest, initPendings);
      }
    }
  }

  void matchWay(RenderCallback renderCallback, PolylineContainer way, Tile tile, Closed closed, List<RenderInstruction> matchingList,
      final RenderContext renderContext, List<RenderInstruction> initPendings) {
    if (matchesWay(way.getTags(), tile.zoomLevel, tile.indoorLevel, closed)) {
      for (int i = 0, n = this.renderInstructions.length; i < n; ++i) {
        matchingList.add(this.renderInstructions.elementAt(i));
      }
      for (int i = 0, n = this.subRules.length; i < n; ++i) {
        this.subRules.elementAt(i).matchWay(renderCallback, way, tile, closed, matchingList, renderContext, initPendings);
      }
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
