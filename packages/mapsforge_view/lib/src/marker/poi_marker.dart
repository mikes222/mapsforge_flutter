import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/renderer.dart';
import 'package:datastore_renderer/shape_painter.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/marker/abstract_poi_marker.dart';
import 'package:mapsforge_view/src/marker/caption_mixin.dart';

class PoiMarker<T> extends AbstractPoiMarker<T> with CaptionMixin {
  late RenderinstructionSymbol renderinstruction;

  RenderInfoNode<RenderinstructionSymbol>? renderInfo;

  PoiMarker({
    super.zoomlevelRange,
    super.key,
    required super.latLong,
    Position position = Position.CENTER,
    bool rotateWithMap = false,
    required String src,
    int bitmapColor = 0xff000000,
    double width = 20,
    double height = 20,

    /// Rotation of the poi in degrees clockwise
    double rotation = 0,
  }) {
    renderinstruction = RenderinstructionSymbol(0);
    renderinstruction.bitmapSrc = src;
    renderinstruction.setBitmapColorFromNumber(bitmapColor);
    renderinstruction.setBitmapMinZoomLevel(MapsforgeSettingsMgr().strokeMinZoomlevelText);
    renderinstruction.theta = Projection.degToRadian(rotation);
    renderinstruction.setBitmapWidth(width.round());
    renderinstruction.setBitmapHeight(height.round());
    renderinstruction.position = position;
    renderinstruction.rotateWithMap = rotateWithMap;
  }

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
  }

  @override
  Future<void> changeZoomlevel(int zoomlevel, PixelProjection projection) async {
    //renderInfo?.shapePainter?.dispose();
    RenderinstructionSymbol renderinstructionZoomed = renderinstruction.forZoomlevel(zoomlevel);
    NodeProperties nodeProperties = NodeProperties(PointOfInterest(0, [], latLong), projection);
    renderInfo = RenderInfoNode(nodeProperties, renderinstructionZoomed);
    await PainterFactory().createShapePainter(renderInfo!);

    // captions needs the new renderinstruction so execute this method after renderInfo is created
    await changeZoomlevelCaptions(zoomlevel, projection);
  }

  ///
  /// Renders this object. Called by markerPainter
  ///
  @override
  void render(UiRenderContext renderContext) {
    if (!zoomlevelRange.isWithin(renderContext.projection.scalefactor.zoomlevel)) return;
    renderCaptions(renderContext: renderContext, nodeProperties: renderInfo!.nodeProperties);

    renderInfo?.render(renderContext);
  }

  @override
  bool isTapped(TapEvent tapEvent) {
    Mappoint absolute = renderInfo!.nodeProperties.getCoordinatesAbsolute();
    Mappoint tapped = tapEvent.projection.latLonToPixel(tapEvent);
    MapRectangle boundary = renderinstruction.getBoundary();
    bool tpd =
        tapped.x >= absolute.x + boundary.left &&
        tapped.x <= absolute.x + boundary.right &&
        tapped.y >= absolute.y + boundary.top &&
        tapped.y <= absolute.y + boundary.bottom;
    return tpd;
  }

  set rotation(double rotation) {
    renderinstruction.theta = Projection.degToRadian(rotation);
    renderInfo?.renderInstruction.theta = Projection.degToRadian(rotation);
  }

  Future<void> setBitmapColorFromNumber(int color) async {
    renderinstruction.setBitmapColorFromNumber(color);
    renderInfo!.renderInstruction.setBitmapColorFromNumber(color);
    await PainterFactory().createShapePainter(renderInfo!);
  }

  Future<void> setAndLoadBitmapSrc(String bitmapSrc) async {
    renderinstruction.bitmapSrc = bitmapSrc;
    renderInfo!.renderInstruction.setBitmapSrc(bitmapSrc);
    await PainterFactory().createShapePainter(renderInfo!);
  }

  void setLatLong(ILatLong latLong, PixelProjection projection) {
    super.latLong = latLong;
    NodeProperties nodeProperties = NodeProperties(PointOfInterest(0, [], latLong), projection);
    RenderInfoNode<RenderinstructionSymbol> renderInfoNew = RenderInfoNode(nodeProperties, renderInfo!.renderInstruction);
    renderInfoNew.shapePainter = renderInfo?.shapePainter;
    renderInfo = renderInfoNew;
  }

  @override
  set latLong(ILatLong latLong) {
    throw UnimplementedError("Use setLangLong instead");
  }

  @override
  MapRectangle? searchForSymbolBoundary(String symbolId) {
    return renderInfo?.renderInstruction.getBoundary();
  }
}
