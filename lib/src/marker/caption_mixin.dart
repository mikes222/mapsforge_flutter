import '../../core.dart';
import '../../marker.dart';
import '../model/maprectangle.dart';
import '../paintelements/shape_paint_caption.dart';
import '../rendertheme/shape/shape_caption.dart';
import '../rendertheme/shape/shape_symbol.dart';
import '../rendertheme/xml/symbol_finder.dart';

mixin class CaptionMixin {
  _SpecialSymbolFinder symbolFinder = _SpecialSymbolFinder(null);

  List<Caption> _captions = [];

  Caption? addCaption({
    required String caption,
    double strokeWidth = 2.0,
    int strokeColor = 0xffffffff,
    int fillColor = 0xff000000,
    double fontSize = 10.0,
    int minZoomLevel = 0,
    int maxZoomLevel = 65535,
    Position position = Position.BELOW,
    double dy = 0,
    int strokeMinZoomLevel = DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT,
    required DisplayModel displayModel,
  }) {
    if (caption.isEmpty) return null;
    Caption cp = Caption(
        caption: caption,
        strokeWidth: strokeWidth,
        strokeColor: strokeColor,
        fillColor: fillColor,
        fontSize: fontSize,
        minZoomLevel: minZoomLevel,
        maxZoomLevel: maxZoomLevel,
        position: position,
        dy: dy,
        strokeMinZoomLevel: strokeMinZoomLevel,
        displayModel: displayModel,
        symbolFinder: symbolFinder);
    _captions.add(cp);
    return cp;
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
      {required MapCanvas flutterCanvas, required MarkerContext markerContext, required MapRectangle symbolBoundary, required Mappoint coordinatesAbsolute}) {
    _captions.forEach((caption) {
      caption.renderCaption(flutterCanvas: flutterCanvas, markerContext: markerContext, coordinatesAbsolute: coordinatesAbsolute);
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

  int minZoomLevel = 0;

  int maxZoomLevel = 65535;

  int _lastZoomLevel = -1;

  final SymbolFinder symbolFinder;

  Caption({
    required String caption,
    double strokeWidth = 2.0,
    int strokeColor = 0xffffffff,
    int fillColor = 0xff000000,
    double fontSize = 10.0,
    int this.minZoomLevel = 0,
    int this.maxZoomLevel = 65535,
    this.position = Position.BELOW,
    double dy = 0,
    int strokeMinZoomLevel = DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT,
    required DisplayModel displayModel,
    required this.symbolFinder,
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
    base.symbolId = "poi";
  }

  void renderCaption({required MapCanvas flutterCanvas, required MarkerContext markerContext, required Mappoint coordinatesAbsolute}) {
    if (markerContext.zoomLevel < minZoomLevel) return;
    if (markerContext.zoomLevel > maxZoomLevel) return;

    if (scaled == null || _lastZoomLevel != markerContext.zoomLevel) {
      scaled = ShapeCaption.scale(base, markerContext.zoomLevel, symbolFinder);
      _lastZoomLevel = markerContext.zoomLevel;
      shapePaint = ShapePaintCaption.forMarker(scaled!, caption: _caption);
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

//////////////////////////////////////////////////////////////////////////////

/// Holds exactly one symbol - the symbol which is connected to the caption(s)
class _SpecialSymbolFinder extends SymbolFinder {
  final SymbolHolder _symbolHolder = SymbolHolder();

  _SpecialSymbolFinder(super.parentSymbolFinder);

  @override
  void add(String symbolId, ShapeSymbol shapeSymbol) {
    _symbolHolder.shapeSymbol = shapeSymbol;
  }

  @override
  SymbolHolder? search(String symbolId) {
    return _symbolHolder;
  }

  @override
  SymbolHolder findSymbolHolder(String symbolId) {
    return _symbolHolder;
  }
}
