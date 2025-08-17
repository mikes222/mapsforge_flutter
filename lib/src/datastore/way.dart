import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:mapsforge_flutter/core.dart';

/// An immutable container for all data associated with a single way or area (closed way).
class Way {
  /// The position of the area label (may be null).
  final ILatLong? labelPosition;

  /// The geographical coordinates of the way nodes. The first item is the outer way whereas succeeding item
  /// always represents inner ways.
  final List<List<ILatLong>> latLongs;

  /// The layer of this way + 5 (to avoid negative values).
  final int layer;

  /// The tags of this way.
  final List<Tag> tags;

  const Way(this.layer, this.tags, this.latLongs, this.labelPosition);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Way &&
          runtimeType == other.runtimeType &&
          labelPosition == other.labelPosition &&
          // note: listEquals() is very expensive
          listEquals(latLongs[0], other.latLongs[0]) &&
          layer == other.layer &&
          listEquals(tags, other.tags);

  @override
  int get hashCode => labelPosition.hashCode ^ latLongs.hashCode ^ layer.hashCode ^ tags.hashCode;

  bool hasTag(String key) {
    return tags.firstWhereOrNull((test) => test.key == key) != null;
  }

  bool hasTagValue(String key, String value) {
    return tags.firstWhereOrNull((test) => test.key == key && test.value == value) != null;
  }

  String? getTag(String key) {
    return tags.firstWhereOrNull((test) => test.key == key)?.value;
  }

  BoundingBox getBoundingBox() {
    return BoundingBox.fromLatLongs(latLongs[0]);
  }

  String printTags() {
    return tags.map((toElement) => "${toElement.key}=${toElement.value}").join(",");
  }

  @override
  String toString() {
    return 'Way{labelPosition: $labelPosition, latLongs: ${latLongs.map((toElement) => "${toElement.length}").toList()}, layer: $layer, tags: ${printTags()}';
  }

  String toStringWithoutNames() {
    return 'Way{labelPosition: $labelPosition, latLongs: ${latLongs.map((toElement) => "${toElement.length}").toList()}, layer: $layer, tags: ${Tag.tagsWithoutNames(tags)}';
  }
}
