import '../../model/tag.dart';

abstract class AttributeMatcher {
  bool isCoveredByAttributeMatcher(AttributeMatcher attributeMatcher);

  bool matchesTagList(List<Tag> tags);
}
