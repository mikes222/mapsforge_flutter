import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/cache/symbolcache.dart';
import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';
import 'package:mapsforge_flutter/src/graphics/style.dart';
import 'package:mapsforge_flutter/src/model/boundingbox.dart';
import 'package:mapsforge_flutter/src/model/ilatlong.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';
import 'package:mapsforge_flutter/src/renderer/geometryutils.dart';
import 'package:mapsforge_flutter/src/utils/latlongutils.dart';

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

  Bitmap _bitmap;

  bool _bitmapInvalid = false;

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
    this.fillColor,
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
        //assert(fillColor != null),
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
  Future<void> initResources(GraphicFactory graphicFactory) async {
    if (init) return;
    super.initResources(graphicFactory);
    if (fill == null && fillColor != null) {
      this.fill = graphicFactory.createPaint();
      this.fill.setColorFromNumber(fillColor);
      this.fill.setStyle(Style.FILL);
      this.fill.setStrokeWidth(fillWidth);
      //this.stroke.setTextSize(fontSize);
    }
    if (stroke == null && strokeWidth > 0) {
      this.stroke = graphicFactory.createPaint();
      this.stroke.setColorFromNumber(strokeColor);
      this.stroke.setStyle(Style.STROKE);
      this.stroke.setStrokeWidth(strokeWidth);
      //this.stroke.setTextSize(fontSize);
    }
    if (_bitmapInvalid == null && src != null && !src.isEmpty && fill != null) {
      try {
        this._bitmap = await symbolCache.getOrCreateBitmap(graphicFactory, src, width, height, percent);
        if (_bitmap != null) {
          _bitmapInvalid = false;
          fill.setBitmapShader(_bitmap);
          _bitmap.incrementRefCount();
        }
      } catch (ioException, stacktrace) {
        print(ioException.toString());
        //print(stacktrace);
        _bitmapInvalid = true;
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

  @override
  bool isTapped(MapViewPosition mapViewPosition, double tappedX, double tappedY) {
    ILatLong latLong =
        mapViewPosition.mercatorProjection.getLatLong(tappedX + mapViewPosition.leftUpper.x, tappedY + mapViewPosition.leftUpper.y);
    //print("Testing ${latLong.toString()} against ${title}");
    return LatLongUtils.contains(path, latLong);
  }
}
