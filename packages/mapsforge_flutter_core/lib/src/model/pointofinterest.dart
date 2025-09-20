import 'package:collection/collection.dart';
import 'package:mapsforge_flutter_core/src/model/ilatlong.dart';
import 'package:mapsforge_flutter_core/src/model/tag.dart';
import 'package:mapsforge_flutter_core/src/utils/list_helper.dart';

/// An immutable container for all data associated with a single Point of Interest (POI).
class PointOfInterest {
  /// The layer of this POI + 5 (to avoid negative values).
  final int layer;

  /// The position of this POI.
  final ILatLong position;

  /// The tags of this POI.
  /// todo change to TagList so that we can implement better caching
  final List<Tag> tags;

  /// Creates a new `PointOfInterest`.
  const PointOfInterest(this.layer, this.tags, this.position) : assert(layer >= -5), assert(layer <= 10);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointOfInterest &&
          runtimeType == other.runtimeType &&
          layer == other.layer &&
          position == other.position &&
          ListHelper().listEquals(tags, other.tags);

  @override
  int get hashCode => layer.hashCode ^ position.hashCode ^ tags.hashCode;

  /// Returns true if this POI has a tag with the given [key].
  bool hasTag(String key) {
    return tags.firstWhereOrNull((test) => test.key == key) != null;
  }

  /// Returns true if this POI has a tag with the given [key] and [value].
  bool hasTagValue(String key, String value) {
    return tags.firstWhereOrNull((test) => test.key == key && test.value == value) != null;
  }

  /// Returns the value of the tag with the given [key], or null if it does not exist.
  String? getTag(String key) {
    return tags.firstWhereOrNull((test) => test.key == key)?.value;
  }

  /// Returns a string representation of the tags.
  String printTags() {
    return tags.map((toElement) => "${toElement.key}=${toElement.value}").join(",");
  }

  @override
  String toString() {
    return 'PointOfInterest{layer: $layer, position: $position, tags: ${tags.map((toElement) => "${toElement.key}=${toElement.value}").join(",")}}';
  }

  /// Returns a string representation of the POI, excluding name tags.
  String toStringWithoutNames() {
    return 'PointOfInterest{layer: $layer, position: $position, tags: ${Tag.tagsWithoutNames(tags)}}';
  }
}
