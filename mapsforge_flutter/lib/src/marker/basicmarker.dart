import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/model/boundingbox.dart';
import 'package:mapsforge_flutter/src/model/ilatlong.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';
import 'package:mapsforge_flutter/src/renderer/textmixin.dart';

import 'markercallback.dart';

class BasicPointMarker<T> extends BasicMarker<T> {
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

class BasicMarker<T> {
  final Display display;

  int minZoomLevel;

  int maxZoomLevel;

  /// the item this marker represents.
  ///
  /// This property is NOT used by mapsforge.
  T? item;

  /// The caption of the marker or [null]
  MarkerCaption? markerCaption;

  BasicMarker({
    this.display = Display.ALWAYS,
    this.minZoomLevel = 0,
    this.maxZoomLevel = 65535,
    this.item,
    this.markerCaption,
  })  : assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(minZoomLevel <= maxZoomLevel);

  @mustCallSuper
  Future<void> initResources(GraphicFactory graphicFactory) async {
    await markerCaption?.initResources(graphicFactory);
  }

  void dispose() {
    markerCaption?.dispose();
  }

  ///
  /// Renders this object. Called by markerPointer -> markerRenderer
  ///
  void render(MarkerCallback markerCallback, int zoomLevel) {
    renderBitmap(markerCallback, zoomLevel);
    if (markerCaption != null)
      markerCaption!.renderCaption(markerCallback, zoomLevel);
  }

  /// returns true if this marker is within the visible boundary and therefore should be painted. Since the initResources() is called
  /// only if shouldPoint() returns true, do not test for available resources here.
  bool shouldPaint(BoundingBox boundary, int zoomLevel) {
    return display != Display.NEVER &&
        minZoomLevel <= zoomLevel &&
        maxZoomLevel >= zoomLevel;
  }

  /// renders the bitmap portion of this marker. This method is called by [render()] which also call the render method for the caption
  void renderBitmap(MarkerCallback markerCallback, int zoomLevel) {}

  String? get title {
    if (markerCaption?.text != null && markerCaption!.text.length > 0)
      return markerCaption!.text;
    return null;
  }

  /// returns true if the position specified by [tappedX], [tappedY] relative to the [mapViewPosition] is in the area of this marker.
  bool isTapped(
      MapViewPosition mapViewPosition, double tappedX, double tappedY) {
    return false;
  }
}

/////////////////////////////////////////////////////////////////////////////

/// The caption of a marker
class MarkerCaption with TextMixin {
  /// The text to show.
  ///
  final String text;

  /// The position of the text or [null] if the position should be calculated based on the position of the marker
  ///
  ILatLong? latLong;

  /// The offset of the caption in screen pixels
  double captionOffsetX;

  double captionOffsetY;

  final double strokeWidth;

  final int strokeColor;

  final int fillColor;

  final double fontSize;

  final int minZoomLevel;

  int maxZoomLevel;

  MarkerCaption({
    required this.text,
    this.latLong,
    this.captionOffsetX = 0,
    this.captionOffsetY = 0,
    this.strokeWidth = 1.0,
    this.strokeColor = 0xff000000,
    this.fillColor = 0xffffffff,
    this.fontSize = 10.0,
    this.minZoomLevel = 0,
    this.maxZoomLevel = 65535,
  })  : assert(strokeWidth >= 0),
        assert(minZoomLevel >= 0),
        assert(minZoomLevel <= maxZoomLevel),
        assert(text.length > 0);

  Future<void> initResources(GraphicFactory graphicFactory) {
    initTextMixin(graphicFactory);
    stroke!.setStrokeWidth(strokeWidth);
    stroke!.setColorFromNumber(strokeColor);
    stroke!.setTextSize(fontSize);
    fill!.setTextSize(fontSize);
    fill!.setColorFromNumber(fillColor);
    return Future.value(null);
  }

  void dispose() {
    mixinDispose();
  }

  void renderCaption(MarkerCallback markerCallback, int zoomLevel) {
    if (zoomLevel < minZoomLevel) return;
    if (zoomLevel > maxZoomLevel) return;
    if (latLong != null) {
      markerCallback.renderText(text, latLong!, captionOffsetX, captionOffsetY,
          getFillPaint(zoomLevel));
      markerCallback.renderText(text, latLong!, captionOffsetX, captionOffsetY,
          getStrokePaint(zoomLevel));
    }
  }
}
