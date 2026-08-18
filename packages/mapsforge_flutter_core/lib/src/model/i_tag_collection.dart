abstract class ITagCollection {
  bool matchesTagList(Iterable<String> keys);

  bool valueMatchesTagList(Iterable<String> values);

  /// Returns the value of the tag with the given [key], or null if it does not exist.
  String? getTag(String key);
}
