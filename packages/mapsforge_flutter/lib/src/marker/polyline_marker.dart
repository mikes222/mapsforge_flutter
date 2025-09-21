import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_renderer/shape_painter.dart';
import 'package:mapsforge_flutter_renderer/ui.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';

/// A Marker which draws an open path specified by a series of lat/lon attributes.
///
/// See also:
/// [AreaMarker] which draws a closed polyline. Also more information about the differences to this marker can be found in [AreaMarker].
class PolylineMarker<T> extends Marker<T> {
  static final _log = Logger('PolylineMarker');

  late final RenderinstructionPolyline renderinstruction;

  final Map<int, RenderinstructionPolyline> renderinstructionsZoomed = {};

  RenderInfoWay<RenderinstructionPolyline>? renderInfo;

  late final Waypath _path;

  PolylineMarker({
    super.zoomlevelRange,
    super.key,
    double strokeWidth = 2.0,
    int strokeColor = 0xff000000,
    List<double>? strokeDasharray,
    List<ILatLong> path = const [],
    int? strokeMinZoomLevel,
  }) {
    _path = path.isEmpty ? Waypath.empty() : Waypath(path: path);
    renderinstruction = RenderinstructionPolyline(0);
    renderinstruction.setStrokeColorFromNumber(strokeColor);
    renderinstruction.setStrokeWidth(strokeWidth);
    renderinstruction.setStrokeDashArray(strokeDasharray);
    if (strokeMinZoomLevel != null) renderinstruction.setStrokeMinZoomLevel(strokeMinZoomLevel);
  }

  @override
  Future<void> changeZoomlevel(int zoomlevel, PixelProjection projection) async {
    // we are unable to initialize without a path
    if (_path.isEmpty) {
      _log.warning("PolylineMarker has an empty path, cannot draw anyhting $this");
      return;
    }
    RenderinstructionPolyline renderinstructionZoomed = renderinstructionsZoomed.putIfAbsent(zoomlevel, () => renderinstruction.forZoomlevel(zoomlevel, 0));
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
    // path was empty during initialization
    if (renderInfo == null) return;
    //assert(renderInfo != null, "renderInfo is null, maybe changeZoomlevel() was not called");
    renderInfo?.render(renderContext);
  }

  @override
  bool isTapped(TapEvent tapEvent) {
    if (!zoomlevelRange.isWithin(tapEvent.projection.scalefactor.zoomlevel)) return false;
    return indexOfTappedPath(tapEvent) >= 0;
  }

  int indexOfTappedPath(TapEvent tapEvent) {
    Mappoint tapped = tapEvent.mappoint;
    for (int idx = 0; idx < _path.length - 1; ++idx) {
      Mappoint point0 = tapEvent.projection.latLonToPixel(_path.path[idx]);
      Mappoint point1 = tapEvent.projection.latLonToPixel(_path.path[idx + 1]);
      double distance = LatLongUtils.distanceSegmentPoint(point0.x, point0.y, point1.x, point1.y, tapped.x, tapped.y);
      // correct would be half of strokeWidth but it is hard to tap exactly so be graceful here
      if (distance <= (renderInfo?.renderInstruction.strokeWidth ?? 0)) return idx;
    }
    return -1;
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

  // execute [markerChanged] after changing this property
  void addLatLong(ILatLong latLong) {
    _path.add(latLong);
  }

  List<ILatLong> get path => _path.path;

  // execute [markerChanged] after changing this property
  void clear() {
    _path.clear();
  }

  @override
  bool shouldPaint(BoundingBox boundary, int zoomlevel) {
    if (!zoomlevelRange.isWithin(zoomlevel)) return false;
    if (_path.isEmpty) return false;
    if (!(_path.boundingBox.intersects(boundary))) return false;
    return true;
  }
}
