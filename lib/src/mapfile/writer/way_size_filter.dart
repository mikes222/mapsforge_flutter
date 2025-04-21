import '../../../core.dart';
import '../../../maps.dart';
import '../../../special.dart';

/// Filter ways by size. If the way would be too small in max zoom of the desired
/// subfile (hence maxZoomlevel) we do not want to include it at all.
class WaySizeFilter {
  final PixelProjection projection;

  final double filterSizePixels;

  double? maxDeviationLatLong;

  WaySizeFilter(int zoomlevel, this.filterSizePixels) : projection = PixelProjection(zoomlevel) {}

  Wayholder? filter(Wayholder wayholder) {
    maxDeviationLatLong =
        projection.latitudeDiffPerPixel((wayholder.boundingBoxCached.minLatitude + wayholder.boundingBoxCached.maxLatitude) / 2, filterSizePixels);
    int count = wayholder.innerRead.length + wayholder.openOutersRead.length + wayholder.closedOutersRead.length;
    List<Waypath> inner = wayholder.innerRead.map((e) => _shouldFilter(e)).toList().where((test) => test != null).map((test) => test!).toList();
    List<Waypath> closedOuters = wayholder.closedOutersRead.map((e) => _shouldFilter(e)).toList().where((test) => test != null).map((test) => test!).toList();
    List<Waypath> openOuters = wayholder.openOutersRead.map((e) => _shouldFilter(e)).toList().where((test) => test != null).map((test) => test!).toList();

    /// nothing removed, return the original
    if (count == inner.length + closedOuters.length + openOuters.length) return wayholder;

    /// everything removed.
    if (closedOuters.isEmpty && openOuters.isEmpty) return null;

    return wayholder.cloneWith(inner: inner, closedOuters: closedOuters, openOuters: openOuters);
  }

  Waypath? _shouldFilter(Waypath waypath) {
    BoundingBox boundingBox = waypath.boundingBox;
    if ((boundingBox.maxLatitude - boundingBox.minLatitude).abs() > maxDeviationLatLong!) return waypath;
    if ((boundingBox.maxLongitude - boundingBox.minLongitude).abs() > maxDeviationLatLong!) return waypath;
    return null;
  }
}
