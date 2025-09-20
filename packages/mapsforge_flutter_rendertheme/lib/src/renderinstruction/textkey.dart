import 'package:mapsforge_flutter_core/model.dart';

/// The key to search for in the tags of the node or way. If the key is found the corresponding value is normally used
/// for drawing the text. For example the key may be "street". So if the node/way contains the key "street" the
/// corresponding value (e.g. Sesamstreet) is used.
class TextKey {
  final String key;

  const TextKey(this.key) : assert(key.length > 0);

  String? getValue(TagCollection tags) {
    return tags.getTag(key);
  }

  @override
  String toString() {
    return 'TextKey{key: $key}';
  }
}
