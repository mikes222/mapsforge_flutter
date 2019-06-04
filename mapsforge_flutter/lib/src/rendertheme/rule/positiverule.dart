import '../../model/tag.dart';

import 'attributematcher.dart';
import 'closed.dart';
import 'element.dart';
import 'rule.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/rulebuilder.dart';

class PositiveRule extends Rule {
  final AttributeMatcher keyMatcher;
  final AttributeMatcher valueMatcher;

  PositiveRule(RuleBuilder ruleBuilder, this.keyMatcher, this.valueMatcher) : super(ruleBuilder);

  @override
  bool matchesNode(List<Tag> tags, int zoomLevel) {
    return this.zoomMin <= zoomLevel &&
        this.zoomMax >= zoomLevel &&
        this.elementMatcher.matchesElement(Element.NODE) &&
        this.keyMatcher.matchesTagList(tags) &&
        this.valueMatcher.matchesTagList(tags);
  }

  @override
  bool matchesWay(List<Tag> tags, int zoomLevel, Closed closed) {
    return this.zoomMin <= zoomLevel &&
        this.zoomMax >= zoomLevel &&
        this.elementMatcher.matchesElement(Element.WAY) &&
        this.closedMatcher.matchesClosed(closed) &&
        this.keyMatcher.matchesTagList(tags) &&
        this.valueMatcher.matchesTagList(tags);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PositiveRule && runtimeType == other.runtimeType && keyMatcher == other.keyMatcher && valueMatcher == other.valueMatcher;

  @override
  int get hashCode => keyMatcher.hashCode ^ valueMatcher.hashCode;

  @override
  String toString() {
    return 'PositiveRule{keyMatcher: $keyMatcher, valueMatcher: $valueMatcher, super: ${super.toString()}}';
  }
}
