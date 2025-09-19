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
class PolylineTextMarker<T> extends Marker<T> {
  late final RenderinstructionPolylineText renderinstruction;

  RenderInfoWay<RenderinstructionPolylineText>? renderInfo;

  final List<ILatLong> _path = [];

  final String caption;

  PolylineTextMarker({
    super.zoomlevelRange,
    super.key,
    required this.caption,
    double strokeWidth = 2.0,
    int strokeColor = 0xffffffff,
    int fillColor = 0xff000000,
    List<double>? strokeDasharray,
    List<ILatLong> path = const [],
    double fontSize = 10.0,
    double maxFontSize = 50.0,
    double repeatStart = 10,
    double repeatGap = 100,
    double? maxTextWidth,
  }) {
    if (path.isNotEmpty) _path.addAll(path);
    renderinstruction = RenderinstructionPolylineText(0);
    renderinstruction.setStrokeColorFromNumber(strokeColor);
    renderinstruction.setStrokeWidth(strokeWidth);
    renderinstruction.setStrokeDashArray(strokeDasharray);
    renderinstruction.setFillColorFromNumber(fillColor);
    renderinstruction.setFontSize(fontSize);
    renderinstruction.setRepeatStart(repeatStart);
    renderinstruction.setRepeatGap(repeatGap);
    renderinstruction.setMaxFontSize(maxFontSize);
    if (maxTextWidth != null) renderinstruction.setMaxTextWidth(maxTextWidth);
  }

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
  }

  @override
  Future<void> changeZoomlevel(int zoomlevel, PixelProjection projection) async {
    //renderInfo?.shapePainter?.dispose();
    RenderinstructionPolylineText renderinstructionZoomed = renderinstruction.forZoomlevel(zoomlevel, 0);
    WayProperties wayProperties = WayProperties(Way(0, [], [_path], null), projection);
    renderInfo = RenderInfoWay(wayProperties, renderinstructionZoomed, caption: caption);
    await PainterFactory().createShapePainter(renderInfo!);
    assert(renderInfo!.shapePainter != null, "PainterFactory should create a painter");
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
      if (distance <= renderInfo!.renderInstruction.fontSize) return idx;
    }
    return -1;
  }

  // execute [markerChanged] after changing this property
  void addLatLong(ILatLong latLong) {
    _path.add(latLong);
  }

  List<ILatLong> get path => _path;

  @override
  bool shouldPaint(BoundingBox boundary, int zoomlevel) {
    if (!zoomlevelRange.isWithin(zoomlevel)) return false;
    if (!(renderInfo?.wayProperties.way.getBoundingBox().intersects(boundary) ?? true)) return false;
    return true;
  }
}
