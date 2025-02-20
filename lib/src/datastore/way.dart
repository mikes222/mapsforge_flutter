import 'package:collection/collection.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/model/maprectangle.dart';

import '../renderer/minmaxdouble.dart';

/// An immutable container for all data associated with a single way or area (closed way).
class Way {
  /// The position of the area label (may be null).
  final ILatLong? labelPosition;

  /// The geographical coordinates of the way nodes.
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
          latLongs == other.latLongs &&
          layer == other.layer &&
          tags == other.tags;

  @override
  int get hashCode =>
      labelPosition.hashCode ^
      latLongs.hashCode ^
      layer.hashCode ^
      tags.hashCode;

  // BoundingBox getBoundary() {
  //   MinMaxDouble minMaxMappoint = MinMaxDouble.empty();
  //   latLongs.forEach((List<ILatLong> lls) {
  //     minMaxMappoint.extendLatLong(lls);
  //   });
  //   return minMaxMappoint.getBoundary();
  // }

  bool hasTag(String key) {
    return tags.firstWhereOrNull((test) => test.key == key) != null;
  }

  String? getTag(String key) {
    return tags.firstWhereOrNull((test) => test.key == key)?.value;
  }

  /// Only for debugging purposes. MapRectangle is not meant for lat/lon, use BoundaryBox instead
  MapRectangle calculateBoundary() {
    MinMaxDouble minMaxMappoint = MinMaxDouble.empty();
    latLongs.forEach((List<ILatLong> lls) {
      minMaxMappoint.extendLatLong(lls);
    });
    return minMaxMappoint.getBoundary();
  }

  @override
  String toString() {
    return 'Way{labelPosition: $labelPosition, latLongs: $latLongs, layer: $layer, tags: $tags}';
  }
}
