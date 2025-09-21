import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_renderer/shape_painter.dart';
import 'package:mapsforge_flutter_renderer/ui.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';

/// A Marker which draws a closed polyline specified by a series of lat/lon attributes.
/// Note that there are fundamental differences to [PolylineMarker]:
/// - The area is assumed to be closed and adding/removing/changing points is not allowed
/// - The area can be filled with a color/bitmap which is not possible for open polylines
/// - isTapped checks if the tap event is inside the area as opposed to the polyline where the tap event must be at the line itself.
///
/// See also:
/// [PolylineMarker] which draws an open polyline.
class AreaMarker<T> extends Marker<T> {
  late final RenderinstructionArea renderinstruction;

  final Map<int, RenderinstructionArea> renderinstructionsZoomed = {};

  RenderInfoWay<RenderinstructionArea>? renderInfo;

  late final Waypath _path;

  AreaMarker({
    super.zoomlevelRange,
    super.key,
    double strokeWidth = 2.0,
    int strokeColor = 0xff000000,
    int fillColor = 0x00000000,
    List<double>? strokeDasharray,
    List<ILatLong> path = const [],
    int? strokeMinZoomLevel,
  }) {
    _path = path.isEmpty ? Waypath.empty() : Waypath(path: path);
    renderinstruction = RenderinstructionArea(0);
    renderinstruction.setStrokeColorFromNumber(strokeColor);
    renderinstruction.setStrokeWidth(strokeWidth);
    renderinstruction.setStrokeDashArray(strokeDasharray);
    renderinstruction.setFillColorFromNumber(fillColor);
    if (strokeMinZoomLevel != null) renderinstruction.setStrokeMinZoomLevel(strokeMinZoomLevel);
  }

  @override
  Future<void> changeZoomlevel(int zoomlevel, PixelProjection projection) async {
    assert(_path.isNotEmpty);
    //renderInfo?.shapePainter?.dispose();
    RenderinstructionArea renderinstructionZoomed = renderinstructionsZoomed.putIfAbsent(zoomlevel, () => renderinstruction.forZoomlevel(zoomlevel, 0));
    WayProperties wayProperties = WayProperties(Way.simple(_path.path), projection);
    renderInfo = RenderInfoWay(wayProperties, renderinstructionZoomed);
    await PainterFactory().getOrCreateShapePainter(renderInfo!);
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
    if (!zoomlevelRange.isWithin(tapEvent.projection.scalefactor.zoomlevel)) return false;
    return _path.contains(tapEvent.latLong);
  }

  // execute [markerChanged] after changing this property
  Future<void> setBitmapColorFromNumber(int color) async {
    renderinstruction.setBitmapColorFromNumber(color);
    for (var renderinstruction in renderinstructionsZoomed.values) {
      renderinstruction.setBitmapColorFromNumber(color);
      PainterFactory().removePainterForSerial(renderinstruction.serial);
    }
    if (renderInfo != null) await PainterFactory().createShapePainter(renderInfo!);
  }

  // execute [markerChanged] after changing this property
  Future<void> setAndLoadBitmapSrc(String bitmapSrc) async {
    renderinstruction.bitmapSrc = bitmapSrc;
    for (var renderinstruction in renderinstructionsZoomed.values) {
      renderinstruction.bitmapSrc = bitmapSrc;
      PainterFactory().removePainterForSerial(renderinstruction.serial);
    }
    if (renderInfo != null) await PainterFactory().createShapePainter(renderInfo!);
  }

  @override
  bool shouldPaint(BoundingBox boundary, int zoomlevel) {
    if (!zoomlevelRange.isWithin(zoomlevel)) return false;
    if (!(_path.boundingBox.intersects(boundary))) return false;
    if (!LatLongUtils.doesBoundaryIntersectPolygon(boundary, _path.path)) return false;
    return true;
  }
}
