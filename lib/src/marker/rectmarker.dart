import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/maprect.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';
import 'package:mapsforge_flutter/src/model/maprectangle.dart';
import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/bitmapsrcmixin.dart';

import '../../core.dart';

/// A Marker which draws a rectangle specified by the min/max lat/lon attributes. Currently there is
// no way to set the position of the marker (to e.g. above the position) so an icon which is suitable for
// being centered should be used.
class RectMarker<T> extends BasicMarker<T>
    with BitmapSrcMixin, PaintMixin, CaptionMixin {
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
  }

  @override
  bool shouldPaint(BoundingBox boundary, int zoomLevel) {
    return minZoomLevel <= zoomLevel &&
        maxZoomLevel >= zoomLevel &&
        boundary.intersects(boundingBox);
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
        coordinatesAbsolute: mapRect!.getCenter(),
        symbolBoundary: getSymbolBoundary());
  }

  @override
  void renderBitmap(MapCanvas flutterCanvas, MarkerContext markerContext) {
    // prepareScalePaintMixin(zoomLevel);
    // prepareScaleBitmapSrcMixin(zoomLevel);
    if (mapRect == null || lastZoomLevel != markerContext.zoomLevel) {
      // cache the rect in pixel-coordinates
      Mappoint minmappoint = markerContext.projection.latLonToPixel(minLatLon);
      Mappoint maxmappoint = markerContext.projection.latLonToPixel(maxLatLon);
      mapRect = GraphicFactory().createRect(
          minmappoint.x, maxmappoint.y, maxmappoint.x, minmappoint.y);
      lastZoomLevel = markerContext.zoomLevel;
    }
    MapRect mr =
        mapRect!.offset(-markerContext.mapCenter.x, -markerContext.mapCenter.y);
    // mr = GraphicFactory().createRect(mr.getLeft() * 2, mr.getTop() * 2,
    //     mr.getRight() * 2, mr.getBottom() * 2);

    if (!isFillTransparent())
      flutterCanvas.drawRect(mr, getFillPaint(markerContext.zoomLevel));
    if (!isStrokeTransparent())
      flutterCanvas.drawRect(mr, getStrokePaint(markerContext.zoomLevel));
  }

  @override
  bool isTapped(TapEvent tapEvent) {
    return tapEvent.latitude > minLatLon.latitude &&
        tapEvent.latitude < maxLatLon.latitude &&
        tapEvent.longitude > minLatLon.longitude &&
        tapEvent.longitude < maxLatLon.longitude;
  }

  MapRectangle getSymbolBoundary() {
    return MapRectangle(-mapRect!.getWidth() / 2, -mapRect!.getHeight() / 2,
        mapRect!.getWidth() / 2, mapRect!.getHeight() / 2);
  }
}
