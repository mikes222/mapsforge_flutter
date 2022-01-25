import '../../model/tag.dart';
import 'package:collection/collection.dart';
import 'attributematcher.dart';

class NegativeMatcher implements AttributeMatcher {
  final List<String> keyList;
  final List<String> valueList;

  const NegativeMatcher(this.keyList, this.valueList);

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
        tags.firstWhereOrNull((element) => valueList.contains(element.value));
    return tag != null;
  }

  bool keyListDoesNotContainKeys(List<Tag> tags) {
    Tag? tag =
        tags.firstWhereOrNull((element) => keyList.contains(element.key));
    return tag == null;
  }

  @override
  String toString() {
    return 'NegativeMatcher{keyList: $keyList, valueList: $valueList}';
  }
}
