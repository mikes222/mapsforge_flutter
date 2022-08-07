import 'package:mapsforge_flutter/src/model/tag.dart';

class TextKey {
  static final Map<String, TextKey> TEXT_KEYS = new Map();

  final String key;

  static TextKey getInstance(String key) {
    assert(key.length > 0);
    TextKey? textKey = TEXT_KEYS[key];
    if (textKey == null) {
      textKey = new TextKey(key);
      TEXT_KEYS[key] = textKey;
    }
    return textKey;
  }

  const TextKey(this.key) : assert(key.length > 0);

  String? getValue(List<Tag> tags) {
    for (int i = 0; i < tags.length; ++i) {
      if (this.key == tags[i].key) {
        return tags[i].value;
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'TextKey{key: $key}';
  }
}
