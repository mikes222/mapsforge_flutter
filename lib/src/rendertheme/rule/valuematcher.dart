import '../../model/tag.dart';
import 'package:collection/collection.dart';
import 'attributematcher.dart';

class ValueMatcher implements AttributeMatcher {
  final List<String> values;

  List<Tag>? _tags;

  ValueMatcher(this.values);

  @override
  bool isCoveredByAttributeMatcher(AttributeMatcher attributeMatcher) {
    if (attributeMatcher == this) {
      return true;
    }

    if (_tags == null) {
      List<Tag> tags = [];
      values.forEach((element) {
        tags.add(Tag(null, element));
      });
      _tags = tags;
    }
    return attributeMatcher.matchesTagList(_tags!);
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
