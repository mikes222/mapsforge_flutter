import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';
import 'package:mapsforge_flutter/src/graphics/style.dart';
import 'package:mapsforge_flutter/src/renderer/geometryutils.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/bitmapmixin.dart';
import 'package:mapsforge_flutter/src/utils/latlongutils.dart';

import 'basicmarker.dart';
import 'markercallback.dart';

class PolygonMarker<T> extends BasicMarker<T> with BitmapMixin {
  static final _log = new Logger('PolygonMarker');

  List<ILatLong> path = [];

  MapPaint? fill;

  double fillWidth;

  int? fillColor;

  MapPaint? stroke;

  final double strokeWidth;

  final List<double>? strokeDasharray;

  final int strokeColor;

  PolygonMarker({
    display = Display.ALWAYS,
    int minZoomLevel = 0,
    int maxZoomLevel = 65535,
    T? item,
    MarkerCaption? markerCaption,
    double bitmapWidth = 20,
    double bitmapHeight = 20,
    int bitmapPercent = 100,
    String? bitmapSrc,
    this.fillWidth = 1.0,
    this.fillColor,
    this.strokeWidth = 1.0,
    this.strokeColor = 0xff000000,
    this.strokeDasharray,
  })  : assert(display != null),
        assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(minZoomLevel <= maxZoomLevel),
        assert(strokeWidth >= 0),
        assert(fillWidth >= 0),
        super(
          display: display,
          minZoomLevel: minZoomLevel,
          maxZoomLevel: maxZoomLevel,
          item: item,
          markerCaption: markerCaption,
        ) {
    this.bitmapWidth = bitmapWidth;
    this.bitmapHeight = bitmapHeight;
    this.bitmapPercent = bitmapPercent;
    this.bitmapSrc = bitmapSrc;
    //if (bitmapSrc != null) fillColor = 0xff000000;
  }

  void addLatLong(ILatLong latLong) {
    path.add(latLong);
  }

  @override
  Future<void> initResources(SymbolCache? symbolCache) async {
    await super.initResources(symbolCache);
    await initBitmap(symbolCache);
    if (fill == null && fillColor != null) {
      this.fill = GraphicFactory().createPaint();
      this.fill!.setColorFromNumber(fillColor!);
      this.fill!.setStyle(Style.FILL);
      this.fill!.setStrokeWidth(fillWidth);
      if (bitmap != null) {
        // make sure the color is not transparent
        if (fill!.isTransparent()) fill!.setColorFromNumber(0xff000000);
        fill!.setBitmapShader(bitmap!);
      }
    }
    if (stroke == null && strokeWidth > 0) {
      this.stroke = GraphicFactory().createPaint();
      this.stroke!.setColorFromNumber(strokeColor);
      this.stroke!.setStyle(Style.STROKE);
      this.stroke!.setStrokeWidth(strokeWidth);
      this.stroke!.setStrokeDasharray(strokeDasharray);
      if (bitmap != null) {
        // make sure the color is not transparent
        if (stroke!.isTransparent()) stroke!.setColorFromNumber(0xff000000);
        stroke!.setBitmapShader(bitmap!);
      }
    }
    if (markerCaption != null && markerCaption!.latLong == null) {
      markerCaption!.latLong = GeometryUtils.calculateCenter(path);
    }
  }

  @override
  bool shouldPaint(BoundingBox? boundary, int zoomLevel) {
    return minZoomLevel <= zoomLevel && maxZoomLevel >= zoomLevel;
  }

  @override
  void renderBitmap(MarkerCallback markerCallback, int zoomLevel) {
    MapPath mapPath = GraphicFactory().createPath();

    path.forEach((latLong) {
      double y = markerCallback.mapViewPosition.projection!
              .latitudeToPixelY(latLong.latitude) -
          markerCallback.mapViewPosition.leftUpper!.y;
      double x = markerCallback.mapViewPosition.projection!
              .longitudeToPixelX(latLong.longitude) -
          markerCallback.mapViewPosition.leftUpper!.x;

      if (mapPath.isEmpty())
        mapPath.moveTo(x, y);
      else
        mapPath.lineTo(x, y);
    });
    mapPath.close();
    if (fill != null) markerCallback.renderPath(mapPath, fill!);
    if (stroke != null) markerCallback.renderPath(mapPath, stroke!);
  }

  @override
  bool isTapped(
      MapViewPosition mapViewPosition, double tappedX, double tappedY) {
    ILatLong latLong = mapViewPosition.projection!.pixelToLatLong(
        tappedX + mapViewPosition.leftUpper!.x,
        tappedY + mapViewPosition.leftUpper!.y);
    //print("Testing ${latLong.toString()} against ${title}");
    return LatLongUtils.contains(path, latLong);
  }
}
