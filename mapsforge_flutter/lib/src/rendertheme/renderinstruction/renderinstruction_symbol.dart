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
  final ShapeSymbol base = ShapeSymbol.base();

  final Map<int, ShapeSymbol> _shapeScaled = {};

  final SymbolFinder symbolFinder;

  RenderinstructionSymbol(this.symbolFinder, int level) {
    base.level = level;
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

  ShapeSymbol _getShapeByZoomLevel(int zoomLevel) {
    if (_shapeScaled.containsKey(zoomLevel)) return _shapeScaled[zoomLevel]!;
    ShapeSymbol result = ShapeSymbol.scale(base, zoomLevel);
    _shapeScaled[zoomLevel] = result;
    return result;
  }

  @override
  void renderNode(
      final RenderContext renderContext, NodeProperties nodeProperties) {
    ShapeSymbol shape = _getShapeByZoomLevel(renderContext.job.tile.zoomLevel);

    if (Display.NEVER == shape.display) {
      //_log.info("display is never for $textKey");
      return;
    }

    if (shape.id != null)
      symbolFinder.add(shape.id!, renderContext.job.tile.zoomLevel, shape);

    renderContext.labels.add(NodeRenderInfo(nodeProperties, shape));
  }

  @override
  void renderWay(
      final RenderContext renderContext, WayProperties wayProperties) {
    ShapeSymbol shape = _getShapeByZoomLevel(renderContext.job.tile.zoomLevel);

    if (Display.NEVER == shape.display) {
      //_log.info("display is never for $textKey");
      return;
    }

    if (wayProperties.getCoordinatesAbsolute(renderContext.projection).length ==
        0) return;

    if (shape.id != null)
      symbolFinder.add(shape.id!, renderContext.job.tile.zoomLevel, shape);

    renderContext.labels.add(WayRenderInfo(wayProperties, shape));
  }
}
