import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/renderer.dart';
import 'package:datastore_renderer/shape_painter.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/marker/abstract_poi_marker.dart';
import 'package:mapsforge_view/src/marker/caption_mixin.dart';

class CircleMarker<T> extends AbstractPoiMarker<T> with CaptionMixin {
  late RenderinstructionCircle renderinstruction;

  RenderInfoNode<RenderinstructionCircle>? renderInfo;

  CircleMarker({
    super.zoomlevelRange,
    super.key,
    required super.latLong,
    MapPositioning position = MapPositioning.CENTER,
    int bitmapColor = 0xff000000,
    double radius = 10,
    int fillColor = 0x00000000,
    int strokeColor = 0xff000000,
    double strokeWidth = 2.0,
    int? strokeMinZoomLevel,
  }) {
    renderinstruction = RenderinstructionCircle(0);
    renderinstruction.radius = radius;
    renderinstruction.fillColor = fillColor;
    renderinstruction.strokeColor = strokeColor;
    renderinstruction.position = position;
    renderinstruction.setStrokeWidth(strokeWidth);
    if (strokeMinZoomLevel != null) renderinstruction.setStrokeMinZoomLevel(strokeMinZoomLevel);
  }

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
  }

  @override
  Future<void> changeZoomlevel(int zoomlevel, PixelProjection projection) async {
    //renderInfo?.shapePainter?.dispose();
    RenderinstructionCircle renderinstructionZoomed = renderinstruction.forZoomlevel(zoomlevel);
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
    assert(renderInfo != null, "renderInfo is null, maybe changeZoomlevel() was not called");
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

  void setLatLong(ILatLong latLong, PixelProjection projection) {
    super.latLong = latLong;
    NodeProperties nodeProperties = NodeProperties(PointOfInterest(0, [], latLong), projection);
    RenderInfoNode<RenderinstructionCircle> renderInfoNew = RenderInfoNode(nodeProperties, renderInfo!.renderInstruction);
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
