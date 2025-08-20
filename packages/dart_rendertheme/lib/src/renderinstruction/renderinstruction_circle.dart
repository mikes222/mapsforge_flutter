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

  RenderinstructionCircle(int level) {
    this.level = level;
  }

  @override
  String getType() {
    return "circle";
  }

  void parse(XmlElement rootElement) {
    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (Renderinstruction.RADIUS == name || Renderinstruction.R == name) {
        radius = XmlUtils.parseNonNegativeFloat(name, value) * MapsforgeSettingsMgr().getScaleFactor();
      } else if (Renderinstruction.DISPLAY == name) {
        display = Display.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (Renderinstruction.PRIORITY == name) {
        priority = int.parse(value);
      } else if (Renderinstruction.DY == name) {
        setDy(double.parse(value) * MapsforgeSettingsMgr().getScaleFactor());
      } else if (Renderinstruction.SCALE == name) {
        setScaleFromValue(value);
      } else if (Renderinstruction.FILL == name) {
        setFillColorFromNumber(XmlUtils.getColor(value));
      } else if (Renderinstruction.SCALE_RADIUS == name) {
        scaleRadius = value == "true";
      } else if (Renderinstruction.STROKE == name) {
        setStrokeColorFromNumber(XmlUtils.getColor(value));
      } else if (Renderinstruction.STROKE_WIDTH == name) {
        setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) * MapsforgeSettingsMgr().getScaleFactor());
      } else {
        throw Exception("circle probs");
      }
    });

    XmlUtils.checkMandatoryAttribute(rootElement.name.toString(), Renderinstruction.RADIUS, radius);
  }

  @override
  RenderinstructionCircle forZoomlevel(int zoomlevel) {
    RenderinstructionCircle renderinstruction = RenderinstructionCircle(level)
      ..baseSrcMixinScale(this, zoomlevel)
      ..fillColorSrcMixinScale(this, zoomlevel)
      ..strokeColorSrcMixinScale(this, zoomlevel);

    renderinstruction.radius = radius;
    renderinstruction.scaleRadius = scaleRadius;
    return renderinstruction;
  }
}
