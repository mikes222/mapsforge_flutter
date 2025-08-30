import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:dart_rendertheme/src/model/nodewayproperties.dart';

/// Properties for one Node (PointOfInterest) read from the datastore. Note that the properties are
/// dependent on the zoomLevel. Therefore one instance of NodeProperties can be used for one zoomlevel only.
class NodeProperties implements NodeWayProperties {
  final PointOfInterest pointOfInterest;

  /// a cache for absolute coordinates
  late Mappoint _coordinatesAbsolute;

  NodeProperties(this.pointOfInterest, PixelProjection projection) {
    _coordinatesAbsolute = projection.latLonToPixel(pointOfInterest.position);
  }

  int get layer => pointOfInterest.layer;

  List<Tag> get tags => pointOfInterest.tags;

  /// Returns the absolute coordinates in pixel of this node
  Mappoint getCoordinatesAbsolute() {
    return _coordinatesAbsolute;
  }

  @override
  String toString() {
    return 'NodeProperties{pointOfInterest: $pointOfInterest, _coordinatesAbsolute: $_coordinatesAbsolute}';
  }
}
