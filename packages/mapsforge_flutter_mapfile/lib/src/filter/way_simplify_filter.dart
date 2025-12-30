import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

/// A filter that simplifies way geometries using the Douglas-Peucker algorithm.
///
/// This is a crucial performance optimization that reduces the number of vertices
/// in a way while preserving its general shape. The level of simplification is
/// determined by a maximum allowed deviation in pixels, which is converted to a
/// geographical distance based on the current zoom level and latitude.
class WaySimplifyFilter {
  final _log = Logger('WaySimplifyFilter');

  final DouglasPeuckerLatLong dpl = DouglasPeuckerLatLong();

  final PixelProjection projection;

  final double maxDeviationPixel;

  WaySimplifyFilter(int zoomlevel, this.maxDeviationPixel) : projection = PixelProjection(zoomlevel) {
    // print(
    //     "maxDeviationLatLong: $maxDeviationLatLong from $maxDeviationPixel for maxZoom: $zoomlevel in boundingbox $boundingBox would result to ${LatLongUtils.euclideanDistance(boundingBox.getCenterPoint(), LatLong(boundingBox.getCenterPoint().latitude + maxDeviationLatLong, boundingBox.getCenterPoint().longitude + maxDeviationLatLong))}");
  }

  /// Reduces the complexity of all ways within a [wayholder].
  ///
  /// This method calculates the appropriate simplification tolerance based on the
  /// wayholder's bounding box and then applies the Douglas-Peucker algorithm to
  /// each way path (inner, closed outer, and open outer).
  Wayholder reduce(Wayholder wayholder) {
    double maxDeviationLatLong = projection.latitudeDiffPerPixel(
      (wayholder.boundingBoxCached.minLatitude + wayholder.boundingBoxCached.maxLatitude) / 2,
      maxDeviationPixel,
    );
    List<Waypath> inner = wayholder.innerRead.map((e) => _reduceWay(e, maxDeviationLatLong).clone()).toList();
    List<Waypath> closedOuters = wayholder.closedOutersRead.map((e) => _reduceWay(e, maxDeviationLatLong).clone()).toList()
      ..removeWhere((test) => test.length <= 3);
    List<Waypath> openOuters = wayholder.openOutersRead.map((e) => _reduceWay(e, maxDeviationLatLong).clone()).toList();
    Wayholder result = wayholder.cloneWith(inner: inner, closedOuters: closedOuters, openOuters: openOuters);
    return result;
  }

  Waypath _reduceWay(Waypath waypath, double maxDeviationLatLong) {
    if (waypath.length <= 5) {
      return waypath;
    }
    List<ILatLong> res1 = dpl.simplify(waypath.path, maxDeviationLatLong);
    assert(res1.isNotEmpty);
    if (res1.length > 32767) {
      _log.info("${res1.length} too much at zoomlevel ${projection.scalefactor.zoomlevel} and $maxDeviationPixel ($maxDeviationLatLong)");
    }
    assert(res1.length >= 2);
    if (LatLongUtils.isClosedWay(res1)) assert(res1.length > 2);
    return Waypath(path: res1);
  }

  /// Reduces the complexity of a single [waypath], ensuring that the resulting
  /// number of points does not exceed the maximum allowed (32767).
  ///
  /// If the initial simplification still results in too many points, this method
  /// will iteratively increase the simplification tolerance until the point count
  /// is within the limit.
  Waypath reduceWayEnsureMax(Waypath waypath) {
    double maxDeviationLatLong = projection.latitudeDiffPerPixel((waypath.boundingBox.minLatitude + waypath.boundingBox.maxLatitude) / 2, maxDeviationPixel);
    if (waypath.length <= 5) {
      return waypath;
    }
    return _reduceWayEnsureMax(waypath, maxDeviationLatLong, maxDeviationLatLong);
  }

  Waypath _reduceWayEnsureMax(Waypath waypath, double maxDeviation, double maxDeviationLatLong) {
    List<ILatLong> res1 = dpl.simplify(waypath.path, maxDeviation);
    if (res1.length > 32767) return _reduceWayEnsureMax(waypath, maxDeviation + maxDeviationLatLong, maxDeviationLatLong);
    assert(res1.length > 2);
    return Waypath(path: res1);
  }
}
