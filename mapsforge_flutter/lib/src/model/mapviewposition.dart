import 'package:mapsforge_flutter/src/model/dimension.dart';
import 'package:mapsforge_flutter/src/utils/mercatorprojection.dart';

import 'boundingbox.dart';
import 'mappoint.dart';

class MapViewPosition {
  final double latitude;

  final double longitude;

  final int zoomLevel;

  /// the latitude/longitude boundaries of the current map view.
  /// This property must be calculated if needed based on the current view
  BoundingBox boundingBox;

  // the left/upper corner of the current mapview in relation to the current lat/lon.
  Mappoint leftUpper;

  MapViewPosition(this.latitude, this.longitude, this.zoomLevel);

  MapViewPosition.zoomIn(MapViewPosition old)
      : latitude = old.latitude,
        longitude = old.longitude,
        zoomLevel = old.zoomLevel + 1;

  void sizeChanged() {
    leftUpper = null;
    boundingBox = null;
  }

  BoundingBox calculateBoundingBox(int tileSize, Dimension viewSize) {
    if (boundingBox != null) return boundingBox;
    double centerY = MercatorProjection.latitudeToPixelY(latitude, zoomLevel, tileSize);
    double centerX = MercatorProjection.longitudeToPixelX(longitude, zoomLevel, tileSize);
    double leftX = centerX - viewSize.width / 2;
    double rightX = centerX + viewSize.width / 2;
    double topY = centerY - viewSize.height / 2;
    double bottomY = centerY + viewSize.height / 2;
    int mapSize = MercatorProjection.getMapSize(zoomLevel, tileSize);
    boundingBox = BoundingBox(MercatorProjection.pixelYToLatitude(bottomY, mapSize), MercatorProjection.pixelXToLongitude(leftX, mapSize),
        MercatorProjection.pixelYToLatitude(topY, mapSize), MercatorProjection.pixelXToLongitude(rightX, mapSize));
    leftUpper = Mappoint(leftX, topY);
    return boundingBox;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapViewPosition &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          zoomLevel == other.zoomLevel;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode ^ zoomLevel.hashCode;
}
