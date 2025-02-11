import 'package:collection/collection.dart';

import '../../model/tag.dart';
import 'attributematcher.dart';

class ValueMatcher implements AttributeMatcher {
  final List<String> values;

  const ValueMatcher(this.values);

  @override
  bool isCoveredByAttributeMatcher(AttributeMatcher attributeMatcher) {
    if (attributeMatcher == this) {
      return true;
    }

    String? missing = (attributeMatcher as ValueMatcher)
        .values
        .firstWhereOrNull((test) => !values.contains(test));
    return missing == null;
  }

  @override
  bool matchesTagList(List<Tag> tags) {
    Tag? tag =
        tags.firstWhereOrNull((element) => values.contains(element.value));
    return tag != null;
  }

  @override
  String toString() {
    return 'ValueMatcher{values: $values}';
  }
}
