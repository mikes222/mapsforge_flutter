import 'package:collection/collection.dart';
import 'package:mapsforge_flutter/src/model/tag.dart';

/// The key to search for in the tags of the node or way. If the key is found the corresponding value is normally used
/// for drawing the text. For example the key may be "street". So if the node/way contains the key "street" the
/// corresponding value (e.g. Sesamstreet) is used.
class TextKey {
  final String key;

  const TextKey(this.key) : assert(key.length > 0);

  String? getValue(List<Tag> tags) {
    return tags.firstWhereOrNull((element) => element.key == key)?.value;
  }

  @override
  String toString() {
    return 'TextKey{key: $key}';
  }
}
