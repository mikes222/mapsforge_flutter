import 'package:mapsforge_flutter/model/tag.dart';

class TextKey {
  static final Map<String, TextKey> TEXT_KEYS = new Map();

  static TextKey getInstance(String key) {
    assert(key != null && key.length > 0);
    TextKey textKey = TEXT_KEYS[key];
    if (textKey == null) {
      textKey = new TextKey(key);
      TEXT_KEYS[key] = textKey;
    }
    assert(textKey != null);
    return textKey;
  }

  final String key;

  TextKey(this.key) : assert(key != null && key.length > 0);

  String getValue(List<Tag> tags) {
    assert(tags != null);
    for (int i = 0; i < tags.length; ++i) {
      if (this.key == tags[i].key) {
        return tags[i].value;
      }
    }
    return null;
  }
}
