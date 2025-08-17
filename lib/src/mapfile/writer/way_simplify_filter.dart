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

  double? maxDeviationLatLong;

  WaySimplifyFilter(int zoomlevel, this.maxDeviationPixel) : projection = PixelProjection(zoomlevel) {
    // print(
    //     "maxDeviationLatLong: $maxDeviationLatLong from $maxDeviationPixel for maxZoom: $zoomlevel in boundingbox $boundingBox would result to ${LatLongUtils.euclideanDistance(boundingBox.getCenterPoint(), LatLong(boundingBox.getCenterPoint().latitude + maxDeviationLatLong, boundingBox.getCenterPoint().longitude + maxDeviationLatLong))}");
  }

  Wayholder reduce(Wayholder wayholder) {
    maxDeviationLatLong =
        projection.latitudeDiffPerPixel((wayholder.boundingBoxCached.minLatitude + wayholder.boundingBoxCached.maxLatitude) / 2, maxDeviationPixel);
    List<Waypath> inner = wayholder.innerRead.map((e) => _reduceWay(e)).toList();
    List<Waypath> closedOuters = wayholder.closedOutersRead.map((e) => _reduceWay(e)).toList()..removeWhere((test) => test.length <= 3);
    List<Waypath> openOuters = wayholder.openOutersRead.map((e) => _reduceWay(e)).toList();
    Wayholder result = wayholder.cloneWith(inner: inner, closedOuters: closedOuters, openOuters: openOuters);
    return result;
  }

  Waypath _reduceWay(Waypath waypath) {
    if (waypath.length <= 5) {
      return waypath;
    }
    List<ILatLong> res1 = dpl.simplify(waypath.path, maxDeviationLatLong!);
    assert(res1.isNotEmpty);
    if (res1.length > 32767) {
      _log.info("${res1.length} too much at zoomlevel ${projection.scalefactor.zoomlevel} and $maxDeviationPixel ($maxDeviationLatLong)");
    }
    assert(res1.length >= 2);
    if (LatLongUtils.isClosedWay(res1)) assert(res1.length > 2);
    return Waypath(res1);
  }

  Waypath reduceWayEnsureMax(Waypath waypath) {
    maxDeviationLatLong = projection.latitudeDiffPerPixel((waypath.boundingBox.minLatitude + waypath.boundingBox.maxLatitude) / 2, maxDeviationPixel);
    if (waypath.length <= 5) {
      return waypath;
    }
    return _reduceWayEnsureMax(waypath, maxDeviationLatLong!);
  }

  Waypath _reduceWayEnsureMax(Waypath waypath, double maxDeviation) {
    List<ILatLong> res1 = dpl.simplify(waypath.path, maxDeviation);
    if (res1.length > 32767) return _reduceWayEnsureMax(waypath, maxDeviation + maxDeviationLatLong!);
    assert(res1.length > 2);
    return Waypath(res1);
  }
}
