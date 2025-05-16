import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/special.dart';

/// tries to fix open ways from relationships (PBF) by connecting missing ends.
class WayRepair {
  /// Max gap in meter allowed to connect ways.
  final double maxGapMeter;

  WayRepair(this.maxGapMeter);

  void repairOpen(Wayholder wayholder) {
    _repair(wayholder);
  }

  void repairClosed(Wayholder wayholder, BoundingBox? boundingBox) {
    _repair(wayholder);
    for (Waypath waypath in List.from(wayholder.openOutersRead)) {
      if (Projection.distance(waypath.first, waypath.last) <= maxGapMeter) {
        waypath.add(waypath.first);
        wayholder.mayMoveToClosed(waypath);
      } else {
        // maybe both ends are at the boundary, we should connect anyway then.
        if (boundingBox != null) {
          bool ok = _repairAtBoundary(boundingBox, boundingBox.getRightUpper(), boundingBox.getRightLower(), wayholder, waypath);
          if (!ok) ok = _repairAtBoundary(boundingBox, boundingBox.getRightLower(), boundingBox.getLeftLower(), wayholder, waypath);
          if (!ok) ok = _repairAtBoundary(boundingBox, boundingBox.getLeftLower(), boundingBox.getLeftUpper(), wayholder, waypath);
          if (!ok) ok = _repairAtBoundary(boundingBox, boundingBox.getLeftUpper(), boundingBox.getRightUpper(), wayholder, waypath);
        }
      }
    }
    // if (wayholder.hasTagValue("name", "Balaton")) {
    //   print("repairClosed: Balaton ${wayholder.toStringWithoutNames()}");
    //   if (open != null) {
    //     print("  first: ${open.first}, last: ${open.last}, closed: ${open.isClosedWay()}, gap: ${Projection.distance(open.first, open.last)}");
    //   }
    // }
  }

  bool _repairAtBoundary(BoundingBox boundingBox, ILatLong first, ILatLong second, Wayholder wayholder, Waypath waypath) {
    ILatLong nearestPoint = LatLongUtils.nearestSegmentPoint(
      first.longitude,
      first.latitude,
      second.longitude,
      second.latitude,
      waypath.first.longitude,
      waypath.first.latitude,
    );
    if (Projection.distance(nearestPoint, waypath.first) > maxGapMeter) return false;
    nearestPoint = LatLongUtils.nearestSegmentPoint(
      first.longitude,
      first.latitude,
      second.longitude,
      second.latitude,
      waypath.last.longitude,
      waypath.last.latitude,
    );
    if (Projection.distance(nearestPoint, waypath.last) > maxGapMeter) return false;
    // both are near the right border, connect them
    waypath.add(waypath.first);
    wayholder.mayMoveToClosed(waypath);
    return true;
  }

  double _repair(Wayholder wayholder) {
    // calculate the bounding box over all possible affected ways
    // BoundingBox boundingBox = BoundingBox.fromLatLongs(wayholder.way.latLongs[0]);
    // for (Waypath wayFirst in wayholder.otherOuters) {
    //   boundingBox = boundingBox.extendBoundingBox(wayFirst.boundingBox);
    // }
    //    double maxGap = LatLongUtils.euclideanDistanceSquared(boundingBox.getLeftUpper(), boundingBox.getRightLower());
    // do not accept gaps more than 5% of the overall size
    //    maxGap *= 0.05;
    double maxGap = 0;

    while (true) {
      Set<_Gap> gaps = _findGaps(wayholder);
      int count = gaps.length;
      while (gaps.isNotEmpty) {
        _Gap smallest = gaps.reduce((first, second) => first.gapSquared < second.gapSquared ? first : second);
        if (smallest.gapSquared > maxGap) {
          double distance = Projection.distance(smallest.first, smallest.second);
          if (distance < maxGapMeter) {
            // allow a minimum distance of 200 m
            maxGap = smallest.gapSquared * 1.05;
          }
          if (smallest.gapSquared > maxGap) {
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
    for (Waypath wayFirst in wayholder.openOutersWrite) {
      bool start = false;
      for (Waypath waySecond in wayholder.openOutersWrite) {
        if (wayFirst == waySecond) {
          start = true;
          continue;
        }
        if (!start) continue;
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
    bool ok = LatLongUtils.combine(smallest.firstWay, smallest.secondWay.path);
    if (ok) {
      wayholder.openOutersRemove(smallest.secondWay);
      if (smallest.firstWay.isClosedWay()) {
        wayholder.openOutersRemove(smallest.firstWay);
        wayholder.closedOutersAdd(smallest.firstWay);
      }
      gaps.remove(smallest);
      gaps.removeWhere((test) => test.secondWay == smallest.firstWay);
      gaps.removeWhere((test) => test.firstWay == smallest.firstWay);
      gaps.removeWhere((test) => test.secondWay == smallest.secondWay);
      gaps.removeWhere((test) => test.firstWay == smallest.secondWay);
      // save memory and inform the class that it is no longer needed
      smallest.secondWay.clear();
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

  void _addGaps(Waypath wayFirst, Waypath waySecond, Set<_Gap> gaps) {
    // make sure there is a gap between the two ways
    assert(
      wayFirst.first != waySecond.first,
      "First: ${wayFirst.first} (${wayFirst.length}), Second: ${waySecond.first} (${waySecond.length}), first is closed: ${wayFirst.isClosedWay()}, second is closed: ${waySecond.isClosedWay()}",
    );
    assert(wayFirst.first != waySecond.last, "First: ${wayFirst.first} (${wayFirst.length}), Second: ${waySecond.last}  (${waySecond.length})");
    assert(wayFirst.last != waySecond.first);
    assert(wayFirst.last != waySecond.last);
    assert(!wayFirst.isClosedWay(), "WayFecond should not be closed $wayFirst");
    assert(!waySecond.isClosedWay(), "WaySecond should not be closed $waySecond");
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

  final Waypath firstWay;

  final Waypath secondWay;

  /// In order to combine the two ways we must insert this coordinate to the
  /// first way at the first position.
  final ILatLong? prependFirstWay;

  /// In order to combine the two ways we must append this coordinate to the
  /// first way
  final ILatLong? appendFirstWay;

  late final double gapSquared;

  _Gap(this.first, this.second, this.firstWay, this.secondWay, this.prependFirstWay, this.appendFirstWay) {
    gapSquared = LatLongUtils.euclideanDistanceSquared(first, second);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Gap && runtimeType == other.runtimeType && (first == other.first || first == other.second) && (second == other.second || second == other.first);

  @override
  int get hashCode => first.hashCode ^ second.hashCode;

  @override
  String toString() {
    return '_Gap{prependFirstWay: $prependFirstWay, first: $first, appendFirstWay: $appendFirstWay, second: $second, gap: $gapSquared}';
  }
}
