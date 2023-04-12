import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_circle.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../../graphics/display.dart';
import '../nodeproperties.dart';
import '../noderenderinfo.dart';
import '../rendercontext.dart';
import '../wayproperties.dart';
import 'renderinstruction.dart';

/**
 * Represents a round area on the map.
 */
class RenderinstructionCircle extends RenderInstruction {
  late final ShapeCircle base;

  RenderinstructionCircle(int level, [ShapeCircle? base]) {
    this.base = base ?? ShapeCircle.base()
      ..level = level;
  }

  @override
  RenderinstructionCircle? prepareScale(int zoomLevel) {
    ShapeCircle newShape = ShapeCircle.scale(base, zoomLevel);
    if (newShape.display == Display.NEVER) return null;
    return RenderinstructionCircle(base.level, newShape);
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

  @override
  void renderNode(final RenderContext renderContext, NodeProperties container) {
    renderContext.addToCurrentDrawingLayer(
        base.level, NodeRenderInfo<ShapeCircle>(container, base));
    return;
  }

  @override
  void renderWay(final RenderContext renderContext, WayProperties container) {
    // do nothing
    return;
  }
}
