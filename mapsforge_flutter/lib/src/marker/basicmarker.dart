import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/style.dart';
import 'package:mapsforge_flutter/src/model/boundingbox.dart';
import 'package:mapsforge_flutter/src/model/ilatlong.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';

import 'markercallback.dart';

class BasicMarker<T> {
  final Display display;

  ILatLong latLong;

  double imageOffsetX = 0;

  double imageOffsetY = 0;

  MapPaint imagePaint;

  int imageColor;

  int minZoomLevel;

  int maxZoomLevel;

  double rotation;

  // the item this marker represents
  T item;

  final MarkerCaption markerCaption;

  BasicMarker({
    this.display = Display.ALWAYS,
    this.minZoomLevel = 0,
    this.maxZoomLevel = 65535,
    this.imageColor = 0xff000000,
    this.rotation,
    this.item,
    this.latLong,
    this.markerCaption,
  })  : assert(display != null),
        assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(rotation == null || (rotation >= 0 && rotation <= 360)),
        assert(imageColor != null);

  void initResources(MarkerCallback markerCallback) {
    if (markerCaption != null) markerCaption.initResources(markerCallback);
  }

  void dispose() {}

  void renderNode(MarkerCallback markerCallback) {
    if (Display.NEVER == this.display) {
      return;
    }
    //if (latLong?.latitude == null || latLong?.longitude == null) return;

    initResources(markerCallback);
    renderBitmap(markerCallback);
    if (markerCaption != null) markerCaption.renderCaption(markerCallback);
  }

  bool shouldPaint(BoundingBox boundary, int zoomLevel) {
    return minZoomLevel <= zoomLevel && maxZoomLevel >= zoomLevel && boundary.contains(latLong.latitude, latLong.longitude);
  }

  void renderBitmap(MarkerCallback markerCallback) {}

  String get title {
    if (markerCaption?.text != null && markerCaption.text.length > 0) return markerCaption.text;
    return null;
  }

  bool isTapped(MapViewPosition mapViewPosition, double tappedX, double tappedY) {
    return false;
  }
}

/////////////////////////////////////////////////////////////////////////////

class MarkerCaption {
  final String text;

  ILatLong latLong;

  double captionOffsetX;

  double captionOffsetY;

  MapPaint stroke;

  final double strokeWidth;

  final int strokeColor;

  final double fontSize;

  final int minZoom;

  MarkerCaption({
    this.text,
    this.latLong,
    this.captionOffsetX = 0,
    this.captionOffsetY = 0,
    this.stroke,
    this.strokeWidth = 1.0,
    this.strokeColor = 0xff000000,
    this.fontSize = 10.0,
    this.minZoom = 0,
  })  : assert(strokeWidth >= 0),
        assert(strokeColor != null),
        assert(minZoom != null && minZoom >= 0);

  void initResources(MarkerCallback markerCallback) {
    if (stroke == null && strokeWidth > 0) {
      this.stroke = markerCallback.graphicFactory.createPaint();
      this.stroke.setColorFromNumber(strokeColor);
      this.stroke.setStyle(Style.STROKE);
      this.stroke.setStrokeWidth(strokeWidth);
      this.stroke.setTextSize(fontSize);
    }
  }

  void renderCaption(MarkerCallback markerCallback) {
    if (markerCallback.mapViewPosition.zoomLevel < minZoom) return;
    if (text != null && text.length > 0 && stroke != null && latLong != null) {
      markerCallback.renderText(text, latLong, captionOffsetX, captionOffsetY, stroke);
    }
  }
}
