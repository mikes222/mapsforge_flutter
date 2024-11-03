import 'dart:math';

import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/model/dimension.dart';

import '../../maps.dart';
import 'boundingbox.dart';
import 'mappoint.dart';

class MapViewPosition {
  /// The latitude of the center of the widget
  double? _latitude;

  /// The longitude of the center of the widget
  double? _longitude;

  /// The current zoomLevel
  final int zoomLevel;

  /// The current indoorLevel
  final int indoorLevel;

  final double scale;

  /// orientation of the map in clockwise direction 0-360°. 0° is north, 360° is excluded.
  final double _rotation;

  final double _rotationRadian;

  /// The focal point. Used when pinch-and-zoom to know the center of the zoom
  final Mappoint? focalPoint;

  /// the latitude/longitude boundaries of the current map view.
  /// This property must be calculated if needed based on the current view
  BoundingBox? boundingBox;

  /// the left/upper corner of the current mapview in pixels in relation to the current lat/lon.
  Mappoint? _leftUpper;

  /// The center of the map in absolute pixel coordinates. Note that the center
  /// needs to be recalculated if the map moves OR if the map zooms
  Mappoint? _center;

  final PixelProjection _projection;

  Dimension? _lastMapDimension;

  MapViewPosition(this._latitude, this._longitude, this.zoomLevel,
      this.indoorLevel, this._rotation)
      : scale = 1,
        focalPoint = null,
        _rotationRadian = Projection.degToRadian(_rotation),
        assert(zoomLevel >= 0),
        _projection = PixelProjection(zoomLevel);

  MapViewPosition.zoomIn(MapViewPosition old)
      : _latitude = old._latitude,
        _longitude = old._longitude,
        zoomLevel = old.zoomLevel + 1,
        indoorLevel = old.indoorLevel,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        scale = 1,
        focalPoint = null,
        _projection =
            PixelProjection(old.zoomLevel + 1),
        _lastMapDimension = old._lastMapDimension;

  MapViewPosition.zoomInAround(
      MapViewPosition old, double latitude, double longitude)
      : _latitude = latitude,
        _longitude = longitude,
        zoomLevel = old.zoomLevel + 1,
        indoorLevel = old.indoorLevel,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        scale = 1,
        focalPoint = null,
        _projection =
            PixelProjection(old.zoomLevel + 1),
        _lastMapDimension = old._lastMapDimension;

  MapViewPosition.zoomOut(MapViewPosition old)
      : _latitude = old._latitude,
        _longitude = old._longitude,
        zoomLevel = max(old.zoomLevel - 1, 0),
        indoorLevel = old.indoorLevel,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        scale = 1,
        focalPoint = null,
        _projection =
            PixelProjection(max(old.zoomLevel - 1, 0)),
        _lastMapDimension = old._lastMapDimension;

  MapViewPosition.zoom(MapViewPosition old, int zoomLevel)
      : _latitude = old._latitude,
        _longitude = old._longitude,
        this.zoomLevel = max(zoomLevel, 0),
        indoorLevel = old.indoorLevel,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        scale = 1,
        focalPoint = null,
        _projection =
            PixelProjection(max(zoomLevel, 0)),
        _lastMapDimension = old._lastMapDimension;

  MapViewPosition.zoomAround(
      MapViewPosition old, double latitude, double longitude, int zoomLevel)
      : _latitude = latitude,
        _longitude = longitude,
        this.zoomLevel = max(zoomLevel, 0),
        indoorLevel = old.indoorLevel,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        scale = 1,
        focalPoint = null,
        _projection =
            PixelProjection(max(zoomLevel, 0)),
        _lastMapDimension = old._lastMapDimension;

  MapViewPosition.indoorLevelUp(MapViewPosition old)
      : _latitude = old._latitude,
        _longitude = old._longitude,
        zoomLevel = old.zoomLevel,
        indoorLevel = old.indoorLevel + 1,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        _projection = old._projection,
        scale = 1,
        focalPoint = null,
        boundingBox = old.boundingBox,
        _leftUpper = old._leftUpper,
        _center = old._center,
        _lastMapDimension = old._lastMapDimension;

  MapViewPosition.indoorLevelDown(MapViewPosition old)
      : _latitude = old._latitude,
        _longitude = old._longitude,
        zoomLevel = old.zoomLevel,
        indoorLevel = old.indoorLevel - 1,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        _projection = old._projection,
        scale = 1,
        focalPoint = null,
        boundingBox = old.boundingBox,
        _leftUpper = old._leftUpper,
        _center = old._center,
        _lastMapDimension = old._lastMapDimension;

  MapViewPosition.setIndoorLevel(MapViewPosition old, int indoorLevel)
      : _latitude = old._latitude,
        _longitude = old._longitude,
        zoomLevel = old.zoomLevel,
        this.indoorLevel = indoorLevel,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        _projection = old._projection,
        scale = 1,
        focalPoint = null,
        boundingBox = old.boundingBox,
        _leftUpper = old._leftUpper,
        _center = old._center,
        _lastMapDimension = old._lastMapDimension;

  ///
  /// sets the new scale relative to the current zoomlevel. A scale of 1 means no action,
  /// 0..1 means zoom-out (you will see more area on screen since at pinch-to-zoom the fingers are moved towards each other)
  /// >1 means zoom-in.
  /// Scaling is different from zooming. Scaling is used during pinch-to-zoom gesture to scale the current area. Zooming triggers new tile-images. Scaling does not.
  MapViewPosition.scaleAround(MapViewPosition old, this.focalPoint, this.scale)
      : assert(scale > 0),
        _latitude = old._latitude,
        _longitude = old._longitude,
        this.zoomLevel = old.zoomLevel,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        indoorLevel = old.indoorLevel,
        _center = old._center,
        _projection = old._projection,
        _lastMapDimension = old._lastMapDimension;

  MapViewPosition.move(MapViewPosition old, this._latitude, this._longitude)
      : zoomLevel = old.zoomLevel,
        indoorLevel = old.indoorLevel,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        _projection = old._projection,
        scale = old.scale,
        focalPoint = old.focalPoint,
        assert(_latitude == null),
        assert(_longitude == null),
        _lastMapDimension = old._lastMapDimension;

  MapViewPosition.rotate(MapViewPosition old, this._rotation)
      : _latitude = old._latitude,
        _longitude = old._longitude,
        zoomLevel = old.zoomLevel,
        indoorLevel = old.indoorLevel,
        _projection = old._projection,
        scale = old.scale,
        focalPoint = old.focalPoint,
        _rotationRadian = Projection.degToRadian(_rotation),
        _center = old._center,
        assert(_rotation >= 0 && _rotation < 360),
        _lastMapDimension = old._lastMapDimension;

  MapViewPosition.setLeftUpper(
      MapViewPosition old, double left, double upper, Dimension mapDimension)
      : zoomLevel = old.zoomLevel,
        indoorLevel = old.indoorLevel,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        scale = old.scale,
        focalPoint = old.focalPoint,
        _projection = old._projection,
        _lastMapDimension = mapDimension {
    //calculateBoundingBox(tileSize, viewSize);
    _leftUpper = Mappoint(
        min(max(left, -mapDimension.width / 2),
            _projection.mapsize - mapDimension.width / 2),
        min(max(upper, -mapDimension.height / 2),
            _projection.mapsize - mapDimension.height / 2));

    ILatLong latLong = _projection.pixelToLatLong(_leftUpper!.x + mapDimension.width / 2, _leftUpper!.y + mapDimension.height / 2);
    _latitude = latLong.latitude;
    _longitude = latLong.longitude;
  }

  MapViewPosition.setCenter(MapViewPosition old, double x, double y)
      : zoomLevel = old.zoomLevel,
        indoorLevel = old.indoorLevel,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        scale = old.scale,
        focalPoint = old.focalPoint,
        _projection = old._projection,
        _lastMapDimension = old._lastMapDimension {
    _center = Mappoint(min(max(x, 0), _projection.mapsize + 0.0),
        min(max(y, 0), _projection.mapsize + 0.0));
    _leftUpper = null;

    _latitude = _projection.pixelYToLatitude(y);
    _longitude = _projection.pixelXToLongitude(x);
  }

  bool hasPosition() {
    return _latitude != null && _longitude != null;
  }

  /// Calculates the bounding box of the given dimensions of the view. Scaling or focalPoint are NOT considered.
  BoundingBox calculateBoundingBox(Dimension mapDimension) {
    if (boundingBox != null && _lastMapDimension == mapDimension)
      return boundingBox!;
    Mappoint center = getCenter();
    double leftX = center.x - mapDimension.width / 2;
    double rightX = center.x + mapDimension.width / 2;
    double topY = center.y - mapDimension.height / 2;
    double bottomY = center.y + mapDimension.height / 2;
    boundingBox = BoundingBox(
        _projection
            .pixelYToLatitude(min(bottomY, _projection.mapsize.toDouble())),
        _projection.pixelXToLongitude(max(leftX, 0)),
        _projection.pixelYToLatitude(max(topY, 0)),
        _projection
            .pixelXToLongitude(min(rightX, _projection.mapsize.toDouble())));
    _leftUpper = Mappoint(leftX, topY);
    _lastMapDimension = mapDimension;
    return boundingBox!;
  }

  PixelProjection get projection => _projection;

  /// returns the absoulute pixel-coordinates of the left-upper point of the mapview.
  /// Since this is confusing while rotating the map we encourage you to use center()
  /// instead and calculate everything from there.
  @Deprecated("Use getCenter() instead if possible")
  Mappoint getLeftUpper(Dimension mapDimension) {
    if (_leftUpper != null && _lastMapDimension == mapDimension)
      return _leftUpper!;
    calculateBoundingBox(mapDimension);
    return _leftUpper!;
  }

  /// The latitude of the center of the widget
  double? get latitude => _latitude;

  /// The longitude of the center of the widget
  double? get longitude => _longitude;

  /// Returns the center of the map in absolute mappixels
  Mappoint getCenter() {
    if (_center != null) return _center!;
    _center = _projection.latLonToPixel(LatLong(_latitude!, _longitude!));
    return _center!;
  }

  /// Returns the rotation in radians
  double get rotationRadian => _rotationRadian;

  /// Returns the rotation of the map in degrees clockwise
  double get rotation => _rotation;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapViewPosition &&
          runtimeType == other.runtimeType &&
          _latitude == other._latitude &&
          _longitude == other._longitude &&
          zoomLevel == other.zoomLevel &&
          indoorLevel == other.indoorLevel &&
          _rotation == other._rotation &&
          scale == other.scale;

  @override
  int get hashCode =>
      _latitude.hashCode ^
      _longitude.hashCode ^
      zoomLevel.hashCode ^
      _rotation.hashCode ^
      indoorLevel.hashCode << 5 ^
      scale.hashCode;

  @override
  String toString() {
    return 'MapViewPosition{_latitude: $_latitude, _longitude: $_longitude, zoomLevel: $zoomLevel, indoorLevel: $indoorLevel, scale: $scale}';
  }
}
