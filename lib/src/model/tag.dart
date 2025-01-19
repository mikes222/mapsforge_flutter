/**
 * A tag represents an immutable key-value pair.
 */
class Tag implements Comparable<Tag> {
  static final String KEY_VALUE_SEPARATOR = '=';

  /**
   * The key of this tag.
   */
  final String? key;

  /**
   * The value of this tag.
   */
  final String? value;

  /**
   * @param key   the key of the tag.
   * @param value the value of the tag.
   */
  const Tag(this.key, this.value);

  /**
   * @param tag the textual representation of the tag.
   */
  Tag.fromTag(tag)
      : key = tag.substring(0, tag.indexOf(KEY_VALUE_SEPARATOR)),
        value = tag.substring(tag.indexOf(KEY_VALUE_SEPARATOR) + 1);

  /**
   * Compares this tag to the specified tag.
   * The tag comparison is based on a comparison of key and value in that order.
   *
   * @param tag The tag to compare to.
   * @return 0 if equal, &lt; 0 if considered "smaller", and &gt; 0 if considered "bigger".
   */
  @override
  int compareTo(Tag tag) {
    int keyResult = this.key!.compareTo(tag.key!);

    if (keyResult != 0) {
      return keyResult;
    }

    return this.value!.compareTo(tag.value!);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          value == other.value;

  @override
  int get hashCode => key.hashCode ^ value.hashCode;

  @override
  String toString() {
    return 'Tag{key: $key, value: $value}';
  }
}
