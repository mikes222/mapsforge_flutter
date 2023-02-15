import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/rendertheme/wayrenderinfo.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../nodeproperties.dart';
import '../rendercontext.dart';
import '../shape/shape_area.dart';
import '../wayproperties.dart';
import 'renderinstruction.dart';

/**
 * Represents a closed polygon on the map.
 */
class RenderinstructionArea extends RenderInstruction {
  final ShapeArea base = ShapeArea.base();

  final Map<int, ShapeArea> _shapeScaled = {};

  RenderinstructionArea(String elementName, int level) : super() {
    // do not scale bitmaps in areas. They look ugly
    base.setBitmapMinZoomLevel(65535);
    base.level = level;
    // setFillColor(Colors.transparent);
    // setStrokeColor(Colors.transparent);
  }

  void parse(DisplayModel displayModel, XmlElement rootElement) {
    base.setBitmapPercent(100 * displayModel.getFontScaleFactor().round());

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;
      if (RenderInstruction.SRC == name) {
        base.bitmapSrc = value;
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.FILL == name) {
        base.setFillColorFromNumber(XmlUtils.getColor(value, this));
      } else if (RenderInstruction.SCALE == name) {
        base.scale = scaleFromValue(value);
        if (base.scale == Scale.NONE) base.setStrokeMinZoomLevel(665535);
      } else if (RenderInstruction.STROKE == name) {
        base.setStrokeColorFromNumber(XmlUtils.getColor(value, this));
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

  ShapeArea _getShapeByZoomLevel(int zoomLevel) {
    if (_shapeScaled.containsKey(zoomLevel)) return _shapeScaled[zoomLevel]!;
    ShapeArea result = ShapeArea.scale(base, zoomLevel);
    _shapeScaled[zoomLevel] = result;
    return result;
  }

  @override
  void renderNode(
      final RenderContext renderContext, NodeProperties nodeProperties) {
    // do nothing
  }

  @override
  void renderWay(
      final RenderContext renderContext, WayProperties wayProperties) {
    if (wayProperties.getCoordinatesAbsolute(renderContext.projection).length ==
        0) return;

    ShapeArea shape = _getShapeByZoomLevel(renderContext.job.tile.zoomLevel);
    renderContext.addToCurrentDrawingLayer(
        shape.level, WayRenderInfo<ShapeArea>(wayProperties, shape));
  }
}
