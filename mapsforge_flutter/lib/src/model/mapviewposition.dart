import 'dart:math';

import 'package:mapsforge_flutter/src/model/dimension.dart';
import 'package:mapsforge_flutter/src/projection/mercatorprojectionimpl.dart';

import 'boundingbox.dart';
import 'mappoint.dart';

class MapViewPosition {
  double _latitude;

  double _longitude;

  final double _tileSize;

  final int zoomLevel;

  /// the latitude/longitude boundaries of the current map view.
  /// This property must be calculated if needed based on the current view
  BoundingBox boundingBox;

  // the left/upper corner of the current mapview in pixels in relation to the current lat/lon.
  Mappoint _leftUpper;

  MercatorProjectionImpl _mercatorProjection;

  MapViewPosition(this._latitude, this._longitude, this.zoomLevel, this._tileSize)
      : assert(zoomLevel >= 0),
        assert(_tileSize > 0),
        assert(_latitude == null || MercatorProjectionImpl.checkLatitude(_latitude)),
        assert(_longitude == null || MercatorProjectionImpl.checkLongitude(_longitude));

  MapViewPosition.zoomIn(MapViewPosition old)
      : _latitude = old._latitude,
        _longitude = old._longitude,
        zoomLevel = old.zoomLevel + 1,
        _tileSize = old._tileSize;

  MapViewPosition.zoomOut(MapViewPosition old)
      : _latitude = old._latitude,
        _longitude = old._longitude,
        zoomLevel = old.zoomLevel - 1,
        _tileSize = old._tileSize;

  MapViewPosition.zoom(MapViewPosition old, int zoomLevel)
      : _latitude = old._latitude,
        _longitude = old._longitude,
        this.zoomLevel = zoomLevel,
        _tileSize = old._tileSize;

  MapViewPosition.move(MapViewPosition old, this._latitude, this._longitude)
      : zoomLevel = old.zoomLevel,
        _tileSize = old._tileSize,
        _mercatorProjection = old._mercatorProjection,
        assert(_latitude == null || MercatorProjectionImpl.checkLatitude(_latitude)),
        assert(_longitude == null || MercatorProjectionImpl.checkLongitude(_longitude));

  MapViewPosition.setLeftUpper(MapViewPosition old, double left, double upper, Dimension viewSize)
      : zoomLevel = old.zoomLevel,
        _tileSize = old._tileSize,
        _mercatorProjection = old._mercatorProjection {
    //calculateBoundingBox(tileSize, viewSize);
    _leftUpper = Mappoint(left, upper);

    double rightX = _leftUpper.x + viewSize.width;
    double bottomY = _leftUpper.y + viewSize.height;

    boundingBox = BoundingBox(
        mercatorProjection.pixelYToLatitude(min(bottomY, mercatorProjection.mapSize)),
        mercatorProjection.pixelXToLongitude(max(_leftUpper.x, 0)),
        mercatorProjection.pixelYToLatitude(max(_leftUpper.y, 0)),
        mercatorProjection.pixelXToLongitude(min(rightX, mercatorProjection.mapSize)));

    _latitude = mercatorProjection.pixelYToLatitude(_leftUpper.y + viewSize.height / 2);

    _longitude = mercatorProjection.pixelXToLongitude(_leftUpper.x + viewSize.width / 2);

    MercatorProjectionImpl.checkLatitude(_latitude);

    MercatorProjectionImpl.checkLongitude(_longitude);
  }

  void sizeChanged() {
    _leftUpper = null;
    boundingBox = null;
  }

  bool hasPosition() {
    return _latitude != null && _longitude != null;
  }

  BoundingBox calculateBoundingBox(Dimension viewSize) {
    if (boundingBox != null) return boundingBox;

    double centerY = mercatorProjection.latitudeToPixelY(_latitude);
    double centerX = mercatorProjection.longitudeToPixelX(_longitude);
    double leftX = centerX - viewSize.width / 2;
    double rightX = centerX + viewSize.width / 2;
    double topY = centerY - viewSize.height / 2;
    double bottomY = centerY + viewSize.height / 2;
    boundingBox = BoundingBox(
        mercatorProjection.pixelYToLatitude(min(bottomY, mercatorProjection.mapSize)),
        mercatorProjection.pixelXToLongitude(max(leftX, 0)),
        mercatorProjection.pixelYToLatitude(max(topY, 0)),
        mercatorProjection.pixelXToLongitude(min(rightX, mercatorProjection.mapSize)));
    _leftUpper = Mappoint(leftX, topY);
    return boundingBox;
  }

  Mappoint get leftUpper => _leftUpper;

  MercatorProjectionImpl get mercatorProjection {
    if (_mercatorProjection != null) return _mercatorProjection;
    _mercatorProjection = MercatorProjectionImpl(_tileSize, zoomLevel);
    return _mercatorProjection;
  }

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
