import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/maprect.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';
import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/bitmapsrcmixin.dart';

import '../../core.dart';
import 'basicmarker.dart';
import 'markercallback.dart';

/// A Marker which draws a rectangle specified by the min/max lat/lon attributes.
class RectMarker<T> extends BasicMarker<T> with BitmapSrcMixin, PaintMixin {
  final ILatLong minLatLon;

  final ILatLong maxLatLon;

  /// the box which enclosed the rect specified by the given minLatLon and maxLatLon
  final BoundingBox boundingBox;

  ResourceBitmap? bitmap;

  MapRect? mapRect;

  int lastZoomLevel = -1;

  RectMarker({
    display = Display.ALWAYS,
    int minZoomLevel = 0,
    int maxZoomLevel = 65535,
    T? item,
    String? bitmapSrc,
    MarkerCaption? markerCaption,
    int? fillColor,
    double strokeWidth = 2.0,
    int strokeColor = 0xff000000,
    List<double>? strokeDasharray,
    required this.minLatLon,
    required this.maxLatLon,
    required DisplayModel displayModel,
  })  : assert(display != null),
        assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(strokeWidth >= 0),
        assert(strokeDasharray == null || strokeDasharray.length == 2),
        boundingBox = BoundingBox(minLatLon.latitude, minLatLon.longitude,
            maxLatLon.latitude, maxLatLon.longitude),
        super(
          display: display,
          minZoomLevel: minZoomLevel,
          maxZoomLevel: maxZoomLevel,
          item: item,
          markerCaption: markerCaption,
        ) {
    //initBitmapSrcMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    initPaintMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    this.bitmapSrc = bitmapSrc;
    if (fillColor != null)
      setFillColorFromNumber(fillColor);
    else
      setFillColor(Colors.transparent);
    setStrokeWidth(strokeWidth * displayModel.getScaleFactor());
    setStrokeColorFromNumber(strokeColor);
    if (strokeDasharray != null) setStrokeDashArray(strokeDasharray);
  }

  @override
  @mustCallSuper
  void dispose() {
    bitmap?.dispose();
    bitmap = null;
    super.dispose();
  }

  Future<void> initResources(SymbolCache symbolCache) async {
    bitmap?.dispose();
    //bitmap = await loadBitmap(10, symbolCache);
    if (bitmap != null) {
      if (isFillTransparent()) setFillColorFromNumber(0xff000000);
      setFillBitmapShader(bitmap!);
      bitmap!.dispose();
    }
    if (markerCaption != null) {
      markerCaption!.latLong = LatLong(
          minLatLon.latitude + (maxLatLon.latitude - minLatLon.latitude) / 2,
          minLatLon.longitude +
              (maxLatLon.longitude - minLatLon.longitude) /
                  2); //GeometryUtils.calculateCenter(path);
    }
  }

  @override
  void setMarkerCaption(MarkerCaption? markerCaption) {
    if (markerCaption != null && markerCaption.latLong == null) {
      markerCaption.latLong = LatLong(
          minLatLon.latitude + (maxLatLon.latitude - minLatLon.latitude) / 2,
          minLatLon.longitude +
              (maxLatLon.longitude - minLatLon.longitude) /
                  2); //GeometryUtils.calculateCenter(path);
    }
    super.setMarkerCaption(markerCaption);
  }

  @override
  bool shouldPaint(BoundingBox? boundary, int zoomLevel) {
    return minZoomLevel <= zoomLevel &&
        maxZoomLevel >= zoomLevel &&
        boundary!.intersects(boundingBox);
  }

  @override
  void renderBitmap(MarkerCallback markerCallback) {
    // prepareScalePaintMixin(zoomLevel);
    // prepareScaleBitmapSrcMixin(zoomLevel);
    if (mapRect == null ||
        lastZoomLevel != markerCallback.mapViewPosition.zoomLevel) {
      // cache the rect in pixel-coordinates
      mapRect = GraphicFactory().createRect(
          markerCallback.mapViewPosition.projection
              .longitudeToPixelX(minLatLon.longitude),
          markerCallback.mapViewPosition.projection
              .latitudeToPixelY(maxLatLon.latitude),
          markerCallback.mapViewPosition.projection
              .longitudeToPixelX(maxLatLon.longitude),
          markerCallback.mapViewPosition.projection
              .latitudeToPixelY(minLatLon.latitude));
      lastZoomLevel = markerCallback.mapViewPosition.zoomLevel;
    }
    Mappoint leftUpper = markerCallback.mapViewPosition
        .getLeftUpper(markerCallback.viewModel.mapDimension);
    MapRect mr = mapRect!.offset(-leftUpper.x, -leftUpper.y);

    if (!isFillTransparent())
      markerCallback.flutterCanvas
          .drawRect(mr, getFillPaint(markerCallback.mapViewPosition.zoomLevel));
    if (!isStrokeTransparent())
      markerCallback.flutterCanvas.drawRect(
          mr, getStrokePaint(markerCallback.mapViewPosition.zoomLevel));
  }

  @override
  bool isTapped(TapEvent tapEvent) {
    return tapEvent.latitude > minLatLon.latitude &&
        tapEvent.latitude < maxLatLon.latitude &&
        tapEvent.longitude > minLatLon.longitude &&
        tapEvent.longitude < maxLatLon.longitude;
  }
}
