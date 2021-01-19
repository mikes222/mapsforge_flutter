import '../../model/tag.dart';

import 'attributematcher.dart';

class NegativeMatcher implements AttributeMatcher {
  final List<String> keyList;
  final List<String> valueList;

  NegativeMatcher(this.keyList, this.valueList);

  @override
  bool isCoveredByAttributeMatcher(AttributeMatcher attributeMatcher) {
    return false;
  }

  @override
  bool matchesTagList(List<Tag> tags) {
    if (keyListDoesNotContainKeys(tags)) {
      return true;
    }

    Tag tag = tags.firstWhere((element) => valueList.contains(element.value), orElse: () => null);
    return tag != null;
  }

  bool keyListDoesNotContainKeys(List<Tag> tags) {
    Tag tag = tags.firstWhere((element) => keyList.contains(element.key), orElse: () => null);
    return tag == null;
  }

  @override
  String toString() {
    return 'NegativeMatcher{keyList: $keyList, valueList: $valueList}';
  }
}
