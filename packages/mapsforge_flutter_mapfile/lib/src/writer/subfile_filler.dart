import 'dart:isolate';

import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/filter.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

/// An isolate-based wrapper for [SubfileFiller] to perform way preparation
/// in the background.
@pragma("vm:entry-point")
class IsolateSubfileFiller {
  Future<List<Wayholder>> prepareWays(
    ZoomlevelRange subfileZoomlevelRange,
    ZoomlevelRange zoomlevelRange,
    List<Wayholder> wayholders,
    BoundingBox boundingBox,
    int tilePixelSize, [
    double maxDeviation = 10,
  ]) async {
    return await Isolate.run(() {
      SubfileFiller subfileFiller = SubfileFiller(subfileZoomlevelRange, maxDeviation, boundingBox);
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

  late WayCropper wayCropper;

  final ZoomlevelRange subfileZoomlevelRange;

  final BoundingBox boundingBox;

  final double maxDeviation;

  SubfileFiller(this.subfileZoomlevelRange, this.maxDeviation, this.boundingBox) {
    sizeFilter = WaySizeFilter(subfileZoomlevelRange.zoomlevelMax, maxDeviation);
    simplifyFilter = WaySimplifyFilter(subfileZoomlevelRange.zoomlevelMax, maxDeviation);
    wayCropper = const WayCropper(maxDeviationPixel: 5);
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
      if (res == null) continue;
      // size is big enough, now simplify the way
      res = simplifyFilter.reduce(res);
      // if the object was so tiny that we can simplify it away, do not store it
      if (res.closedOutersRead.isEmpty && res.innerRead.isEmpty && res.openOutersRead.isEmpty) continue;
      // crop everything outside of the mapfile's bounding box
      res = wayCropper.cropOutsideWay(res, boundingBox);
      if (res == null) continue;

      result.add(res);
    }
    return result;
  }
}
