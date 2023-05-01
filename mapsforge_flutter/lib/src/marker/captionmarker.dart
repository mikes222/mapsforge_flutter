import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/src/model/maprectangle.dart';
import 'package:mapsforge_flutter/src/paintelements/shape_paint_caption.dart';
import 'package:mapsforge_flutter/src/rendertheme/nodeproperties.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_caption.dart';

import '../../marker.dart';

class CaptionMarker<T> extends BasicPointMarker<T> {
  static final double DEFAULT_GAP = 2;

  String caption;

  late ShapePaintCaption shapePaint;

  late NodeProperties nodeProperties;

  late ShapeCaption base;

  int _lastZoom = -1;

  ShapeCaption? scaled;

  MapRectangle? _symbolBoundary;

  final Position position;

  final double dy;

  CaptionMarker({
    required this.caption,
    required ILatLong latLong,
    double strokeWidth = 2.0,
    int strokeColor = 0xffffffff,
    int fillColor = 0xff000000,
    double fontSize = 10.0,
    int minZoomLevel = 0,
    int maxZoomLevel = 65535,
    double maxTextWidth = 200,
    this.dy = 0,
    this.position = Position.BELOW,
    required DisplayModel displayModel,
    int strokeMinZoomLevel = DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT,
  }) : super(
            latLong: latLong,
            minZoomLevel: minZoomLevel,
            maxZoomLevel: maxZoomLevel) {
    base = ShapeCaption.base();
    base.setStrokeWidth(strokeWidth * displayModel.getFontScaleFactor());
    base.setStrokeColorFromNumber(strokeColor);
    base.setFillColorFromNumber(fillColor);
    base.setFontSize(fontSize * displayModel.getFontScaleFactor());
    base.position = position;
    base.maxTextWidth = maxTextWidth;
    base.gap = DEFAULT_GAP * displayModel.getFontScaleFactor();
    base.setStrokeMinZoomLevel(strokeMinZoomLevel);
    base.dy = dy;
    setLatLong(latLong);
  }

  void setSymbolBoundary(MapRectangle symbolBoundary) {
    this._symbolBoundary = symbolBoundary;
    if (scaled != null)
      shapePaint = ShapePaintCaption(scaled!,
          caption: caption, symbolBoundary: _symbolBoundary);
  }

  @override
  void renderBitmap(MarkerCallback markerCallback) {
    if (scaled == null ||
        _lastZoom != markerCallback.mapViewPosition.zoomLevel) {
      scaled =
          ShapeCaption.scale(base, markerCallback.mapViewPosition.zoomLevel);
      _lastZoom = markerCallback.mapViewPosition.zoomLevel;
      shapePaint = ShapePaintCaption(scaled!,
          caption: caption, symbolBoundary: _symbolBoundary);
    }
    // print(
    //     "renderCaption $caption for $minZoomLevel and $maxZoomLevel at ${markerCallback.mapViewPosition.zoomLevel}");
    shapePaint.renderNode(
      markerCallback.flutterCanvas,
      nodeProperties,
      markerCallback.mapViewPosition.projection,
      markerCallback.mapViewPosition
          .getLeftUpper(markerCallback.viewModel.mapDimension),
      markerCallback.mapViewPosition.rotationRadian,
    );
  }

  void setDy(double dy) {
    base.setDy(dy);
    _lastZoom = -1;
  }

  double getFontSize() => base.fontSize;

  @override
  void setLatLong(ILatLong latLong) {
    super.setLatLong(latLong);
    nodeProperties = NodeProperties(PointOfInterest(0, [], latLong));
  }

  @override
  void set latLong(ILatLong latLong) {
    super.latLong = latLong;
    nodeProperties = NodeProperties(PointOfInterest(0, [], latLong));
  }
}
