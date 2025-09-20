import 'package:collection/collection.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/src/matcher/attributematcher.dart';

class KeyMatcher implements AttributeMatcher {
  final List<String> keys;

  const KeyMatcher(this.keys);

  @override
  bool isCoveredByAttributeMatcher(AttributeMatcher attributeMatcher) {
    if (attributeMatcher == this) {
      return true;
    }
    String? missing = (attributeMatcher as KeyMatcher).keys.firstWhereOrNull((test) => !keys.contains(test));
    return missing == null;
  }

  @override
  bool matchesTagList(TagCollection tags) {
    return tags.matchesTagList(keys);
  }

  @override
  String toString() {
    return 'KeyMatcher{keys: $keys}';
  }
}
