import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:datastore_renderer/src/model/nodewayproperties.dart';

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

  @override
  String toString() {
    return 'NodeProperties{pointOfInterest: $pointOfInterest, _coordinatesAbsolute: $_coordinatesAbsolute}';
  }
}
