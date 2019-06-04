import '../../model/tag.dart';

import 'attributematcher.dart';

class KeyMatcher implements AttributeMatcher {
  final List<String> keys;

  KeyMatcher(this.keys);

  @override
  bool isCoveredByAttributeMatcher(AttributeMatcher attributeMatcher) {
    if (attributeMatcher == this) {
      return true;
    }

    List<Tag> tags = new List<Tag>(this.keys.length);
    for (int i = 0, n = this.keys.length; i < n; ++i) {
      tags.add(new Tag(this.keys.elementAt(i), null));
    }
    return attributeMatcher.matchesTagList(tags);
  }

  @override
  bool matchesTagList(List<Tag> tags) {
    for (int i = 0, n = tags.length; i < n; ++i) {
      if (this.keys.contains(tags.elementAt(i).key)) {
        return true;
      }
    }
    return false;
  }

  @override
  String toString() {
    return 'KeyMatcher{keys: $keys}';
  }
}
