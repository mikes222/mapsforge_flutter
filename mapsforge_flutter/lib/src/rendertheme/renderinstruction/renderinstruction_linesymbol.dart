import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/position.dart';
import 'package:mapsforge_flutter/src/rendertheme/wayrenderinfo.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../nodeproperties.dart';
import '../rendercontext.dart';
import '../shape/shape_linesymbol.dart';
import '../wayproperties.dart';
import 'renderinstruction.dart';

/// Represents an icon along a polyline on the map.
class RenderinstructionLinesymbol extends RenderInstruction {
  static final double REPEAT_GAP_DEFAULT = 200;
  static final double REPEAT_START_DEFAULT = 30;

  late final ShapeLinesymbol base;

  RenderinstructionLinesymbol(int level, [ShapeLinesymbol? base]) {
    this.base = base ?? ShapeLinesymbol.base()
      ..level = level;
  }

  @override
  RenderinstructionLinesymbol? prepareScale(int zoomLevel) {
    ShapeLinesymbol newShape = ShapeLinesymbol.scale(base, zoomLevel);
    if (newShape.display == Display.NEVER) return null;
    return RenderinstructionLinesymbol(base.level, newShape);
  }

  void parse(DisplayModel displayModel, XmlElement rootElement) {
    //initBitmapSrcMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    base.setRepeatGap(REPEAT_GAP_DEFAULT * displayModel.getFontScaleFactor());
    base.repeatStart = REPEAT_START_DEFAULT * displayModel.getFontScaleFactor();
    base.setBitmapPercent(100 * displayModel.getFontScaleFactor().round());
    base.setBitmapMinZoomLevel(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.SRC == name) {
        base.bitmapSrc = value;
      } else if (RenderInstruction.ALIGN_CENTER == name) {
        base.alignCenter = "true" == (value);
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.DISPLAY == name) {
        base.display = Display.values
            .firstWhere((v) => v.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.DY == name) {
        base.setDy(double.parse(value) * displayModel.getScaleFactor());
      } else if (RenderInstruction.POSITION == name) {
        base.position = Position.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.PRIORITY == name) {
        base.priority = int.parse(value);
      } else if (RenderInstruction.REPEAT == name) {
        base.repeat = "true" == (value);
      } else if (RenderInstruction.REPEAT_GAP == name) {
        base.setRepeatGap(
            double.parse(value) * displayModel.getFontScaleFactor());
      } else if (RenderInstruction.REPEAT_START == name) {
        base.repeatStart =
            double.parse(value) * displayModel.getFontScaleFactor();
      } else if (RenderInstruction.ROTATE == name) {
        base.rotate = "true" == (value);
      } else if (RenderInstruction.SCALE == name) {
        base.scale = scaleFromValue(value);
        if (base.scale == Scale.NONE) {
          base.setBitmapMinZoomLevel(65535);
        }
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
        throw Exception("LineSymbol probs: unknown '$name'");
      }
    });
  }

  @override
  void renderNode(
      final RenderContext renderContext, NodeProperties nodeProperties) {
    return;
    // do nothing
  }

  @override
  void renderWay(
      final RenderContext renderContext, WayProperties wayProperties) {
    if (wayProperties.getCoordinatesAbsolute(renderContext.projection).length ==
        0) return;

    //renderContext.labels.add(WayRenderInfo(wayProperties, shape));
    renderContext.addToClashDrawingLayer(
        base.level, WayRenderInfo(wayProperties, base));
  }
}
