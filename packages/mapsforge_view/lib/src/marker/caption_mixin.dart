import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/renderer.dart';
import 'package:datastore_renderer/shape_painter.dart';
import 'package:mapsforge_view/src/marker/caption_reference.dart';

mixin class CaptionMixin {
  final List<Caption> _captions = [];

  Caption addCaption({
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
    Caption cp = Caption(
      caption: caption,
      strokeWidth: strokeWidth,
      strokeColor: strokeColor,
      fillColor: fillColor,
      fontSize: fontSize,
      zoomlevelRange: zoomlevelRange ?? ZoomlevelRange.standard(),
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
  }) : assert(strokeWidth >= 0),
       _caption = caption {
    renderinstruction = RenderinstructionCaption(0);
    renderinstruction.setStrokeWidth(strokeWidth);
    renderinstruction.setStrokeColorFromNumber(strokeColor);
    renderinstruction.setFillColorFromNumber(fillColor);
    renderinstruction.setFontSize(fontSize);
    renderinstruction.position = position;
    renderinstruction.maxTextWidth = MapsforgeSettingsMgr().getMaxTextWidth();
    renderinstruction.setStrokeMinZoomLevel(strokeMinZoomLevel ?? MapsforgeSettingsMgr().strokeMinZoomlevelText);
    renderinstruction.dy = dy;
    renderinstruction.gap = gap;
    renderinstruction.symbolId = "marker";
  }

  Future<void> changeZoomlevel(int zoomlevel, PixelProjection projection) async {
    //renderInfo?.shapePainter?.dispose();
    RenderinstructionCaption renderinstructionZoomed = renderinstruction.forZoomlevel(zoomlevel, 0);
    renderinstructionZoomed.secondPass(poiMarker);
    NodeProperties nodeProperties = NodeProperties(PointOfInterest(0, [], poiMarker.getReference()), projection);
    renderInfo = RenderInfoNode(nodeProperties, renderinstruction.forZoomlevel(zoomlevel, 0), caption: _caption);
    renderInfo?.shapePainter = await ShapePainterCaption.create(renderinstructionZoomed);
  }

  void render({required UiRenderContext renderContext, required NodeProperties nodeProperties}) {
    if (!zoomlevelRange.isWithin(renderContext.projection.scalefactor.zoomlevel)) return;
    renderInfo?.render(renderContext);
  }

  set caption(String caption) {
    _caption = caption;
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
