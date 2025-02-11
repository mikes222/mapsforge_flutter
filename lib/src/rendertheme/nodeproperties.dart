import 'package:mapsforge_flutter/src/rendertheme/nodewayproperties.dart';

import '../../core.dart';
import '../../datastore.dart';
import '../../maps.dart';
import '../model/tag.dart';

/// Properties for one Node (PointOfInterest) read from the datastore. Note that the properties are
/// dependent on the zoomLevel and pixelsize of the device. Therefore one instance
/// of NodeProperties can be used for one zoomlevel only.
class NodeProperties implements NodeWayProperties {
  final PointOfInterest pointOfInterest;

  NodeProperties(this.pointOfInterest);

  int get layer => pointOfInterest.layer;

  List<Tag> get tags => pointOfInterest.tags;

  /// a cache for absolute coordinates
  Mappoint? _coordinatesAbsolute;

  /// Returns the absolute coordinates in pixel of this node
  Mappoint getCoordinatesAbsolute(PixelProjection projection) {
    _coordinatesAbsolute ??= projection.latLonToPixel(pointOfInterest.position);
    return _coordinatesAbsolute!;
  }

  void clearCache() {
    _coordinatesAbsolute = null;
  }

  @override
  String toString() {
    return 'NodeProperties{pointOfInterest: $pointOfInterest, _coordinatesAbsolute: $_coordinatesAbsolute}';
  }
}
