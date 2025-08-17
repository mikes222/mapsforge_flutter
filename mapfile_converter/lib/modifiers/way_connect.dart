import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/special.dart';

/// Connects open ways together to form a longer way. Only master and openOuters will be taken into account.
class WayConnect {
  static final _log = new Logger('WayConnect');

  void connect(Wayholder wayholder) {
    if (wayholder.openOutersRead.length > 5000) {
      // calculate the spanning boundingbox
      BoundingBox boundingBox = wayholder.openOutersRead.first.boundingBox;
      wayholder.openOutersRead.skip(1).forEach((action) {
        boundingBox = boundingBox.extendBoundingBox(action.boundingBox);
      });

      // create 101*101 clusters to combine the ways inbetween a cluster before trying to combine the rest. This should speed up the process
      int clusterSplitCount = (wayholder.openOutersRead.length / 300).round();
      while (true) {
        int count = wayholder.openOutersRead.length;
        _connectClusterMulti(wayholder, boundingBox, clusterSplitCount);
        _log.info("Connecting cluster: from $count to ${wayholder.openOutersRead.length}, clusterSplit: $clusterSplitCount");
        clusterSplitCount = (clusterSplitCount * 0.3).round();
        if (clusterSplitCount <= 5) break;
        //print("After connect: ${wayholder.otherOuters.length}, clusterSplit: $clusterSplitCount");
      }
    }
    while (true) {
      int count = wayholder.openOutersRead.length;
      if (count <= 1) break;
      _ConnectCluster connectCluster = _ConnectCluster(wayholder, wayholder.openOutersWrite);
      connectCluster.connect(100);
      //_log.info("Connecting cluster: from $count to ${wayholder.openOutersRead.length}");
      if (count == wayholder.openOutersRead.length) break;
    }
  }

  /// splits the open ways into several clusters and connects them cluster by cluster
  void _connectClusterMulti(Wayholder wayholder, BoundingBox boundingBox, int clusterSplitCount) {
    double latDiff = boundingBox.maxLatitude - boundingBox.minLatitude;
    double lonDiff = boundingBox.maxLongitude - boundingBox.minLongitude;

    Map<String, _ConnectCluster> clusters = {};
    for (Waypath wayFirst in wayholder.openOutersRead) {
      double latKey = (wayFirst.boundingBox.maxLatitude - boundingBox.minLatitude) / (latDiff) * clusterSplitCount;
      double lonKey = (wayFirst.boundingBox.maxLongitude - boundingBox.minLongitude) / (lonDiff) * clusterSplitCount;
      String key = "${latKey.round()}_${lonKey.round()}";
      if (!clusters.containsKey(key)) {
        //print("Creating cluster $key $boundingBox, $latDiff / $lonDiff ${wayFirst.boundingBox}");
        clusters[key] = _ConnectCluster(wayholder, []);
      }
      clusters[key]!.waypaths.add(wayFirst);
    }
    clusters.forEach((key, value) {
      //if (value.waypaths.length > 2) print("  Cluster start $key ${value.waypaths.length}");
      value.connect(10);
    });
    clusters.clear();
  }
}

//////////////////////////////////////////////////////////////////////////////

class _ConnectCluster {
  final Wayholder wayholder;

  final List<Waypath> waypaths;

  _ConnectCluster(this.wayholder, this.waypaths);

  void connect(int maxIter) {
    // for (Waypath waySecond in List.from(waypaths)) {
    //   assert(!waySecond.isClosedWay());
    //   if (waySecond.isClosedWay()) {
    //     waypaths.remove(waySecond);
    //     wayholder.openOuters.remove(waySecond);
    //     wayholder.closedOuters.add(waySecond);
    //     continue;
    //   }
    // }
    int iter = 0;
    while (true) {
      int count = waypaths.length;
      // for (final pair in waypaths.combinations(2)) {
      //
      // }
      for (Waypath wayFirst in List.from(waypaths)) {
        // if already merged
        if (wayFirst.isEmpty) continue;
        if (wayFirst.isClosedWay()) {
          // it may be closed in the inner loop. Ignore it since it is already moved to closedOuters
          continue;
        }
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
          assert(!waySecond.isClosedWay());
          if (wayFirst.boundingBox.intersects(waySecond.boundingBox)) {
            _connect(wayFirst, waySecond);
            // do not further process way first if it is closed
            if (wayFirst.isClosedWay()) break;
          }
        }
      }
      ++iter;
      //if (count > 30) print("remaining: from $count to ${waypaths.length} $iter");
      if (count == waypaths.length) break;
      if (iter == maxIter) break;
    }
    //print("step 3 ${wayholder} $iter");
  }

  void _connect(Waypath wayFirst, Waypath waySecond) {
    bool ok = LatLongUtils.combine(wayFirst, waySecond.path);
    if (ok) {
      wayholder.openOutersRemove(waySecond);
      waypaths.remove(waySecond);
      // save memory and inform the class that it is no longer needed
      waySecond.clear();
      bool ok = wayholder.mayMoveToClosed(wayFirst);
      if (ok) {
        waypaths.remove(wayFirst);
      }
    }
  }
}
