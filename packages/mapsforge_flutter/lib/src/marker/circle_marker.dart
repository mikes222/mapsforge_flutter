import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/marker/abstract_poi_marker.dart';
import 'package:mapsforge_flutter/src/marker/caption_mixin.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/shape_painter.dart';
import 'package:mapsforge_flutter_renderer/ui.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';

class CircleMarker<T> extends AbstractPoiMarker<T> with CaptionMixin {
  late final RenderinstructionCircle renderinstruction;

  RenderInfoNode<RenderinstructionCircle>? renderInfo;

  CircleMarker({
    super.zoomlevelRange,
    super.key,
    required super.latLong,
    MapPositioning position = MapPositioning.CENTER,
    int bitmapColor = 0xff000000,
    double radius = 10,
    int fillColor = 0x00000000, // transparent
    int strokeColor = 0xff000000, // black
    double strokeWidth = 2.0,
    int? strokeMinZoomLevel,
  }) {
    renderinstruction = RenderinstructionCircle(0);
    renderinstruction.radius = radius;
    renderinstruction.fillColor = fillColor;
    renderinstruction.setStrokeColorFromNumber(strokeColor);
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
    RenderinstructionCircle renderinstructionZoomed = renderinstruction.forZoomlevel(zoomlevel, 0);
    NodeProperties nodeProperties = NodeProperties(PointOfInterest.simple(latLong), projection);
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
    MapRectangle boundary = renderinstruction.getBoundary(renderInfo!);
    bool tpd =
        tapped.x >= absolute.x + boundary.left &&
        tapped.x <= absolute.x + boundary.right &&
        tapped.y >= absolute.y + boundary.top &&
        tapped.y <= absolute.y + boundary.bottom;
    return tpd;
  }

  void setLatLong(ILatLong latLong, PixelProjection projection) {
    super.latLong = latLong;
    NodeProperties nodeProperties = NodeProperties(PointOfInterest.simple(latLong), projection);
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
    return renderInfo?.renderInstruction.getBoundary(renderInfo!);
  }

  // execute [markerChanged] after changing this property
  void setStrokeColorFromNumber(int color) {
    renderinstruction.setStrokeColorFromNumber(color);
  }

  // execute [markerChanged] after changing this property
  void setFillColorFromNumber(int color) {
    renderinstruction.setFillColorFromNumber(color);
  }
}
