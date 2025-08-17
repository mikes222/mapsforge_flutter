import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';
import 'package:mapsforge_flutter/src/graphics/style.dart';
import 'package:mapsforge_flutter/src/model/maprectangle.dart';
import 'package:mapsforge_flutter/src/rendertheme/bitmapmixin.dart';

import '../graphics/implementation/fluttercanvas.dart';

/// Draws a closed polygon. The optional text will be drawn in the middle
/// of the polygon.
class PolygonMarker<T> extends BasicMarker<T> with BitmapMixin {
  static final _log = new Logger('PolygonMarker');

  List<ILatLong> path = [];

  BoundingBox? _boundingBox;

  MapPaint? fill;

  int? fillColor;

  MapPaint? stroke;

  late final double strokeWidth;

  final List<double>? strokeDasharray;

  final int strokeColor;

  List<Mappoint> _points = [];

  int _zoom = -1;

  MapPath? mapPath;

  double _leftUpperX = -1;

  double _leftUpperY = -1;

  PolygonMarker({
    display = Display.ALWAYS,
    int minZoomLevel = 0,
    int maxZoomLevel = 65535,
    T? item,
    double bitmapWidth = 20,
    double bitmapHeight = 20,
    int bitmapPercent = 100,
    String? bitmapSrc,
    this.fillColor,
    double strokeWidth = 1.0,
    this.strokeColor = 0xff000000,
    this.strokeDasharray,
    required DisplayModel displayModel,
  })  : assert(display != null),
        assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(minZoomLevel <= maxZoomLevel),
        assert(strokeWidth >= 0),
        super(
          display: display,
          minZoomLevel: minZoomLevel,
          maxZoomLevel: maxZoomLevel,
          item: item,
        ) {
    this.bitmapWidth = bitmapWidth * displayModel.getScaleFactor();
    this.bitmapHeight = bitmapHeight * displayModel.getScaleFactor();
    this.bitmapPercent = bitmapPercent;
    this.bitmapSrc = bitmapSrc;
    this.strokeWidth = strokeWidth * displayModel.getScaleFactor();
    //if (bitmapSrc != null) fillColor = 0xff000000;
  }

  void addLatLong(ILatLong latLong) {
    path.add(latLong);
    _boundingBox = BoundingBox.fromLatLongs(path);
  }

  Future<void> initResources(SymbolCache? symbolCache) async {
    await initBitmap(symbolCache);
    if (fill == null && fillColor != null) {
      this.fill = GraphicFactory().createPaint();
      this.fill!.setColorFromNumber(fillColor!);
      this.fill!.setStyle(Style.FILL);
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
  }

  @override
  bool shouldPaint(BoundingBox boundary, int zoomLevel) {
    if (_boundingBox == null) return false;
    return minZoomLevel <= zoomLevel &&
        maxZoomLevel >= zoomLevel &&
        _boundingBox!.intersects(boundary);
  }

  @override
  void renderBitmap(MapCanvas mapCanvas, MarkerContext markerContext) {
    mapPath ??= GraphicFactory().createPath();

    if (_zoom == markerContext.zoomLevel) {
      (mapCanvas as FlutterCanvas).uiCanvas.save();
      (mapCanvas as FlutterCanvas).uiCanvas.translate(
          _leftUpperX - markerContext.mapCenter.x,
          _leftUpperY - markerContext.mapCenter.y);
      if (fill != null) mapCanvas.drawPath(mapPath!, fill!);
      if (stroke != null) mapCanvas.drawPath(mapPath!, stroke!);
      mapCanvas.uiCanvas.restore();
      return;
      // _points.forEach((mappoint) {
      //   double y = mappoint.y - markerCallback.mapViewPosition.leftUpper!.y;
      //   double x = mappoint.x - markerCallback.mapViewPosition.leftUpper!.x;
      //   if (mapPath!.isEmpty())
      //     mapPath!.moveTo(x, y);
      //   else
      //     mapPath!.lineTo(x, y);
      // });
    } else {
      mapPath!.clear();
      _points.clear();
      _zoom = markerContext.zoomLevel;
      path.forEach((latLong) {
        Mappoint mappoint = markerContext.projection.latLonToPixel(latLong);
        double y = mappoint.y - markerContext.mapCenter.y;
        double x = mappoint.x - markerContext.mapCenter.x;

        _points.add(mappoint);

        if (mapPath!.isEmpty())
          mapPath!.moveTo(x, y);
        else
          mapPath!.lineTo(x, y);
      });
      mapPath!.close();
      _leftUpperX = markerContext.mapCenter.x;
      _leftUpperY = markerContext.mapCenter.y;
    }
    if (fill != null) mapCanvas.drawPath(mapPath!, fill!);
    if (stroke != null) mapCanvas.drawPath(mapPath!, stroke!);
  }

  @override
  bool isTapped(TapEvent tapEvent) {
    //print("Testing ${latLong.toString()} against ${title}");
    return LatLongUtils.contains(path, tapEvent);
  }

  @override
  MapRectangle getSymbolBoundary() {
    // TODO: implement getSymbolBoundary
    throw UnimplementedError();
  }
}
