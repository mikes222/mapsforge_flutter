import 'package:mapsforge_flutter_core/model.dart';

import 'attributematcher.dart';

class NegativeMatcher implements AttributeMatcher {
  final List<String> keys;
  final List<String> values;

  const NegativeMatcher(this.keys, this.values);

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
    return 'NegativeMatcher{keyList: $keys, valueList: $values}';
  }
}
