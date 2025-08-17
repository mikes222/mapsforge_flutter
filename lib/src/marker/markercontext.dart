import 'package:mapsforge_flutter/maps.dart';

import '../../core.dart';

class MarkerContext {
  /// The center of the map. Note that this may not be the same as the current mapViewposition because we shift the map on screen according to the position and
  /// redraw the map only if we need to.
  final Mappoint mapCenter;

  final int zoomLevel;

  final PixelProjection projection;

  final double rotationRadian;

  /// The bounding box of the current map in lat/lon coordinates
  final BoundingBox boundingBox;

  const MarkerContext(
    this.mapCenter,
    this.zoomLevel,
    this.projection,
    this.rotationRadian,
    this.boundingBox,
  );
}
