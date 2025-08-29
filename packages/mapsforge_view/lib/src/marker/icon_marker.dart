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

class IconMarker<T> extends AbstractPoiMarker<T> with CaptionMixin {
  late RenderinstructionIcon renderinstruction;

  RenderInfoNode<RenderinstructionIcon>? renderInfo;

  IconMarker({
    super.zoomlevelRange,
    super.key,
    required super.latLong,
    MapPositioning position = MapPositioning.CENTER,
    bool rotateWithMap = false,
    required IconData iconData,
    int bitmapColor = 0xff000000,
    double size = 20,

    /// Rotation of the poi in degrees clockwise
    double rotation = 0,
  }) {
    renderinstruction = RenderinstructionIcon(0);
    renderinstruction.codePoint = iconData.codePoint;
    renderinstruction.fontFamily = iconData.fontFamily!;
    renderinstruction.setBitmapColorFromNumber(bitmapColor);
    renderinstruction.setBitmapMinZoomLevel(MapsforgeSettingsMgr().strokeMinZoomlevelText);
    renderinstruction.theta = Projection.degToRadian(rotation);
    renderinstruction.setBitmapWidth(size.round());
    renderinstruction.setBitmapHeight(size.round());
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
    RenderinstructionIcon renderinstructionZoomed = renderinstruction.forZoomlevel(zoomlevel, 0);
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
    assert(renderInfo != null, "renderInfo is null, maybe changeZoomlevel() was not called");
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
    RenderInfoNode<RenderinstructionIcon> renderInfoNew = RenderInfoNode(nodeProperties, renderInfo!.renderInstruction);
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
