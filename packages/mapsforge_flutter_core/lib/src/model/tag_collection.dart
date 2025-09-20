import 'package:collection/collection.dart';
import 'package:mapsforge_flutter_core/model.dart';

/// A collection of `Tag` objects that provides a convenient way to access tags by key.
class TagCollection {
  final List<Tag> _tags;

  /// Creates a new `TagCollection`.
  TagCollection({required List<Tag> tags}) : _tags = tags;

  /// Returns the first tag with the given [key], or null if no such tag exists.
  Tag? getTagByKey(String key) {
    return _tags.firstWhereOrNull((Tag test) => test.key == key);
  }
}
