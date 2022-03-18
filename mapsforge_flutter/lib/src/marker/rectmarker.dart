import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/maprect.dart';
import 'package:mapsforge_flutter/src/graphics/style.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/bitmapmixin.dart';

import '../../core.dart';
import 'basicmarker.dart';
import 'markercallback.dart';

class RectMarker<T> extends BasicMarker<T> with BitmapMixin {
  ILatLong minLatLon;
  ILatLong maxLatLon;

  MapPaint? fill;

  double fillWidth;

  int? fillColor;

  MapPaint? stroke;

  final double strokeWidth;

  int strokeColor;

  List<double>? strokeDasharray;

  RectMarker({
    display = Display.ALWAYS,
    int minZoomLevel = 0,
    int maxZoomLevel = 65535,
    T? item,
    String? bitmapSrc,
    MarkerCaption? markerCaption,
    this.fillWidth = 1.0,
    this.fillColor,
    this.strokeWidth = 1.0,
    this.strokeColor = 0xff000000,
    this.strokeDasharray,
    required this.minLatLon,
    required this.maxLatLon,
  })  : assert(display != null),
        assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(strokeWidth >= 0),
        assert(fillWidth >= 0),
        assert(strokeDasharray == null || strokeDasharray.length == 2),
        super(
          display: display,
          minZoomLevel: minZoomLevel,
          maxZoomLevel: maxZoomLevel,
          item: item,
          markerCaption: markerCaption,
        ) {
    this.bitmapSrc = bitmapSrc;
  }

  @override
  Future<void> initResources( SymbolCache? symbolCache) async {
    await super.initResources( symbolCache);
    await initBitmap( symbolCache);
    if (fill == null && (fillColor != null || bitmap != null)) {
      this.fill = GraphicFactory().createPaint();
      if (fillColor != null) this.fill!.setColorFromNumber(fillColor!);
      this.fill!.setStyle(Style.FILL);
      this.fill!.setStrokeWidth(fillWidth);
      if (bitmap != null) {
        // make sure the color is not transparent
        if (fill!.isTransparent()) fill!.setColorFromNumber(0xff000000);
        fill!.setBitmapShader(bitmap!);
      }
      //this.stroke.setTextSize(fontSize);
    }
    if (stroke == null && strokeWidth > 0) {
      this.stroke = GraphicFactory().createPaint();
      this.stroke!.setColorFromNumber(strokeColor);
      this.stroke!.setStyle(Style.STROKE);
      this.stroke!.setStrokeWidth(strokeWidth);
      //this.stroke.setTextSize(fontSize);
      if (strokeDasharray != null) stroke!.setStrokeDasharray(strokeDasharray);
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
  bool shouldPaint(BoundingBox? boundary, int zoomLevel) {
    return minZoomLevel <= zoomLevel &&
        maxZoomLevel >= zoomLevel &&
        boundary!.intersects(BoundingBox(
          minLatLon.latitude,
          minLatLon.longitude,
          maxLatLon.latitude,
          maxLatLon.longitude,
        ));
  }

  @override
  void renderBitmap(MarkerCallback markerCallback, int zoomLevel) {
    MapRect mapRect = GraphicFactory().createRect(
        markerCallback.mapViewPosition.projection!
                .longitudeToPixelX(minLatLon.longitude) -
            markerCallback.mapViewPosition.leftUpper!.x,
        markerCallback.mapViewPosition.projection!
                .latitudeToPixelY(maxLatLon.latitude) -
            markerCallback.mapViewPosition.leftUpper!.y,
        markerCallback.mapViewPosition.projection!
                .longitudeToPixelX(maxLatLon.longitude) -
            markerCallback.mapViewPosition.leftUpper!.x,
        markerCallback.mapViewPosition.projection!
                .latitudeToPixelY(minLatLon.latitude) -
            markerCallback.mapViewPosition.leftUpper!.y);

//    markerCallback.renderRect(mapRect, stroke);

    if (fill != null) markerCallback.renderRect(mapRect, fill!);
    if (stroke != null) markerCallback.renderRect(mapRect, stroke!);
  }

  @override
  bool isTapped(
      MapViewPosition mapViewPosition, double tappedX, double tappedY) {
    ILatLong latLong = mapViewPosition.projection!.pixelToLatLong(
        tappedX + mapViewPosition.leftUpper!.x,
        tappedY + mapViewPosition.leftUpper!.y);
    //print("Testing ${latLong.toString()} against ${title}");
    return latLong.latitude > minLatLon.latitude &&
        latLong.latitude < maxLatLon.latitude &&
        latLong.longitude > minLatLon.longitude &&
        latLong.longitude < maxLatLon.longitude;
  }
}
