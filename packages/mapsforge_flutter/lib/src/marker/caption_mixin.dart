import 'package:mapsforge_flutter/src/marker/caption_reference.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_renderer/shape_painter.dart';
import 'package:mapsforge_flutter_renderer/ui.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';

mixin class CaptionMixin {
  final List<Caption> _captions = [];

  Caption? addCaption({
    required String caption,
    double strokeWidth = 2.0,
    int strokeColor = 0xffffffff,
    int fillColor = 0xff000000,
    double fontSize = 10.0,
    ZoomlevelRange? zoomlevelRange,
    MapPositioning position = MapPositioning.BELOW,
    double dy = 0,
    int? strokeMinZoomLevel,
    double gap = 1,
  }) {
    if (caption.trim().isEmpty) return null;
    Caption cp = Caption(
      caption: caption,
      strokeWidth: strokeWidth,
      strokeColor: strokeColor,
      fillColor: fillColor,
      fontSize: fontSize,
      zoomlevelRange: zoomlevelRange ?? const ZoomlevelRange.standard(),
      position: position,
      dy: dy,
      gap: gap,
      strokeMinZoomLevel: strokeMinZoomLevel,
      poiMarker: (this as CaptionReference),
    );
    _captions.add(cp);
    return cp;
  }

  void removeCaption(Caption caption) {
    _captions.remove(caption);
  }

  void removeCaptionPerText(String caption) {
    _captions.removeWhere((captionObject) => captionObject.caption == caption);
  }

  bool hasCaptions() {
    return _captions.isNotEmpty;
  }

  void removeAllCaptions() {
    _captions.clear();
  }

  List<Caption> get captions => _captions;

  void renderCaptions({required UiRenderContext renderContext, required NodeProperties nodeProperties}) {
    for (var caption in _captions) {
      caption.render(renderContext: renderContext, nodeProperties: nodeProperties);
    }
  }

  Future<void> changeZoomlevelCaptions(int zoomlevel, PixelProjection projection) async {
    for (var caption in _captions) {
      await caption.changeZoomlevel(zoomlevel, projection);
    }
  }
}

//////////////////////////////////////////////////////////////////////////////

class Caption {
  static final double DEFAULT_GAP = 2;

  String _caption;

  late RenderinstructionCaption renderinstruction;

  final ZoomlevelRange zoomlevelRange;

  RenderInfoNode<RenderinstructionCaption>? renderInfo;

  final CaptionReference poiMarker;

  Caption({
    required String caption,
    double strokeWidth = 2.0,
    int strokeColor = 0xffffffff,
    int fillColor = 0xff000000,
    double fontSize = 10.0,
    required this.zoomlevelRange,
    MapPositioning position = MapPositioning.BELOW,
    double dy = 0,
    double gap = 1,
    int? strokeMinZoomLevel,
    required this.poiMarker,
    double? maxTextWidth,
  }) : assert(strokeWidth >= 0),
       _caption = caption {
    renderinstruction = RenderinstructionCaption(0);
    renderinstruction.setStrokeWidth(strokeWidth);
    renderinstruction.setStrokeColorFromNumber(strokeColor);
    renderinstruction.setFillColorFromNumber(fillColor);
    renderinstruction.setFontSize(fontSize);
    renderinstruction.position = position;
    if (maxTextWidth != null) renderinstruction.setMaxTextWidth(maxTextWidth);
    renderinstruction.setStrokeMinZoomLevel(strokeMinZoomLevel ?? MapsforgeSettingsMgr().strokeMinZoomlevelText);
    renderinstruction.setTextMinZoomLevel(strokeMinZoomLevel ?? MapsforgeSettingsMgr().strokeMinZoomlevelText);
    renderinstruction.dy = dy;
    renderinstruction.gap = gap;
    renderinstruction.symbolId = "marker";
  }

  Future<void> changeZoomlevel(int zoomlevel, PixelProjection projection) async {
    //renderInfo?.shapePainter?.dispose();
    RenderinstructionCaption renderinstructionZoomed = renderinstruction.forZoomlevel(zoomlevel, 0);
    renderinstructionZoomed.secondPass(poiMarker);
    NodeProperties nodeProperties = NodeProperties(PointOfInterest.simple(poiMarker.getReference()), projection);
    renderInfo = RenderInfoNode(nodeProperties, renderinstruction.forZoomlevel(zoomlevel, 0), caption: _caption);
    renderInfo?.shapePainter = await ShapePainterCaption.create(renderinstructionZoomed);
  }

  void render({required UiRenderContext renderContext, required NodeProperties nodeProperties}) {
    if (!zoomlevelRange.isWithin(renderContext.projection.scalefactor.zoomlevel)) return;
    assert(renderInfo != null, "renderInfo is null, maybe changeZoomlevel() was not called");
    renderInfo?.render(renderContext);
  }

  set caption(String caption) {
    _caption = caption;

    /// stop if the caption is not yet initialized
    if (renderInfo == null) return;
    RenderInfoNode<RenderinstructionCaption> renderInfoNew = RenderInfoNode<RenderinstructionCaption>(
      renderInfo!.nodeProperties,
      renderInfo!.renderInstruction,
      caption: _caption,
    );
    renderInfoNew.shapePainter = renderInfo?.shapePainter;
    renderInfo = renderInfoNew;
  }

  String get caption => _caption;

  Future<void> setStrokeColorFromNumber(int strokeColor) async {
    renderinstruction.setStrokeColorFromNumber(strokeColor);
    renderInfo?.renderInstruction.setStrokeColorFromNumber(strokeColor);
    renderInfo?.shapePainter = await ShapePainterCaption.create(renderInfo!.renderInstruction);
  }

  Future<void> setFillColorFromNumber(int fillColor) async {
    renderinstruction.setFillColorFromNumber(fillColor);
    renderInfo?.renderInstruction.setFillColorFromNumber(fillColor);
    renderInfo?.shapePainter = await ShapePainterCaption.create(renderInfo!.renderInstruction);
  }
}
