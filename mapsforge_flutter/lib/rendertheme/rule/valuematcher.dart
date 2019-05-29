import '../../model/tag.dart';

import 'attributematcher.dart';

class ValueMatcher implements AttributeMatcher {
  final List<String> values;

  ValueMatcher(this.values);

  @override
  bool isCoveredByAttributeMatcher(AttributeMatcher attributeMatcher) {
    if (attributeMatcher == this) {
      return true;
    }

    List<Tag> tags = new List<Tag>(this.values.length);
    for (int i = 0, n = this.values.length; i < n; ++i) {
      tags.add(new Tag(null, this.values.elementAt(i)));
    }
    return attributeMatcher.matchesTagList(tags);
  }

  @override
  bool matchesTagList(List<Tag> tags) {
    for (int i = 0, n = tags.length; i < n; ++i) {
      if (this.values.contains(tags.elementAt(i).value)) {
        return true;
      }
    }
    return false;
  }
}
