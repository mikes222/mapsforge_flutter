import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/model/dimension.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/projection/scalefactor.dart';
import 'package:rxdart/rxdart.dart';

class ViewModel {
  Widget? noPositionView;
  MapViewPosition? _mapViewPosition;
  final DisplayModel displayModel;
  ContextMenuBuilder? contextMenuBuilder;

  /// Overlays to the map. Overlays can show things which do not move along with the map. Examples for overlays are zoombuttons.
  List<Widget>? overlays;

  ///
  /// The width and height of the view in pixels
  ///
  Dimension? _viewDimension;

  Subject<MapViewPosition> _injectPosition = PublishSubject();

  Stream<MapViewPosition> get observePosition => _injectPosition.stream;

  Subject<TapEvent> _injectTap = PublishSubject();

  Stream<TapEvent> get observeTap => _injectTap.stream;

  Subject<GestureEvent> _injectGesture = PublishSubject();

  Stream<GestureEvent> get observeGesture => _injectGesture.stream;

  ViewModel(
      {this.contextMenuBuilder,
      required this.displayModel,
      this.noPositionView,
      this.overlays}) {
    noPositionView ??= NoPositionView();
  }

  void dispose() {
    _injectPosition.close();
    _injectTap.close();
    _injectGesture.close();
  }

  MapViewPosition? get mapViewPosition => _mapViewPosition;

  void setMapViewPosition(double latitude, double longitude) {
    if (_mapViewPosition != null) {
      if (_mapViewPosition!.latitude == latitude &&
          _mapViewPosition!.longitude == longitude) return;
      MapViewPosition newPosition = MapViewPosition(
          latitude,
          longitude,
          _mapViewPosition!.zoomLevel,
          _mapViewPosition!.indoorLevel,
          displayModel.tileSize);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(
          latitude,
          longitude,
          displayModel.DEFAULT_ZOOM,
          displayModel.DEFAULT_INDOOR_LEVEL,
          displayModel.tileSize);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    }
  }

  void zoomIn() {
    assert(_mapViewPosition != null);
    if (_mapViewPosition!.zoomLevel >= displayModel.maxZoomLevel) return;
    MapViewPosition newPosition = MapViewPosition.zoomIn(_mapViewPosition!);
    _mapViewPosition = newPosition;
    _injectPosition.add(newPosition);
  }

  void zoomInAround(double latitude, double longitude) {
    assert(_mapViewPosition != null);
    if (_mapViewPosition!.zoomLevel >= displayModel.maxZoomLevel) return;
    MapViewPosition newPosition =
        MapViewPosition.zoomInAround(_mapViewPosition!, latitude, longitude);
    _mapViewPosition = newPosition;
    _injectPosition.add(newPosition);
  }

  void zoomOut() {
    assert(_mapViewPosition != null);
    if (_mapViewPosition!.zoomLevel <= 0) return;
    MapViewPosition newPosition = MapViewPosition.zoomOut(_mapViewPosition!);
    _mapViewPosition = newPosition;
    _injectPosition.add(newPosition);
  }

  MapViewPosition setZoomLevel(int zoomLevel) {
    if (zoomLevel > displayModel.maxZoomLevel)
      zoomLevel = displayModel.maxZoomLevel;
    if (zoomLevel < 0) zoomLevel = 0;
    if (_mapViewPosition != null) {
      if (_mapViewPosition!.zoomLevel == zoomLevel) return _mapViewPosition!;
      MapViewPosition newPosition =
          MapViewPosition.zoom(_mapViewPosition!, zoomLevel);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
      return newPosition;
    } else {
      MapViewPosition newPosition = MapViewPosition(null, null, zoomLevel,
          displayModel.DEFAULT_INDOOR_LEVEL, displayModel.tileSize);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
      return newPosition;
    }
  }

  void indoorLevelUp() {
    assert(_mapViewPosition != null);
    if (_mapViewPosition!.zoomLevel >= displayModel.maxZoomLevel) return;
    MapViewPosition newPosition =
        MapViewPosition.indoorLevelUp(_mapViewPosition!);
    _mapViewPosition = newPosition;
    _injectPosition.add(newPosition);
  }

  void indoorLevelDown() {
    assert(_mapViewPosition != null);
    MapViewPosition newPosition =
        MapViewPosition.indoorLevelDown(_mapViewPosition!);
    _mapViewPosition = newPosition;
    _injectPosition.add(newPosition);
  }

  MapViewPosition setIndoorLevel(int indoorLevel) {
    if (_mapViewPosition != null) {
      if (_mapViewPosition!.indoorLevel == indoorLevel)
        return _mapViewPosition!;
      MapViewPosition newPosition =
          MapViewPosition.setIndoorLevel(_mapViewPosition!, indoorLevel);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
      return newPosition;
    } else {
      MapViewPosition newPosition = MapViewPosition(null, null,
          displayModel.DEFAULT_ZOOM, indoorLevel, displayModel.tileSize);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
      return newPosition;
    }
  }

  int getIndoorLevel() {
    return _mapViewPosition?.indoorLevel ?? 0;
  }

  ///
  /// sets the new scale relative to the current zoomlevel. A scale of 1 means no action,
  /// 0..1 means zoom-out (you will see more area on screen since at pinch-to-zoom the fingers are moved towards each other)
  /// >1 means zoom-in.
  ///
  MapViewPosition? setScale(Mappoint focalPoint, double scale) {
    assert(scale > 0);
    // do not scale if the scale is too minor to do anything
    if ((scale - 1).abs() < 0.01) return _mapViewPosition;
    if (_mapViewPosition != null) {
      //print("Scaling ${_mapViewPosition.zoomLevel} * $scale");
      if (Scalefactor.zoomlevelToScalefactor(_mapViewPosition!.zoomLevel) *
              scale <
          1) {
        // zoom out until we reached zoomlevel 0
        scale =
            1 / Scalefactor.zoomlevelToScalefactor(_mapViewPosition!.zoomLevel);
      } else {
        double scaleFactor =
            Scalefactor.zoomlevelToScalefactor(_mapViewPosition!.zoomLevel) *
                scale;
        if (scaleFactor >
            Scalefactor.zoomlevelToScalefactor(displayModel.maxZoomLevel)) {
          // zoom in until we reach the maximum zoom level, limit the zoom then
          scale = Scalefactor.zoomlevelToScalefactor(
                  displayModel.maxZoomLevel) /
              Scalefactor.zoomlevelToScalefactor(_mapViewPosition!.zoomLevel);
        }
      }
      MapViewPosition newPosition =
          MapViewPosition.scale(_mapViewPosition!, focalPoint, scale);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
      return newPosition;
    } else {
      MapViewPosition newPosition = MapViewPosition(
          null,
          null,
          displayModel.DEFAULT_ZOOM,
          displayModel.DEFAULT_INDOOR_LEVEL,
          displayModel.tileSize);
      newPosition = MapViewPosition.scale(newPosition, null, scale);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
      return newPosition;
    }
  }

  void setLeftUpper(double left, double upper) {
    if (_mapViewPosition != null) {
      MapViewPosition newPosition = MapViewPosition.setLeftUpper(
          _mapViewPosition!, left, upper, _viewDimension!);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(
          null,
          null,
          displayModel.DEFAULT_ZOOM - 1,
          displayModel.DEFAULT_INDOOR_LEVEL,
          displayModel.tileSize);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    }
  }

  void tapEvent(double left, double upper) {
    if (_mapViewPosition == null) return;
    _mapViewPosition!.calculateBoundingBox(_viewDimension!);
    TapEvent event = TapEvent(
        _mapViewPosition!.projection!
            .pixelYToLatitude(_mapViewPosition!.leftUpper!.y + upper),
        _mapViewPosition!.projection!
            .pixelXToLongitude(_mapViewPosition!.leftUpper!.x + left),
        left,
        upper);
    _injectTap.add(event);
  }

  void gestureEvent() {
    _injectGesture.add(GestureEvent());
  }

  Dimension? get viewDimension => _viewDimension;

  Dimension? setViewDimension(double width, double height) {
    if (_viewDimension != null &&
        _viewDimension!.width == width &&
        _viewDimension!.height == height) return _viewDimension;
    _viewDimension = Dimension(width, height);
    if (_mapViewPosition != null) _injectPosition.add(_mapViewPosition!);
    return _viewDimension;
  }

  void addOverlay(Widget overlay) {
    overlays ??= [];
    overlays!.add(overlay);
  }
}

/////////////////////////////////////////////////////////////////////////////

class TapEvent {
  final double latitude;

  final double longitude;

  final double x;

  final double y;

  const TapEvent(this.latitude, this.longitude, this.x, this.y);
}

/////////////////////////////////////////////////////////////////////////////

class GestureEvent {}
