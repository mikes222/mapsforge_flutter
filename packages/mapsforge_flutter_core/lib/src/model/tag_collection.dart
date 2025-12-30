import 'package:collection/collection.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/src/utils/list_helper.dart';

/// A collection of `Tag` objects that provides a convenient way to access tags by key.
class TagCollection implements ITagCollection {
  final List<Tag> _tags;

  final int _hashCode;

  /// Creates a new `TagCollection`.
  TagCollection({required List<Tag> tags}) : _tags = tags, _hashCode = _calculateHashCode(tags);

  const TagCollection.empty() : _tags = const [], _hashCode = 0;

  /// Creates a list of `Tag` objects from a map of key-value pairs.
  static TagCollection from(Map<String, String> tags) {
    return TagCollection(tags: tags.entries.map((entry) => Tag(entry.key, entry.value)).toList());
  }

  TagCollection clone() {
    TagCollection tagCollection = TagCollection(tags: List.from(_tags));
    return tagCollection;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TagCollection && runtimeType == other.runtimeType && ListHelper().listEquals(_tags, other._tags);

  static int _calculateHashCode(List<Tag> tags) {
    // Optimized hash function using FNV-1a algorithm for better distribution
    // and reduced collision probability compared to simple XOR operations
    int hash = 2166136261; // FNV offset basis (32-bit)

    // Hash tags using FNV-1a algorithm
    for (final tag in tags) {
      hash ^= tag.hashCode;
      hash *= 16777619; // FNV prime (32-bit)
    }
    return hash;
  }

  @override
  int get hashCode => _hashCode;

  // @override
  // int get hashCode => _tags.hashCode;

  /// Returns true if this POI has a tag with the given [key].
  bool hasTag(String key) {
    return _tags.firstWhereOrNull((test) => test.key == key) != null;
  }

  /// Returns true if this POI has a tag with the given [key] and [value].
  bool hasTagValue(String key, String value) {
    return _tags.firstWhereOrNull((test) => test.key == key && test.value == value) != null;
  }

  /// Returns the value of the tag with the given [key], or null if it does not exist.
  @override
  String? getTag(String key) {
    return _tags.firstWhereOrNull((test) => test.key == key)?.value;
  }

  @override
  bool matchesTagList(List<String> keys) {
    Tag? tag = _tags.firstWhereOrNull((element) => keys.contains(element.key));
    return tag != null;
  }

  @override
  bool valueMatchesTagList(List<String> values) {
    Tag? tag = _tags.firstWhereOrNull((element) => values.contains(element.value));
    return tag != null;
  }

  bool get isEmpty => _tags.isEmpty;

  bool get isNotEmpty => _tags.isNotEmpty;

  int get length => _tags.length;

  List<Tag> get tags => _tags;

  // void add(Tag tag) {
  //   _tags.add(tag);
  // }

  /// Returns a string representation of the tags.
  String printTags() {
    return _tags.map((toElement) => "${toElement.key}=${toElement.value}").join(",");
  }

  /// Returns a string representation of the given list of tags, excluding any
  /// name-related tags.
  String printTagsWithoutNames() {
    String result = '';
    for (var tag in _tags) {
      if (tag.key.startsWith("name:") || tag.key.startsWith("official_name") || tag.key.startsWith("alt_name") || tag.key.startsWith("int_name")) continue;
      if (result.isNotEmpty) result += ",";
      result += "${tag.key}=${tag.value}";
    }
    return result;
  }
}
