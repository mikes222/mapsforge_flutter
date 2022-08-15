import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/special.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';

/// A marker which draws a circle specified by its center as lat/lon and by its radius in pixels.
class CircleMarker<T> extends BasicPointMarker<T> with PaintMixin {
  final double radius;

  final int? percent;

  CircleMarker({
    display = Display.ALWAYS,
    minZoomLevel = 0,
    maxZoomLevel = 65535,
    item,
    markerCaption,
    required ILatLong center,
    this.radius = 10,
    this.percent,
    int? fillColor,
    double strokeWidth = 2.0,
    int strokeColor = 0xff000000,
  })  : assert(display != null),
        assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(strokeWidth >= 0),
        assert(radius > 0),
        assert(percent == null || percent > 0),
        super(
          display: display,
          minZoomLevel: minZoomLevel,
          maxZoomLevel: maxZoomLevel,
          item: item,
          markerCaption: markerCaption,
          latLong: center,
        ) {
    initPaintMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL);
    if (fillColor != null)
      setFillColorFromNumber(fillColor);
    else
      setFillColor(Colors.transparent);
    setStrokeColorFromNumber(strokeColor);
    setStrokeWidth(strokeWidth);

    if (markerCaption != null && markerCaption!.latLong == null) {
      markerCaption!.latLong = latLong;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  bool shouldPaint(BoundingBox? boundary, int zoomLevel) {
    return minZoomLevel <= zoomLevel && maxZoomLevel >= zoomLevel;
  }

  @override
  void renderBitmap(MarkerCallback markerCallback) {
    markerCallback.renderCircle(
        latLong.latitude,
        latLong.longitude,
        getRadius(markerCallback.mapViewPosition.zoomLevel),
        getFillPaint(markerCallback.mapViewPosition.zoomLevel));
    markerCallback.renderCircle(
        latLong.latitude,
        latLong.longitude,
        getRadius(markerCallback.mapViewPosition.zoomLevel),
        getStrokePaint(markerCallback.mapViewPosition.zoomLevel));
  }

  double getRadius(int zoomLevel) {
    if (percent != null && percent != 100) return radius / 100 * percent!;
    return radius;
  }

  @override
  bool isTapped(TapEvent tapEvent) {
    Mappoint p1 = Mappoint(
        tapEvent.x + tapEvent.leftUpperX, tapEvent.y + tapEvent.leftUpperY);
    Mappoint p2 = tapEvent.projection.latLonToPixel(latLong);

    return p2.distance(p1) <=
        getRadius(tapEvent.projection.scalefactor.zoomlevel);
  }
}
