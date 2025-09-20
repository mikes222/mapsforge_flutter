import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/src/utils/list_helper.dart';

/// An immutable container for all data associated with a single way or area (closed way).
class Way {
  /// The position of the area label (may be null).
  final ILatLong? labelPosition;

  /// The geographical coordinates of the way nodes. The first item is the outer way whereas succeeding item
  /// always represents inner ways.
  /// todo replace with class-structure to make it easier to understand
  final List<List<ILatLong>> latLongs;

  /// The layer of this way + 5 (to avoid negative values).
  final int layer;

  /// The tags of this way.
  final TagCollection tags;

  /// Creates a new `Way`.
  Way(this.layer, List<Tag> tags, this.latLongs, this.labelPosition) : tags = TagCollection(tags: tags);

  Way.simple(List<ILatLong> latLongs) : layer = 0, tags = const TagCollection.empty(), latLongs = [latLongs], labelPosition = null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Way &&
          runtimeType == other.runtimeType &&
          labelPosition == other.labelPosition &&
          // note: listEquals() is very expensive
          ListHelper().listEquals(latLongs[0], other.latLongs[0]) &&
          layer == other.layer &&
          tags == other.tags;

  @override
  int get hashCode => labelPosition.hashCode ^ latLongs.hashCode ^ layer.hashCode ^ tags.hashCode;

  /// Returns true if this way has a tag with the given [key].
  bool hasTag(String key) {
    return tags.hasTag(key);
  }

  /// Returns true if this way has a tag with the given [key] and [value].
  bool hasTagValue(String key, String value) {
    return tags.hasTagValue(key, value);
  }

  /// Returns the value of the tag with the given [key], or null if it does not exist.
  String? getTag(String key) {
    return tags.getTag(key);
  }

  /// Returns the bounding box of the outer way.
  BoundingBox getBoundingBox() {
    return BoundingBox.fromLatLongs(latLongs[0]);
  }

  @override
  String toString() {
    return 'Way{labelPosition: $labelPosition, latLongs: ${latLongs.map((toElement) => "${toElement.length}").toList()}, layer: $layer, tags: ${tags.printTags()}';
  }

  /// Returns a string representation of the way, excluding name tags.
  String toStringWithoutNames() {
    return 'Way{labelPosition: $labelPosition, latLongs: ${latLongs.map((toElement) => "${toElement.length}").toList()}, layer: $layer, tags: ${tags.printTagsWithoutNames()}';
  }
}
