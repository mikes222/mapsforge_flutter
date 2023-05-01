import 'dart:math';

import 'package:mapsforge_flutter/src/model/dimension.dart';

import '../../maps.dart';
import 'boundingbox.dart';
import 'mappoint.dart';

class MapViewPosition {
  /// The latitude of the center of the widget
  double? _latitude;

  /// The longitude of the center of the widget
  double? _longitude;

  /// The size of a tile in pixel
  final int tileSize;

  /// The current zoomLevel
  final int zoomLevel;

  /// The current indoorLevel
  final int indoorLevel;

  final double scale;

  /// The focal point. Used when pinch-and-zoom to know the center of the zoom
  final Mappoint? focalPoint;

  /// the latitude/longitude boundaries of the current map view.
  /// This property must be calculated if needed based on the current view
  BoundingBox? boundingBox;

  // the left/upper corner of the current mapview in pixels in relation to the current lat/lon.
  Mappoint? _leftUpper;

  /// The center of the map in absolute pixel coordinates. Note that the center
  /// needs to be recalculated if the map moves OR if the map zooms
  Mappoint? _center;

  /// orientation of the map in clockwise direction 0-360°. 360 is excluded
  final double _rotation;

  final double _rotationRadian;

  final PixelProjection _projection;

  MapViewPosition(this._latitude, this._longitude, this.zoomLevel,
      this.indoorLevel, this.tileSize, this._rotation)
      : scale = 1,
        focalPoint = null,
        _rotationRadian = Projection.degToRadian(_rotation),
        assert(zoomLevel >= 0),
        assert(tileSize > 0),
        _projection = PixelProjection(zoomLevel, tileSize);

  MapViewPosition.zoomIn(MapViewPosition old)
      : _latitude = old._latitude,
        _longitude = old._longitude,
        zoomLevel = old.zoomLevel + 1,
        indoorLevel = old.indoorLevel,
        tileSize = old.tileSize,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        scale = 1,
        focalPoint = null,
        _projection = PixelProjection(old.zoomLevel + 1, old.tileSize);

  MapViewPosition.zoomInAround(MapViewPosition old, double latitude,
      double longitude)
      : _latitude = latitude,
        _longitude = longitude,
        zoomLevel = old.zoomLevel + 1,
        indoorLevel = old.indoorLevel,
        tileSize = old.tileSize,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        scale = 1,
        focalPoint = null,
        _projection = PixelProjection(old.zoomLevel + 1, old.tileSize);

  MapViewPosition.zoomOut(MapViewPosition old)
      : _latitude = old._latitude,
        _longitude = old._longitude,
        zoomLevel = max(old.zoomLevel - 1, 0),
        indoorLevel = old.indoorLevel,
        tileSize = old.tileSize,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        scale = 1,
        focalPoint = null,
        _projection = PixelProjection(max(old.zoomLevel - 1, 0), old.tileSize);

  MapViewPosition.zoom(MapViewPosition old, int zoomLevel)
      : _latitude = old._latitude,
        _longitude = old._longitude,
        this.zoomLevel = max(zoomLevel, 0),
        indoorLevel = old.indoorLevel,
        tileSize = old.tileSize,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        scale = 1,
        focalPoint = null,
        _projection = PixelProjection(max(zoomLevel, 0), old.tileSize);

  MapViewPosition.zoomAround(MapViewPosition old, double latitude,
      double longitude, int zoomLevel)
      : _latitude = latitude,
        _longitude = longitude,
        this.zoomLevel = max(zoomLevel, 0),
        indoorLevel = old.indoorLevel,
        tileSize = old.tileSize,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        scale = 1,
        focalPoint = null,
        _projection = PixelProjection(max(zoomLevel, 0), old.tileSize);

  MapViewPosition.indoorLevelUp(MapViewPosition old)
      : _latitude = old._latitude,
        _longitude = old._longitude,
        zoomLevel = old.zoomLevel,
        indoorLevel = old.indoorLevel + 1,
        tileSize = old.tileSize,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        _projection = old._projection,
        scale = 1,
        focalPoint = null,
        boundingBox = old.boundingBox,
        _leftUpper = old._leftUpper,
        _center = old._center;

  MapViewPosition.indoorLevelDown(MapViewPosition old)
      : _latitude = old._latitude,
        _longitude = old._longitude,
        zoomLevel = old.zoomLevel,
        indoorLevel = old.indoorLevel - 1,
        tileSize = old.tileSize,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        _projection = old._projection,
        scale = 1,
        focalPoint = null,
        boundingBox = old.boundingBox,
        _leftUpper = old._leftUpper,
        _center = old._center;

  MapViewPosition.setIndoorLevel(MapViewPosition old, int indoorLevel)
      : _latitude = old._latitude,
        _longitude = old._longitude,
        zoomLevel = old.zoomLevel,
        this.indoorLevel = indoorLevel,
        tileSize = old.tileSize,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        _projection = old._projection,
        scale = 1,
        focalPoint = null,
        boundingBox = old.boundingBox,
        _leftUpper = old._leftUpper,
        _center = old._center;

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
        tileSize = old.tileSize,
        _center = old._center,
        _projection = old._projection;

  MapViewPosition.move(MapViewPosition old, this._latitude, this._longitude)
      : zoomLevel = old.zoomLevel,
        indoorLevel = old.indoorLevel,
        tileSize = old.tileSize,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        _projection = old._projection,
        scale = old.scale,
        focalPoint = old.focalPoint,
        assert(_latitude == null),
        assert(_longitude == null);

  MapViewPosition.rotate(MapViewPosition old, this._rotation)
      : _latitude = old._latitude,
        _longitude = old._longitude,
        zoomLevel = old.zoomLevel,
        indoorLevel = old.indoorLevel,
        tileSize = old.tileSize,
        _projection = old._projection,
        scale = old.scale,
        focalPoint = old.focalPoint,
        _rotationRadian = Projection.degToRadian(_rotation),
        _center = old._center,
        assert(_rotation >= 0 && _rotation < 360);

  MapViewPosition.setLeftUpper(MapViewPosition old, double left, double upper,
      Dimension viewDimension)
      : zoomLevel = old.zoomLevel,
        indoorLevel = old.indoorLevel,
        tileSize = old.tileSize,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        scale = old.scale,
        focalPoint = old.focalPoint,
        _projection = old._projection {
    //calculateBoundingBox(tileSize, viewSize);
    _leftUpper = Mappoint(
        min(max(left, -viewDimension.width / 2),
            _projection.mapsize - viewDimension.width / 2),
        min(max(upper, -viewDimension.height / 2),
            _projection.mapsize - viewDimension.height / 2));

    // double rightX = _leftUpper!.x + viewDimension.width;
    // double bottomY = _leftUpper!.y + viewDimension.height;

    // boundingBox = BoundingBox(
    //     _projection
    //         .pixelYToLatitude(min(bottomY, _projection.mapsize.toDouble())),
    //     _projection.pixelXToLongitude(max(_leftUpper!.x, 0)),
    //     _projection.pixelYToLatitude(max(_leftUpper!.y, 0)),
    //     _projection
    //         .pixelXToLongitude(min(rightX, _projection.mapsize.toDouble())));

    _latitude =
        _projection.pixelYToLatitude(_leftUpper!.y + viewDimension.height / 2);

    _longitude =
        _projection.pixelXToLongitude(_leftUpper!.x + viewDimension.width / 2);

    // Projection.checkLatitude(_latitude!);
    // Projection.checkLongitude(_longitude!);
  }

  MapViewPosition.setCenter(MapViewPosition old, double left, double upper,
      Dimension viewDimension)
      : zoomLevel = old.zoomLevel,
        indoorLevel = old.indoorLevel,
        tileSize = old.tileSize,
        _rotation = old._rotation,
        _rotationRadian = old._rotationRadian,
        scale = old.scale,
        focalPoint = old.focalPoint,
        _projection = old._projection {
    _center = Mappoint(
        min(max(left, -viewDimension.width / 2),
            _projection.mapsize - viewDimension.width / 2),
        min(max(upper, -viewDimension.height / 2),
            _projection.mapsize - viewDimension.height / 2));
    _leftUpper = null;

    _latitude = _projection.pixelYToLatitude(upper);
    _longitude = _projection.pixelXToLongitude(left);
  }

  /// called if the size of the view has been changed. The boundingBox needs to be
  /// destroyed then as well as the _leftUpper variable.
  void sizeChanged() {
    _leftUpper = null;
    _center = null;
    boundingBox = null;
  }

  bool hasPosition() {
    return _latitude != null && _longitude != null;
  }

  /// Calculates the bounding box of the given dimensions of the view. Scaling or focalPoint are NOT considered.
  BoundingBox calculateBoundingBox(Dimension mapDimension) {
    if (boundingBox != null) return boundingBox!;
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
    return boundingBox!;
  }

  PixelProjection get projection => _projection;

  /// returns the absoulute pixel-coordinates of the left-upper point of the mapview.
  /// Since this is confusing while rotating the map we encourage you to use center()
  /// instead and calculate everything from there.
  @Deprecated("Use getCenter() instead if possible")
  Mappoint getLeftUpper(Dimension mapDimension) {
    if (_leftUpper != null) return _leftUpper!;
    calculateBoundingBox(mapDimension);
    return _leftUpper!;
  }

  /// The latitude of the center of the widget
  double? get latitude => _latitude;

  /// The longitude of the center of the widget
  double? get longitude => _longitude;

  /// Returns the center of the map in absolute pixels
  Mappoint getCenter() {
    if (_center != null) return _center!;
    double centerY = _projection.latitudeToPixelY(_latitude!);
    double centerX = _projection.longitudeToPixelX(_longitude!);
    _center = Mappoint(centerX, centerY);
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
    return 'MapViewPosition{_latitude: $_latitude, _longitude: $_longitude, _tileSize: $tileSize, zoomLevel: $zoomLevel, indoorLevel: $indoorLevel, scale: $scale}';
  }
}
