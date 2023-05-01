import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/marker/captionmarker.dart';

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
    MarkerCaption? markerCaption,
  })  : assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(minZoomLevel <= maxZoomLevel),
        super(
            display: display,
            minZoomLevel: minZoomLevel,
            maxZoomLevel: maxZoomLevel,
            item: item,
            markerCaption: markerCaption);

  @override
  void setMarkerCaption(MarkerCaption? markerCaption) {
    if (markerCaption != null) {
      markerCaption.latLong = latLong;
    }
    super.setMarkerCaption(markerCaption);
  }

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
  void render(MarkerCallback markerCallback) {
    if (_mappoint == null ||
        markerCallback.mapViewPosition.zoomLevel != _lastZoomLevel) {
      _mappoint =
          markerCallback.mapViewPosition.projection.latLonToPixel(latLong);
      _lastZoomLevel = markerCallback.mapViewPosition.zoomLevel;
    }
    super.render(markerCallback);
  }
}

/////////////////////////////////////////////////////////////////////////////

/// Abstract Marker class for further extensions. This class handles the caption of a marker.
abstract class BasicMarker<T> extends Marker<T> {
  /// The caption of the marker or [null]
  MarkerCaption? _markerCaption;

  BasicMarker({
    Display display = Display.ALWAYS,
    int minZoomLevel = 0,
    int maxZoomLevel = 65535,
    T? item,
    MarkerCaption? markerCaption,
  })  : assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(minZoomLevel <= maxZoomLevel),
        super(
            display: display,
            minZoomLevel: minZoomLevel,
            maxZoomLevel: maxZoomLevel,
            item: item) {
    setMarkerCaption(markerCaption);
  }

  @override
  @mustCallSuper
  void dispose() {
    _markerCaption?.dispose();
    _markerCaption = null;
    super.dispose();
  }

  void setMarkerCaption(MarkerCaption? markerCaption) {
    _markerCaption?.dispose();
    _markerCaption = markerCaption;
  }

  ///
  /// Renders this object. Called by markerPointer -> markerRenderer
  ///
  @override
  void render(MarkerCallback markerCallback) {
    renderBitmap(markerCallback);
    if (_markerCaption != null) _markerCaption!.renderCaption(markerCallback);
  }

  MarkerCaption? get markerCaption => _markerCaption;

  /// renders the bitmap portion of this marker. This method is called by [render()] which also call the render method for the caption
  void renderBitmap(MarkerCallback markerCallback);
}

/////////////////////////////////////////////////////////////////////////////

/// The caption of a marker
class MarkerCaption extends CaptionMarker {
  MarkerCaption({
    required String text,
    ILatLong? latLong,
    double strokeWidth = 2.0,
    int strokeColor = 0xffffffff,
    int fillColor = 0xff000000,
    double fontSize = 10.0,
    int minZoomLevel = 0,
    int maxZoomLevel = 65535,
    Position position = Position.BELOW,
    double dy = 0,
    int strokeMinZoomLevel = DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT,
    required DisplayModel displayModel,
  })  : assert(strokeWidth >= 0),
        assert(minZoomLevel >= 0),
        assert(minZoomLevel <= maxZoomLevel) /*assert(text.length > 0)*/,
        super(
          latLong: latLong ?? const LatLong(0, 0),
          caption: text,
          fillColor: fillColor,
          fontSize: fontSize,
          strokeColor: strokeColor,
          strokeWidth: strokeWidth,
          minZoomLevel: minZoomLevel,
          maxZoomLevel: maxZoomLevel,
          maxTextWidth: displayModel.getMaxTextWidth(),
          position: position,
          displayModel: displayModel,
          dy: dy,
          strokeMinZoomLevel: strokeMinZoomLevel,
        ) {}

  void renderCaption(MarkerCallback markerCallback) {
    if (markerCallback.mapViewPosition.zoomLevel < minZoomLevel) return;
    if (markerCallback.mapViewPosition.zoomLevel > maxZoomLevel) return;
    renderBitmap(markerCallback);
  }

  void set text(String text) {
    caption = text;
    if (scaled != null) shapePaint.setCaption(caption);
  }

  void setStrokeColorFromNumber(int strokeColor) {
    base.setStrokeColorFromNumber(strokeColor);
    if (scaled != null) shapePaint.reinit(caption);
  }

  void setFillColorFromNumber(int fillColor) {
    base.setFillColorFromNumber(fillColor);
    if (scaled != null) shapePaint.reinit(caption);
  }
}
