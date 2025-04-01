import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/way_simplify_filter.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/wayholder.dart';
import 'package:mapsforge_flutter/src/model/zoomlevel_range.dart';

import '../../../maps.dart';
import '../../utils/flutter_isolate.dart';

@pragma("vm:entry-point")
class IsolateSubfileFiller {
  IsolateSubfileFiller();

  Future<List<Wayholder>> prepareWays(
      ZoomlevelRange subfileZoomlevelRange, BoundingBox subfileBoundingBox, ZoomlevelRange zoomlevelRange, List<Wayholder> wayholders, int tilePixelSize,
      [double maxDeviation = 10]) async {
    return await FlutterIsolateInstance.isolateCompute(
        prepareWaysStatic,
        _SubfileFillerRequest(
            subfileZoomlevelRange: subfileZoomlevelRange,
            subfileBoundingBox: subfileBoundingBox,
            zoomlevelRange: zoomlevelRange,
            wayholders: wayholders,
            tilePixelSize: tilePixelSize,
            maxDeviation: maxDeviation));
  }

  @pragma('vm:entry-point')
  static Future<List<Wayholder>> prepareWaysStatic(_SubfileFillerRequest request) async {
    DisplayModel(tilesize: request.tilePixelSize);
    SubfileFiller subfileFiller = SubfileFiller(request.subfileZoomlevelRange, request.subfileBoundingBox, request.maxDeviation);
    return subfileFiller.prepareWays(request.zoomlevelRange, request.wayholders);
  }
}

//////////////////////////////////////////////////////////////////////////////

class _SubfileFillerRequest {
  final ZoomlevelRange subfileZoomlevelRange;

  final BoundingBox subfileBoundingBox;

  final ZoomlevelRange zoomlevelRange;

  final List<Wayholder> wayholders;

  final int tilePixelSize;

  final double maxDeviation;

  _SubfileFillerRequest(
      {required this.subfileZoomlevelRange,
      required this.subfileBoundingBox,
      required this.zoomlevelRange,
      required this.wayholders,
      required this.tilePixelSize,
      required this.maxDeviation});
}

//////////////////////////////////////////////////////////////////////////////

class SubfileFiller {
  late _SizeFilter sizeFilter;

  late WaySimplifyFilter simplifyFilter;

  final ZoomlevelRange subfileZoomlevelRange;

  final double maxDeviation;

  SubfileFiller(this.subfileZoomlevelRange, BoundingBox subfileBoundingBox, this.maxDeviation) {
    sizeFilter = _SizeFilter(subfileZoomlevelRange.zoomlevelMax, maxDeviation, subfileBoundingBox);
    simplifyFilter = WaySimplifyFilter(subfileZoomlevelRange.zoomlevelMax, maxDeviation, subfileBoundingBox);
  }

  List<Wayholder> prepareWays(
    ZoomlevelRange zoomlevelRange,
    List<Wayholder> wayholders,
  ) {
    if (subfileZoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) return [];
    if (subfileZoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) return [];
    if (maxDeviation > 0) {
      wayholders.removeWhere((test) => sizeFilter.shouldFilter(test));
      wayholders = wayholders.map((test) => simplifyFilter.reduce(test)).toList();
    }
    return wayholders;
  }
}

//////////////////////////////////////////////////////////////////////////////

/// Filter ways by size. If the way would be too small in max zoom of the desired
/// subfile (hence maxZoomlevel) we do not want to include it at all.
class _SizeFilter {
  final PixelProjection projection;

  final double filterSizePixels;

  late final double maxDeviationLatLong;

  _SizeFilter(int zoomlevel, this.filterSizePixels, BoundingBox boundingBox) : projection = PixelProjection(zoomlevel) {
    maxDeviationLatLong = projection.latitudeDiffPerPixel((boundingBox.minLatitude + boundingBox.maxLatitude) / 2, filterSizePixels);
  }

  bool shouldFilter(Wayholder wayHolder) {
    BoundingBox boundingBox = wayHolder.way.getBoundingBox();
    if ((boundingBox.maxLatitude - boundingBox.minLatitude).abs() > maxDeviationLatLong) return false;
    if ((boundingBox.maxLongitude - boundingBox.minLongitude).abs() > maxDeviationLatLong) return false;

    for (Waypath latLongs in wayHolder.otherOuters) {
      BoundingBox boundingBox = latLongs.boundingBox;
      if ((boundingBox.maxLatitude - boundingBox.minLatitude).abs() > maxDeviationLatLong) return false;
      if ((boundingBox.maxLongitude - boundingBox.minLongitude).abs() > maxDeviationLatLong) return false;
    }
    return true;
  }
}
