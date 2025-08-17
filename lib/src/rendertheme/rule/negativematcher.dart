import 'package:collection/collection.dart';

import '../../model/tag.dart';
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
  bool matchesTagList(List<Tag> tags) {
    if (keyListDoesNotContainKeys(tags)) {
      return true;
    }

    Tag? tag =
        tags.firstWhereOrNull((element) => values.contains(element.value));
    return tag != null;
  }

  bool keyListDoesNotContainKeys(List<Tag> tags) {
    Tag? tag = tags.firstWhereOrNull((element) => keys.contains(element.key));
    return tag == null;
  }

  @override
  String toString() {
    return 'NegativeMatcher{keyList: $keys, valueList: $values}';
  }
}
