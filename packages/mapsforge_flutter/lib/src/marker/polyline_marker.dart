import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_renderer/shape_painter.dart';
import 'package:mapsforge_flutter_renderer/ui.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';

/// A Marker which draws a rectangle specified by the min/max lat/lon attributes. Currently there is no way
/// to position captions other than in the center of the rectangle (RenderinstructionPath always returns Boundary.zero since it does not have any information
/// about the actual size of the rectangle).
class PolylineMarker<T> extends Marker<T> {
  late RenderinstructionPolyline renderinstruction;

  RenderInfoWay<RenderinstructionPolyline>? renderInfo;

  final List<ILatLong> _path = [];

  PolylineMarker({
    super.zoomlevelRange,
    super.key,
    double strokeWidth = 2.0,
    int strokeColor = 0xff000000,
    List<double>? strokeDasharray,
    List<ILatLong> path = const [],
    int? strokeMinZoomLevel,
  }) {
    if (path.isNotEmpty) _path.addAll(path);
    renderinstruction = RenderinstructionPolyline(0);
    renderinstruction.setStrokeColorFromNumber(strokeColor);
    renderinstruction.setStrokeWidth(strokeWidth);
    renderinstruction.setStrokeDashArray(strokeDasharray);
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
    RenderinstructionPolyline renderinstructionZoomed = renderinstruction.forZoomlevel(zoomlevel, 0);
    WayProperties wayProperties = WayProperties(Way(0, [], [_path], null), projection);
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
    renderInfo?.render(renderContext);
  }

  @override
  bool isTapped(TapEvent tapEvent) {
    return indexOfTappedPath(tapEvent) >= 0;
  }

  int indexOfTappedPath(TapEvent tapEvent) {
    Mappoint tapped = tapEvent.mappoint;
    for (int idx = 0; idx < _path.length - 1; ++idx) {
      Mappoint point0 = tapEvent.projection.latLonToPixel(_path[idx]);
      Mappoint point1 = tapEvent.projection.latLonToPixel(_path[idx + 1]);
      double distance = LatLongUtils.distanceSegmentPoint(point0.x, point0.y, point1.x, point1.y, tapped.x, tapped.y);
      // correct would be half of strokeWidth but it is hard to tap exactly so be graceful here
      if (distance <= renderInfo!.renderInstruction.strokeWidth) return idx;
    }
    return -1;
  }

  void setBitmapColorFromNumber(int color) {
    renderinstruction.setBitmapColorFromNumber(color);
  }

  void setAndLoadBitmapSrc(String bitmapSrc) {
    renderinstruction.bitmapSrc = bitmapSrc;
  }

  void addLatLong(ILatLong latLong) {
    _path.add(latLong);
  }

  void clear() {
    _path.clear();
  }

  List<ILatLong> get path => _path;
}
