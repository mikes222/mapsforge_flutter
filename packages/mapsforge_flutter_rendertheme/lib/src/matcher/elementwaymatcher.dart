import 'element.dart';
import 'elementmatcher.dart';

class ElementWayMatcher implements ElementMatcher {
  const ElementWayMatcher();

  @override
  bool isCoveredByElementMatcher(ElementMatcher elementMatcher) {
    return elementMatcher.matchesElement(Element.WAY);
  }

  @override
  bool matchesElement(Element element) {
    return element == Element.WAY;
  }

  @override
  String toString() {
    return 'ElementWayMatcher{}';
  }
}
