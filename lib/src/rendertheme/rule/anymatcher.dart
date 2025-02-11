import '../../model/tag.dart';
import 'attributematcher.dart';
import 'closed.dart';
import 'closedmatcher.dart';
import 'element.dart';
import 'elementmatcher.dart';

class AnyMatcher implements ElementMatcher, AttributeMatcher, ClosedMatcher {
  const AnyMatcher();

  @override
  bool isCoveredByAttributeMatcher(AttributeMatcher attributeMatcher) {
    return attributeMatcher == this;
  }

  @override
  bool isCoveredByClosedMatcher(ClosedMatcher closedMatcher) {
    return closedMatcher == this;
  }

  @override
  bool isCoveredByElementMatcher(ElementMatcher elementMatcher) {
    return elementMatcher == this;
  }

  @override
  bool matchesClosed(Closed closed) {
    return true;
  }

  @override
  bool matchesElement(Element element) {
    return true;
  }

  @override
  bool matchesTagList(List<Tag?>? tags) {
    return true;
  }

  @override
  String toString() {
    return 'AnyMatcher{}';
  }
}
