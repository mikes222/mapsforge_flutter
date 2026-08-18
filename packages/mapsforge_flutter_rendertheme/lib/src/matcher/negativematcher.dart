import 'package:mapsforge_flutter_core/model.dart';

import 'attributematcher.dart';

class NegativeMatcher implements AttributeMatcher {
  final Set<String> keys;
  final Set<String> values;

  NegativeMatcher(List<String> keys, List<String> values)
      : keys = Set.unmodifiable(keys),
        values = Set.unmodifiable(values);

  @override
  bool isCoveredByAttributeMatcher(AttributeMatcher attributeMatcher) {
    return false;
  }

  @override
  bool matchesTagList(ITagCollection tags) {
    if (keyListDoesNotContainKeys(tags)) {
      return true;
    }

    return tags.valueMatchesTagList(values);
  }

  bool keyListDoesNotContainKeys(ITagCollection tags) {
    return !tags.matchesTagList(keys);
  }

  @override
  String toString() {
    return 'NegativeMatcher{keyList: ${keys.toList()}, valueList: ${values.toList()}}';
  }
}
