import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/marker/marker.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';
import 'package:mapsforge_flutter/src/renderer/textmixin.dart';

import 'markercallback.dart';

/// Abstract Marker class for further extensions. This class holds the position of a marker as [ILatLong] and implements the shouldPaint() method.
abstract class BasicPointMarker<T> extends BasicMarker<T> {
  ///
  /// The position in the map if the current marker is a "point". For path this makes no sense so a pathmarker must control its own position
  ///
  ILatLong latLong;

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

  /// returns true if the marker should be painted. The [boundary] represents the currently visible area
  @override
  bool shouldPaint(BoundingBox boundary, int zoomLevel) {
    return super.shouldPaint(boundary, zoomLevel) &&
        boundary.contains(latLong.latitude, latLong.longitude);
  }
}

/////////////////////////////////////////////////////////////////////////////

/// Abstract Marker class for further extensions. This class handles the caption of a marker.
abstract class BasicMarker<T> extends Marker<T> {
  /// The caption of the marker or [null]
  final MarkerCaption? markerCaption;

  BasicMarker({
    Display display = Display.ALWAYS,
    int minZoomLevel = 0,
    int maxZoomLevel = 65535,
    T? item,
    this.markerCaption,
  })  : assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(minZoomLevel <= maxZoomLevel),
        super(
            display: display,
            minZoomLevel: minZoomLevel,
            maxZoomLevel: maxZoomLevel,
            item: item);

  @override
  void dispose() {
    markerCaption?.dispose();
  }

  ///
  /// Renders this object. Called by markerPointer -> markerRenderer
  ///
  @override
  void render(MarkerCallback markerCallback) {
    renderBitmap(markerCallback);
    if (markerCaption != null) markerCaption!.renderCaption(markerCallback);
  }

  /// renders the bitmap portion of this marker. This method is called by [render()] which also call the render method for the caption
  void renderBitmap(MarkerCallback markerCallback);
}

/////////////////////////////////////////////////////////////////////////////

/// The caption of a marker
class MarkerCaption with TextMixin, PaintMixin {
  /// The text to show.
  ///
  String text;

  /// The position of the text or [null] if the position should be calculated based on the position of the marker
  ///
  ILatLong? latLong;

  /// The offset of the caption in screen pixels
  double captionOffsetX;

  double captionOffsetY;

  final int minZoomLevel;

  int maxZoomLevel;

  /// The maximum width of a text as defined in the displaymodel
  final double maxTextWidth;

  MarkerCaption({
    required this.text,
    this.latLong,
    this.captionOffsetX = 0,
    this.captionOffsetY = 0,
    double strokeWidth = 2.0,
    int strokeColor = 0xffffffff,
    int fillColor = 0xff000000,
    double fontSize = 10.0,
    this.minZoomLevel = 0,
    this.maxZoomLevel = 65535,
    this.maxTextWidth = 200,
  })  : assert(strokeWidth >= 0),
        assert(minZoomLevel >= 0),
        assert(minZoomLevel <= maxZoomLevel),
        assert(text.length > 0) {
    initTextMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    initPaintMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    setStrokeWidth(strokeWidth);
    setStrokeColorFromNumber(strokeColor);
    setFontSize(fontSize);
    setFillColorFromNumber(fillColor);
  }

  void dispose() {
    disposeTextMixin();
    disposePaintMixin();
  }

  void renderCaption(MarkerCallback markerCallback) {
    if (markerCallback.mapViewPosition.zoomLevel < minZoomLevel) return;
    if (markerCallback.mapViewPosition.zoomLevel > maxZoomLevel) return;
    if (latLong == null) return;
    prepareScalePaintMixin(markerCallback.mapViewPosition.zoomLevel);
    prepareScaleTextMixin(markerCallback.mapViewPosition.zoomLevel);
    Mappoint mappoint = markerCallback.mapViewPosition.projection!
        .pixelRelativeToLeftUpper(
            latLong!, markerCallback.mapViewPosition.leftUpper!);
    markerCallback.flutterCanvas.drawText(
        text,
        (mappoint.x + captionOffsetX),
        (mappoint.y + captionOffsetY),
        getStrokePaint(markerCallback.mapViewPosition.zoomLevel),
        getTextPaint(markerCallback.mapViewPosition.zoomLevel),
        maxTextWidth);
    markerCallback.flutterCanvas.drawText(
        text,
        (mappoint.x + captionOffsetX),
        (mappoint.y + captionOffsetY),
        getFillPaint(markerCallback.mapViewPosition.zoomLevel),
        getTextPaint(markerCallback.mapViewPosition.zoomLevel),
        maxTextWidth);
  }
}
