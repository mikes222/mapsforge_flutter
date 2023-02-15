import '../../model/tag.dart';

import 'attributematcher.dart';
import 'closed.dart';
import 'element.dart';
import 'rule.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/rulebuilder.dart';
import 'package:mapsforge_flutter/src/indoor/indoornotationmatcher.dart';

class NegativeRule extends Rule {
  final AttributeMatcher attributeMatcher;

  NegativeRule(RuleBuilder ruleBuilder, this.attributeMatcher)
      : super(ruleBuilder);

  /// Creates a ruleset which is a subset of the current rules
  NegativeRule.create(NegativeRule oldRule, List<Rule> subs)
      : attributeMatcher = oldRule.attributeMatcher,
        super.create(oldRule, subs);

  @override
  NegativeRule createRule(List<Rule> subs) {
    NegativeRule result = NegativeRule.create(this, subs);
    return result;
  }

  @override
  bool matchesForZoomLevel(int zoomLevel) {
    return this.zoomMin <= zoomLevel && this.zoomMax >= zoomLevel;
  }

  @override
  bool matchesNode(List<Tag> tags, int indoorLevel) {
    return IndoorNotationMatcher.isOutdoorOrMatchesIndoorLevel(
            tags, indoorLevel) &&
        this.elementMatcher!.matchesElement(Element.NODE) &&
        this.attributeMatcher.matchesTagList(tags);
  }

  @override
  bool matchesWay(List<Tag> tags, int indoorLevel, Closed closed) {
    return IndoorNotationMatcher.isOutdoorOrMatchesIndoorLevel(
            tags, indoorLevel) &&
        this.elementMatcher!.matchesElement(Element.WAY) &&
        this.closedMatcher!.matchesClosed(closed) &&
        this.attributeMatcher.matchesTagList(tags);
  }

  @override
  String toString() {
    return 'NegativeRule{attributeMatcher: $attributeMatcher, super: ${super.toString()}}';
  }
}
