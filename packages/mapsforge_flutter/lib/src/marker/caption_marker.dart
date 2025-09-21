import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/marker/abstract_poi_marker.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/shape_painter.dart';
import 'package:mapsforge_flutter_renderer/ui.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';

class CaptionMarker<T> extends AbstractPoiMarker<T> {
  late final RenderinstructionCaption renderinstruction;

  final Map<int, RenderinstructionCaption> renderinstructionsZoomed = {};

  RenderInfoNode<RenderinstructionCaption>? renderInfo;

  String caption;

  CaptionMarker({
    super.zoomlevelRange,
    super.key,
    required super.latLong,
    MapPositioning position = MapPositioning.CENTER,
    bool rotateWithMap = false,
    required this.caption,
    int bitmapColor = 0xff000000,
    double strokeWidth = 2.0,
    int strokeColor = 0xffffffff,
    int fillColor = 0xff000000,
    double fontSize = 10.0,

    /// Rotation of the poi in degrees clockwise
    double rotation = 0,
  }) {
    renderinstruction = RenderinstructionCaption(0);
    renderinstruction.setStrokeWidth(strokeWidth);
    renderinstruction.setStrokeColorFromNumber(strokeColor);
    renderinstruction.setFillColorFromNumber(fillColor);
    renderinstruction.setFontSize(fontSize);
    renderinstruction.position = position;
    renderinstruction.rotateWithMap = rotateWithMap;
  }

  @override
  Future<void> changeZoomlevel(int zoomlevel, PixelProjection projection) async {
    //renderInfo?.shapePainter?.dispose();
    RenderinstructionCaption renderinstructionZoomed = renderinstructionsZoomed.putIfAbsent(zoomlevel, () => renderinstruction.forZoomlevel(zoomlevel, 0));
    NodeProperties nodeProperties = NodeProperties(PointOfInterest.simple(latLong), projection);
    renderInfo = RenderInfoNode(nodeProperties, renderinstructionZoomed, caption: caption);
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
    if (!zoomlevelRange.isWithin(tapEvent.projection.scalefactor.zoomlevel)) return false;
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
    RenderInfoNode<RenderinstructionCaption> renderInfoNew = RenderInfoNode(nodeProperties, renderInfo!.renderInstruction, caption: caption);
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
}
