import 'package:mapsforge_flutter/src/indoor/indoornotationmatcher.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/shape_instructions.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/rulebuilder.dart';

import '../../model/tag.dart';
import 'attributematcher.dart';
import 'rule.dart';

class PositiveRule extends Rule {
  final AttributeMatcher keyMatcher;
  final AttributeMatcher valueMatcher;

  PositiveRule(RuleBuilder ruleBuilder, this.keyMatcher, this.valueMatcher)
      : super(ruleBuilder);

  /// Creates a ruleset which is a subset of the current rules
  PositiveRule.create(PositiveRule oldRule, List<Rule> subs,
      ShapeInstructions shapeInstructions)
      : keyMatcher = oldRule.keyMatcher,
        valueMatcher = oldRule.valueMatcher,
        super.create(oldRule, subs, shapeInstructions);

  @override
  PositiveRule createRule(
      List<Rule> subs, ShapeInstructions shapeInstructions) {
    PositiveRule result = PositiveRule.create(this, subs, shapeInstructions);
    return result;
  }

  @override
  bool matchesForZoomLevel(int zoomlevel) {
    return zoomlevelRange.matches(zoomlevel);
  }

  @override
  bool matches(List<Tag> tags, int indoorLevel) {
    return IndoorNotationMatcher.isOutdoorOrMatchesIndoorLevel(
            tags, indoorLevel) &&
        this.keyMatcher.matchesTagList(tags) &&
        this.valueMatcher.matchesTagList(tags);
  }

  @override
  bool matchesForZoomlevelRange(List<Tag> tags) {
    return this.keyMatcher.matchesTagList(tags) &&
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
    return 'PositiveRule{keyMatcher: $keyMatcher, valueMatcher: $valueMatcher, super: ${super.toString()}}';
  }
}
