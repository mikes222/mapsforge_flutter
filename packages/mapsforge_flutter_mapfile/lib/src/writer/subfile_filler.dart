import 'dart:isolate';

import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/filter/way_simplify_filter.dart';
import 'package:mapsforge_flutter_mapfile/src/filter/way_size_filter.dart';

/// An isolate-based wrapper for [SubfileFiller] to perform way preparation
/// in the background.
@pragma("vm:entry-point")
class IsolateSubfileFiller {
  Future<List<Wayholder>> prepareWays(
    ZoomlevelRange subfileZoomlevelRange,
    ZoomlevelRange zoomlevelRange,
    List<Wayholder> wayholders,
    int tilePixelSize, [
    double maxDeviation = 10,
  ]) async {
    return await Isolate.run(() {
      SubfileFiller subfileFiller = SubfileFiller(subfileZoomlevelRange, maxDeviation);
      return subfileFiller.prepareWays(zoomlevelRange, wayholders);
    });
  }
}

//////////////////////////////////////////////////////////////////////////////

/// A class that prepares way data before it is added to a sub-file.
///
/// This involves two main steps:
/// 1. Filtering: Removing ways that are too small to be visually significant at
///    the target zoom level.
/// 2. Simplification: Reducing the number of vertices in the remaining ways to
///    optimize storage and rendering performance.
class SubfileFiller {
  late WaySizeFilter sizeFilter;

  late WaySimplifyFilter simplifyFilter;

  final ZoomlevelRange subfileZoomlevelRange;

  final double maxDeviation;

  SubfileFiller(this.subfileZoomlevelRange, this.maxDeviation) {
    sizeFilter = WaySizeFilter(subfileZoomlevelRange.zoomlevelMax, maxDeviation);
    simplifyFilter = WaySimplifyFilter(subfileZoomlevelRange.zoomlevelMax, maxDeviation);
  }

    /// Prepares a list of ways by filtering and simplifying them.
  List<Wayholder> prepareWays(ZoomlevelRange zoomlevelRange, List<Wayholder> wayholders) {
    if (subfileZoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) return [];
    if (subfileZoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) return [];
    if (maxDeviation <= 0) {
      // we do not want to filter anything, return the original
      return wayholders;
    }
    List<Wayholder> result = [];
    for (Wayholder wayholder in wayholders) {
      Wayholder? res = sizeFilter.filter(wayholder);
      if (res != null) {
        // size is big enough, now simplify the way
        res = simplifyFilter.reduce(res);
        // if the object was so tiny that we can simplify it away, do not store it
        if (res.closedOutersRead.isNotEmpty || res.openOutersRead.isNotEmpty) result.add(res);
      }
    }
    return result;
  }
}
