import 'package:mapsforge_flutter/src/cache/symbolcache.dart';
import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/maprect.dart';
import 'package:mapsforge_flutter/src/graphics/style.dart';
import 'package:mapsforge_flutter/src/model/boundingbox.dart';
import 'package:mapsforge_flutter/src/model/ilatlong.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';
import 'package:meta/meta.dart';

import '../../core.dart';
import 'basicmarker.dart';
import 'markercallback.dart';

class RectMarker<T> extends BasicMarker<T> {
  ILatLong minLatLon;
  ILatLong maxLatLon;

  MapPaint fill;

  double fillWidth;

  int fillColor;

  MapPaint stroke;

  final double strokeWidth;

  final int strokeColor;

  bool _bitmapInvalid;
  Bitmap _bitmap;
  String src;
  SymbolCache symbolCache;
  final int width;

  final int height;

  final int percent;

  List<double> strokeDasharray;

  RectMarker({
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
    this.strokeDasharray,
    @required this.minLatLon,
    @required this.maxLatLon,
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
        assert(minLatLon != null),
        assert(maxLatLon != null),
        assert(strokeDasharray == null || strokeDasharray.length == 2),
        super(
          display: display,
          minZoomLevel: minZoomLevel,
          maxZoomLevel: maxZoomLevel,
          imageColor: imageColor,
          rotation: rotation,
          item: item,
          markerCaption: markerCaption,
        );

  @override
  Future<void> initResources(GraphicFactory graphicFactory) async {
    if (init) return;
    super.initResources(graphicFactory);
    if (fill == null && (fillColor != null || src != null)) {
      this.fill = graphicFactory.createPaint();
      if (fillColor != null)
        this.fill.setColorFromNumber(fillColor);
      else
        this.fill.setColorFromNumber(0x40000000);
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
      if (strokeDasharray != null) stroke.setStrokeDasharray(strokeDasharray);
    }
    if (_bitmapInvalid == null && src != null && !src.isEmpty) {
      try {
        this._bitmap = await symbolCache.getOrCreateBitmap(graphicFactory, src, width, height, percent);
        if (_bitmap != null) {
          _bitmapInvalid = false;
          fill.setBitmapShader(_bitmap);
          _bitmap.incrementRefCount();
        }
      } catch (ioException, stacktrace) {
        print(ioException.toString());
        print(stacktrace);
        _bitmapInvalid = true;
      }
    }
    if (markerCaption != null && markerCaption.latLong == null) {
      markerCaption.latLong = LatLong(minLatLon.latitude + (maxLatLon.latitude - minLatLon.latitude) / 2,
          minLatLon.longitude + (maxLatLon.longitude - minLatLon.longitude) / 2); //GeometryUtils.calculateCenter(path);
    }
  }

  @override
  bool shouldPaint(BoundingBox boundary, int zoomLevel) {
    return minZoomLevel <= zoomLevel &&
        maxZoomLevel >= zoomLevel &&
        boundary.intersects(BoundingBox(
          minLatLon.latitude,
          minLatLon.longitude,
          maxLatLon.latitude,
          maxLatLon.longitude,
        ));
  }

  @override
  void renderBitmap(MarkerCallback markerCallback) {
    MapRect mapRect = markerCallback.graphicFactory.createRect(
        markerCallback.mapViewPosition.mercatorProjection.longitudeToPixelX(minLatLon.longitude) -
            markerCallback.mapViewPosition.leftUpper.x,
        markerCallback.mapViewPosition.mercatorProjection.latitudeToPixelY(maxLatLon.latitude) - markerCallback.mapViewPosition.leftUpper.y,
        markerCallback.mapViewPosition.mercatorProjection.longitudeToPixelX(maxLatLon.longitude) -
            markerCallback.mapViewPosition.leftUpper.x,
        markerCallback.mapViewPosition.mercatorProjection.latitudeToPixelY(minLatLon.latitude) -
            markerCallback.mapViewPosition.leftUpper.y);

//    markerCallback.renderRect(mapRect, stroke);

    if (fill != null) markerCallback.renderRect(mapRect, fill);
    if (stroke != null) markerCallback.renderRect(mapRect, stroke);
  }

  @override
  bool isTapped(MapViewPosition mapViewPosition, double tappedX, double tappedY) {
    ILatLong latLong =
        mapViewPosition.mercatorProjection.getLatLong(tappedX + mapViewPosition.leftUpper.x, tappedY + mapViewPosition.leftUpper.y);
    //print("Testing ${latLong.toString()} against ${title}");
    return latLong.latitude > minLatLon.latitude &&
        latLong.latitude < maxLatLon.latitude &&
        latLong.longitude > minLatLon.longitude &&
        latLong.longitude < maxLatLon.longitude;
  }
}
