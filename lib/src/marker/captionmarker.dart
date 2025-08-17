import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/symbol_finder.dart';

import '../../marker.dart';

class CaptionMarker<T> extends BasicPointMarker<T> {
  static final double DEFAULT_GAP = 2;

  Caption caption;

  CaptionMarker({
    required String caption,
    required ILatLong latLong,
    double strokeWidth = 2.0,
    int strokeColor = 0xffffffff,
    int fillColor = 0xff000000,
    double fontSize = 10.0,
    int minZoomLevel = 0,
    int maxZoomLevel = 65535,
    double maxTextWidth = 200,
    double dy = 0,
    required DisplayModel displayModel,
    int strokeMinZoomLevel = DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT,
  })  : caption = Caption(
          caption: caption,
          displayModel: displayModel,
          strokeWidth: strokeWidth * displayModel.getFontScaleFactor(),
          strokeColor: strokeColor,
          fillColor: fillColor,
          fontSize: fontSize * displayModel.getFontScaleFactor(),
          dy: dy,
          symbolFinder: SymbolFinder(null),
        ),
        super(
            latLong: latLong,
            minZoomLevel: minZoomLevel,
            maxZoomLevel: maxZoomLevel) {
    // base.maxTextWidth = maxTextWidth;
    // base.setStrokeMinZoomLevel(strokeMinZoomLevel);
    setLatLong(latLong);
  }

  ///
  /// Renders this object. Called by markerPainter
  ///
  @override
  void render(MapCanvas flutterCanvas, MarkerContext markerContext) {
    super.render(flutterCanvas, markerContext);
    caption.renderCaption(
      flutterCanvas: flutterCanvas,
      markerContext: markerContext,
      coordinatesAbsolute: markerContext.projection.latLonToPixel(latLong),
    );
  }

  @override
  void renderBitmap(MapCanvas flutterCanvas, MarkerContext markerContext) {}
}
