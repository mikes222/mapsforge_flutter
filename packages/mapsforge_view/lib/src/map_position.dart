import 'dart:math';
import 'dart:ui';

import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';

/// Immutable position of the map
class MapPosition {
  /// The latitude of the center of the widget
  final double _latitude;

  /// The longitude of the center of the widget
  final double _longitude;

  /// The current zoomLevel
  final int zoomLevel;

  /// The current indoorLevel
  final int indoorLevel;

  final double scale;

  /// orientation of the map in clockwise direction 0-360°. 0° is north, 360° is excluded.
  final double _rotation;

  final double _rotationRadian;

  /// The focal point. Used when pinch-and-zoom to know the center of the zoom
  final Offset? focalPoint;

  /// The center of the map in absolute pixel coordinates. Note that the center
  /// needs to be recalculated if the map moves OR if the map zooms
  Mappoint? _center;

  final PixelProjection _projection;

  MapPosition._({
    required double latitude,
    required double longitude,
    required this.zoomLevel,
    required this.indoorLevel,
    required this.scale,
    required double rotation,
    required double rotationRadian,
    required this.focalPoint,
    Mappoint? center,
    required PixelProjection projection,
  }) : _latitude = latitude,
       _longitude = longitude,
       _rotation = rotation,
       _rotationRadian = rotationRadian,
       _center = center,
       _projection = projection;

  MapPosition(this._latitude, this._longitude, this.zoomLevel, [this.indoorLevel = 0, this._rotation = 0])
    : scale = 1,
      focalPoint = null,
      _rotationRadian = Projection.degToRadian(_rotation),
      assert(zoomLevel >= 0),
      _projection = PixelProjection(zoomLevel);

  MapPosition zoomIn() {
    return MapPosition._(
      latitude: _latitude,
      longitude: _longitude,
      zoomLevel: zoomLevel + 1,
      indoorLevel: indoorLevel,
      rotation: _rotation,
      rotationRadian: _rotationRadian,
      scale: 1,
      focalPoint: null,
      projection: PixelProjection(zoomLevel + 1),
    );
  }

  /// Zooms in around a specific latitude and longitude point.
  MapPosition zoomInAround(double latitude, double longitude) {
    return MapPosition._(
      latitude: latitude,
      longitude: longitude,
      zoomLevel: zoomLevel + 1,
      indoorLevel: indoorLevel,
      rotation: _rotation,
      rotationRadian: _rotationRadian,
      scale: 1,
      focalPoint: null,
      projection: PixelProjection(zoomLevel + 1),
    );
  }

  /// Zooms out from the current position.
  MapPosition zoomOut() {
    final newZoomLevel = max(zoomLevel - 1, 0);
    return MapPosition._(
      latitude: _latitude,
      longitude: _longitude,
      zoomLevel: newZoomLevel,
      indoorLevel: indoorLevel,
      rotation: _rotation,
      rotationRadian: _rotationRadian,
      scale: 1,
      focalPoint: null,
      projection: PixelProjection(newZoomLevel),
    );
  }

  /// Zooms to a specific zoom level.
  MapPosition zoomTo(int newZoomLevel) {
    final clampedZoom = max(newZoomLevel, 0);
    return MapPosition._(
      latitude: _latitude,
      longitude: _longitude,
      zoomLevel: clampedZoom,
      indoorLevel: indoorLevel,
      rotation: _rotation,
      rotationRadian: _rotationRadian,
      scale: 1,
      focalPoint: null,
      projection: PixelProjection(clampedZoom),
    );
  }

  /// Zooms to a specific level around a given latitude and longitude.
  MapPosition zoomToAround(double latitude, double longitude, int newZoomLevel) {
    final clampedZoom = max(newZoomLevel, 0);
    return MapPosition._(
      latitude: latitude,
      longitude: longitude,
      zoomLevel: clampedZoom,
      indoorLevel: indoorLevel,
      rotation: _rotation,
      rotationRadian: _rotationRadian,
      scale: 1,
      focalPoint: null,
      projection: PixelProjection(clampedZoom),
    );
  }

  /// Increases the indoor level by 1.
  MapPosition indoorLevelUp() {
    return MapPosition._(
      latitude: _latitude,
      longitude: _longitude,
      zoomLevel: zoomLevel,
      indoorLevel: indoorLevel + 1,
      rotation: _rotation,
      rotationRadian: _rotationRadian,
      scale: 1,
      focalPoint: null,
      projection: _projection,
      center: _center,
    );
  }

  /// Decreases the indoor level by 1.
  MapPosition indoorLevelDown() {
    return MapPosition._(
      latitude: _latitude,
      longitude: _longitude,
      zoomLevel: zoomLevel,
      indoorLevel: indoorLevel - 1,
      rotation: _rotation,
      rotationRadian: _rotationRadian,
      scale: 1,
      focalPoint: null,
      projection: _projection,
      center: _center,
    );
  }

  /// Sets a specific indoor level.
  MapPosition withIndoorLevel(int level) {
    return MapPosition._(
      latitude: _latitude,
      longitude: _longitude,
      zoomLevel: zoomLevel,
      indoorLevel: level,
      rotation: _rotation,
      rotationRadian: _rotationRadian,
      scale: 1,
      focalPoint: null,
      projection: _projection,
      center: _center,
    );
  }

  /// Sets the scale around a focal point.
  ///
  /// [focalPoint] The point to scale around.
  /// [scale] The new scale value. Must be greater than 0.
  /// A scale of 1 means no action,
  /// 0..1 means zoom-out (you will see more area on screen since at pinch-to-zoom the fingers are moved towards each other)
  /// >1 means zoom-in.
  /// Scaling is different from zooming. Scaling is used during pinch-to-zoom gesture to scale the current area.
  /// Zooming triggers new tile-images. Scaling does not.
  MapPosition scaleAround(Offset? focalPoint, double scale) {
    assert(scale > 0, 'Scale must be greater than 0');
    return MapPosition._(
      latitude: _latitude,
      longitude: _longitude,
      zoomLevel: zoomLevel,
      indoorLevel: indoorLevel,
      rotation: _rotation,
      rotationRadian: _rotationRadian,
      scale: scale,
      focalPoint: focalPoint,
      projection: _projection,
      center: _center,
    );
  }

  /// Moves to a new latitude and longitude.
  MapPosition moveTo(double latitude, double longitude) {
    return MapPosition._(
      latitude: latitude,
      longitude: longitude,
      zoomLevel: zoomLevel,
      indoorLevel: indoorLevel,
      rotation: _rotation,
      rotationRadian: _rotationRadian,
      scale: scale,
      focalPoint: null,
      projection: _projection,
    );
  }

  /// Rotates to a specific angle in degrees clockwise.
  ///
  /// [rotation] The new rotation angle in degrees. Must be between 0 (inclusive) and 360 (exclusive).
  MapPosition rotateTo(double rotation) {
    assert(rotation >= 0 && rotation < 360, 'Rotation must be between 0 and 360: $rotation');
    return MapPosition._(
      latitude: _latitude,
      longitude: _longitude,
      zoomLevel: zoomLevel,
      indoorLevel: indoorLevel,
      rotation: rotation,
      rotationRadian: Projection.degToRadian(rotation),
      scale: scale,
      focalPoint: null,
      projection: _projection,
      center: _center,
    );
  }

  /// Rotates by a delta angle in degrees clockwise.
  MapPosition rotateBy(double rotationDelta) {
    final newRotation = Projection.normalizeRotation(_rotation + rotationDelta);
    return MapPosition._(
      latitude: _latitude,
      longitude: _longitude,
      zoomLevel: zoomLevel,
      indoorLevel: indoorLevel,
      rotation: newRotation,
      rotationRadian: Projection.degToRadian(newRotation),
      scale: scale,
      focalPoint: null,
      projection: _projection,
      center: _center,
    );
  }

  MapPosition setCenter(double x, double y) {
    return MapPosition._(
      latitude: _projection.pixelYToLatitude(y),
      longitude: _projection.pixelXToLongitude(x),
      zoomLevel: zoomLevel,
      indoorLevel: indoorLevel,
      rotation: _rotation,
      rotationRadian: _rotationRadian,
      scale: scale,
      focalPoint: null,
      projection: _projection,
      center: Mappoint(x, y),
    );
  }

  PixelProjection get projection => _projection;

  /// The latitude of the center of the widget
  double? get latitude => _latitude;

  /// The longitude of the center of the widget
  double? get longitude => _longitude;

  /// Returns the center of the map in absolute mappixels
  Mappoint getCenter() {
    if (_center != null) return _center!;
    _center = _projection.latLonToPixel(LatLong(_latitude, _longitude));
    return _center!;
  }

  /// Returns the rotation in radians
  double get rotationRadian => _rotationRadian;

  /// Returns the rotation of the map in degrees clockwise
  double get rotation => _rotation;

  @override
  String toString() {
    return 'MapPosition{_latitude: $_latitude, _longitude: $_longitude, zoomLevel: $zoomLevel, indoorLevel: $indoorLevel, _rotation: $_rotation, focalPoint: $focalPoint, _center: $_center}';
  }
}
