import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/keymatcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/valuematcher.dart';

import '../matcher/anymatcher.dart';
import '../xml/rulebuilder.dart';

abstract class AttributeMatcher {
  // Keyed by the joined string, not the List<String>: Dart lists compare by
  // identity, so a List key never hits and the cache grows by one entry per
  // rule per theme parse (the Java original relies on List.equals/hashCode
  // being content-based).
  static final Map<String, AttributeMatcher> MATCHERS_CACHE_KEY = {};
  static final Map<String, AttributeMatcher> MATCHERS_CACHE_VALUE = {};

  static String _cacheKey(List<String> list) => list.join('|');

  static AttributeMatcher getKeyMatcher(List<String> keyList) {
    if (RuleBuilder.STRING_WILDCARD == (keyList.elementAt(0))) {
      return const AnyMatcher();
    }

    String cacheKey = _cacheKey(keyList);
    AttributeMatcher? attributeMatcher = MATCHERS_CACHE_KEY[cacheKey];
    if (attributeMatcher == null) {
      attributeMatcher = KeyMatcher(keyList);
      MATCHERS_CACHE_KEY[cacheKey] = attributeMatcher;
    }
    return attributeMatcher;
  }

  static AttributeMatcher getValueMatcher(List<String> valueList) {
    if (valueList.isNotEmpty && RuleBuilder.STRING_WILDCARD == (valueList[0])) {
      return const AnyMatcher();
    }

    String cacheKey = _cacheKey(valueList);
    AttributeMatcher? attributeMatcher = MATCHERS_CACHE_VALUE[cacheKey];
    if (attributeMatcher == null) {
      attributeMatcher = ValueMatcher(valueList);
      MATCHERS_CACHE_VALUE[cacheKey] = attributeMatcher;
    }
    return attributeMatcher;
  }

  bool isCoveredByAttributeMatcher(AttributeMatcher attributeMatcher);

  bool matchesTagList(ITagCollection tags);
}
