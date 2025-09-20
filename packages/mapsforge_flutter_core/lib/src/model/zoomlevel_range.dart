import 'dart:math' as Math;

import 'package:mapsforge_flutter_core/utils.dart';

/// An immutable range of zoom levels, defined by a minimum and maximum value.
class ZoomlevelRange {
  final int zoomlevelMin;

  final int zoomlevelMax;

  /// Creates a new `ZoomlevelRange` with the default standard zoom levels (0-22).
  const ZoomlevelRange.standard() : zoomlevelMin = 0, zoomlevelMax = MapsforgeSettingsMgr.defaultMaxZoomlevel;

  /// Creates a new `ZoomlevelRange`.
  const ZoomlevelRange([this.zoomlevelMin = 0, this.zoomlevelMax = 25])
    : assert(zoomlevelMin <= zoomlevelMax, "zoomlevelMin ($zoomlevelMin) should less or equal zoomlevelMax ($zoomlevelMax)");

  /// Creates a new `ZoomlevelRange` by restricting the minimum zoom level of this
  /// range to the given [min] value, if it is greater.
  ZoomlevelRange restrictToMin(int min) {
    return ZoomlevelRange(Math.max(min, zoomlevelMin), zoomlevelMax);
  }

  /// Creates a new `ZoomlevelRange` by restricting the maximum zoom level of this
  /// range to the given [max] value, if it is smaller.
  ZoomlevelRange restrictToMax(int max) {
    return ZoomlevelRange(zoomlevelMin, Math.min(max, zoomlevelMax));
  }

  /// Creates a new `ZoomlevelRange` that is the intersection of this range and
  /// the given [range].
  ZoomlevelRange restrictTo(ZoomlevelRange range) {
    return ZoomlevelRange(Math.max(range.zoomlevelMin, zoomlevelMin), Math.min(range.zoomlevelMax, zoomlevelMax));
  }

  /// Creates a new `ZoomlevelRange` that is the union of this range and the
  /// given [range].
  ZoomlevelRange widenTo(ZoomlevelRange range) {
    return ZoomlevelRange(Math.min(range.zoomlevelMin, zoomlevelMin), Math.max(range.zoomlevelMax, zoomlevelMax));
  }

  /// Clamps the given [zoomlevel] to be within this range.
  int ensureBounds(int zoomlevel) {
    return Math.max(zoomlevelMin, Math.min(zoomlevelMax, zoomlevel));
  }

  /// Returns true if the given [zoomlevel] is within this range (inclusive).
  bool isWithin(int zoomlevel) {
    return zoomlevelMin <= zoomlevel && zoomlevel <= zoomlevelMax;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZoomlevelRange && runtimeType == other.runtimeType && zoomlevelMin == other.zoomlevelMin && zoomlevelMax == other.zoomlevelMax;

  @override
  int get hashCode => zoomlevelMin.hashCode ^ zoomlevelMax.hashCode;

  @override
  String toString() {
    return 'ZoomlevelRange{$zoomlevelMin - $zoomlevelMax}';
  }

  /// Returns true if the given [zoomlevel] is within this range (inclusive).
  bool matches(int zoomlevel) {
    return zoomlevelMin <= zoomlevel && zoomlevel <= zoomlevelMax;
  }
}
