import 'package:collection/collection.dart';

import '../../model/tag.dart';
import 'attributematcher.dart';

class KeyMatcher implements AttributeMatcher {
  final List<String> keys;

  const KeyMatcher(this.keys);

  @override
  bool isCoveredByAttributeMatcher(AttributeMatcher attributeMatcher) {
    if (attributeMatcher == this) {
      return true;
    }
    String? missing = (attributeMatcher as KeyMatcher)
        .keys
        .firstWhereOrNull((test) => !keys.contains(test));
    return missing == null;
  }

  @override
  bool matchesTagList(List<Tag> tags) {
    Tag? tag = tags.firstWhereOrNull((element) => keys.contains(element.key));
    return tag != null;
  }

  @override
  String toString() {
    return 'KeyMatcher{keys: $keys}';
  }
}
