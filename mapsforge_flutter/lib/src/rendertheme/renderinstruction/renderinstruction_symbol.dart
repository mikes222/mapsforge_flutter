import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_symbol.dart';
import 'package:mapsforge_flutter/src/rendertheme/wayrenderinfo.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../nodeproperties.dart';
import '../noderenderinfo.dart';
import '../rendercontext.dart';
import '../wayproperties.dart';
import '../xml/rulebuilder.dart';

///
/// Represents an icon on the map. The rendertheme.xml has the possiblity to define a symbol by id and use that symbol later by referring to this id.
/// The [RenderinstructionSymbol] class holds a symbol (=bitmap) and refers it by it's id. The class can be used by several other [RenderInstruction] implementations.
///
class RenderinstructionSymbol extends RenderInstruction {
  late final ShapeSymbol base;

  final SymbolFinder symbolFinder;

  RenderinstructionSymbol(this.symbolFinder, int level, [ShapeSymbol? base]) {
    this.base = base ?? ShapeSymbol.base()
      ..level = level;
  }

  @override
  RenderinstructionSymbol? prepareScale(int zoomLevel) {
    ShapeSymbol newShape = ShapeSymbol.scale(base, zoomLevel);
    if (newShape.display == Display.NEVER) return null;
    return RenderinstructionSymbol(symbolFinder, base.level, newShape);
  }

  void parse(DisplayModel displayModel, XmlElement rootElement) {
    base.setBitmapPercent(100 * displayModel.getFontScaleFactor().round());
    base.setBitmapMinZoomLevel(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.SRC == name) {
        base.bitmapSrc = value;
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.DISPLAY == name) {
        base.display = Display.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.ID == name) {
        base.id = value;
      } else if (RenderInstruction.PRIORITY == name) {
        base.priority = int.parse(value);
      } else if (RenderInstruction.SYMBOL_HEIGHT == name) {
        base.setBitmapHeight(XmlUtils.parseNonNegativeInteger(name, value));
      } else if (RenderInstruction.SYMBOL_PERCENT == name) {
        base.setBitmapPercent(XmlUtils.parseNonNegativeInteger(name, value) *
            displayModel.getFontScaleFactor().round());
      } else if (RenderInstruction.SYMBOL_SCALING == name) {
// no-op
      } else if (RenderInstruction.SYMBOL_WIDTH == name) {
        base.setBitmapWidth(XmlUtils.parseNonNegativeInteger(name, value));
      } else {
        throw Exception("Symbol probs");
      }
    });
  }

  @override
  void renderNode(
      final RenderContext renderContext, NodeProperties nodeProperties) {
    if (base.id != null)
      symbolFinder.add(base.id!, renderContext.job.tile.zoomLevel, base);

    renderContext.labels.add(NodeRenderInfo(nodeProperties, base));
  }

  @override
  void renderWay(
      final RenderContext renderContext, WayProperties wayProperties) {
    if (wayProperties.getCoordinatesAbsolute(renderContext.projection).length ==
        0) return;

    if (base.id != null)
      symbolFinder.add(base.id!, renderContext.job.tile.zoomLevel, base);

    renderContext.addToClashDrawingLayer(
        base.level, WayRenderInfo(wayProperties, base));
  }
}
