import 'package:mapsforge_flutter/src/indoor/indoornotationmatcher.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/rulebuilder.dart';

import '../../model/tag.dart';
import '../renderinstruction/renderinstruction.dart';
import 'attributematcher.dart';
import 'closed.dart';
import 'element.dart';
import 'rule.dart';

class PositiveRule extends Rule {
  final AttributeMatcher keyMatcher;
  final AttributeMatcher valueMatcher;

  PositiveRule(RuleBuilder ruleBuilder, this.keyMatcher, this.valueMatcher)
      : super(ruleBuilder);

  /// Creates a ruleset which is a subset of the current rules
  PositiveRule.create(PositiveRule oldRule, List<Rule> subs,
      List<RenderInstruction> renderInstructions)
      : keyMatcher = oldRule.keyMatcher,
        valueMatcher = oldRule.valueMatcher,
        super.create(oldRule, subs, renderInstructions);

  @override
  PositiveRule createRule(List<Rule> subs,
      List<RenderInstruction> renderInstructions) {
    PositiveRule result = PositiveRule.create(this, subs, renderInstructions);
    return result;
  }

  @override
  bool matchesForZoomLevel(int zoomLevel) {
    return zoomMin <= zoomLevel && zoomMax >= zoomLevel;
  }

  @override
  bool matchesNode(List<Tag> tags, int indoorLevel) {
    return IndoorNotationMatcher.isOutdoorOrMatchesIndoorLevel(
        tags, indoorLevel) &&
        this.elementMatcher!.matchesElement(Element.NODE) &&
        this.keyMatcher.matchesTagList(tags) &&
        this.valueMatcher.matchesTagList(tags);
  }

  @override
  bool matchesWay(List<Tag> tags, int indoorLevel, Closed closed) {
    return IndoorNotationMatcher.isOutdoorOrMatchesIndoorLevel(
        tags, indoorLevel) &&
        this.elementMatcher!.matchesElement(Element.WAY) &&
        this.closedMatcher!.matchesClosed(closed) &&
        this.keyMatcher.matchesTagList(tags) &&
        this.valueMatcher.matchesTagList(tags);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PositiveRule &&
              runtimeType == other.runtimeType &&
              keyMatcher == other.keyMatcher &&
              valueMatcher == other.valueMatcher;

  @override
  int get hashCode => keyMatcher.hashCode ^ valueMatcher.hashCode;

  @override
  String toString() {
    return 'PositiveRule{keyMatcher: $keyMatcher, valueMatcher: $valueMatcher, super: ${super
        .toString()}}';
  }
}
