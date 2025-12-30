abstract class ITagCollection {
  bool matchesTagList(List<String> keys);

  bool valueMatchesTagList(List<String> values);

  /// Returns the value of the tag with the given [key], or null if it does not exist.
  String? getTag(String key);
}
