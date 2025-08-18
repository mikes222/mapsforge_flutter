import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/src/matcher/attributematcher.dart';
import 'package:dart_rendertheme/src/matcher/indoornotationmatcher.dart';

import 'rule.dart';

class NegativeRule extends Rule {
  final AttributeMatcher attributeMatcher;

  NegativeRule({
    required this.attributeMatcher,
    required super.zoomlevelRange,
    required super.subRules,
    required super.renderInstructionNodes,
    required super.renderInstructionOpenWays,
    required super.renderInstructionClosedWays,
  });

  @override
  bool matchesForZoomLevel(int zoomlevel) {
    return zoomlevelRange.matches(zoomlevel);
  }

  @override
  bool matches(List<Tag> tags, int indoorLevel) {
    return IndoorNotationMatcher.isOutdoorOrMatchesIndoorLevel(tags, indoorLevel) && attributeMatcher.matchesTagList(tags);
  }

  @override
  bool matchesTags(List<Tag> tags) {
    return attributeMatcher.matchesTagList(tags);
  }

  @override
  String toString() {
    return 'NegativeRule{attributeMatcher: $attributeMatcher, super: ${super.toString()}}';
  }
}
