import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_symbol.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/renderinstruction/renderinstruction.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/renderinstruction/renderinstruction_node.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/renderinstruction/renderinstruction_way.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../symbol_finder.dart';

///
/// Represents an icon on the map. The rendertheme.xml has the possiblity to define a symbol by id and use that symbol later by referring to this id.
/// The [RenderinstructionSymbol] class holds a symbol (=bitmap) and refers it by it's id. The class can be used by several other [RenderInstruction] implementations.
///
class RenderinstructionSymbol implements RenderInstructionNode, RenderInstructionWay {
  late final ShapeSymbol base;

  final ZoomlevelSymbolFinder zoomlevelSymbolFinder;

  RenderinstructionSymbol(this.zoomlevelSymbolFinder, int level, [ShapeSymbol? base]) {
    this.base = base ?? ShapeSymbol.base(level);
  }

  @override
  ShapeSymbol? prepareScale(int zoomLevel) {
    SymbolFinder symbolFinder = zoomlevelSymbolFinder.find(zoomLevel);
    ShapeSymbol newShape = ShapeSymbol.scale(base, zoomLevel, symbolFinder);
    if (newShape.display == Display.NEVER) return null;
    return newShape;
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
        base.category = value;
      } else if (RenderInstruction.DISPLAY == name) {
        base.display = Display.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.ID == name) {
        base.id = value;
      } else if (RenderInstruction.PRIORITY == name) {
        base.priority = int.parse(value);
      } else if (RenderInstruction.SYMBOL_HEIGHT == name) {
        base.setBitmapHeight(XmlUtils.parseNonNegativeInteger(name, value));
      } else if (RenderInstruction.SYMBOL_PERCENT == name) {
        base.setBitmapPercent(XmlUtils.parseNonNegativeInteger(name, value) * displayModel.getFontScaleFactor().round());
      } else if (RenderInstruction.SYMBOL_SCALING == name) {
// no-op
      } else if (RenderInstruction.SYMBOL_WIDTH == name) {
        base.setBitmapWidth(XmlUtils.parseNonNegativeInteger(name, value));
      } else {
        throw Exception("Symbol probs");
      }
    });
  }
}
