import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/src/model/display.dart';
import 'package:dart_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/bitmap_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_node.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_way.dart';
import 'package:dart_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

///
/// Represents an icon on the map. The rendertheme.xml has the possiblity to define a symbol by id and use that symbol later by referring to this id.
/// The [RenderinstructionSymbol] class holds a symbol (=bitmap) and refers it by it's id. The class can be used by several other [Renderinstruction] implementations.
///
class RenderinstructionSymbol with BaseSrcMixin, BitmapSrcMixin implements RenderInstructionNode, RenderInstructionWay {
  String? id;

  RenderinstructionSymbol(int level) {
    this.level = level;
  }

  @override
  String getType() {
    return "symbol";
  }

  void parse(XmlElement rootElement) {
    setBitmapPercent(100 * MapsforgeSettingsMgr().getFontScaleFactor().round());
    setBitmapMinZoomLevel(MapsforgeSettingsMgr().strokeMinZoomlevelText);

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;
      if (Renderinstruction.SRC == name) {
        bitmapSrc = value;
      } else if (Renderinstruction.DISPLAY == name) {
        display = Display.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (Renderinstruction.PRIORITY == name) {
        priority = int.parse(value);
      } else if (Renderinstruction.DY == name) {
        setDy(double.parse(value) * MapsforgeSettingsMgr().getScaleFactor());
      } else if (Renderinstruction.SCALE == name) {
        setScaleFromValue(value);
      } else if (Renderinstruction.ID == name) {
        id = value;
      } else if (Renderinstruction.SYMBOL_HEIGHT == name) {
        setBitmapHeight(XmlUtils.parseNonNegativeInteger(name, value));
      } else if (Renderinstruction.SYMBOL_PERCENT == name) {
        setBitmapPercent(XmlUtils.parseNonNegativeInteger(name, value) * MapsforgeSettingsMgr().getFontScaleFactor().round());
      } else if (Renderinstruction.SYMBOL_SCALING == name) {
        // no-op
      } else if (Renderinstruction.SYMBOL_WIDTH == name) {
        setBitmapWidth(XmlUtils.parseNonNegativeInteger(name, value));
      } else {
        throw Exception("Symbol probs");
      }
    });
  }

  @override
  RenderinstructionSymbol forZoomlevel(int zoomlevel) {
    RenderinstructionSymbol renderinstruction = RenderinstructionSymbol(level)
      ..baseSrcMixinScale(this, zoomlevel)
      ..bitmapSrcMixinScale(this, zoomlevel);
    renderinstruction.id = id;
    return renderinstruction;
  }
}
