import 'dart:math';

import 'package:mapsforge_flutter/src/model/dimension.dart';
import 'package:mapsforge_flutter/src/utils/mercatorprojection.dart';

import 'boundingbox.dart';
import 'mappoint.dart';

class MapViewPosition {
  double _latitude;

  double _longitude;

  final int zoomLevel;

  /// the latitude/longitude boundaries of the current map view.
  /// This property must be calculated if needed based on the current view
  BoundingBox boundingBox;

  // the left/upper corner of the current mapview in pixels in relation to the current lat/lon.
  Mappoint _leftUpper;

  MapViewPosition(this._latitude, this._longitude, this.zoomLevel) : assert(zoomLevel >= 0)
  //assert(_latitude != null),
  //assert(_longitude != null)
  ;

  MapViewPosition.zoomIn(MapViewPosition old)
      : _latitude = old._latitude,
        _longitude = old._longitude,
        zoomLevel = old.zoomLevel + 1;

  MapViewPosition.zoomOut(MapViewPosition old)
      : _latitude = old._latitude,
        _longitude = old._longitude,
        zoomLevel = old.zoomLevel - 1;

  MapViewPosition.move(MapViewPosition old, this._latitude, this._longitude) : zoomLevel = old.zoomLevel;

  MapViewPosition.setLeftUpper(MapViewPosition old, double left, double upper, int tileSize, Dimension viewSize)
      : zoomLevel = old.zoomLevel {
    //calculateBoundingBox(tileSize, viewSize);
    _leftUpper = Mappoint(left, upper);

    double rightX = _leftUpper.x + viewSize.width;
    double bottomY = _leftUpper.y + viewSize.height;
    int mapSize = MercatorProjection.getMapSize(zoomLevel, tileSize);
    boundingBox = BoundingBox(
        MercatorProjection.pixelYToLatitude(min(bottomY, mapSize.toDouble()), mapSize),
        MercatorProjection.pixelXToLongitude(max(_leftUpper.x, 0), mapSize),
        MercatorProjection.pixelYToLatitude(max(_leftUpper.y, 0), mapSize),
        MercatorProjection.pixelXToLongitude(min(rightX, mapSize.toDouble()), mapSize));

    _latitude = MercatorProjection.pixelYToLatitude(_leftUpper.y + viewSize.height / 2, mapSize);
    _longitude = MercatorProjection.pixelXToLongitude(_leftUpper.x + viewSize.width / 2, mapSize);
  }

  void sizeChanged() {
    _leftUpper = null;
    boundingBox = null;
  }

  bool hasPosition() {
    return _latitude != null && _longitude != null;
  }

  BoundingBox calculateBoundingBox(int tileSize, Dimension viewSize) {
    if (boundingBox != null) return boundingBox;
    double centerY = MercatorProjection.latitudeToPixelY(_latitude, zoomLevel, tileSize);
    double centerX = MercatorProjection.longitudeToPixelX(_longitude, zoomLevel, tileSize);
    double leftX = centerX - viewSize.width / 2;
    double rightX = centerX + viewSize.width / 2;
    double topY = centerY - viewSize.height / 2;
    double bottomY = centerY + viewSize.height / 2;
    int mapSize = MercatorProjection.getMapSize(zoomLevel, tileSize);
    boundingBox = BoundingBox(
        MercatorProjection.pixelYToLatitude(min(bottomY, mapSize.toDouble()), mapSize),
        MercatorProjection.pixelXToLongitude(max(leftX, 0), mapSize),
        MercatorProjection.pixelYToLatitude(max(topY, 0), mapSize),
        MercatorProjection.pixelXToLongitude(min(rightX, mapSize.toDouble()), mapSize));
    _leftUpper = Mappoint(leftX, topY);
    return boundingBox;
  }

  Mappoint get leftUpper => _leftUpper;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapViewPosition &&
          runtimeType == other.runtimeType &&
          _latitude == other._latitude &&
          _longitude == other._longitude &&
          zoomLevel == other.zoomLevel;

  @override
  int get hashCode => _latitude.hashCode ^ _longitude.hashCode ^ zoomLevel.hashCode;
}
