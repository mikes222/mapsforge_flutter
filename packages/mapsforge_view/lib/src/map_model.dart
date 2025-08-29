import 'dart:ui';

import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:datastore_renderer/renderer.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:rxdart/rxdart.dart';

class MapModel {
  final Renderer renderer;

  MapPosition? _lastPosition;

  final ZoomlevelRange zoomlevelRange;

  /// Inform a listener about the last known position even if he was not listening at the time, hence using the [BehaviorSubject].
  final Subject<MapPosition> _positionSubject = BehaviorSubject<MapPosition>();

  final Subject<Object> _manualMoveSubject = PublishSubject<Object>();

  final Subject<TapEvent?> _tapSubject = PublishSubject();

  final Subject<TapEvent?> _longTapSubject = PublishSubject();

  final Subject<TapEvent?> _doubleTapSubject = PublishSubject();

  MapModel({required this.renderer, this.zoomlevelRange = const ZoomlevelRange.standard()});

  void dispose() {
    _positionSubject.close();
    _manualMoveSubject.close();
    _tapSubject.close();
    _longTapSubject.close();
    _doubleTapSubject.close();
    renderer.dispose();
  }

  void setPosition(MapPosition position) {
    _lastPosition = position;
    _positionSubject.add(position);
  }

  MapPosition? get lastPosition => _lastPosition;

  Stream<MapPosition> get positionStream => _positionSubject.stream;

  /// A stream which triggers an event if the user starts to move the map. This can be used to switch off automatic movements
  Stream<Object> get manualMoveStream => _manualMoveSubject.stream;

  /// A stream which triggers an event if the user taps at the map. Sending a null value down the stream means that the listener is not
  /// entitled to handle the event anymore. This is currently being used to hide the context menu.
  Stream<TapEvent?> get tapStream => _tapSubject.stream;

  /// A stream which triggers an event if the user long taps at the map. Sending a null value down the stream means that the listener is not
  /// entitled to handle the event anymore. This is currently being used to hide the context menu.
  Stream<TapEvent?> get longTapStream => _longTapSubject.stream;

  /// A stream which triggers an event if the user double-taps at the map. Sending a null value down the stream means that the listener is not
  /// entitled to handle the event anymore. This is currently being used to hide the context menu.
  Stream<TapEvent?> get doubleTapStream => _doubleTapSubject.stream;

  void manualMove(Object object) {
    _manualMoveSubject.add(object);
  }

  /// sets or clears a tap event. Clearing a tap event usually means that the context menu should not be shown anymore
  void tap(TapEvent? event) {
    _tapSubject.add(event);
  }

  void longTap(TapEvent? event) {
    _longTapSubject.add(event);
  }

  void doubleTap(TapEvent? event) {
    _doubleTapSubject.add(event);
  }

  void zoomIn() {
    if (_lastPosition!.zoomlevel == zoomlevelRange.zoomlevelMax) return;
    MapPosition newPosition = _lastPosition!.zoomIn();
    setPosition(newPosition);
  }

  void zoomInAround(double latitude, double longitude) {
    if (_lastPosition!.zoomlevel == zoomlevelRange.zoomlevelMax) return;
    MapPosition newPosition = _lastPosition!.zoomInAround(latitude, longitude);
    setPosition(newPosition);
  }

  void zoomOut() {
    if (_lastPosition!.zoomlevel == zoomlevelRange.zoomlevelMin) return;
    MapPosition newPosition = _lastPosition!.zoomOut();
    setPosition(newPosition);
  }

  void zoomTo(int zoomLevel) {
    zoomLevel = zoomlevelRange.ensureBounds(zoomLevel);
    MapPosition newPosition = _lastPosition!.zoomTo(zoomLevel);
    setPosition(newPosition);
  }

  void zoomToAround(double latitude, double longitude, int zoomLevel) {
    zoomLevel = zoomlevelRange.ensureBounds(zoomLevel);
    MapPosition newPosition = _lastPosition!.zoomToAround(latitude, longitude, zoomLevel);
    setPosition(newPosition);
  }

  void indoorLevelUp() {
    MapPosition newPosition = _lastPosition!.indoorLevelUp();
    setPosition(newPosition);
  }

  void indoorLevelDown() {
    MapPosition newPosition = _lastPosition!.indoorLevelDown();
    setPosition(newPosition);
  }

  void setIndoorLevel(int level) {
    MapPosition newPosition = _lastPosition!.withIndoorLevel(level);
    setPosition(newPosition);
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
  void scaleAround(Offset? focalPoint, double scale) {
    MapPosition newPosition = _lastPosition!.scaleAround(focalPoint, scale);
    setPosition(newPosition);
  }

  void moveTo(double latitude, double longitude) {
    MapPosition newPosition = _lastPosition!.moveTo(latitude, longitude);
    setPosition(newPosition);
  }

  void rotateTo(double rotation) {
    MapPosition newPosition = _lastPosition!.rotateTo(rotation);
    setPosition(newPosition);
  }

  void rotateBy(double rotationDelta) {
    MapPosition newPosition = _lastPosition!.rotateBy(rotationDelta);
    setPosition(newPosition);
  }

  void setCenter(double x, double y) {
    MapPosition newPosition = _lastPosition!.setCenter(x, y);
    setPosition(newPosition);
  }
}

/////////////////////////////////////////////////////////////////////////////

/// Event which is triggered when the user taps at the map
class TapEvent implements ILatLong {
  // The position of the event in lat direction (north-south)
  @override
  final double latitude;

  // The position of the event in lon direction (east-west)
  @override
  final double longitude;

  final PixelProjection projection;

  /// The point of the event in absolute mappixels
  final Mappoint mappoint;

  const TapEvent({required this.latitude, required this.longitude, required this.projection, required this.mappoint});

  LatLong get latLong => LatLong(latitude, longitude);

  @override
  String toString() {
    return 'TapEvent{latitude: $latitude, longitude: $longitude, mappoint: $mappoint}';
  }
}

//////////////////////////////////////////////////////////////////////////////

enum TapEventListener {
  /// listen to single tap events
  singleTap,

  /// listen to double tap events
  doubleTap,

  /// listen to long tap events
  longTap;

  Stream<TapEvent?> getStream(MapModel mapModel) {
    switch (this) {
      case TapEventListener.singleTap:
        return mapModel.tapStream;
      case TapEventListener.doubleTap:
        return mapModel.doubleTapStream;
      case TapEventListener.longTap:
        return mapModel.longTapStream;
    }
  }
}
