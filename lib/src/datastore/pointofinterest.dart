import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:mapsforge_flutter/core.dart';

/// An immutable container for all data associated with a single point of interest node (POI).
class PointOfInterest {
  /// The layer of this POI + 5 (to avoid negative values).
  final int layer;

  /// The position of this POI.
  final ILatLong position;

  /// The tags of this POI.
  final List<Tag> tags;

  const PointOfInterest(this.layer, this.tags, this.position)
      : assert(layer >= -5),
        assert(layer <= 10);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointOfInterest && runtimeType == other.runtimeType && layer == other.layer && position == other.position && listEquals(tags, other.tags);

  @override
  int get hashCode => layer.hashCode ^ position.hashCode ^ tags.hashCode;

  bool hasTag(String key) {
    return tags.firstWhereOrNull((test) => test.key == key) != null;
  }

  bool hasTagValue(String key, String value) {
    return tags.firstWhereOrNull((test) => test.key == key && test.value == value) != null;
  }

  String? getTag(String key) {
    return tags.firstWhereOrNull((test) => test.key == key)?.value;
  }

  String printTags() {
    return tags.map((toElement) => "${toElement.key}=${toElement.value}").join(",");
  }

  @override
  String toString() {
    return 'PointOfInterest{layer: $layer, position: $position, tags: ${tags.map((toElement) => "${toElement.key}=${toElement.value}").join(",")}}';
  }

  String toStringWithoutNames() {
    return 'PointOfInterest{layer: $layer, position: $position, tags: ${Tag.tagsWithoutNames(tags)}}';
  }
}
