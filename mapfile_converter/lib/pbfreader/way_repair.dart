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

  void repairClosed(Wayholder wayholder) {
    /*double maxGap =*/
    _repair(wayholder);
    if (!LatLongUtils.isClosedWay(wayholder.way.latLongs[0])) {
      if (LatLongUtils.euclideanDistance(wayholder.way.latLongs[0].first, wayholder.way.latLongs[0].last) <= maxGapMeter) {
        wayholder.way.latLongs[0].add(wayholder.way.latLongs[0].first);
      }
    }
    for (var waypath in wayholder.otherOuters) {
      if (!waypath.isClosedWay()) {
        if (LatLongUtils.euclideanDistance(waypath.first, waypath.last) <= maxGapMeter) {
          waypath.add(waypath.first);
        }
      }
    }
    // print("Could not close $wayholder, because it exceeds the max gap");
  }

  void connect(Wayholder wayholder) {
    if (wayholder.otherOuters.length > 5000) {
      // calculate the spanning boundingbox
      BoundingBox boundingBox = BoundingBox.fromLatLongs(wayholder.way.latLongs[0]);
      for (Waypath wayFirst in wayholder.otherOuters) {
        boundingBox = boundingBox.extendBoundingBox(wayFirst.boundingBox);
      }
      // create 101*101 clusters to combine the ways inbetween a cluster before trying to combine the rest. This should speed up the process
      int clusterSplitCount = 100;
      while (true) {
        int count = wayholder.otherOuters.length;
        _connectCluster(wayholder, boundingBox, clusterSplitCount);
        if (count == wayholder.otherOuters.length && clusterSplitCount < 10) break;
        clusterSplitCount -= 7;
        if (clusterSplitCount <= 1) break;
        //print("After connect: ${wayholder.otherOuters.length}, clusterSplit: $clusterSplitCount");
      }
    }
    while (true) {
      int count = wayholder.otherOuters.length;
      _ConnectCluster connectCluster = _ConnectCluster(wayholder, Waypath(wayholder.way.latLongs[0]), wayholder.otherOuters);
      connectCluster.connect();
      if (count == wayholder.otherOuters.length) break;
    }
  }

  void _connectCluster(Wayholder wayholder, BoundingBox boundingBox, int clusterSplitCount) {
    double latDiff = boundingBox.maxLatitude - boundingBox.minLatitude;
    double lonDiff = boundingBox.maxLongitude - boundingBox.minLongitude;

    Map<String, _ConnectCluster> clusters = {};
    for (Waypath wayFirst in wayholder.otherOuters) {
      double latKey = (wayFirst.boundingBox.maxLatitude - boundingBox.minLatitude) / (latDiff) * clusterSplitCount;
      double lonKey = (wayFirst.boundingBox.maxLongitude - boundingBox.minLongitude) / (lonDiff) * clusterSplitCount;
      String key = "${latKey.round()}_${lonKey.round()}";
      if (!clusters.containsKey(key)) {
        //print("Creating cluster $key $boundingBox, ${wayFirst.boundingBox}");
        clusters[key] = _ConnectCluster(wayholder, Waypath(wayholder.way.latLongs[0]), []);
      }
      clusters[key]!.waypaths.add(wayFirst);
    }
    clusters.forEach((key, value) {
      //print("Cluster start $key");
      value.connect();
    });
    clusters.clear();
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
    Waypath wayFirst = Waypath(wayholder.way.latLongs[0]);
    if (!wayFirst.isClosedWay()) {
      for (Waypath waySecond in wayholder.otherOuters) {
        if (waySecond.isClosedWay()) continue;
        _addGaps(wayFirst, waySecond, gaps);
      }
    }
    for (Waypath wayFirst in wayholder.otherOuters) {
      if (wayFirst.isClosedWay()) continue;
      for (Waypath waySecond in wayholder.otherOuters) {
        if (wayFirst == waySecond) continue;
        if (waySecond.isClosedWay()) continue;
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
    bool ok = LatLongUtils.combine(smallest.firstWay.pathForModification, smallest.secondWay.path);
    if (ok) {
      wayholder.otherOuters.remove(smallest.secondWay);
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

//////////////////////////////////////////////////////////////////////////////

class _ConnectCluster {
  final Wayholder wayholder;

  final Waypath masterWaypath;

  final List<Waypath> waypaths;

  _ConnectCluster(this.wayholder, this.masterWaypath, this.waypaths);

  void connect() {
    Waypath wayFirst = masterWaypath;
    if (!wayFirst.isClosedWay()) {
      for (Waypath waySecond in List.from(waypaths)) {
        if (waySecond.isClosedWay()) continue;
        _connect(wayFirst, waySecond);
      }
    }
    for (Waypath wayFirst in List.from(waypaths)) {
      // if already merged
      if (wayFirst.isEmpty) continue;
      if (wayFirst.isClosedWay()) continue;
      bool start = false;
      for (Waypath waySecond in List.from(waypaths)) {
        if (wayFirst == waySecond) {
          start = true;
          continue;
        }
        if (!start) {
          continue;
        }
        if (waySecond.isEmpty) continue;
        if (waySecond.isClosedWay()) continue;
        if (wayFirst.boundingBox.intersects(waySecond.boundingBox)) {
          _connect(wayFirst, waySecond);
        }
      }
      //print("remaining: ${waypaths.length}");
    }
  }

  void _connect(Waypath wayFirst, Waypath waySecond) {
    bool ok = LatLongUtils.combine(wayFirst.pathForModification, waySecond.path);
    if (ok) {
      wayholder.otherOuters.remove(waySecond);
      waypaths.remove(waySecond);
      // save memory and inform the class that it is no longer needed
      waySecond.clear();
    }
  }
}
