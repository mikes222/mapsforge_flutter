import 'package:collection/collection.dart';

import '../../../datastore.dart';

class ZoomlevelCreator {
  final int zoomlevel;

  final ZoomlevelCreator? parent;

  List<PointOfInterest> poiholders = [];

  int poiCount = 0;

  List<Way> wayholders = [];

  int wayCount = 0;

  int potentialGrandWayCount = 0;

  ZoomlevelCreator({required this.zoomlevel, this.parent}) {}

  PointOfInterest? searchPoiRecursive(PointOfInterest poi) {
    PointOfInterest? poiholder =
        poiholders.firstWhereOrNull((value) => value == poi);
    if (poiholder != null) return poiholder;
    return parent?.searchPoiRecursive(poi);
  }

  void addPoidata(List<PointOfInterest> pois) {
    for (PointOfInterest poi in pois) {
      PointOfInterest? parentPoi = parent?.searchPoiRecursive(poi);
      // make sure we are working with the same instance to save memory
      if (parentPoi != null) poi = parentPoi;
      poiholders.add(poi);
      ++poiCount;
    }
  }

  Way? searchWay(Way way) {
    Way? wayholder = wayholders.firstWhereOrNull((value) => value == way);
    if (wayholder != null) return wayholder;
    return null;
  }

  Way? searchWayRecursive(Way way) {
    Way? wayholder = wayholders.firstWhereOrNull((value) => value == way);
    if (wayholder != null) return wayholder;
    return parent?.searchWayRecursive(way);
  }

  void addWaydata(List<Way> ways) {
    for (Way way in ways) {
      Way? parentWay = parent?.searchWayRecursive(way);
      // make sure we are working with the same instance to save memory
      if (parentWay != null) way = parentWay;
      if (parent?.parent?.searchWay(way) != null) {
        ++potentialGrandWayCount;
      }
      wayholders.add(way);
      ++wayCount;
    }
  }

  @override
  String toString() {
    return 'ZoomlevelCreator{zoomlevel: $zoomlevel, poiCount: $poiCount, wayCount: $wayCount, potentialGrandWayCount: $potentialGrandWayCount}';
  }
}

//////////////////////////////////////////////////////////////////////////////

class SubfileSimulator {
  final bool debugFile = false;

  final int baseZoomlevel;

  /// Minimum zoom level for which the block entries tables are made.
  final int zoomLevelMin;

  /// Maximum zoom level for which the block entries tables are made.
  final int zoomLevelMax;

  final Map<int, SubfileZoomSimulator> zoomSimulators = {};

  SubfileSimulator(
      {required this.baseZoomlevel,
      required this.zoomLevelMin,
      required this.zoomLevelMax}) {
    for (int zoomlevel = zoomLevelMin; zoomlevel <= zoomLevelMax; ++zoomlevel) {
      zoomSimulators[zoomlevel] =
          SubfileZoomSimulator(zoomSimulators[zoomlevel - 1]);
    }
  }

  void addPoidata(int zoomlevel, List<PointOfInterest> pois) {
    zoomSimulators[zoomlevel]!.addPoidata(pois);
  }

  void addWaydata(int zoomlevel, List<Way> ways) {
    zoomSimulators[zoomlevel]!.addWaydata(ways);
  }

  void finalize() {
    for (int zoomlevel = zoomLevelMin;
        zoomlevel <= zoomLevelMax - 2;
        ++zoomlevel) {
      List<Way> wayholders = zoomSimulators[zoomlevel]!.wayholders;
      List<Way> wayholdersGrandchildren =
          zoomSimulators[zoomlevel + 2]!.wayholders;
      for (Way wayholder in wayholders) {
        Way? grandchild = wayholdersGrandchildren
            .firstWhereOrNull((test) => test == wayholder);
        if (grandchild == null) {
          // The way is not relevant in the grandchild zoomlevel
          zoomSimulators[zoomlevel + 2]!.irrelevantWays++;
        }
      }
    }
  }

  @override
  String toString() {
    int pois = 0;
    int ways = 0;
    String result =
        'SubfileSimulator{baseZoomlevel: $baseZoomlevel, zoomLevelMin: $zoomLevelMin, zoomLevelMax: $zoomLevelMax\n';
    zoomSimulators.forEach((zoomlevel, zoomSimulator) {
      pois += zoomSimulator.poiCount;
      ways += zoomSimulator.wayCount;
      if (zoomlevel == baseZoomlevel) ways -= zoomSimulator.irrelevantWays;

      result += '  $zoomlevel: $zoomSimulator';
      result += ", reading $pois pois and $ways ways for this zoomlevel\n";
    });
    result += 'pois: $pois, ways: $ways}';
    return result;
  }
}

//////////////////////////////////////////////////////////////////////////////

class SubfileZoomSimulator {
  List<PointOfInterest> poiholders = [];

  List<Way> wayholders = [];

  int poiCount = 0;

  int wayCount = 0;

  int irrelevantWays = 0;

  final SubfileZoomSimulator? parent;

  SubfileZoomSimulator(this.parent);

  PointOfInterest? searchPoiRecursive(PointOfInterest poi) {
    PointOfInterest? poiholder =
        poiholders.firstWhereOrNull((value) => value == poi);
    if (poiholder != null) return poiholder;
    return parent?.searchPoiRecursive(poi);
  }

  void addPoidata(List<PointOfInterest> pois) {
    for (PointOfInterest poi in pois) {
      PointOfInterest? parentPoi = parent?.searchPoiRecursive(poi);
      if (parentPoi != null) {
        // it is already in this subfile
        continue;
      }
      poiholders.add(poi);
      ++poiCount;
    }
  }

  Way? searchWay(Way way) {
    Way? wayholder = wayholders.firstWhereOrNull((value) => value == way);
    if (wayholder != null) return wayholder;
    return null;
  }

  Way? searchWayRecursive(Way way) {
    Way? wayholder = wayholders.firstWhereOrNull((value) => value == way);
    if (wayholder != null) return wayholder;
    return parent?.searchWayRecursive(way);
  }

  void addWaydata(List<Way> ways) {
    for (Way way in ways) {
      Way? parentWay = parent?.searchWayRecursive(way);
      if (parentWay != null) {
        // it is already in this subfile
        // if (parent?.parent?.searchWay(way) != null) {
        // }
        continue;
      } else {}
      wayholders.add(way);
      ++wayCount;
    }
  }

  @override
  String toString() {
    return 'ZoomSimulator{poiCount: $poiCount, wayCount: $wayCount, irrelevantWays: $irrelevantWays}';
  }
}
