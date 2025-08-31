import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/attributematcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/closed.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/closedmatcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/element.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/elementmatcher.dart';

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
  bool matchesTagList(List<Tag> tags) {
    return true;
  }

  @override
  String toString() {
    return 'AnyMatcher{}';
  }
}
