import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';
import 'package:mapsforge_flutter/src/graphics/style.dart';
import 'package:mapsforge_flutter/src/renderer/geometryutils.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/bitmapmixin.dart';

import 'basicmarker.dart';
import 'markercallback.dart';

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
    MarkerCaption? markerCaption,
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
          markerCaption: markerCaption,
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
    if (markerCaption != null && markerCaption!.latLong == null) {
      markerCaption!.latLong = GeometryUtils.calculateCenter(path);
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
  void renderBitmap(MarkerCallback markerCallback) {
    mapPath ??= GraphicFactory().createPath();

    if (_zoom == markerCallback.mapViewPosition.zoomLevel) {
      markerCallback.flutterCanvas.uiCanvas.save();
      Mappoint leftUpper = markerCallback.mapViewPosition
          .getLeftUpper(markerCallback.viewModel.mapDimension);
      markerCallback.flutterCanvas.uiCanvas
          .translate(_leftUpperX - leftUpper.x, _leftUpperY - leftUpper.y);
      if (fill != null) markerCallback.renderPath(mapPath!, fill!);
      if (stroke != null) markerCallback.renderPath(mapPath!, stroke!);
      markerCallback.flutterCanvas.uiCanvas.restore();
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
      _zoom = markerCallback.mapViewPosition.zoomLevel;
      Mappoint leftUpper = markerCallback.mapViewPosition
          .getLeftUpper(markerCallback.viewModel.mapDimension);
      path.forEach((latLong) {
        Mappoint mappoint = Mappoint(
            markerCallback.mapViewPosition.projection
                .longitudeToPixelX(latLong.longitude),
            markerCallback.mapViewPosition.projection
                .latitudeToPixelY(latLong.latitude));
        double y = mappoint.y - leftUpper.y;
        double x = mappoint.x - leftUpper.x;

        _points.add(mappoint);

        if (mapPath!.isEmpty())
          mapPath!.moveTo(x, y);
        else
          mapPath!.lineTo(x, y);
      });
      mapPath!.close();
      _leftUpperX = leftUpper.x;
      _leftUpperY = leftUpper.y;
    }
    if (fill != null) markerCallback.renderPath(mapPath!, fill!);
    if (stroke != null) markerCallback.renderPath(mapPath!, stroke!);
  }

  @override
  bool isTapped(TapEvent tapEvent) {
    //print("Testing ${latLong.toString()} against ${title}");
    return LatLongUtils.contains(path, tapEvent);
  }
}
