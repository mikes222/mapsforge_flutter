import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/src/model/maprectangle.dart';
import 'package:mapsforge_flutter/src/paintelements/shape_paint_caption.dart';
import 'package:mapsforge_flutter/src/rendertheme/nodeproperties.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_caption.dart';

import '../../marker.dart';
import '../graphics/mapcanvas.dart';

class CaptionMarker<T> extends BasicPointMarker<T> {
  static final double DEFAULT_GAP = 2;

  String caption;

  late ShapePaintCaption shapePaint;

  late NodeProperties nodeProperties;

  late ShapeCaption base;

  int _lastZoomLevel = -1;

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
    base = ShapeCaption.base(0);
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
  void renderBitmap(MapCanvas flutterCanvas, MarkerContext markerContext) {
    if (_lastZoomLevel != markerContext.zoomLevel) {
      // zoomLevel changed, set _coordinatesAbsolute cache to null
      nodeProperties.clearCache();
    }
    if (scaled == null || _lastZoomLevel != markerContext.zoomLevel) {
      scaled = ShapeCaption.scale(base, markerContext.zoomLevel);
      _lastZoomLevel = markerContext.zoomLevel;
      shapePaint = ShapePaintCaption(scaled!,
          caption: caption, symbolBoundary: _symbolBoundary);
    }
    // print(
    //     "renderCaption $caption for $minZoomLevel and $maxZoomLevel at ${markerCallback.mapViewPosition.zoomLevel}");
    shapePaint.renderNode(
      flutterCanvas,
      nodeProperties,
      markerContext.projection,
      markerContext.mapCenter,
      markerContext.rotationRadian,
    );
  }

  void setDy(double dy) {
    base.setDy(dy);
    _lastZoomLevel = -1;
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
