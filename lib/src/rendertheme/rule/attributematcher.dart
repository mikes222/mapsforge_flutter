import 'package:mapsforge_flutter/src/rendertheme/rule/valuematcher.dart';

import '../../model/tag.dart';
import '../xml/rulebuilder.dart';
import 'anymatcher.dart';
import 'keymatcher.dart';

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
    if (valueList.length > 0 && RuleBuilder.STRING_WILDCARD == (valueList[0])) {
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
