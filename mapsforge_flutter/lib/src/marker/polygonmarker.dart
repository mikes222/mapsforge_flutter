import 'package:mapsforge_flutter/src/cache/symbolcache.dart';
import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';
import 'package:mapsforge_flutter/src/graphics/style.dart';
import 'package:mapsforge_flutter/src/model/boundingbox.dart';
import 'package:mapsforge_flutter/src/model/ilatlong.dart';
import 'package:mapsforge_flutter/src/renderer/geometryutils.dart';

import 'basicmarker.dart';
import 'markercallback.dart';

class PolygonMarker<T> extends BasicMarker<T> {
  List<ILatLong> path = List();

  MapPaint fill;

  double fillWidth;

  int fillColor;

  MapPaint stroke;

  final double strokeWidth;

  final int strokeColor;

  bool bitmapInvalid;
  Bitmap shaderBitmap;
  String src;
  SymbolCache symbolCache;
  final int width;

  final int height;

  final int percent;

  PolygonMarker({
    this.symbolCache,
    display = Display.ALWAYS,
    minZoomLevel = 0,
    maxZoomLevel = 65535,
    imageColor = 0xff000000,
    rotation,
    item,
    markerCaption,
    this.width = 20,
    this.height = 20,
    this.percent,
    this.fillWidth = 1.0,
    this.fillColor = 0x40000000,
    this.strokeWidth = 1.0,
    this.strokeColor = 0xff000000,
    this.src,
  })  : assert(display != null),
        assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(rotation == null || (rotation >= 0 && rotation <= 360)),
        assert(strokeWidth >= 0),
        assert(fillWidth >= 0),
        assert(strokeColor != null),
        assert(fillColor != null),
        assert(imageColor != null),
        assert(src == null || (symbolCache != null)),
        super(
          display: display,
          minZoomLevel: minZoomLevel,
          maxZoomLevel: maxZoomLevel,
          imageColor: imageColor,
          rotation: rotation,
          item: item,
          markerCaption: markerCaption,
        );

  void addLatLong(ILatLong latLong) {
    path.add(latLong);
  }

  @override
  void initResources(MarkerCallback markerCallback) {
    super.initResources(markerCallback);
    if (fill == null && fillWidth > 0) {
      this.fill = markerCallback.graphicFactory.createPaint();
      this.fill.setColorFromNumber(fillColor);
      this.fill.setStyle(Style.FILL);
      this.fill.setStrokeWidth(fillWidth);
      //this.stroke.setTextSize(fontSize);
    }
    if (stroke == null && strokeWidth > 0) {
      this.stroke = markerCallback.graphicFactory.createPaint();
      this.stroke.setColorFromNumber(strokeColor);
      this.stroke.setStyle(Style.STROKE);
      this.stroke.setStrokeWidth(strokeWidth);
      //this.stroke.setTextSize(fontSize);
    }
    if (bitmapInvalid == null && src != null && !src.isEmpty) {
      try {
        shaderBitmap = symbolCache.getBitmap(src, width.round(), height.round(), percent);
        if (shaderBitmap != null) {
          bitmapInvalid = false;
          fill.setBitmapShader(shaderBitmap);
          shaderBitmap.incrementRefCount();
        }
      } catch (ioException, stacktrace) {
        print(ioException.toString());
        //print(stacktrace);
        bitmapInvalid = true;
      }
    }
    if (markerCaption != null && markerCaption.latLong == null) {
      markerCaption.latLong = GeometryUtils.calculateCenter(path);
//      List<Mappoint> points = path
//          .map((latLong) => markerCallback.mapViewPosition.mercatorProjection
//                  .getPixelRelativeToLeftUpper(latLong, markerCallback.mapViewPosition.leftUpper)
////          Mappoint(markerCallback.mapViewPosition.mercatorProjection.longitudeToPixelX(latLong.longitude),
////              markerCallback.mapViewPosition.mercatorProjection.latitudeToPixelY(latLong.latitude))
//              )
//          .toList();
//      Mappoint center = GeometryUtils.calculateCenterOfBoundingBox(points);
    }
  }

  @override
  bool shouldPaint(BoundingBox boundary, int zoomLevel) {
    return minZoomLevel <= zoomLevel && maxZoomLevel >= zoomLevel;
  }

  @override
  void renderBitmap(MarkerCallback markerCallback) {
    MapPath mapPath = markerCallback.graphicFactory.createPath();

    path.forEach((latLong) {
      double y =
          markerCallback.mapViewPosition.mercatorProjection.latitudeToPixelY(latLong.latitude) - markerCallback.mapViewPosition.leftUpper.y;
      double x = markerCallback.mapViewPosition.mercatorProjection.longitudeToPixelX(latLong.longitude) -
          markerCallback.mapViewPosition.leftUpper.x;

      if (mapPath.isEmpty())
        mapPath.moveTo(x, y);
      else
        mapPath.lineTo(x, y);
    });
    mapPath.close();
    if (fill != null) markerCallback.renderPath(mapPath, fill);
    if (stroke != null) markerCallback.renderPath(mapPath, stroke);
  }
}
