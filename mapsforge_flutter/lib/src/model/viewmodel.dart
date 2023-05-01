import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
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
  /// The width and height of the visible view in pixels. Note that this is NOT equal to screen-pixels since the view will be scaled by [viewScaleFactor] in order
  /// to gain a better resolution of the tile-images.
  ///
  late Dimension _mapDimension;

  /// The factor to scale down the map. With [DisplayModel.deviceScaleFactor] one can scale up the view and make it bigger. With this value
  /// one can scale down the view and make the resolution of the map better. This comes with the cost of increased tile image sizes and thus increased time for creating the tile-images
  late final double viewScaleFactor;

  /// The last position should be reported to a new subscriber
  Subject<MapViewPosition> _injectPosition = BehaviorSubject();

  /// Receives events when the position or zoom or indoor-level of the map changes
  Stream<MapViewPosition> get observePosition => _injectPosition.stream;

  Subject<TapEvent> _injectTap = PublishSubject();

  /// Receives events when the user taps (short) at the screen
  Stream<TapEvent> get observeTap => _injectTap.stream;

  Subject<TapEvent> _injectLongTap = PublishSubject();

  /// Receives event when the user taps for a longer period at the same position of the screen. This event is sent when the user releases
  Stream<TapEvent> get observeLongTap => _injectLongTap.stream;

  Subject<GestureEvent> _injectGesture = PublishSubject();

  /// Receives events when a gesture is recognized. Use this event to eventually stop automatically moving the map
  Stream<GestureEvent> get observeGesture => _injectGesture.stream;

  Subject<MoveAroundEvent> _injectMoveAroundStart = PublishSubject();

  /// Receives events when the user taps for a longer period at the same position of the screen. This could mean either that the user wants
  /// to drag something around or that the user performs a long-tap. In the latter case a [observeMoveAroundCancel] event will be sent.
  Stream<MoveAroundEvent> get observeMoveAroundStart =>
      _injectMoveAroundStart.stream;

  Subject<MoveAroundEvent> _injectMoveAroundCancel = PublishSubject();

  /// Receives events to denotes that a user just wanted to long-press at the same position. Cancels a "move-around" start event.
  Stream<MoveAroundEvent> get observeMoveAroundCancel =>
      _injectMoveAroundCancel.stream;

  Subject<MoveAroundEvent> _injectMoveAroundUpdate = PublishSubject();

  /// Receives events to denote that the user moves an object around
  Stream<MoveAroundEvent> get observeMoveAroundUpdate =>
      _injectMoveAroundUpdate.stream;

  Subject<MoveAroundEvent> _injectMoveAroundEnd = PublishSubject();

  /// Receives events when the user ended a drag'n'drop event
  Stream<MoveAroundEvent> get observeMoveAroundEnd =>
      _injectMoveAroundEnd.stream;

  ViewModel(
      {this.contextMenuBuilder = const DefaultContextMenuBuilder(),
      required this.displayModel,
      this.noPositionView,
      this.overlays}) {
    noPositionView ??= NoPositionView();
    viewScaleFactor = displayModel.deviceScaleFactor;
    _mapDimension = Dimension(100 * viewScaleFactor, 100 * viewScaleFactor);
  }

  void dispose() {
    overlays?.forEach((element) {
      //element.dispose();
    });
    overlays?.clear();
    _injectPosition.close();
    _injectTap.close();
    _injectLongTap.close();
    _injectGesture.close();
    _injectMoveAroundStart.close();
    _injectMoveAroundUpdate.close();
    _injectMoveAroundEnd.close();
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
          displayModel.tileSize,
          _mapViewPosition!.rotation);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(
          latitude,
          longitude,
          displayModel.DEFAULT_ZOOM,
          displayModel.DEFAULT_INDOOR_LEVEL,
          displayModel.tileSize,
          displayModel.DEFAULT_ROTATION);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    }
  }

  void setMapViewPositionAndRotation(
      double latitude, double longitude, double rotation) {
    if (_mapViewPosition != null) {
      if (_mapViewPosition!.latitude == latitude &&
          _mapViewPosition!.longitude == longitude) return;
      MapViewPosition newPosition = MapViewPosition(
          latitude,
          longitude,
          _mapViewPosition!.zoomLevel,
          _mapViewPosition!.indoorLevel,
          displayModel.tileSize,
          rotation);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(
          latitude,
          longitude,
          displayModel.DEFAULT_ZOOM,
          displayModel.DEFAULT_INDOOR_LEVEL,
          displayModel.tileSize,
          rotation);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    }
  }

  void zoomIn() {
    if (_mapViewPosition == null) return;
    if (_mapViewPosition!.zoomLevel >= displayModel.maxZoomLevel) return;
    MapViewPosition newPosition = MapViewPosition.zoomIn(_mapViewPosition!);
    _mapViewPosition = newPosition;
    _injectPosition.add(newPosition);
  }

  void zoomInAround(double latitude, double longitude) {
    if (_mapViewPosition == null) return;
    if (_mapViewPosition!.zoomLevel >= displayModel.maxZoomLevel) return;
    MapViewPosition newPosition =
        MapViewPosition.zoomInAround(_mapViewPosition!, latitude, longitude);
    _mapViewPosition = newPosition;
    _injectPosition.add(newPosition);
  }

  void zoomOut() {
    if (_mapViewPosition == null) return;
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
      if (_mapViewPosition!.zoomLevel == zoomLevel &&
          _mapViewPosition!.scale == 1) return _mapViewPosition!;
      MapViewPosition newPosition =
          MapViewPosition.zoom(_mapViewPosition!, zoomLevel);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
      return newPosition;
    } else {
      MapViewPosition newPosition = MapViewPosition(
          null,
          null,
          zoomLevel,
          displayModel.DEFAULT_INDOOR_LEVEL,
          displayModel.tileSize,
          displayModel.DEFAULT_ROTATION);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
      return newPosition;
    }
  }

  MapViewPosition zoomAround(double latitude, double longitude, int zoomLevel) {
    assert(_mapViewPosition != null);
    if (zoomLevel > displayModel.maxZoomLevel)
      zoomLevel = displayModel.maxZoomLevel;
    if (zoomLevel < 0) zoomLevel = 0;
    MapViewPosition newPosition = MapViewPosition.zoomAround(
        _mapViewPosition!, latitude, longitude, zoomLevel);
    _mapViewPosition = newPosition;
    _injectPosition.add(newPosition);
    return newPosition;
  }

  void indoorLevelUp() {
    if (_mapViewPosition == null) return;
    if (_mapViewPosition!.zoomLevel >= displayModel.maxZoomLevel) return;
    MapViewPosition newPosition =
        MapViewPosition.indoorLevelUp(_mapViewPosition!);
    _mapViewPosition = newPosition;
    _injectPosition.add(newPosition);
  }

  void indoorLevelDown() {
    if (_mapViewPosition == null) return;
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
      MapViewPosition newPosition = MapViewPosition(
          null,
          null,
          displayModel.DEFAULT_ZOOM,
          indoorLevel,
          displayModel.tileSize,
          displayModel.DEFAULT_ROTATION);
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
  MapViewPosition? setScaleAround(Mappoint focalPoint, double scale) {
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
          MapViewPosition.scaleAround(_mapViewPosition!, focalPoint, scale);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
      return newPosition;
    } else {
      MapViewPosition newPosition = MapViewPosition(
          null,
          null,
          displayModel.DEFAULT_ZOOM,
          displayModel.DEFAULT_INDOOR_LEVEL,
          displayModel.tileSize,
          displayModel.DEFAULT_ROTATION);
      newPosition = MapViewPosition.scaleAround(newPosition, null, scale);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
      return newPosition;
    }
  }

  void rotate(double rotation) {
    if (_mapViewPosition != null) {
      MapViewPosition newPosition =
          MapViewPosition.rotate(_mapViewPosition!, rotation);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(
          null,
          null,
          displayModel.DEFAULT_ZOOM - 1,
          displayModel.DEFAULT_INDOOR_LEVEL,
          displayModel.tileSize,
          rotation);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    }
  }

  void setLeftUpper(double left, double upper) {
    if (_mapViewPosition != null) {
      MapViewPosition newPosition = MapViewPosition.setLeftUpper(
          _mapViewPosition!, left, upper, _mapDimension);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(
          null,
          null,
          displayModel.DEFAULT_ZOOM - 1,
          displayModel.DEFAULT_INDOOR_LEVEL,
          displayModel.tileSize,
          displayModel.DEFAULT_ROTATION);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    }
  }

  void setCenter(double left, double upper) {
    if (_mapViewPosition != null) {
      MapViewPosition newPosition = MapViewPosition.setCenter(
          _mapViewPosition!, left, upper, _mapDimension);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(
          null,
          null,
          displayModel.DEFAULT_ZOOM - 1,
          displayModel.DEFAULT_INDOOR_LEVEL,
          displayModel.tileSize,
          displayModel.DEFAULT_ROTATION);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    }
  }

  /// The user has tapped at the map. The event has been detected by the [FlutterGestureDetector].
  /// left/upper 0/0 indicates the left-upper corner of the widget (NOT of the screen)
  void tapEvent(TapEvent event) {
    _injectTap.add(event);
  }

  /// This method is intended to remove the contextmenu. Call this method if the user clicks at the close-icon of the contextmenu
  void clearTapEvent() {
    _injectTap.add(const TapEvent.clear());
  }

  /// left/upper 0/0 indicates the left-upper corner of the widget (NOT of the screen)
  void longTapEvent(TapEvent event) {
    _injectLongTap.add(event);
  }

  /// An event sent by the [FlutterGestureDetector] to indicate a user-driven gesture-event. This can be used to
  /// switch off automatic movement of the map.
  void gestureEvent() {
    _injectGesture.add(GestureEvent());
  }

  void gestureMoveStartEvent(MoveAroundEvent event) {
    _injectMoveAroundStart.add(event);
  }

  /// The moveStart event has already been reported but the user decided to cancel the move events
  void gestureMoveCancelEvent(MoveAroundEvent event) {
    _injectMoveAroundCancel.add(event);
  }

  void gestureMoveUpdateEvent(MoveAroundEvent event) {
    _injectMoveAroundUpdate.add(event);
  }

  void gestureMoveEndEvent(MoveAroundEvent event) {
    _injectMoveAroundEnd.add(event);
  }

  ///
  /// The width and height of the visible view in pixels. Note that this is NOT
  /// equal to screen-pixels since the view will be scaled by [viewScaleFactor] in order
  /// to gain a better resolution of the tile-images.
  ///
  Dimension get mapDimension => _mapDimension;

  // called if the size of the widget changes
  Dimension? setViewDimension(double width, double height) {
    assert(width >= 0);
    assert(height >= 0);
    if (_mapDimension.width == width * viewScaleFactor &&
        _mapDimension.height == height * viewScaleFactor) return _mapDimension;
    _mapDimension =
        Dimension(width * viewScaleFactor, height * viewScaleFactor);
    if (_mapViewPosition != null) {
      _injectPosition.add(_mapViewPosition!);
    }
    return _mapDimension;
  }

  void addOverlay(Widget overlay) {
    overlays ??= [];
    overlays!.add(overlay);
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

  final PixelProjection? _projection;

  /// The coordinates of the event in logical pixels of the screen in the mapwidget. The left/upper point of the widget is considered 0/0. Note that the widgetpixels differs from the mappixels by the [viewScaleFactor]
//  final Mappoint widgetPixelMappoint;

  /// the left-upper point of the map in pixels
  //final Mappoint leftUpperMappoint;

  /// The position of the event in mappixels
  final Mappoint mapPixelMappoint;

  bool isCleared() {
    return _projection == null;
  }

  PixelProjection get projection => _projection!;

  const TapEvent(
      {required this.latitude,
      required this.longitude,
      //required this.leftUpperMappoint,
      required this.mapPixelMappoint,
      required PixelProjection projection})
      : _projection = projection;

  const TapEvent.clear()
      : latitude = 0,
        longitude = 0,
        //leftUpperMappoint = const Mappoint(0, 0),
        mapPixelMappoint = const Mappoint(0, 0),
        _projection = null;

  @override
  String toString() {
    return 'TapEvent{latitude: $latitude, longitude: $longitude, _projection: $_projection, mapPixelMappoint: $mapPixelMappoint}';
  }
}

/////////////////////////////////////////////////////////////////////////////

/// Triggered when the user moves the map around (tap and hold and move)
class MoveAroundEvent extends TapEvent {
  MoveAroundEvent({
    required double latitude,
    required double longitude,
    required PixelProjection projection,
    //required Mappoint leftUpperMappoint,
    required Mappoint mapPixelMappoint,
  }) : super(
            latitude: latitude,
            longitude: longitude,
            //leftUpperMappoint: leftUpperMappoint,
            mapPixelMappoint: mapPixelMappoint,
            projection: projection);
}

/////////////////////////////////////////////////////////////////////////////

///
/// This event is triggered as soon as a user gesture intervention is detected.
/// It can be used to disable auto-movement or auto-zoom of the map in order to prevent interfering with the user.
class GestureEvent {}
