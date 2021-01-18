import '../../model/tag.dart';

import 'attributematcher.dart';
import 'closed.dart';
import 'element.dart';
import 'rule.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/rulebuilder.dart';
import 'package:mapsforge_flutter/src/indoor/indoornotationmatcher.dart';

class NegativeRule extends Rule {
  final AttributeMatcher attributeMatcher;

  NegativeRule(RuleBuilder ruleBuilder, this.attributeMatcher) : super(ruleBuilder);

  @override
  bool matchesNode(List<Tag> tags, int zoomLevel, int indoorLevel) {
    return this.zoomMin <= zoomLevel &&
        this.zoomMax >= zoomLevel &&
        IndoorNotationMatcher.isOutdoorOrMatchesIndoorLevel(tags, indoorLevel) &&
        this.elementMatcher.matchesElement(Element.NODE) &&
        this.attributeMatcher.matchesTagList(tags);
  }

  @override
  bool matchesWay(List<Tag> tags, int zoomLevel, int indoorLevel, Closed closed) {
    return this.zoomMin <= zoomLevel &&
        this.zoomMax >= zoomLevel &&
        IndoorNotationMatcher.isOutdoorOrMatchesIndoorLevel(tags, indoorLevel) &&
        this.elementMatcher.matchesElement(Element.WAY) &&
        this.closedMatcher.matchesClosed(closed) &&
        this.attributeMatcher.matchesTagList(tags);
  }

  @override
  String toString() {
    return 'NegativeRule{attributeMatcher: $attributeMatcher, super: ${super.toString()}}';
  }
}
