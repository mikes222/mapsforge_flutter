import 'package:dart_common/src/model/maprectangle.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:dart_rendertheme/src/model/layer_container.dart';
import 'package:dart_rendertheme/src/model/nodeproperties.dart';
import 'package:dart_rendertheme/src/model/wayproperties.dart';
import 'package:dart_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:dart_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

/**
 * Represents hillshading on a painter algorithm layer/level in the parsed rendertheme
 * (but without a rule, we don't need to increase waymatching complexity here)
 */
class RenderinstructionHillshading extends Renderinstruction with BaseSrcMixin implements RenderinstructionWay {
  bool always = true;
  int layer = 0;
  int minZoom = 0;
  int maxZoom = 25;
  double magnitude = 0;

  RenderinstructionHillshading(int level) {
    this.level = level;
  }

  @override
  RenderinstructionHillshading forZoomlevel(int zoomlevel, int level) {
    RenderinstructionHillshading renderinstruction = RenderinstructionHillshading(level)
      ..renderinstructionScale(this, zoomlevel)
      ..baseSrcMixinScale(this, zoomlevel);
    renderinstruction.always = always;
    renderinstruction.layer = layer;
    renderinstruction.minZoom = minZoom;
    renderinstruction.maxZoom = maxZoom;
    renderinstruction.magnitude = magnitude;
    return renderinstruction;
  }

  @override
  String getType() {
    return "hillshading";
  }

  void parse(XmlElement rootElement) {
    for (var element in rootElement.attributes) {
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
      } else {
        throw Exception("Parsing problems $name=$value");
      }
    }
  }

  @override
  MapRectangle getBoundary() {
    throw UnimplementedError();
  }

  @override
  void matchNode(LayerContainer layerContainer, NodeProperties nodeProperties) {}

  @override
  void matchWay(LayerContainer layerContainer, WayProperties wayProperties) {}
}
