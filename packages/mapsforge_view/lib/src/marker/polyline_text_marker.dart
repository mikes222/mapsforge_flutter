import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
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
class PolylineTextMarker<T> extends Marker<T> {
  late RenderinstructionPolylineText renderinstruction;

  RenderInfoWay<RenderinstructionPolylineText>? renderInfo;

  List<ILatLong> path = [];

  final String caption;

  PolylineTextMarker({
    super.zoomlevelRange,
    super.key,
    required this.caption,
    double strokeWidth = 2.0,
    int strokeColor = 0xffffffff,
    int fillColor = 0xff000000,
    List<double>? strokeDasharray,
    this.path = const [],
    double fontSize = 10.0,
    double maxFontSize = 50.0,
    double repeatStart = 10,
    double repeatGap = 100,
  }) {
    renderinstruction = RenderinstructionPolylineText(0);
    renderinstruction.setStrokeColorFromNumber(strokeColor);
    renderinstruction.setStrokeWidth(strokeWidth);
    renderinstruction.setStrokeDashArray(strokeDasharray);
    renderinstruction.setFillColorFromNumber(fillColor);
    renderinstruction.setFontSize(fontSize);
    renderinstruction.setRepeatStart(repeatStart);
    renderinstruction.setRepeatGap(repeatGap);
    renderinstruction.setMaxFontSize(maxFontSize);
  }

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
  }

  @override
  Future<void> changeZoomlevel(int zoomlevel, PixelProjection projection) async {
    //renderInfo?.shapePainter?.dispose();
    RenderinstructionPolylineText renderinstructionZoomed = renderinstruction.forZoomlevel(zoomlevel);
    WayProperties wayProperties = WayProperties(Way(0, [], [path], null), projection);
    renderInfo = RenderInfoWay(wayProperties, renderinstructionZoomed, caption: caption);
    await PainterFactory().createShapePainter(renderInfo!);
  }

  ///
  /// Renders this object. Called by markerPainter
  ///
  @override
  void render(UiRenderContext renderContext) {
    if (!zoomlevelRange.isWithin(renderContext.projection.scalefactor.zoomlevel)) return;
    assert(renderInfo != null, "renderInfo is null, maybe changeZoomlevel() was not called");
    renderInfo?.render(renderContext);
  }

  @override
  bool isTapped(TapEvent tapEvent) {
    return indexOfTappedPath(tapEvent) >= 0;
  }

  int indexOfTappedPath(TapEvent tapEvent) {
    Mappoint tapped = tapEvent.mappoint;
    for (int idx = 0; idx < path.length - 1; ++idx) {
      Mappoint point0 = tapEvent.projection.latLonToPixel(path[idx]);
      Mappoint point1 = tapEvent.projection.latLonToPixel(path[idx + 1]);
      double distance = LatLongUtils.distanceSegmentPoint(point0.x, point0.y, point1.x, point1.y, tapped.x, tapped.y);
      if (distance <= renderInfo!.renderInstruction.fontSize) return idx;
    }
    return -1;
  }

  Future<void> addLatLong(ILatLong latLong, PixelProjection projection) async {
    path.add(latLong);
    WayProperties wayProperties = WayProperties(Way(0, [], [path], null), projection);
    RenderInfoWay<RenderinstructionPolylineText> renderInfoNew = RenderInfoWay(wayProperties, renderInfo!.renderInstruction);
    renderInfoNew.shapePainter = await PainterFactory().createShapePainter(renderInfo!);
    renderInfo = renderInfoNew;
  }
}
