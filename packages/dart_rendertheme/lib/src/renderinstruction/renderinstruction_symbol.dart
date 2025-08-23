import 'package:dart_common/model.dart';
import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/rendertheme.dart';
import 'package:dart_rendertheme/src/model/display.dart';
import 'package:dart_rendertheme/src/model/render_info_node.dart';
import 'package:dart_rendertheme/src/model/render_info_way.dart';
import 'package:dart_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/bitmap_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_node.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_way.dart';
import 'package:dart_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

///
/// Represents an icon on the map. The rendertheme.xml has the possiblity to define a symbol by id and use that symbol later by referring to this id.
/// The [RenderinstructionSymbol] class holds a symbol (=bitmap) and refers it by it's id. The class can be used by several other [Renderinstruction] implementations.
///
class RenderinstructionSymbol extends Renderinstruction with BaseSrcMixin, BitmapSrcMixin implements RenderinstructionNode, RenderinstructionWay {
  String? id;

  Position position = Position.CENTER;

  /// The rotation of the symbol. Currently not fully supported
  double theta = 0;

  RenderinstructionSymbol(int level) {
    this.level = level;
  }

  @override
  RenderinstructionSymbol forZoomlevel(int zoomlevel) {
    RenderinstructionSymbol renderinstruction = RenderinstructionSymbol(level)
      ..renderinstructionScale(this, zoomlevel)
      ..baseSrcMixinScale(this, zoomlevel)
      ..bitmapSrcMixinScale(this, zoomlevel);
    renderinstruction.id = id;
    renderinstruction.position = position;
    return renderinstruction;
  }

  @override
  String getType() {
    return "symbol";
  }

  void parse(XmlElement rootElement) {
    setBitmapPercent(100 * MapsforgeSettingsMgr().getFontScaleFactor().round());
    setBitmapMinZoomLevel(MapsforgeSettingsMgr().strokeMinZoomlevelText);

    for (var element in rootElement.attributes) {
      String name = element.name.toString();
      String value = element.value;
      if (Renderinstruction.SRC == name) {
        bitmapSrc = value;
      } else if (Renderinstruction.DISPLAY == name) {
        display = Display.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (Renderinstruction.PRIORITY == name) {
        priority = int.parse(value);
      } else if (Renderinstruction.DY == name) {
        setDy(double.parse(value) * MapsforgeSettingsMgr().getUserScaleFactor());
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
        throw Exception("Parsing problems $name=$value");
      }
    }
  }

  @override
  MapRectangle getBoundary() {
    if (boundary != null) return boundary!;

    double halfWidth = getBitmapWidth() / 2;
    double halfHeight = getBitmapHeight() / 2;

    switch (position) {
      case Position.AUTO:
      case Position.CENTER:
        boundary = MapRectangle(-halfWidth, -halfHeight, halfWidth, halfHeight);
        break;
      case Position.BELOW:
        boundary = MapRectangle(-halfWidth, 0 + dy, halfWidth, getBitmapHeight() + dy);
        break;
      case Position.BELOW_LEFT:
        boundary = MapRectangle(-getBitmapWidth().toDouble(), 0 + dy, 0, getBitmapHeight() + dy);
        break;
      case Position.BELOW_RIGHT:
        boundary = MapRectangle(0, 0 + dy, getBitmapWidth().toDouble(), getBitmapHeight() + dy);
        break;
      case Position.ABOVE:
        boundary = MapRectangle(-halfWidth, -getBitmapHeight() + dy, halfWidth, 0 + dy);
        break;
      case Position.ABOVE_LEFT:
        boundary = MapRectangle(-getBitmapWidth().toDouble(), -getBitmapHeight() + dy, 0, 0 + dy);
        break;
      case Position.ABOVE_RIGHT:
        boundary = MapRectangle(0, -getBitmapHeight() + dy, getBitmapWidth().toDouble(), 0 + dy);
        break;
      case Position.LEFT:
        boundary = MapRectangle(-getBitmapWidth().toDouble(), -halfHeight + dy, 0, halfHeight + dy);
        break;
      case Position.RIGHT:
        boundary = MapRectangle(0, -halfHeight + dy, getBitmapWidth().toDouble(), halfHeight + dy);
        break;
    }
    return boundary!;
  }

  @override
  void matchNode(LayerContainer layerContainer, NodeProperties nodeProperties) {
    if (bitmapSrc == null) return;
    layerContainer.addLabel(RenderInfoNode(nodeProperties, this));
  }

  @override
  void matchWay(LayerContainer layerContainer, WayProperties wayProperties) {
    if (bitmapSrc == null) return;

    if (wayProperties.getCoordinatesAbsolute().isEmpty) return;

    layerContainer.addLabel(RenderInfoWay(wayProperties, this));
  }
}
