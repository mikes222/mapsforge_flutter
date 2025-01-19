import '../../core.dart';
import '../../marker.dart';
import '../model/maprectangle.dart';
import '../paintelements/shape_paint_caption.dart';
import '../rendertheme/shape/shape_caption.dart';

mixin class CaptionMixin {
  List<Caption> _captions = [];

  void addCaption(Caption caption) {
    _captions.add(caption);
  }

  void removeCaption(Caption caption) {
    _captions.remove(caption);
  }

  void removeCaptionPerText(String caption) {
    _captions.removeWhere((captionObject) => captionObject.caption == caption);
  }

  bool hasCaptions() {
    return _captions.isNotEmpty;
  }

  void removeAllCaptions() {
    _captions.clear();
  }

  List<Caption> get captions => _captions;

  void renderMarker(
      {required MapCanvas flutterCanvas,
      required MarkerContext markerContext,
      required MapRectangle symbolBoundary,
      required Mappoint coordinatesAbsolute}) {
    _captions.forEach((caption) {
      caption.renderCaption(
          flutterCanvas: flutterCanvas,
          markerContext: markerContext,
          coordinatesAbsolute: coordinatesAbsolute,
          symbolBoundary: symbolBoundary);
    });
  }
}

//////////////////////////////////////////////////////////////////////////////

class Caption {
  static final double DEFAULT_GAP = 2;

  String _caption;

  late ShapePaintCaption shapePaint;

  late ShapeCaption base;

  ShapeCaption? scaled;

  final Position position;

  final double dy;

  int minZoomLevel = 0;

  int maxZoomLevel = 65535;

  int _lastZoomLevel = -1;

  Caption({
    required String caption,
    double strokeWidth = 2.0,
    int strokeColor = 0xffffffff,
    int fillColor = 0xff000000,
    double fontSize = 10.0,
    int this.minZoomLevel = 0,
    int this.maxZoomLevel = 65535,
    this.position = Position.BELOW,
    this.dy = 0,
    int strokeMinZoomLevel = DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT,
    required DisplayModel displayModel,
  })  : assert(strokeWidth >= 0),
        assert(minZoomLevel >= 0),
        assert(minZoomLevel <= maxZoomLevel),
        _caption = caption /*assert(text.length > 0)*/
  {
    base = ShapeCaption.base(0);
    base.setStrokeWidth(strokeWidth * displayModel.getFontScaleFactor());
    base.setStrokeColorFromNumber(strokeColor);
    base.setFillColorFromNumber(fillColor);
    base.setFontSize(fontSize * displayModel.getFontScaleFactor());
    base.position = position;
    base.maxTextWidth = displayModel.getMaxTextWidth();
    base.gap = DEFAULT_GAP * displayModel.getFontScaleFactor();
    base.setStrokeMinZoomLevel(strokeMinZoomLevel);
    base.dy = dy;
  }

  void renderCaption(
      {required MapCanvas flutterCanvas,
      required MarkerContext markerContext,
      MapRectangle? symbolBoundary,
      required Mappoint coordinatesAbsolute}) {
    if (markerContext.zoomLevel < minZoomLevel) return;
    if (markerContext.zoomLevel > maxZoomLevel) return;

    if (scaled == null || _lastZoomLevel != markerContext.zoomLevel) {
      scaled = ShapeCaption.scale(base, markerContext.zoomLevel);
      _lastZoomLevel = markerContext.zoomLevel;
      shapePaint = ShapePaintCaption(scaled!,
          caption: _caption, symbolBoundary: symbolBoundary);
    }
    // print(
    //     "renderCaption $_caption for $minZoomLevel and $maxZoomLevel at ${markerContext.zoomLevel} $coordinatesAbsolute ${markerContext.mapCenter}");
    shapePaint.renderNode(
      flutterCanvas,
      coordinatesAbsolute,
      markerContext.mapCenter,
      markerContext.rotationRadian,
    );
  }

  void set caption(String caption) {
    this._caption = caption;
    if (scaled != null) shapePaint.setCaption(caption);
  }

  String get caption => _caption;

  void setStrokeColorFromNumber(int strokeColor) {
    base.setStrokeColorFromNumber(strokeColor);
    if (scaled != null) shapePaint.reinit(_caption);
  }

  void setFillColorFromNumber(int fillColor) {
    base.setFillColorFromNumber(fillColor);
    if (scaled != null) shapePaint.reinit(_caption);
  }
}
