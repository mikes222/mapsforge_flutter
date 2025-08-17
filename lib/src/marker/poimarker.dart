import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/model/maprectangle.dart';

import '../../datastore.dart';
import '../../maps.dart';
import '../paintelements/shape_paint_symbol.dart';
import '../rendertheme/shape/shape_symbol.dart';

class PoiMarker<T> extends BasicPointMarker<T> with CaptionMixin {
  late ShapePaintSymbol shapePaint;

  late NodeProperties nodeProperties;

  late ShapeSymbol base;

  int _lastZoom = -1;

  ShapeSymbol? scaled;

  final bool rotateWithMap;

  final Position position;

  int _lastZoomLevel = -1;

  PoiMarker({
    Display display = Display.ALWAYS,
    required String src,
    double width = 20,
    double height = 20,
    required ILatLong latLong,
    int minZoomLevel = 0,
    int maxZoomLevel = 65535,
    int bitmapColor = 0xff000000,
    double rotation = 0,
    T? item,
    required DisplayModel displayModel,
    this.position = Position.CENTER,
    this.rotateWithMap = true,
  })  : assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(rotation >= 0 && rotation <= 360),
        assert(width > 0),
        assert(height > 0),
        super(
          display: display,
          minZoomLevel: minZoomLevel,
          maxZoomLevel: maxZoomLevel,
          item: item,
          latLong: latLong,
        ) {
    base = ShapeSymbol.base(0);
    setLatLong(latLong);
    base.setBitmapPercent(100 * displayModel.getFontScaleFactor().round());
    base.bitmapSrc = src;
    base.setBitmapColorFromNumber(bitmapColor);
    base.setBitmapMinZoomLevel(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    base.theta = Projection.degToRadian(rotation);
    base.setBitmapWidth(width.round());
    base.setBitmapHeight(height.round());
    base.position = position;
    base.id = "poi";
    symbolFinder.add("poi", base);
  }

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
  }

  Future<void> initResources(SymbolCache symbolCache) async {
    if (scaled == null) {
      scaled = ShapeSymbol.scale(base, 0, symbolFinder);
      _lastZoom = 0;
      shapePaint = await ShapePaintSymbol.create(scaled!, symbolCache);
      await shapePaint.init(symbolCache);
    }
  }

  void set rotation(double rotation) {
    base.theta = Projection.degToRadian(rotation);
    if (scaled != null) scaled!.theta = Projection.degToRadian(rotation);
  }

  void setBitmapColorFromNumber(int color) {
    base.setBitmapColorFromNumber(color);
  }

  Future<void> setAndLoadBitmapSrc(String bitmapSrc, SymbolCache symbolCache) async {
    base.bitmapSrc = bitmapSrc;
    scaled = null;
    await initResources(symbolCache);
  }

  ///
  /// Renders this object. Called by markerPainter
  ///
  @override
  void render(MapCanvas flutterCanvas, MarkerContext markerContext) {
    super.render(flutterCanvas, markerContext);
    renderMarker(
        flutterCanvas: flutterCanvas,
        markerContext: markerContext,
        coordinatesAbsolute: nodeProperties.getCoordinatesAbsolute(markerContext.projection),
        symbolBoundary: getSymbolBoundary());
  }

  @override
  void renderBitmap(MapCanvas flutterCanvas, MarkerContext markerContext) {
    // if (scaled == null ||
    //     _lastZoom != markerCallback.mapViewPosition.zoomLevel) {
    //   scaled =
    //       ShapeSymbol.scale(base, markerCallback.mapViewPosition.zoomLevel);
    //   _lastZoom = markerCallback.mapViewPosition.zoomLevel;
    //   //shapePaint = ShapePaintSymbol(scaled!);
    //   //shapePaint.init(symbolCache).then((value) {});
    // }
    // print(
    //     "renderCaption $caption for $minZoomLevel and $maxZoomLevel at ${markerCallback.mapViewPosition.zoomLevel}");
    if (_lastZoomLevel != markerContext.zoomLevel) {
      // zoomLevel changed, set _coordinatesAbsolute cache to null
      nodeProperties.clearCache();
    }
    _lastZoomLevel = markerContext.zoomLevel;
    shapePaint.renderNode(
      flutterCanvas,
      nodeProperties.getCoordinatesAbsolute(markerContext.projection),
      markerContext.mapCenter,
      rotateWithMap ? markerContext.rotationRadian : 0,
    );
  }

  @override
  bool isTapped(TapEvent tapEvent) {
    if (_lastZoomLevel != tapEvent.projection.scalefactor.zoomlevel) {
      // zoomLevel changed, set _coordinatesAbsolute cache to null
      nodeProperties.clearCache();
    }
    _lastZoomLevel = tapEvent.projection.scalefactor.zoomlevel;
    Mappoint absolute = nodeProperties.getCoordinatesAbsolute(tapEvent.projection);
    Mappoint tapped = tapEvent.projection.latLonToPixel(tapEvent);
    MapRectangle boundary = base.calculateBoundary();
    bool tpd = tapped.x >= absolute.x + boundary.left &&
        tapped.x <= absolute.x + boundary.right &&
        tapped.y >= absolute.y + boundary.top &&
        tapped.y <= absolute.y + boundary.bottom;
    // print(
    //     "src: ${base.bitmapSrc}, tapX: ${tapped.x}, absolute: ${absolute.x}, boundary: ${boundary.left} ${boundary.right}");
    // print(
    //     "src: ${base.bitmapSrc}, tapY: ${tapped.y}, absolute: ${absolute.y}, boundary: ${boundary.top} ${boundary.bottom}");
    // print("src: ${base.bitmapSrc}, tapped: $tpd");
    return tpd;
  }

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

  MapRectangle getSymbolBoundary() {
    return base.calculateBoundary();
  }
}
