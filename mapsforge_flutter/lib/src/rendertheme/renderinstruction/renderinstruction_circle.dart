import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_circle.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../nodeproperties.dart';
import '../noderenderinfo.dart';
import '../rendercontext.dart';
import '../wayproperties.dart';
import 'renderinstruction.dart';

/**
 * Represents a round area on the map.
 */
class RenderinstructionCircle extends RenderInstruction {
  final ShapeCircle base = ShapeCircle.base();

  final Map<int, ShapeCircle> _shapeScaled = {};

  RenderinstructionCircle(int level) {
    base.level = level;
  }

  void parse(DisplayModel displayModel, XmlElement rootElement) {
    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.RADIUS == name || RenderInstruction.R == name) {
        base.radius = XmlUtils.parseNonNegativeFloat(name, value) *
            displayModel.getScaleFactor();
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.FILL == name) {
        base.setFillColorFromNumber(XmlUtils.getColor(value, this));
      } else if (RenderInstruction.SCALE_RADIUS == name) {
        base.scaleRadius = value == "true";
      } else if (RenderInstruction.STROKE == name) {
        base.setStrokeColorFromNumber(XmlUtils.getColor(value, this));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        base.setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) *
            displayModel.getScaleFactor());
      } else {
        throw Exception("circle probs");
      }
    });

    XmlUtils.checkMandatoryAttribute(
        rootElement.name.toString(), RenderInstruction.RADIUS, base.radius);
  }

  ShapeCircle _getShapeByZoomLevel(int zoomLevel) {
    if (_shapeScaled.containsKey(zoomLevel)) return _shapeScaled[zoomLevel]!;
    ShapeCircle result = ShapeCircle.scale(base, zoomLevel);
    _shapeScaled[zoomLevel] = result;
    return result;
  }

  @override
  void renderNode(final RenderContext renderContext, NodeProperties container) {
    ShapeCircle shapeSymbol =
        _getShapeByZoomLevel(renderContext.job.tile.zoomLevel);
    renderContext.addToCurrentDrawingLayer(
        shapeSymbol.level, NodeRenderInfo<ShapeCircle>(container, shapeSymbol));
    return;
  }

  @override
  void renderWay(final RenderContext renderContext, WayProperties container) {
    // do nothing
    return;
  }
}
