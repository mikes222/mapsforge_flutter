import 'element.dart';
import 'elementmatcher.dart';

class ElementNodeMatcher implements ElementMatcher {
  static final ElementNodeMatcher INSTANCE = new ElementNodeMatcher();

  ElementNodeMatcher() {
    // do nothing
  }

  @override
  bool isCoveredByElementMatcher(ElementMatcher? elementMatcher) {
    return elementMatcher!.matchesElement(Element.NODE);
  }

  @override
  bool matchesElement(Element element) {
    return element == Element.NODE;
  }
}
