import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontstyle.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../../graphics/mapfontfamily.dart';
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

  late final ShapePathtext base;

  RenderinstructionPathtext(int level, [ShapePathtext? base]) {
    //initTextMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    //initPaintMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    this.base = base ?? ShapePathtext.base()
      ..rotate = true
      ..repeat = true
      ..level = level;
  }

  @override
  RenderinstructionPathtext? prepareScale(int zoomLevel) {
    ShapePathtext newShape = ShapePathtext.scale(base, zoomLevel);
    if (newShape.display == Display.NEVER) return null;
    return RenderinstructionPathtext(base.level, newShape);
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

  @override
  void renderNode(final RenderContext renderContext, NodeProperties container) {
    // do nothing
    return;
  }

  @override
  void renderWay(
      final RenderContext renderContext, WayProperties wayProperties) {
    String? caption = base.textKey!.getValue(wayProperties.getTags());
    if (caption == null) {
      return;
    }

    renderContext.addToClashDrawingLayer(
        base.level, WayRenderInfo(wayProperties, base)..caption = caption);
    return;
  }
}
