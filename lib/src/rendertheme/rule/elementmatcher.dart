import 'element.dart';

abstract class ElementMatcher {
  bool isCoveredByElementMatcher(ElementMatcher? elementMatcher);

  bool matchesElement(Element element);
}
