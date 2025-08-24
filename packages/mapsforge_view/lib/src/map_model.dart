import 'dart:ui';

import 'package:dart_common/model.dart';
import 'package:datastore_renderer/renderer.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:rxdart/rxdart.dart';

class MapModel {
  final Renderer renderer;

  MapPosition? _lastPosition;

  final ZoomlevelRange zoomlevelRange;

  /// Inform a listener about the last known position, hence using the [BehaviorSubject].
  final Subject<MapPosition> _positionSubject = BehaviorSubject<MapPosition>();

  MapModel({required this.renderer, this.zoomlevelRange = const ZoomlevelRange.standard()});

  void dispose() {
    _positionSubject.close();
  }

  void setPosition(MapPosition position) {
    _lastPosition = position;
    _positionSubject.add(position);
  }

  MapPosition? get lastPosition => _lastPosition;

  Stream<MapPosition> get positionStream => _positionSubject.stream;

  void zoomIn() {
    if (_lastPosition!.zoomLevel == zoomlevelRange.zoomlevelMax) return;
    MapPosition newPosition = _lastPosition!.zoomIn();
    setPosition(newPosition);
  }

  void zoomInAround(double latitude, double longitude) {
    if (_lastPosition!.zoomLevel == zoomlevelRange.zoomlevelMax) return;
    MapPosition newPosition = _lastPosition!.zoomInAround(latitude, longitude);
    setPosition(newPosition);
  }

  void zoomOut() {
    if (_lastPosition!.zoomLevel == zoomlevelRange.zoomlevelMin) return;
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
