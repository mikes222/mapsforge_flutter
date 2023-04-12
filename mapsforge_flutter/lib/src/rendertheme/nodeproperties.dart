import 'package:mapsforge_flutter/src/rendertheme/nodewayproperties.dart';

import '../../core.dart';
import '../../datastore.dart';
import '../../maps.dart';
import '../model/tag.dart';

/// Properties for one Node (PointOfInterest) read from the datastore. Note that the properties are
// /// dependent on the zoomLevel and pixelsize of the device.
class NodeProperties implements NodeWayProperties {
  final PointOfInterest pointOfInterest;

  NodeProperties(this.pointOfInterest);

  int get layer => pointOfInterest.layer;

  List<Tag> get tags => pointOfInterest.tags;

  Mappoint? coordinatesAbsolute;

  /// Returns the absolute coordinates in pixel of this node
  Mappoint getCoordinatesAbsolute(PixelProjection projection) {
    coordinatesAbsolute ??= projection.latLonToPixel(pointOfInterest.position);
    return coordinatesAbsolute!;
  }

  Mappoint getCoordinateRelativeToTile(PixelProjection projection, Tile tile) {
    Mappoint tileOrigin = projection.getLeftUpper(tile);
    Mappoint absolute = getCoordinatesAbsolute(projection);
    return absolute.offset(-1.0 * tileOrigin.x, -1.0 * tileOrigin.y);
  }
}
