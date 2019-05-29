import '../../model/tag.dart';

import 'attributematcher.dart';
import 'closed.dart';
import 'element.dart';
import 'rule.dart';
import 'rulebuilder.dart';

class NegativeRule extends Rule {
  final AttributeMatcher attributeMatcher;

  NegativeRule(RuleBuilder ruleBuilder, this.attributeMatcher)
      : super(ruleBuilder);

  @override
  bool matchesNode(List<Tag> tags, int zoomLevel) {
    return this.zoomMin <= zoomLevel &&
        this.zoomMax >= zoomLevel &&
        this.elementMatcher.matchesElement(Element.NODE) &&
        this.attributeMatcher.matchesTagList(tags);
  }

  @override
  bool matchesWay(List<Tag> tags, int zoomLevel, Closed closed) {
    return this.zoomMin <= zoomLevel &&
        this.zoomMax >= zoomLevel &&
        this.elementMatcher.matchesElement(Element.WAY) &&
        this.closedMatcher.matchesClosed(closed) &&
        this.attributeMatcher.matchesTagList(tags);
  }
}
