import 'package:dart_common/model.dart';
import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:dart_rendertheme/src/model/map_display.dart';
import 'package:dart_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/bitmap_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/fill_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/stroke_src_mixin.dart';
import 'package:dart_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

///
/// Represents an icon on the map. The rendertheme.xml has the possiblity to define a symbol by id and use that symbol later by referring to this id.
/// The [RenderinstructionRect] class holds a symbol (=bitmap) and refers it by it's id. The class can be used by several other [Renderinstruction] implementations.
///
class RenderinstructionRect extends Renderinstruction with BaseSrcMixin, BitmapSrcMixin, FillSrcMixin, StrokeSrcMixin implements RenderinstructionWay {
  String? id;

  RenderinstructionRect(int level) {
    this.level = level;
    setBitmapPercent(100);
    setBitmapMinZoomLevel(MapsforgeSettingsMgr().strokeMinZoomlevelText);
  }

  @override
  RenderinstructionRect forZoomlevel(int zoomlevel, int level) {
    RenderinstructionRect renderinstruction = RenderinstructionRect(level)
      ..renderinstructionScale(this, zoomlevel)
      ..baseSrcMixinScale(this, zoomlevel)
      ..bitmapSrcMixinScale(this, zoomlevel)
      ..fillSrcMixinScale(this, zoomlevel)
      ..strokeSrcMixinScale(this, zoomlevel);
    renderinstruction.id = id;
    return renderinstruction;
  }

  @override
  String getType() {
    return "rect";
  }

  void parse(XmlElement rootElement) {
    for (var element in rootElement.attributes) {
      String name = element.name.toString();
      String value = element.value;
      if (Renderinstruction.SRC == name) {
        bitmapSrc = value;
      } else if (Renderinstruction.DISPLAY == name) {
        display = MapDisplay.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (Renderinstruction.PRIORITY == name) {
        priority = int.parse(value);
      } else if (Renderinstruction.DY == name) {
        setDy(double.parse(value));
      } else if (Renderinstruction.SCALE == name) {
        setScaleFromValue(value);
      } else if (Renderinstruction.ID == name) {
        id = value;
      } else if (Renderinstruction.SYMBOL_HEIGHT == name) {
        setBitmapHeight(XmlUtils.parseNonNegativeInteger(name, value));
      } else if (Renderinstruction.SYMBOL_PERCENT == name) {
        setBitmapPercent(XmlUtils.parseNonNegativeInteger(name, value));
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

    boundary = const MapRectangle(0, 0, 0, 0);
    return boundary!;
  }

  @override
  void matchNode(LayerContainer layerContainer, NodeProperties nodeProperties) {
    if (bitmapSrc == null) return;
    layerContainer.add(level, RenderInfoNode(nodeProperties, this));
  }

  @override
  void matchWay(LayerContainer layerContainer, WayProperties wayProperties) {
    if (bitmapSrc == null) return;

    if (wayProperties.getCoordinatesAbsolute().isEmpty) return;

    layerContainer.add(level, RenderInfoWay(wayProperties, this));
  }
}
