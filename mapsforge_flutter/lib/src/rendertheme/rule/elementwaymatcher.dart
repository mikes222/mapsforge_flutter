import 'element.dart';
import 'elementmatcher.dart';

class ElementWayMatcher implements ElementMatcher {
  static final ElementWayMatcher INSTANCE = const ElementWayMatcher();

  const ElementWayMatcher();

  @override
  bool isCoveredByElementMatcher(ElementMatcher? elementMatcher) {
    return elementMatcher!.matchesElement(Element.WAY);
  }

  @override
  bool matchesElement(Element element) {
    return element == Element.WAY;
  }
}
