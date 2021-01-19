import '../../model/tag.dart';

import 'attributematcher.dart';

class ValueMatcher implements AttributeMatcher {
  final List<String> values;

  List<Tag> _tags;

  ValueMatcher(this.values);

  @override
  bool isCoveredByAttributeMatcher(AttributeMatcher attributeMatcher) {
    if (attributeMatcher == this) {
      return true;
    }

    if (_tags == null) {
      List<Tag> tags = new List<Tag>(this.values.length);
      for (int i = 0, n = this.values.length; i < n; ++i) {
        tags.add(new Tag(null, this.values.elementAt(i)));
      }
      _tags = tags;
    }
    return attributeMatcher.matchesTagList(_tags);
  }

  @override
  bool matchesTagList(List<Tag> tags) {
    Tag tag = tags.firstWhere((element) => values.contains(element.value), orElse: () => null);
    return tag != null;
  }

  @override
  String toString() {
    return 'ValueMatcher{values: $values}';
  }
}
