import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/keymatcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/valuematcher.dart';

import '../matcher/anymatcher.dart';
import '../xml/rulebuilder.dart';

abstract class AttributeMatcher {
  static Map<List<String>, AttributeMatcher> MATCHERS_CACHE_KEY = {};
  static Map<List<String>, AttributeMatcher> MATCHERS_CACHE_VALUE = {};

  static AttributeMatcher getKeyMatcher(List<String> keyList) {
    if (RuleBuilder.STRING_WILDCARD == (keyList.elementAt(0))) {
      return const AnyMatcher();
    }

    AttributeMatcher? attributeMatcher = MATCHERS_CACHE_KEY[keyList];
    if (attributeMatcher == null) {
      attributeMatcher = KeyMatcher(keyList);
      MATCHERS_CACHE_KEY[keyList] = attributeMatcher;
    }
    return attributeMatcher;
  }

  static AttributeMatcher getValueMatcher(List<String> valueList) {
    if (valueList.isNotEmpty && RuleBuilder.STRING_WILDCARD == (valueList[0])) {
      return const AnyMatcher();
    }

    AttributeMatcher? attributeMatcher = MATCHERS_CACHE_VALUE[valueList];
    if (attributeMatcher == null) {
      attributeMatcher = ValueMatcher(valueList);
      MATCHERS_CACHE_VALUE[valueList] = attributeMatcher;
    }
    return attributeMatcher;
  }

  bool isCoveredByAttributeMatcher(AttributeMatcher attributeMatcher);

  bool matchesTagList(List<Tag> tags);
}
