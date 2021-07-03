import 'element.dart';
import 'elementmatcher.dart';

class ElementNodeMatcher implements ElementMatcher {
  static final ElementNodeMatcher INSTANCE = new ElementNodeMatcher();

  const ElementNodeMatcher();

  @override
  bool isCoveredByElementMatcher(ElementMatcher? elementMatcher) {
    return elementMatcher!.matchesElement(Element.NODE);
  }

  @override
  bool matchesElement(Element element) {
    return element == Element.NODE;
  }
}
