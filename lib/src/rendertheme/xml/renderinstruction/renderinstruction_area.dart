import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/model/scale.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/renderinstruction/renderinstruction_way.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../../shape/shape_area.dart';
import 'renderinstruction.dart';

/**
 * Represents a closed polygon on the map.
 */
class RenderinstructionArea implements RenderInstructionWay {
  late final ShapeArea base;

  RenderinstructionArea(int level, [ShapeArea? base]) : super() {
    // do not scale bitmaps in areas. They look ugly
    this.base = base ?? ShapeArea.base(level)
      ..setBitmapMinZoomLevel(65535);
  }

  @override
  ShapeArea? prepareScale(int zoomLevel) {
    ShapeArea newShape = ShapeArea.scale(base, zoomLevel);
    if (newShape.display == Display.NEVER) return null;
    return newShape;
  }

  void parse(DisplayModel displayModel, XmlElement rootElement) {
    base.setBitmapPercent(100 * displayModel.getFontScaleFactor().round());

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;
      if (RenderInstruction.SRC == name) {
        base.bitmapSrc = value;
      } else if (RenderInstruction.CAT == name) {
        base.category = value;
      } else if (RenderInstruction.FILL == name) {
        base.setFillColorFromNumber(XmlUtils.getColor(value));
      } else if (RenderInstruction.SCALE == name) {
        base.setScaleFromValue(value);
        if (base.scale == Scale.NONE) base.setStrokeMinZoomLevel(665535);
      } else if (RenderInstruction.STROKE == name) {
        base.setStrokeColorFromNumber(XmlUtils.getColor(value));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        base.setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) *
            displayModel.getScaleFactor());
      } else if (RenderInstruction.SYMBOL_WIDTH == name) {
        base.setBitmapWidth(XmlUtils.parseNonNegativeInteger(name, value));
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
        throw Exception(name + "=" + value);
      }
    });
  }
}
