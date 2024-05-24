import 'package:mapsforge_flutter/src/rendertheme/nodewayproperties.dart';

import '../../core.dart';
import '../../datastore.dart';
import '../../maps.dart';
import '../model/tag.dart';

///
/// In the terminal window run
///
///```
/// flutter packages pub run build_runner build --delete-conflicting-outputs
///```
///
/// Properties for one Node (PointOfInterest) read from the datastore. Note that the properties are
/// dependent on the zoomLevel and pixelsize of the device. However one instance
/// of NodeProperties is used for one zoomlevel only.
class NodeProperties implements NodeWayProperties {
  final PointOfInterest pointOfInterest;

  NodeProperties(this.pointOfInterest);

  int get layer => pointOfInterest.layer;

  List<Tag> get tags => pointOfInterest.tags;

  /// a cache for absolute coordinates
  Mappoint? _coordinatesAbsolute;

  // remove this security feature after 2025/01
  @deprecated
  int _lastZoomLevel = -1;

  /// Returns the absolute coordinates in pixel of this node
  Mappoint getCoordinatesAbsolute(PixelProjection projection) {
    // remove this security feature after 2025/01
    if (_lastZoomLevel != -1 &&
        projection.scalefactor.zoomlevel != _lastZoomLevel)
      throw UnimplementedError("Invalid zoomlevel");
    _coordinatesAbsolute ??= projection.latLonToPixel(pointOfInterest.position);
    _lastZoomLevel = projection.scalefactor.zoomlevel;
    return _coordinatesAbsolute!;
  }

  Mappoint getCoordinateRelativeToLeftUpper(
      PixelProjection projection, Mappoint leftUpper) {
    Mappoint absolute = getCoordinatesAbsolute(projection);
    return absolute.offset(-1.0 * leftUpper.x, -1.0 * leftUpper.y);
  }

  Mappoint getCoordinateRelativeToCenter(
      PixelProjection projection, Mappoint center, double dy) {
    Mappoint absolute = getCoordinatesAbsolute(projection);
    return absolute.offset(-1.0 * center.x, -1.0 * center.y + dy);
  }
}
