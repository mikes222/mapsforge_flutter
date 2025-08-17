import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/model/maprectangle.dart';
import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_symbol.dart';

/// A marker which draws a circle specified by its center as lat/lon and by its radius in pixels.
class CircleMarker<T> extends BasicPointMarker<T> with PaintMixin, CaptionMixin {
  late final double radius;

  final int? percent;

  CircleMarker({
    Display display = Display.ALWAYS,
    int minZoomLevel = 0,
    int maxZoomLevel = 65535,
    T? item,
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
    symbolFinder.add("poi", _CircleShapeSymbol.base(getRadius(0)));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  bool shouldPaint(BoundingBox boundary, int zoomLevel) {
    return minZoomLevel <= zoomLevel && maxZoomLevel >= zoomLevel && boundary.contains(latLong.latitude, latLong.longitude);
  }

  ///
  /// Renders this object. Called by markerPainter
  ///
  @override
  void render(MapCanvas flutterCanvas, MarkerContext markerContext) {
    super.render(flutterCanvas, markerContext);
    renderMarker(
        flutterCanvas: flutterCanvas,
        markerContext: markerContext,
        coordinatesAbsolute: mappoint,
        symbolBoundary: MapRectangle(-radius, -radius, radius, radius));
  }

  @override
  void renderBitmap(MapCanvas flutterCanvas, MarkerContext markerContext) {
    flutterCanvas.drawCircle((mappoint.x - markerContext.mapCenter.x), (mappoint.y - markerContext.mapCenter.y), radius, getFillPaint(markerContext.zoomLevel));
    flutterCanvas.drawCircle(
        (mappoint.x - markerContext.mapCenter.x), (mappoint.y - markerContext.mapCenter.y), radius, getStrokePaint(markerContext.zoomLevel));
  }

  double getRadius(int zoomLevel) {
    if (percent != null && percent != 100) return radius / 100 * percent!;
    return radius;
  }

  @override
  bool isTapped(TapEvent tapEvent) {
    Mappoint p2 = tapEvent.projection.latLonToPixel(latLong);
    Mappoint tapped = tapEvent.projection.latLonToPixel(tapEvent);
    return p2.distance(tapped) <= getRadius(tapEvent.projection.scalefactor.zoomlevel);
  }
}

//////////////////////////////////////////////////////////////////////////////

class _CircleShapeSymbol extends ShapeSymbol {
  final double radius;

  _CircleShapeSymbol.base(this.radius) : super.base(0);

  @override
  MapRectangle calculateBoundary() {
    return MapRectangle(-radius, -radius, radius, radius);
  }
}
