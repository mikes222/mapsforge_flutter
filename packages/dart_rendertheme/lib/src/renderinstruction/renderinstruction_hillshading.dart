import 'package:dart_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_way.dart';
import 'package:dart_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

/**
 * Represents hillshading on a painter algorithm layer/level in the parsed rendertheme
 * (but without a rule, we don't need to increase waymatching complexity here)
 */
class RenderinstructionHillshading with BaseSrcMixin implements RenderInstructionWay {
  bool always = true;
  int layer = 0;
  int minZoom = 0;
  int maxZoom = 25;
  double magnitude = 0;

  RenderinstructionHillshading(int level) {
    this.level = level;
  }

  void parse(XmlElement rootElement) {
    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if ("zoom-min" == name) {
        minZoom = XmlUtils.parseNonNegativeByte("zoom-min", value);
      } else if ("zoom-max" == name) {
        maxZoom = XmlUtils.parseNonNegativeByte("zoom-max", value);
      } else if ("magnitude" == name) {
        magnitude = XmlUtils.parseNonNegativeInteger("magnitude", value).toDouble();
        if (magnitude > 255) throw new Exception("Attribute 'magnitude' must not be > 255");
      } else if ("always" == name) {
        always = "true" == (value);
      } else if ("layer" == name) {
        layer = XmlUtils.parseNonNegativeByte("layer", value);
      }
    });
  }
}
