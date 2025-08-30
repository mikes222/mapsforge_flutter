import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/renderer.dart';
import 'package:datastore_renderer/shape_painter.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/marker.dart';

/// A Marker which draws a rectangle specified by the min/max lat/lon attributes. Currently there is no way
/// to position captions other than in the center of the rectangle (RenderinstructionPath always returns Boundary.zero since it does not have any information
/// about the actual size of the rectangle).
class AreaMarker<T> extends Marker<T> {
  late RenderinstructionArea renderinstruction;

  RenderInfoWay<RenderinstructionArea>? renderInfo;

  List<ILatLong> path = [];

  AreaMarker({
    super.zoomlevelRange,
    super.key,
    double strokeWidth = 2.0,
    int strokeColor = 0xff000000,
    int fillColor = 0xff000000,
    List<double>? strokeDasharray,
    this.path = const [],
    int? strokeMinZoomLevel,
  }) {
    renderinstruction = RenderinstructionArea(0);
    renderinstruction.setStrokeColorFromNumber(strokeColor);
    renderinstruction.setStrokeWidth(strokeWidth);
    renderinstruction.setStrokeDashArray(strokeDasharray);
    renderinstruction.setFillColorFromNumber(fillColor);
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
    RenderinstructionArea renderinstructionZoomed = renderinstruction.forZoomlevel(zoomlevel, 0);
    WayProperties wayProperties = WayProperties(Way(0, [], [path], null), projection);
    renderInfo = RenderInfoWay(wayProperties, renderinstructionZoomed);
    await PainterFactory().createShapePainter(renderInfo!);
  }

  ///
  /// Renders this object. Called by markerPainter
  ///
  @override
  void render(UiRenderContext renderContext) {
    if (!zoomlevelRange.isWithin(renderContext.projection.scalefactor.zoomlevel)) return;
    assert(renderInfo != null, "renderInfo is null, maybe changeZoomlevel() was not called");
    renderInfo!.render(renderContext);
  }

  @override
  bool isTapped(TapEvent tapEvent) {
    return LatLongUtils.contains(path, tapEvent);
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

  Future<void> addLatLong(ILatLong latLong, PixelProjection projection) async {
    path.add(latLong);
    WayProperties wayProperties = WayProperties(Way(0, [], [path], null), projection);
    RenderInfoWay<RenderinstructionArea> renderInfoNew = RenderInfoWay(wayProperties, renderInfo!.renderInstruction);
    renderInfoNew.shapePainter = await PainterFactory().createShapePainter(renderInfo!);
    renderInfo = renderInfoNew;
  }
}
