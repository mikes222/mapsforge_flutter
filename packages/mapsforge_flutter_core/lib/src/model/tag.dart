/// An immutable key-value pair, used to store metadata for map elements.
class Tag implements Comparable<Tag> {
  static final String KEY_VALUE_SEPARATOR = '=';

  /// The key of this tag.
  final String key;

  /// The value of this tag.
  final String value;

  /// Creates a new `Tag`.
  const Tag(this.key, this.value);

  /// Creates a new `Tag` from a string in the format "key=value".
  Tag.fromTag(String tag) : key = tag.substring(0, tag.indexOf(KEY_VALUE_SEPARATOR)), value = tag.substring(tag.indexOf(KEY_VALUE_SEPARATOR) + 1);

  /// Compares this tag to another tag, first by key, then by value.
  @override
  int compareTo(Tag tag) {
    int keyResult = key.compareTo(tag.key);

    if (keyResult != 0) {
      return keyResult;
    }

    return value.compareTo(tag.value);
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is Tag && runtimeType == other.runtimeType && key == other.key && value == other.value;

  @override
  int get hashCode => key.hashCode ^ value.hashCode;

  @override
  String toString() {
    return 'Tag{key: $key, value: $value}';
  }

  /// Returns a string representation of the given list of tags, excluding any
  /// name-related tags.
  static String tagsWithoutNames(List<Tag> tags) {
    String result = '';
    for (var tag in tags) {
      if (tag.key.startsWith("name:") || tag.key.startsWith("official_name") || tag.key.startsWith("alt_name") || tag.key.startsWith("int_name")) continue;
      if (result.isNotEmpty) result += ",";
      result += "${tag.key}=${tag.value}";
    }
    return result;
  }
}
