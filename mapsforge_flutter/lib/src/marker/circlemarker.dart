import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/model/maprectangle.dart';
import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';

/// A marker which draws a circle specified by its center as lat/lon and by its radius in pixels.
class CircleMarker<T> extends BasicPointMarker<T> with PaintMixin {
  late final double radius;

  final int? percent;

  CircleMarker({
    Display display = Display.ALWAYS,
    int minZoomLevel = 0,
    int maxZoomLevel = 65535,
    T? item,
    MarkerCaption? markerCaption,
    required ILatLong center,
    double radius = 10,
    this.percent,
    int? fillColor,
    double strokeWidth = 2.0,
    int strokeColor = 0xff000000,
    required DisplayModel displayModel,
  })  : assert(minZoomLevel >= 0),
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
    setStrokeWidth(strokeWidth * displayModel.getScaleFactor());
    this.radius = radius * displayModel.getScaleFactor();

    if (markerCaption != null) {
      markerCaption.latLong = latLong;
    }
    if (markerCaption != null) {
      // markerCaption
      //     .setDy(radius + strokeWidth + markerCaption.getFontSize() / 2);
      markerCaption
          .setSymbolBoundary(MapRectangle(-radius, -radius, radius, radius));
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
    Mappoint leftUpper = markerCallback.mapViewPosition
        .getLeftUpper(markerCallback.viewModel.mapDimension);
    markerCallback.flutterCanvas.drawCircle(
        (mappoint.x - leftUpper.x),
        (mappoint.y - leftUpper.y),
        radius,
        getFillPaint(markerCallback.mapViewPosition.zoomLevel));
    markerCallback.flutterCanvas.drawCircle(
        (mappoint.x - leftUpper.x),
        (mappoint.y - leftUpper.y),
        radius,
        getStrokePaint(markerCallback.mapViewPosition.zoomLevel));
  }

  double getRadius(int zoomLevel) {
    if (percent != null && percent != 100) return radius / 100 * percent!;
    return radius;
  }

  @override
  bool isTapped(TapEvent tapEvent) {
    Mappoint p2 = tapEvent.projection.latLonToPixel(latLong);
    return p2.distance(tapEvent.mapPixelMappoint) <=
        getRadius(tapEvent.projection.scalefactor.zoomlevel);
  }
}
