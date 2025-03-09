import 'dart:math' as Math;

/// A min/max range of zoomlevels.
class ZoomlevelRange {
  final int zoomlevelMin;

  final int zoomlevelMax;

  /// Standard zoomlevels are 0..25.
  const ZoomlevelRange.standard()
      : zoomlevelMin = 0,
        zoomlevelMax = 25;

  const ZoomlevelRange(this.zoomlevelMin, this.zoomlevelMax)
      : assert(zoomlevelMin <= zoomlevelMax,
            "zoomlevelMin ($zoomlevelMin) should less or equal zoomlevelMax ($zoomlevelMax)");

  /// Returns a new ZoomlevelRange where the minimum zoomlevel is either the given
  /// zoomlevel or the existing one - whichever is bigger.
  ZoomlevelRange restrictToMin(int min) {
    return ZoomlevelRange(Math.max(min, zoomlevelMin), zoomlevelMax);
  }

  /// Returns a new ZoomlevelRange where the maximum zoomlevel is either the given
  /// zoomlevel or the existing one - whichever is smaller.
  ZoomlevelRange restrictToMax(int max) {
    return ZoomlevelRange(zoomlevelMin, Math.min(max, zoomlevelMax));
  }

  /// Returns a new ZoomlevelRange which is equal or smaller than the current one.
  ZoomlevelRange restrictTo(ZoomlevelRange range) {
    return ZoomlevelRange(Math.max(range.zoomlevelMin, zoomlevelMin),
        Math.min(range.zoomlevelMax, zoomlevelMax));
  }

  ZoomlevelRange widenTo(ZoomlevelRange range) {
    return ZoomlevelRange(Math.min(range.zoomlevelMin, zoomlevelMin),
        Math.max(range.zoomlevelMax, zoomlevelMax));
  }

  /// Returns a zoomlevel which lies guaranteed in the range of this zoomlevel range.
  int ensureBounds(int zoomlevel) {
    return Math.max(zoomlevelMin, Math.min(zoomlevelMax, zoomlevel));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZoomlevelRange &&
          runtimeType == other.runtimeType &&
          zoomlevelMin == other.zoomlevelMin &&
          zoomlevelMax == other.zoomlevelMax;

  @override
  int get hashCode => zoomlevelMin.hashCode ^ zoomlevelMax.hashCode;

  @override
  String toString() {
    return 'ZoomlevelRange{zoomlevelMin: $zoomlevelMin, zoomlevelMax: $zoomlevelMax}';
  }

  bool matches(int zoomlevel) {
    return zoomlevelMin <= zoomlevel && zoomlevel <= zoomlevelMax;
  }
}
