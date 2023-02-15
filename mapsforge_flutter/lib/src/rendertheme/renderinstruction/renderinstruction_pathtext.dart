import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontstyle.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinfo.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../../graphics/mapfontfamily.dart';
import '../../model/linesegment.dart';
import '../../model/linestring.dart';
import '../../renderer/rendererutils.dart';
import '../nodeproperties.dart';
import '../rendercontext.dart';
import '../shape/shape_pathtext.dart';
import '../wayproperties.dart';
import '../wayrenderinfo.dart';
import 'renderinstruction.dart';
import 'textkey.dart';

/**
 * Represents a text along a polyline on the map.
 */
class RenderinstructionPathtext extends RenderInstruction {
  static final double REPEAT_GAP_DEFAULT = 100;
  static final double REPEAT_START_DEFAULT = 10;

  final ShapePathtext base = ShapePathtext.base();

  final Map<int, ShapePathtext> _shapeScaled = {};

  RenderinstructionPathtext(int level) {
    //initTextMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    //initPaintMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    base.rotate = true;
    base.repeat = true;
    base.level = level;
  }

  void parse(DisplayModel displayModel, XmlElement rootElement) {
    base.maxTextWidth = displayModel.getMaxTextWidth();
    base.repeatGap = REPEAT_GAP_DEFAULT * displayModel.getFontScaleFactor();
    base.repeatStart = REPEAT_START_DEFAULT * displayModel.getFontScaleFactor();
    base.setStrokeMinZoomLevel(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.K == name) {
        base.textKey = TextKey(value);
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.DISPLAY == name) {
        base.display = Display.values
            .firstWhere((v) => v.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.DY == name) {
        base.setDy(double.parse(value) * displayModel.getScaleFactor());
      } else if (RenderInstruction.FILL == name) {
        base.setFillColorFromNumber(XmlUtils.getColor(value, this));
      } else if (RenderInstruction.FONT_FAMILY == name) {
        base.setFontFamily(MapFontFamily.values
            .firstWhere((v) => v.toString().toLowerCase().contains(value)));
      } else if (RenderInstruction.FONT_SIZE == name) {
        base.setFontSize(XmlUtils.parseNonNegativeFloat(name, value) *
            displayModel.getFontScaleFactor());
      } else if (RenderInstruction.FONT_STYLE == name) {
        base.setFontStyle(MapFontStyle.values
            .firstWhere((v) => v.toString().toLowerCase().contains(value)));
      } else if (RenderInstruction.REPEAT == name) {
        base.repeat = value == "true";
      } else if (RenderInstruction.REPEAT_GAP == name) {
        base.repeatGap =
            double.parse(value) * displayModel.getFontScaleFactor();
      } else if (RenderInstruction.REPEAT_START == name) {
        base.repeatStart =
            double.parse(value) * displayModel.getFontScaleFactor();
      } else if (RenderInstruction.ROTATE == name) {
        base.rotate = value == "true";
      } else if (RenderInstruction.PRIORITY == name) {
        base.priority = int.parse(value);
      } else if (RenderInstruction.SCALE == name) {
        base.scale = scaleFromValue(value);
      } else if (RenderInstruction.STROKE == name) {
        base.setStrokeColorFromNumber(XmlUtils.getColor(value, this));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        base.setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) *
            displayModel.getFontScaleFactor());
      } else {
        throw Exception("PathText probs");
      }
    });

    XmlUtils.checkMandatoryAttribute(
        rootElement.name.toString(), RenderInstruction.K, base.textKey);
  }

  ShapePathtext _getShapeByZoomLevel(int zoomLevel) {
    if (_shapeScaled.containsKey(zoomLevel)) return _shapeScaled[zoomLevel]!;
    ShapePathtext result = ShapePathtext.scale(base, zoomLevel);
    _shapeScaled[zoomLevel] = result;
    return result;
  }

  @override
  void renderNode(final RenderContext renderContext, NodeProperties container) {
    // do nothing
    return;
  }

  @override
  void renderWay(
      final RenderContext renderContext, WayProperties wayProperties) {
    ShapePathtext shape =
        _getShapeByZoomLevel(renderContext.job.tile.zoomLevel);

    if (Display.NEVER == shape.display) {
      return;
    }

    String? caption = shape.textKey!.getValue(wayProperties.getTags());
    if (caption == null) {
      return;
    }

    renderContext.addToClashDrawingLayer(
        shape.level, WayRenderInfo(wayProperties, shape)..caption = caption);
    return;
  }
}
