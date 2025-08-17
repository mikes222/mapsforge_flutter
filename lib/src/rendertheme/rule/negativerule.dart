import 'package:mapsforge_flutter/src/indoor/indoornotationmatcher.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/shape_instructions.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/rulebuilder.dart';

import '../../model/tag.dart';
import 'attributematcher.dart';
import 'rule.dart';

class NegativeRule extends Rule {
  final AttributeMatcher attributeMatcher;

  NegativeRule(RuleBuilder ruleBuilder, this.attributeMatcher)
      : super(ruleBuilder);

  /// Creates a ruleset which is a subset of the current rules
  NegativeRule.create(NegativeRule oldRule, List<Rule> subs,
      ShapeInstructions shapeInstructions)
      : attributeMatcher = oldRule.attributeMatcher,
        super.create(oldRule, subs, shapeInstructions);

  @override
  NegativeRule createRule(
      List<Rule> subs, ShapeInstructions shapeInstructions) {
    NegativeRule result = NegativeRule.create(this, subs, shapeInstructions);
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
        this.attributeMatcher.matchesTagList(tags);
  }

  @override
  bool matchesForZoomlevelRange(List<Tag> tags) {
    return this.attributeMatcher.matchesTagList(tags);
  }

  @override
  String toString() {
    return 'NegativeRule{attributeMatcher: $attributeMatcher, super: ${super.toString()}}';
  }
}
