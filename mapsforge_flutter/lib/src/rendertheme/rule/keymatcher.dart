import '../../model/tag.dart';

import 'attributematcher.dart';

class KeyMatcher implements AttributeMatcher {
  final List<String> keys;

  List<Tag> _tags;

  KeyMatcher(this.keys);

  @override
  bool isCoveredByAttributeMatcher(AttributeMatcher attributeMatcher) {
    if (attributeMatcher == this) {
      return true;
    }

    if (_tags == null) {
      List<Tag> tags = new List<Tag>(this.keys.length);
      for (int i = 0, n = this.keys.length; i < n; ++i) {
        tags.add(new Tag(this.keys.elementAt(i), null));
      }
      _tags = tags;
    }
    return attributeMatcher.matchesTagList(_tags);
  }

  @override
  bool matchesTagList(List<Tag> tags) {
    Tag tag = tags.firstWhere((element) => keys.contains(element.key), orElse: () => null);
    return tag != null;
  }

  @override
  String toString() {
    return 'KeyMatcher{keys: $keys}';
  }
}
