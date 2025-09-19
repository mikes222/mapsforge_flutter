import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/marker/abstract_poi_marker.dart';
import 'package:mapsforge_flutter/src/marker/caption_mixin.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_renderer/shape_painter.dart';
import 'package:mapsforge_flutter_renderer/ui.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';

class PoiMarker<T> extends AbstractPoiMarker<T> with CaptionMixin {
  late final RenderinstructionSymbol renderinstruction;

  RenderInfoNode<RenderinstructionSymbol>? renderInfo;

  PoiMarker({
    super.zoomlevelRange,
    super.key,
    required super.latLong,
    MapPositioning positioning = MapPositioning.CENTER,
    bool rotateWithMap = false,
    required String src,
    int bitmapColor = 0xff000000,
    double width = 20,
    double height = 20,

    /// Rotation of the poi in degrees clockwise
    double rotation = 0,
  }) {
    renderinstruction = RenderinstructionSymbol(0);
    renderinstruction.bitmapSrc = src;
    renderinstruction.setBitmapColorFromNumber(bitmapColor);
    renderinstruction.setBitmapMinZoomLevel(MapsforgeSettingsMgr().strokeMinZoomlevelText);
    renderinstruction.theta = Projection.degToRadian(rotation);
    renderinstruction.setBitmapWidth(width.round());
    renderinstruction.setBitmapHeight(height.round());
    renderinstruction.positioning = positioning;
    renderinstruction.rotateWithMap = rotateWithMap;
  }

  @override
  @mustCallSuper
  void dispose() {
    //    renderinstruction.dispose();
    super.dispose();
  }

  @override
  Future<void> changeZoomlevel(int zoomlevel, PixelProjection projection) async {
    //renderInfo?.shapePainter?.dispose();
    RenderinstructionSymbol renderinstructionZoomed = renderinstruction.forZoomlevel(zoomlevel, 0);
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
    if (!zoomlevelRange.isWithin(renderContext.projection.scalefactor.zoomlevel)) return;
    assert(renderInfo != null, "renderInfo is null, maybe changeZoomlevel() was not called");
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

  set rotation(double rotation) {
    renderinstruction.theta = Projection.degToRadian(rotation);
    renderInfo?.renderInstruction.theta = Projection.degToRadian(rotation);
  }

  // execute [markerChanged] after changing this property
  void setBitmapColorFromNumber(int color) {
    renderinstruction.setBitmapColorFromNumber(color);
    renderInfo?.renderInstruction.setBitmapColorFromNumber(color);
  }

  // execute [markerChanged] after changing this property
  void setAndLoadBitmapSrc(String bitmapSrc) {
    renderinstruction.bitmapSrc = bitmapSrc;
    renderInfo?.renderInstruction.setBitmapSrc(bitmapSrc);
  }

  // execute [markerChanged] after changing this property
  void setLatLong(ILatLong latLong) {
    super.latLong = latLong;
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
