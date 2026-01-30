import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:rxdart/rxdart.dart';

class MapModel extends ChangeNotifier {
  final List<Renderer> _renderers = [];

  MapPosition? _lastPosition;

  final ZoomlevelRange zoomlevelRange;

  /// Inform a listener about the last known position even if he was not listening at the time, hence using the [BehaviorSubject].
  final Subject<MapPosition> _positionSubject = BehaviorSubject<MapPosition>();

  final Subject<Object> _manualMoveSubject = PublishSubject<Object>();

  final Subject<TapEvent?> _tapSubject = PublishSubject();

  final Subject<TapEvent?> _longTapSubject = PublishSubject();

  final Subject<TapEvent?> _doubleTapSubject = PublishSubject();

  final Subject<DragNdropEvent> _dragNdropSubject = PublishSubject();

  final Subject<RenderChangedEvent> _renderChangedSubject = PublishSubject();

  /// When using the context menu we often needs the markers which are tapped. To simplify that we register/unregister datastores to the map.
  final Set<MarkerDatastore> _markerDatastores = {};

  @Deprecated("Since 4.0.1. Use MapModel itself instead of MapModel.rotationNotifier for listening to map-changes")
  final ValueNotifier<double> rotationNotifier = ValueNotifier<double>(0.0);

  double get rotationDeg => _lastPosition?.rotation ?? 0.0;

  MapModel({required Renderer renderer, this.zoomlevelRange = const ZoomlevelRange.standard()}) {
    _renderers.add(renderer);
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await _positionSubject.close();
    await _manualMoveSubject.close();
    await _tapSubject.close();
    await _longTapSubject.close();
    await _doubleTapSubject.close();
    await _dragNdropSubject.close();
    for (var renderer in _renderers) {
      renderer.dispose();
    }
    _renderers.clear();
    rotationNotifier.dispose();
    for (var datastore in List.of(_markerDatastores)) {
      datastore.dispose();
    }
    _markerDatastores.clear();
  }

  void addRenderer(Renderer renderer) {
    _renderers.add(renderer);
  }

  List<Renderer> get renderers => _renderers;

  Iterable<Renderer> get labelRenderers => _renderers.where((test) => test.supportLabels());

  List<Marker> getTappedMarkers(TapEvent event) {
    List<Marker> tappedMarkers = [];
    for (var datastore in _markerDatastores) {
      tappedMarkers.addAll(datastore.getTappedMarkers(event));
    }
    return tappedMarkers;
  }

  void setPosition(MapPosition position) {
    _lastPosition = position;
    _positionSubject.add(position);
    rotationNotifier.value = _normalize180(position.rotation);
    notifyListeners();
  }

  double _normalize180(double deg) {
    deg = deg % 360;
    if (deg >= 180) deg -= 360;
    if (deg < -180) deg += 360;
    return deg;
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

  Stream<DragNdropEvent> get dragNdropStream => _dragNdropSubject.stream;

  /// Listens to [RenderChangedEvent] events.
  /// @see [RenderChangedEvent]
  Stream<RenderChangedEvent> get renderChangedStream => _renderChangedSubject.stream;

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

  void dragNdrop(DragNdropEvent event) {
    _dragNdropSubject.add(event);
  }

  /// Triggers a [RenderChangedEvent] event.
  /// @see [RenderChangedEvent]
  void renderChanged(RenderChangedEvent event) {
    _renderChangedSubject.add(event);
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
    if (zoomLevel == _lastPosition!.zoomlevel) return;
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

  /// Moves to a new latitude and longitude. There must already be a position set.
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

  /// Moves to a new latitude and longitude and rotates to a specific angle in degrees clockwise.
  void moveRotateTo(double latitude, double longitude, double rotation) {
    MapPosition newPosition = _lastPosition!.moveRotateTo(latitude, longitude, rotation);
    setPosition(newPosition);
  }

  /// Sets the center of the mapmodel to the given coordinates in mappixel. There must already be a position set.
  void setCenter(double x, double y) {
    MapPosition newPosition = _lastPosition!.setCenter(x, y);
    setPosition(newPosition);
  }

  /// Moves the center of the map in relative pixel coordinates.
  void moveCenter(double dx, double dy) {
    MapPosition newPosition = _lastPosition!.moveCenter(dx, dy);
    setPosition(newPosition);
  }

  void registerMarkerDatastore(MarkerDatastore datastore) {
    _markerDatastores.add(datastore);
  }

  void unregisterMarkerDatastore(MarkerDatastore datastore) {
    _markerDatastores.remove(datastore);
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

class DragNdropEvent extends TapEvent {
  final DragNdropEventType type;

  DragNdropEvent({required super.latitude, required super.longitude, required super.projection, required super.mappoint, required this.type});
}

//////////////////////////////////////////////////////////////////////////////

enum DragNdropEventType {
  /// Drag'n'drop started
  start,

  /// Drag'n'drop cancelled, for example because the user moved outside of the view
  cancel,

  /// Drag'n'drop moved
  move,

  /// Drag'n'drop finished
  finish,
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

//////////////////////////////////////////////////////////////////////////////

/// Event which is triggered when a part of the render area (hence a part of the map) has been changed so that a rerender is required.
/// This forces eventual caches to revalidate and redraw the screen if the
/// currently shown area is affected.
/// This may occur if a [MultimapDatastore] adds or removes datastores or if the user changes the desired [StyleMenuLayer].
class RenderChangedEvent {
  final BoundingBox boundingBox;

  RenderChangedEvent(this.boundingBox);
}
