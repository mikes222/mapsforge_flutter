import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';

/// Abstract Marker class for further extensions. This class holds the position of a marker as [ILatLong] and implements the shouldPaint() method.
abstract class BasicPointMarker<T> extends BasicMarker<T> implements ILatLong {
  ///
  /// The position in the map if the current marker is a "point". For path this makes no sense so a pathmarker must control its own position
  ///
  ILatLong latLong;

  /// latLong in absolute pixel coordinates
  Mappoint? _mappoint;

  int _lastZoomLevel = -1;

  BasicPointMarker({
    display = Display.ALWAYS,
    int minZoomLevel = 0,
    int maxZoomLevel = 65535,
    required this.latLong,
    T? item,
  })  : assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(minZoomLevel <= maxZoomLevel),
        super(
          display: display,
          minZoomLevel: minZoomLevel,
          maxZoomLevel: maxZoomLevel,
          item: item,
        );

  /// returns true if the marker should be painted. The [boundary] represents the currently visible area
  @override
  bool shouldPaint(BoundingBox boundary, int zoomLevel) {
    return super.shouldPaint(boundary, zoomLevel) &&
        boundary.contains(latLong.latitude, latLong.longitude);
  }

  @override
  double get latitude => latLong.latitude;

  @override
  double get longitude => latLong.longitude;

  Mappoint get mappoint => _mappoint!;

  void setLatLong(ILatLong latLong) {
    this.latLong = latLong;
    _mappoint = null;
  }

  @override
  void render(MapCanvas flutterCanvas, MarkerContext markerContext) {
    if (_mappoint == null || markerContext.zoomLevel != _lastZoomLevel) {
      _mappoint = markerContext.projection.latLonToPixel(latLong);
      _lastZoomLevel = markerContext.zoomLevel;
    }
    super.render(flutterCanvas, markerContext);
  }
}

/////////////////////////////////////////////////////////////////////////////

/// Abstract Marker class for further extensions. This class handles the caption of a marker.
abstract class BasicMarker<T> extends Marker<T> {
  BasicMarker({
    Display display = Display.ALWAYS,
    int minZoomLevel = 0,
    int maxZoomLevel = 65535,
    T? item,
  })  : assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(minZoomLevel <= maxZoomLevel),
        super(
            display: display,
            minZoomLevel: minZoomLevel,
            maxZoomLevel: maxZoomLevel,
            item: item) {}

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
  }

  ///
  /// Renders this object. Called by markerPainter
  ///
  @override
  void render(MapCanvas flutterCanvas, MarkerContext markerContext) {
    renderBitmap(flutterCanvas, markerContext);
  }

  /// renders the bitmap portion of this marker. This method is called by [render()] which also call the render method for the caption
  void renderBitmap(MapCanvas flutterCanvas, MarkerContext markerContext);
}
