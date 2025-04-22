import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/special.dart';

/// Splits wayholders with many closedOuters into smaller wayholders. Clusters the new wayholders geographically.
class LargeDataSplitter {
  static final _log = Logger('LargeDataSplitter');

  void split(List<Wayholder> wayHoldersMerged, Wayholder wayholder) {
    if (wayholder.closedOutersRead.length > 1000) {
      // calculate the spanning boundingbox
      BoundingBox boundingBox = wayholder.closedOutersRead.first.boundingBox;
      wayholder.closedOutersRead.skip(1).forEach((action) {
        boundingBox = boundingBox.extendBoundingBox(action.boundingBox);
      });

      // create 101*101 clusters to combine the ways inbetween a cluster before trying to combine the rest. This should speed up the process
      int clusterSplitCount = (wayholder.closedOutersRead.length / 50).round();
      while (true) {
        int count = wayholder.closedOutersRead.length;
        _connectClusterMulti(wayHoldersMerged, wayholder, wayholder.boundingBoxCached, clusterSplitCount);
        _log.info("Splitting cluster from $count to ${wayholder.closedOutersRead.length} closed outer ways, clusterSplitCount: $clusterSplitCount");
        if (wayholder.closedOutersRead.length < 500000) {
          clusterSplitCount = (clusterSplitCount * 0.6).round();
        } else {
          clusterSplitCount = (clusterSplitCount * 0.8).round();
        }
        if (clusterSplitCount <= 5) break;
        //print("After connect: ${wayholder.otherOuters.length}, clusterSplit: $clusterSplitCount");
      }
    }
    int count = wayholder.closedOutersRead.length;
    if (count > 150) {
      _connectClusterMulti(wayHoldersMerged, wayholder, wayholder.boundingBoxCached, 1);
      _log.info("Splitting cluster from $count to ${wayholder.closedOutersRead.length} closed outer ways");
      if (wayholder.closedOutersRead.isNotEmpty) wayHoldersMerged.add(wayholder);
    }
  }

  /// splits the open ways into several clusters and connects them cluster by cluster
  void _connectClusterMulti(List<Wayholder> _wayHoldersMerged, Wayholder wayholder, BoundingBox boundingBox, int clusterSplitCount) {
    double latDiff = boundingBox.maxLatitude - boundingBox.minLatitude;
    double lonDiff = boundingBox.maxLongitude - boundingBox.minLongitude;

    Map<String, _Cluster> clusters = {};
    for (Waypath wayFirst in wayholder.closedOutersRead) {
      double latKey = (wayFirst.boundingBox.maxLatitude - boundingBox.minLatitude) / (latDiff) * clusterSplitCount;
      double lonKey = (wayFirst.boundingBox.maxLongitude - boundingBox.minLongitude) / (lonDiff) * clusterSplitCount;
      String key = "${latKey.round()}_${lonKey.round()}";
      if (!clusters.containsKey(key)) {
        //print("Creating cluster $key $boundingBox, $latDiff / $lonDiff ${wayFirst.boundingBox}");
        clusters[key] = _Cluster();
      }
      clusters[key]!.waypaths.add(wayFirst);
    }
    clusters.forEach((key, cluster) {
      int count = cluster.waypaths.length;
      cluster.split(_wayHoldersMerged, wayholder);
      //print("reduced from $count to ${cluster.waypaths.length} ${_wayHoldersMerged.length}");
    });
    clusters.clear();
  }

  void splitSimple(List<Wayholder> _wayHoldersMerged, Wayholder mergedWayholder) {
    // todo cluster the ways geographically so that we quickly can rule out ways which do not belong to a geographical area
    while (mergedWayholder.closedOutersRead.length > 300) {
      // too many ways, split it.
      List<Waypath> closedOuters = mergedWayholder.closedOutersRead.take(200).toList();
      mergedWayholder.closedOutersWrite.removeRange(0, 200);
      Wayholder newWayholder = mergedWayholder.cloneWith(inner: [], openOuters: [], closedOuters: closedOuters);
      _wayHoldersMerged.add(newWayholder);
    }
    //_log.info("Remaining coastline ${mergedWayholder.toStringWithoutNames()}");
    _wayHoldersMerged.add(mergedWayholder);
  }
}

//////////////////////////////////////////////////////////////////////////////

class _Cluster {
  final int maxClusterSize = 100;

  final List<Waypath> waypaths = [];

  void split(List<Wayholder> _wayHoldersMerged, Wayholder wayholder) {
    // too less items to connect, ignore it in this iteration
    while (waypaths.length >= maxClusterSize) {
      if (waypaths.length < maxClusterSize * 1.5) {
        // take all items
        for (var action in waypaths) {
          wayholder.closedOutersRemove(action);
        }
        Wayholder newWayholder = wayholder.cloneWith(inner: [], openOuters: [], closedOuters: waypaths);
        _wayHoldersMerged.add(newWayholder);
        return;
      }
      Waypath wayFirst = waypaths.first;
      waypaths.remove(wayFirst);
      ILatLong leftUpper = wayFirst.boundingBox.getLeftUpper();
      List<Waypath> ways = [wayFirst];

      Map<double, Waypath> distances = {};
      int idx = 0;
      for (Waypath waySecond in waypaths) {
        double dist = LatLongUtils.euclideanDistanceSquared(leftUpper, waySecond.boundingBox.getLeftUpper());
        distances[dist] = waySecond;
        ++idx;

        /// for performance reasons stop after we have measured a good number of items.
        if (idx > maxClusterSize * 3) break;
      }
      final sorted = distances.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
      sorted.take(maxClusterSize - 1).forEach((mapEntry) {
        wayholder.closedOutersRemove(mapEntry.value);
        waypaths.remove(mapEntry.value);
        ways.add(mapEntry.value);
      });
      assert(ways.length == maxClusterSize);
      Wayholder newWayholder = wayholder.cloneWith(inner: [], openOuters: [], closedOuters: ways);
      _wayHoldersMerged.add(newWayholder);
    }
  }
}
