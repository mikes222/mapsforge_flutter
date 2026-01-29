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
  static final _log = Logger('WaySimplifyFilter');

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
  Wayholder? reduce(Wayholder wayholder) {
    double maxDeviationLatLong = projection.latitudeDiffPerPixel(
      (wayholder.boundingBoxCached.minLatitude + wayholder.boundingBoxCached.maxLatitude) / 2,
      maxDeviationPixel,
    );
    List<Waypath> inner = [];
    for (var e in wayholder.innerRead) {
      Waypath? waypath = _reduceWay(e, maxDeviationLatLong);
      if (waypath != null) inner.add(waypath);
    }
    List<Waypath> closedOuters = [];
    for (var e in wayholder.closedOutersRead) {
      Waypath? waypath = _reduceWay(e, maxDeviationLatLong);
      if (waypath != null) closedOuters.add(waypath);
    }
    List<Waypath> openOuters = [];
    for (var e in wayholder.openOutersRead) {
      Waypath? waypath = _reduceWay(e, maxDeviationLatLong);
      if (waypath != null) openOuters.add(waypath);
    }

    if (inner.isEmpty && closedOuters.isEmpty && openOuters.isEmpty) return null;

    Wayholder result = wayholder.cloneWith(inner: inner, closedOuters: closedOuters, openOuters: openOuters);
    return result;
  }

  Wayholder ensureMax(Wayholder wayholder) {
    double maxDeviationLatLong = projection.latitudeDiffPerPixel(
      (wayholder.boundingBoxCached.minLatitude + wayholder.boundingBoxCached.maxLatitude) / 2,
      maxDeviationPixel,
    );
    final innerRead = wayholder.innerRead;
    final inner = List<Waypath>.generate(innerRead.length, (i) => _reduceWayEnsureMax(innerRead[i], maxDeviationLatLong, maxDeviationLatLong), growable: false);

    final closedOutersRead = wayholder.closedOutersRead;
    final closedOuters = List<Waypath>.generate(
      closedOutersRead.length,
      (i) => _reduceWayEnsureMax(closedOutersRead[i], maxDeviationLatLong, maxDeviationLatLong),
      growable: false,
    );

    final openOutersRead = wayholder.openOutersRead;
    final openOuters = List<Waypath>.generate(
      openOutersRead.length,
      (i) => _reduceWayEnsureMax(openOutersRead[i], maxDeviationLatLong, maxDeviationLatLong),
      growable: false,
    );

    Wayholder result = wayholder.cloneWith(inner: inner, closedOuters: closedOuters, openOuters: openOuters);
    return result;
  }

  Waypath? _reduceWay(Waypath waypath, double maxDeviationLatLong) {
    if (waypath.length <= 5) {
      return waypath;
    }
    List<ILatLong> res1 = dpl.simplify(waypath.path, maxDeviationLatLong);
    assert(res1.length >= 2);
    if (res1.length > 32767) {
      _log.info(
        "too many nodes (${res1.length}) at zoomlevel ${projection.scalefactor.zoomlevel} and max deviation $maxDeviationPixel (max dev. lat/lon $maxDeviationLatLong)",
      );
    }
    if (waypath.isClosedWay()) {
      if (res1.length < 3) return null;
      assert(LatLongUtils.isClosedWay(res1));
    }
    return Waypath(path: res1);
  }

  Waypath _reduceWayEnsureMax(Waypath waypath, double maxDeviation, double maxDeviationLatLong) {
    if (waypath.length < 32767) return waypath;
    List<ILatLong> res1 = dpl.simplify(waypath.path, maxDeviation);
    if (res1.length > 32767) return _reduceWayEnsureMax(waypath, maxDeviation + maxDeviationLatLong, maxDeviationLatLong);
    assert(res1.length > 2);
    return Waypath(path: res1);
  }
}
