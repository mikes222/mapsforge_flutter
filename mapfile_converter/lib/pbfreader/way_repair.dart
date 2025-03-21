import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/special.dart';

/// tries to fix open ways from relationships (PBF) by connecting missing ends.
class WayRepair {
  void repairOpen(Wayholder wayholder) {
    _repair(wayholder);
  }

  void repairClosed(Wayholder wayholder) {
    double maxGap = _repair(wayholder);
    if (!LatLongUtils.isClosedWay(wayholder.way.latLongs[0])) {
      // if (LatLongUtils.euclideanDistanceSquared(wayholder.way.latLongs[0].first, wayholder.way.latLongs[0].last) > maxGap) {
      //   print("Could not close $wayholder, because it exceeds the max gap");
      // }
      wayholder.way.latLongs[0].add(wayholder.way.latLongs[0].first);
    }
  }

  double _repair(Wayholder wayholder) {
    // calculate the bounding box over all possible affected ways
    BoundingBox boundingBox = BoundingBox.fromLatLongs(wayholder.way.latLongs[0]);
    for (List<ILatLong> wayFirst in wayholder.otherOuters) {
      boundingBox.extendBoundingBox(BoundingBox.fromLatLongs(wayFirst));
    }
    double maxGap = LatLongUtils.euclideanDistanceSquared(boundingBox.getLeftUpper(), boundingBox.getRightLower());
    // do not accept gaps more than 5% of the overall size
    maxGap *= 0.05;

    while (true) {
      Set<_Gap> gaps = _findGaps(wayholder);
      int count = gaps.length;
      while (gaps.isNotEmpty) {
        _Gap smallest = gaps.reduce((first, second) => first.gap < second.gap ? first : second);
        if (smallest.gap > maxGap) {
          double distance = Projection.distance(smallest.first, smallest.second);
          if (distance < 200) {
            // allow a minimum distance of 200 m
            maxGap = smallest.gap * 1.05;
          }
          if (smallest.gap > maxGap) {
            // print("Could not combine $smallest for $wayholder, because it exceeds the max gap of $distance");
            break;
          }
        }
        // now combine the two ways
        _combine(smallest, wayholder, gaps);
      }
      if (gaps.length == count) break;
    }
    return maxGap;
  }

  Set<_Gap> _findGaps(Wayholder wayholder) {
    Set<_Gap> gaps = {};
    List<ILatLong> wayFirst = wayholder.way.latLongs[0];
    if (!LatLongUtils.isClosedWay(wayFirst)) {
      for (List<ILatLong> waySecond in wayholder.otherOuters) {
        if (LatLongUtils.isClosedWay(waySecond)) continue;
        _addGaps(wayFirst, waySecond, gaps);
      }
    }
    for (List<ILatLong> wayFirst in wayholder.otherOuters) {
      if (LatLongUtils.isClosedWay(wayFirst)) continue;
      for (List<ILatLong> waySecond in wayholder.otherOuters) {
        if (wayFirst == waySecond) continue;
        if (LatLongUtils.isClosedWay(waySecond)) continue;
        _addGaps(wayFirst, waySecond, gaps);
      }
    }
    return gaps;
  }

  void _combine(_Gap smallest, Wayholder wayholder, Set<_Gap> gaps) {
    if (smallest.prependFirstWay != null) {
      smallest.firstWay.insert(0, smallest.prependFirstWay!);
    }
    if (smallest.appendFirstWay != null) {
      smallest.firstWay.add(smallest.appendFirstWay!);
    }
    bool ok = LatLongUtils.combine(smallest.firstWay, smallest.secondWay);
    if (ok) {
      wayholder.otherOuters.remove(smallest.secondWay);
      gaps.remove(smallest);
      gaps.removeWhere((test) => test.secondWay == smallest.firstWay);
      gaps.removeWhere((test) => test.firstWay == smallest.firstWay);
      gaps.removeWhere((test) => test.secondWay == smallest.secondWay);
      gaps.removeWhere((test) => test.firstWay == smallest.secondWay);
    } else {
      print("Could not combine $smallest for $wayholder, why?");
      print(
        "Firstway: ${smallest.firstWay.length <= 6 ? smallest.firstWay : [...smallest.firstWay.sublist(0, 3), ...smallest.firstWay.sublist(smallest.firstWay.length - 3)]} (${smallest.firstWay.length})",
      );
      print(
        "Secondway: ${smallest.secondWay.length <= 6 ? smallest.secondWay : [...smallest.secondWay.sublist(0, 3), ...smallest.secondWay.sublist(smallest.secondWay.length - 3)]} (${smallest.secondWay.length})",
      );
    }
  }

  void _addGaps(List<ILatLong> wayFirst, List<ILatLong> waySecond, Set<_Gap> gaps) {
    // make sure there is a gap between the two ways
    assert(wayFirst.first != waySecond.first, "First: ${wayFirst.first} (${wayFirst.length}), Second: ${waySecond.first} (${waySecond.length})");
    assert(wayFirst.first != waySecond.last, "First: ${wayFirst.first} (${wayFirst.length}), Second: ${waySecond.last}  (${waySecond.length})");
    assert(wayFirst.last != waySecond.first);
    assert(wayFirst.last != waySecond.last);
    gaps.add(_Gap(wayFirst.first, waySecond.first, wayFirst, waySecond, waySecond.first, null));
    gaps.add(_Gap(wayFirst.first, waySecond.last, wayFirst, waySecond, waySecond.last, null));
    gaps.add(_Gap(wayFirst.last, waySecond.last, wayFirst, waySecond, null, waySecond.last));
    gaps.add(_Gap(wayFirst.last, waySecond.first, wayFirst, waySecond, null, waySecond.first));
  }
}

//////////////////////////////////////////////////////////////////////////////

class _Gap {
  final ILatLong first;

  final ILatLong second;

  final List<ILatLong> firstWay;

  final List<ILatLong> secondWay;

  /// In order to combine the two ways we must insert this coordinate to the
  /// first way at the first position.
  final ILatLong? prependFirstWay;

  /// In order to combine the two ways we must append this coordinate to the
  /// first way
  final ILatLong? appendFirstWay;

  late final double gap;

  _Gap(this.first, this.second, this.firstWay, this.secondWay, this.prependFirstWay, this.appendFirstWay) {
    gap = LatLongUtils.euclideanDistanceSquared(first, second);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Gap && runtimeType == other.runtimeType && (first == other.first || first == other.second) && (second == other.second || second == other.first);

  @override
  int get hashCode => first.hashCode ^ second.hashCode;

  @override
  String toString() {
    return '_Gap{prependFirstWay: $prependFirstWay, first: $first, appendFirstWay: $appendFirstWay, second: $second, gap: $gap}';
  }
}
