import 'package:logging/logging.dart';

import '../../../core.dart';
import '../../../maps.dart';
import '../../../special.dart';
import '../../utils/douglas_peucker_latlong.dart';

class WaySimplifyFilter {
  final _log = Logger('WaySimplifyFilter');

  final DouglasPeuckerLatLong dpl = DouglasPeuckerLatLong();

  final PixelProjection projection;

  final double maxDeviationPixel;

  late final double maxDeviationLatLong;

  final BoundingBox boundingBox;

  WaySimplifyFilter(int zoomlevel, this.maxDeviationPixel, this.boundingBox) : projection = PixelProjection(zoomlevel) {
    maxDeviationLatLong = projection.latitudeDiffPerPixel((boundingBox.minLatitude + boundingBox.maxLatitude) / 2, maxDeviationPixel);
    // print(
    //     "maxDeviationLatLong: $maxDeviationLatLong from $maxDeviationPixel for maxZoom: $zoomlevel in boundingbox $boundingBox would result to ${LatLongUtils.euclideanDistance(boundingBox.getCenterPoint(), LatLong(boundingBox.getCenterPoint().latitude + maxDeviationLatLong, boundingBox.getCenterPoint().longitude + maxDeviationLatLong))}");
  }

  Wayholder reduce(Wayholder wayholder) {
    List<Waypath> inner = wayholder.innerRead.map((e) => reduceWay(e)).toList();
    List<Waypath> closedOuters = wayholder.closedOutersRead.map((e) {
      var result = reduceWay(e);
      if (result.length == 2) {
        // this object is so tiny that it gets reduced to 2 points, remove it.
        return Waypath.empty();
      }
      return result;
    }).toList()
      ..removeWhere((test) => test.isEmpty);
    List<Waypath> openOuters = wayholder.openOutersRead.map((e) => reduceWay(e)).toList();
    Wayholder result = wayholder.cloneWith(inner: inner, closedOuters: closedOuters, openOuters: openOuters);
    return result;
  }

  Waypath reduceWay(Waypath waypath) {
    if (waypath.length <= 5) {
      return waypath;
    }
    List<ILatLong> res1 = dpl.simplify(waypath.path, maxDeviationLatLong);
    assert(res1.isNotEmpty);
    if (res1.length > 32767) {
      _log.info("${res1.length} too much at zoomlevel ${projection.scalefactor.zoomlevel} and $maxDeviationPixel ($maxDeviationLatLong) and $boundingBox");
    }
    assert(res1.length >= 2);
    if (LatLongUtils.isClosedWay(res1)) assert(res1.length > 2);
    return Waypath(res1);
  }

  Waypath reduceWayEnsureMax(Waypath waypath) {
    if (waypath.length <= 5) {
      return waypath;
    }
    return _reduceWayEnsureMax(waypath, maxDeviationLatLong);
  }

  Waypath _reduceWayEnsureMax(Waypath waypath, double maxDeviation) {
    List<ILatLong> res1 = dpl.simplify(waypath.path, maxDeviation);
    if (res1.length > 32767) return _reduceWayEnsureMax(waypath, maxDeviation + maxDeviationLatLong);
    assert(res1.length > 2);
    return Waypath(res1);
  }
}
