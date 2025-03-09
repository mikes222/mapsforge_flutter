import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/wayholder.dart';
import 'package:mapsforge_flutter/src/model/zoomlevel_range.dart';

import '../../../datastore.dart';
import '../../../maps.dart';
import '../../utils/douglas_peucker_latlong.dart';
import '../../utils/flutter_isolate.dart';

@pragma("vm:entry-point")
class IsolateSubfileFiller {
  IsolateSubfileFiller();

  Future<List<Wayholder>> prepareWays(
      ZoomlevelRange subfileZoomlevelRange,
      BoundingBox subfileBoundingBox,
      ZoomlevelRange zoomlevelRange,
      List<Wayholder> wayholders,
      int tilePixelSize) async {
    return await FlutterIsolateInstance.isolateCompute(
        prepareWaysStatic,
        _SubfileFillerRequest(
            subfileZoomlevelRange: subfileZoomlevelRange,
            subfileBoundingBox: subfileBoundingBox,
            zoomlevelRange: zoomlevelRange,
            wayholders: wayholders,
            tilePixelSize: tilePixelSize));
  }

  @pragma('vm:entry-point')
  static Future<List<Wayholder>> prepareWaysStatic(
      _SubfileFillerRequest request) async {
    DisplayModel(tilesize: request.tilePixelSize);
    SubfileFiller subfileFiller = SubfileFiller(
        request.subfileZoomlevelRange, request.subfileBoundingBox);
    return subfileFiller.prepareWays(request.subfileZoomlevelRange,
        request.zoomlevelRange, request.wayholders);
  }
}

//////////////////////////////////////////////////////////////////////////////

class _SubfileFillerRequest {
  final ZoomlevelRange subfileZoomlevelRange;

  final BoundingBox subfileBoundingBox;

  final ZoomlevelRange zoomlevelRange;

  final List<Wayholder> wayholders;

  final int tilePixelSize;

  _SubfileFillerRequest(
      {required this.subfileZoomlevelRange,
      required this.subfileBoundingBox,
      required this.zoomlevelRange,
      required this.wayholders,
      required this.tilePixelSize});
}

//////////////////////////////////////////////////////////////////////////////

class SubfileFiller {
  late _SizeFilter sizeFilter;

  late _SimplifyFilter simplifyFilter;

  SubfileFiller(
      ZoomlevelRange subfileZoomlevelRange, BoundingBox subfileBoundingBox) {
    sizeFilter =
        _SizeFilter(subfileZoomlevelRange.zoomlevelMax, 10, subfileBoundingBox);
    simplifyFilter = _SimplifyFilter(
        subfileZoomlevelRange.zoomlevelMax, 5, subfileBoundingBox);
  }

  List<Wayholder> prepareWays(
    ZoomlevelRange subfileZoomlevelRange,
    ZoomlevelRange zoomlevelRange,
    List<Wayholder> wayholders,
  ) {
    if (subfileZoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax)
      return [];
    if (subfileZoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin)
      return [];
    wayholders.removeWhere((test) => sizeFilter.shouldFilter(test));
    wayholders = wayholders.map((test) => simplifyFilter.reduce(test)).toList();
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

  _SizeFilter(int zoomlevel, this.filterSizePixels, BoundingBox boundingBox)
      : projection = PixelProjection(zoomlevel) {
    maxDeviationLatLong = projection.latitudeDiffPerPixel(
        (boundingBox.minLatitude + boundingBox.maxLatitude) / 2,
        filterSizePixels);
  }

  bool shouldFilter(Wayholder wayHolder) {
    BoundingBox boundingBox = wayHolder.way.getBoundingBox();
    if ((boundingBox.maxLatitude - boundingBox.minLatitude).abs() >
        maxDeviationLatLong) return false;
    if ((boundingBox.maxLongitude - boundingBox.minLongitude).abs() >
        maxDeviationLatLong) return false;

    for (List<ILatLong> latLongs in wayHolder.otherOuters) {
      BoundingBox boundingBox = BoundingBox.fromLatLongs(latLongs);
      if ((boundingBox.maxLatitude - boundingBox.minLatitude).abs() >
          maxDeviationLatLong) return false;
      if ((boundingBox.maxLongitude - boundingBox.minLongitude).abs() >
          maxDeviationLatLong) return false;
    }
    return true;
  }
}

//////////////////////////////////////////////////////////////////////////////

class _SimplifyFilter {
  final DouglasPeuckerLatLong dpl = DouglasPeuckerLatLong();

  final PixelProjection projection;

  final double maxDeviationPixel;

  late final double maxDeviationLatLong;

  _SimplifyFilter(
      int zoomlevel, this.maxDeviationPixel, BoundingBox boundingBox)
      : projection = PixelProjection(zoomlevel) {
    maxDeviationLatLong = projection.latitudeDiffPerPixel(
        (boundingBox.minLatitude + boundingBox.maxLatitude) / 2,
        maxDeviationPixel);
    //print("maxDeviationLatLong: $maxDeviationLatLong for maxZoom: $zoomlevel");
  }

  Wayholder reduce(Wayholder wayHolder) {
    List<List<ILatLong>> newLatLongs = [];
    for (List<ILatLong> latLongs in wayHolder.way.latLongs) {
      if (latLongs.length <= 4) {
        newLatLongs.add(latLongs);
        continue;
      }
      List<ILatLong> res1 = dpl.simplify(latLongs, maxDeviationLatLong);
      if (res1.length <= 0.8 * latLongs.length) {
        newLatLongs.add(res1);
      } else {
        newLatLongs.add(latLongs);
      }
    }
    // at most 80% of the previous nodes
    Wayholder result = Wayholder(Way(wayHolder.way.layer, wayHolder.way.tags,
        newLatLongs, wayHolder.way.labelPosition));

    newLatLongs = [];
    for (List<ILatLong> latLongs in wayHolder.otherOuters) {
      if (latLongs.length <= 4) {
        newLatLongs.add(latLongs);
        continue;
      }
      List<ILatLong> res1 = dpl.simplify(latLongs, maxDeviationLatLong);
      if (res1.length <= 0.8 * latLongs.length) {
        newLatLongs.add(res1);
      } else {
        newLatLongs.add(latLongs);
      }
    }
    result.otherOuters = newLatLongs;
    return result;
  }
}
