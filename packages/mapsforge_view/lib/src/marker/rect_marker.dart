import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:dart_rendertheme/rendertheme.dart';
import 'package:datastore_renderer/renderer.dart';
import 'package:datastore_renderer/shape_painter.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/marker.dart';
import 'package:mapsforge_view/src/marker/caption_mixin.dart';
import 'package:mapsforge_view/src/marker/caption_reference.dart';

/// A Marker which draws a rectangle specified by the min/max lat/lon attributes. Currently there is no way
/// to position captions other than in the center of the rectangle (RenderinstructionRect always returns Boundary.zero since it does not have any information
/// about the actual size of the rectangle).
class RectMarker<T> extends Marker<T> with CaptionMixin implements SymbolSearcher, CaptionReference {
  late RenderinstructionRect renderinstruction;

  RenderInfoWay<RenderinstructionRect>? renderInfo;

  NodeProperties? nodeProperties;

  final ILatLong minLatLon;

  final ILatLong maxLatLon;

  late final ILatLong center;

  RectMarker({
    super.zoomlevelRange,
    super.key,
    String? bitmapSrc,
    int fillColor = 0x00000000,
    double strokeWidth = 2.0,
    int strokeColor = 0xff000000,
    List<double>? strokeDasharray,
    required this.minLatLon,
    required this.maxLatLon,
    int? strokeMinZoomLevel,

    /// Rotation of the poi in degrees clockwise
    double rotation = 0,
  }) {
    renderinstruction = RenderinstructionRect(0);
    renderinstruction.bitmapSrc = bitmapSrc;
    renderinstruction.setFillColorFromNumber(fillColor);
    renderinstruction.setStrokeColorFromNumber(strokeColor);
    renderinstruction.setStrokeWidth(strokeWidth);
    renderinstruction.setStrokeDashArray(strokeDasharray);
    renderinstruction.setBitmapMinZoomLevel(MapsforgeSettingsMgr().strokeMinZoomlevelText);
    if (strokeMinZoomLevel != null) renderinstruction.setStrokeMinZoomLevel(strokeMinZoomLevel);

    center = LatLong((minLatLon.latitude + maxLatLon.latitude) / 2, (minLatLon.longitude + maxLatLon.longitude) / 2);
  }

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
  }

  @override
  Future<void> changeZoomlevel(int zoomlevel, PixelProjection projection) async {
    //renderInfo?.shapePainter?.dispose();
    RenderinstructionRect renderinstructionZoomed = renderinstruction.forZoomlevel(zoomlevel);
    nodeProperties = NodeProperties(PointOfInterest(0, [], center), projection);
    WayProperties wayProperties = WayProperties(
      Way(0, [], [
        [minLatLon, maxLatLon],
      ], null),
      projection,
    );
    renderInfo = RenderInfoWay(wayProperties, renderinstructionZoomed);
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
    renderCaptions(renderContext: renderContext, nodeProperties: nodeProperties!);

    renderInfo?.render(renderContext);
  }

  @override
  bool isTapped(TapEvent tapEvent) {
    return tapEvent.latitude > minLatLon.latitude &&
        tapEvent.latitude < maxLatLon.latitude &&
        tapEvent.longitude > minLatLon.longitude &&
        tapEvent.longitude < maxLatLon.longitude;
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

  @override
  MapRectangle? searchForSymbolBoundary(String symbolId) {
    return renderInfo?.renderInstruction.getBoundary();
  }

  @override
  ILatLong getReference() {
    return center;
  }
}
