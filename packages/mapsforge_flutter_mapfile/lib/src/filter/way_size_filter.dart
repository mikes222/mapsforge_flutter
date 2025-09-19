import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

/// A filter that removes ways that are too small to be visually significant at a
/// given zoom level.
///
/// This is an important optimization to avoid processing and rendering ways that
/// would only cover a few pixels on the screen. The size threshold is defined in
/// pixels and converted to a geographical distance.
class WaySizeFilter {
  final PixelProjection projection;

  final double filterSizePixels;

  double? maxDeviationLatLong;

  WaySizeFilter(int zoomlevel, this.filterSizePixels) : projection = PixelProjection(zoomlevel);

    /// Filters the ways within a [wayholder], removing any that are smaller than
  /// the configured pixel size.
  ///
  /// Returns a new [Wayholder] containing only the ways that passed the filter.
  /// If all ways are filtered out, this method returns `null`.
  /// If no ways are filtered, the original [wayholder] is returned.
  Wayholder? filter(Wayholder wayholder) {
    maxDeviationLatLong = projection.latitudeDiffPerPixel(
      (wayholder.boundingBoxCached.minLatitude + wayholder.boundingBoxCached.maxLatitude) / 2,
      filterSizePixels,
    );
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
