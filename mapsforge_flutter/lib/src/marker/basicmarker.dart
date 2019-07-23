import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/style.dart';
import 'package:mapsforge_flutter/src/model/boundingbox.dart';
import 'package:mapsforge_flutter/src/model/ilatlong.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';

import 'markercallback.dart';

class BasicMarker<T> {
  final String caption;

  final Display display;

  ILatLong latLong;

  double imageOffsetX = 0;

  double imageOffsetY = 0;

  double captionOffsetX = 0;

  double captionOffsetY = 0;

  MapPaint stroke;

  double strokeWidth;

  int strokeColor;

  MapPaint imagePaint;

  int imageColor;

  int minZoomLevel;

  int maxZoomLevel;

  double rotation;

  // the item this marker represents
  T item;

  BasicMarker({
    this.caption,
    this.display = Display.ALWAYS,
    this.minZoomLevel = 0,
    this.maxZoomLevel = 65535,
    this.strokeWidth = 1.0,
    this.strokeColor = 0xff000000,
    this.imageColor = 0xff000000,
    this.rotation,
    this.item,
    this.latLong,
  })  : assert(display != null),
        assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(rotation == null || (rotation >= 0 && rotation <= 360)),
        assert(strokeWidth >= 0),
        assert(strokeColor != null),
        assert(imageColor != null);

  void initRessources(MarkerCallback markerCallback) {
    if (stroke == null && strokeWidth > 0) {
      this.stroke = markerCallback.graphicFactory.createPaint();
      this.stroke.setColorFromNumber(strokeColor);
      this.stroke.setStyle(Style.STROKE);
      this.stroke.setStrokeWidth(strokeWidth);
      //this.stroke.setTextSize(fontSize);
    }
  }

  void dispose() {}

  void renderNode(MarkerCallback markerCallback) {
    if (Display.NEVER == this.display) {
      return;
    }
    //if (latLong?.latitude == null || latLong?.longitude == null) return;

    initRessources(markerCallback);
    renderBitmap(markerCallback);
    renderCaption(markerCallback);
  }

  bool shouldPaint(BoundingBox boundary, int zoomLevel) {
    return minZoomLevel <= zoomLevel && maxZoomLevel >= zoomLevel && boundary.contains(latLong.latitude, latLong.longitude);
  }

  void renderBitmap(MarkerCallback markerCallback) {}

  void renderCaption(MarkerCallback markerCallback) {
    if (caption != null && caption.length > 0) {
      markerCallback.renderText(caption, latLong.latitude, latLong.longitude, captionOffsetX, captionOffsetY, stroke);
    }
  }

  String get title {
    if (caption != null && caption.length > 0) return caption;
    return null;
  }

  bool isTapped(MapViewPosition mapViewPosition, double tappedX, double tappedY) {
    return false;
  }
}
