import 'element.dart';
import 'elementmatcher.dart';

class ElementNodeMatcher implements ElementMatcher {
  const ElementNodeMatcher();

  @override
  bool isCoveredByElementMatcher(ElementMatcher elementMatcher) {
    return elementMatcher.matchesElement(Element.NODE);
  }

  @override
  bool matchesElement(Element element) {
    return element == Element.NODE;
  }

  @override
  String toString() {
    return 'ElementNodeMatcher{}';
  }
}
