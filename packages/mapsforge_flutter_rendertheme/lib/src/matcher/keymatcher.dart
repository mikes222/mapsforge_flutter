import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/attributematcher.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/anymatcher.dart';

class KeyMatcher implements AttributeMatcher {
  final Set<String> keys;

  KeyMatcher(List<String> keys) : keys = Set.unmodifiable(keys);

  @override
  bool isCoveredByAttributeMatcher(AttributeMatcher attributeMatcher) {
    if (attributeMatcher == this) {
      return true;
    }
    if (attributeMatcher is AnyMatcher) {
      return true;
    }
    if (attributeMatcher is KeyMatcher) {
      return attributeMatcher.keys.every(keys.contains);
    }
    return false;
  }

  @override
  bool matchesTagList(ITagCollection tags) {
    return tags.matchesTagList(keys);
  }

  @override
  String toString() {
    return 'KeyMatcher{keys: ${keys.toList()}}';
  }
}
