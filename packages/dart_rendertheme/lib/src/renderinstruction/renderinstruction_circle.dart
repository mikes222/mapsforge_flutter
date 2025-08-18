import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/src/model/display.dart';
import 'package:dart_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/fill_color_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_node.dart';
import 'package:dart_rendertheme/src/renderinstruction/stroke_color_src_mixin.dart';
import 'package:dart_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import 'renderinstruction.dart';

/**
 * Represents a round area on the map.
 */
class RenderinstructionCircle with BaseSrcMixin, FillColorSrcMixin, StrokeColorSrcMixin implements RenderInstructionNode {
  /// the radius of the circle in pixels
  double radius = 10;

  bool scaleRadius = true;

  RenderinstructionCircle(int level) {}

  void parse(XmlElement rootElement) {
    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.RADIUS == name || RenderInstruction.R == name) {
        radius = XmlUtils.parseNonNegativeFloat(name, value) * MapsforgeSettingsMgr().getScaleFactor();
      } else if (RenderInstruction.DISPLAY == name) {
        display = Display.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.PRIORITY == name) {
        priority = int.parse(value);
      } else if (RenderInstruction.DY == name) {
        setDy(double.parse(value) * MapsforgeSettingsMgr().getScaleFactor());
      } else if (RenderInstruction.SCALE == name) {
        setScaleFromValue(value);
      } else if (RenderInstruction.FILL == name) {
        setFillColorFromNumber(XmlUtils.getColor(value));
      } else if (RenderInstruction.SCALE_RADIUS == name) {
        scaleRadius = value == "true";
      } else if (RenderInstruction.STROKE == name) {
        setStrokeColorFromNumber(XmlUtils.getColor(value));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) * MapsforgeSettingsMgr().getScaleFactor());
      } else {
        throw Exception("circle probs");
      }
    });

    XmlUtils.checkMandatoryAttribute(rootElement.name.toString(), RenderInstruction.RADIUS, radius);
  }
}
