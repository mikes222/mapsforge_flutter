import '../../model/tag.dart';
import 'package:collection/collection.dart';
import 'attributematcher.dart';

class KeyMatcher implements AttributeMatcher {
  final List<String> keys;

  List<Tag>? _tags;

  KeyMatcher(this.keys);

  @override
  bool isCoveredByAttributeMatcher(AttributeMatcher attributeMatcher) {
    if (attributeMatcher == this) {
      return true;
    }

    if (_tags == null) {
      List<Tag> tags = [];
      keys.forEach((element) {
        tags.add(Tag(element, null));
      });
      _tags = tags;
    }
    return attributeMatcher.matchesTagList(_tags!);
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
