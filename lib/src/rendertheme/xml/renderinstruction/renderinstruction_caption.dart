import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontfamily.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontstyle.dart';
import 'package:mapsforge_flutter/src/rendertheme/textkey.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/renderinstruction/renderinstruction.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/renderinstruction/renderinstruction_node.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/renderinstruction/renderinstruction_way.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../../shape/shape_caption.dart';
import '../symbol_finder.dart';

/**
 * Represents a text label on the map.
 * <p/>
 * If a bitmap symbol is present the caption position is calculated relative to the bitmap, the
 * center of which is at the point of the POI. The bitmap itself is never rendered.
 */
class RenderinstructionCaption
    implements RenderInstructionNode, RenderInstructionWay {
  static final double DEFAULT_GAP = 1;

  late final ShapeCaption base;

  final ZoomlevelSymbolFinder zoomlevelSymbolFinder;

  RenderinstructionCaption(this.zoomlevelSymbolFinder, int level,
      [ShapeCaption? base]) {
    this.base = base ?? ShapeCaption.base(level);
  }

  @override
  ShapeCaption? prepareScale(int zoomLevel) {
    SymbolFinder symbolFinder = zoomlevelSymbolFinder.find(zoomLevel);
    ShapeCaption newShape = ShapeCaption.scale(base, zoomLevel, symbolFinder);
    if (newShape.display == Display.NEVER) return null;
    return newShape;
  }

  void parse(DisplayModel displayModel, XmlElement rootElement) {
    base.maxTextWidth = displayModel.getMaxTextWidth();
    base.gap = DEFAULT_GAP * displayModel.getFontScaleFactor();
    base.setStrokeMinZoomLevel(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    base.setFontSize(10 * displayModel.getFontScaleFactor());

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.K == name) {
        base.textKey = TextKey(value);
      } else if (RenderInstruction.CAT == name) {
        base.category = value;
      } else if (RenderInstruction.DISPLAY == name) {
        base.display = Display.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.DY == name) {
        base.setDy(double.parse(value) * displayModel.getScaleFactor());
      } else if (RenderInstruction.FILL == name) {
        base.setFillColorFromNumber(XmlUtils.getColor(value));
      } else if (RenderInstruction.FONT_FAMILY == name) {
        base.setFontFamily(MapFontFamily.values
            .firstWhere((v) => v.toString().toLowerCase().contains(value)));
      } else if (RenderInstruction.FONT_SIZE == name) {
        base.setFontSize(XmlUtils.parseNonNegativeFloat(name, value) *
            displayModel.getFontScaleFactor());
      } else if (RenderInstruction.FONT_STYLE == name) {
        base.setFontStyle(MapFontStyle.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value)));
      } else if (RenderInstruction.POSITION == name) {
        base.position = Position.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.PRIORITY == name) {
        base.priority = int.parse(value);
      } else if (RenderInstruction.STROKE == name) {
        base.setStrokeColorFromNumber(XmlUtils.getColor(value));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        base.setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) *
            displayModel.getFontScaleFactor());
      } else if (RenderInstruction.SYMBOL_ID == name) {
        base.symbolId = value;
      } else {
        throw Exception("caption unknwon attribute");
      }
    });

    XmlUtils.checkMandatoryAttribute(
        rootElement.name.toString(), RenderInstruction.K, base.textKey);
  }
}
