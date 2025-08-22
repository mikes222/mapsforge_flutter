import 'package:dart_common/model.dart';
import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/src/model/cap.dart';
import 'package:dart_rendertheme/src/model/display.dart';
import 'package:dart_rendertheme/src/model/join.dart';
import 'package:dart_rendertheme/src/model/layer_container.dart';
import 'package:dart_rendertheme/src/model/nodeproperties.dart';
import 'package:dart_rendertheme/src/model/render_info_way.dart';
import 'package:dart_rendertheme/src/model/scale.dart';
import 'package:dart_rendertheme/src/model/wayproperties.dart';
import 'package:dart_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/bitmap_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_way.dart';
import 'package:dart_rendertheme/src/renderinstruction/stroke_color_src_mixin.dart';
import 'package:dart_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

/// Represents an open polyline on the map.
class RenderinstructionPolyline extends Renderinstruction with BaseSrcMixin, BitmapSrcMixin, StrokeColorSrcMixin implements RenderinstructionWay {
  String? id;

  RenderinstructionPolyline(int level) {
    this.level = level;
  }

  @override
  RenderinstructionPolyline forZoomlevel(int zoomlevel) {
    RenderinstructionPolyline renderinstruction = RenderinstructionPolyline(level)
      ..renderinstructionScale(this, zoomlevel)
      ..baseSrcMixinScale(this, zoomlevel)
      ..bitmapSrcMixinScale(this, zoomlevel)
      ..strokeColorSrcMixinScale(this, zoomlevel);
    renderinstruction.id = id;
    return renderinstruction;
  }

  @override
  String getType() {
    return "polyline";
  }

  void parse(XmlElement rootElement) {
    // do not scale bitmap in lines they look ugly
    setBitmapPercent(100 * MapsforgeSettingsMgr().getFontScaleFactor().round());
    //    base.setBitmapMinZoomLevel(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    setBitmapMinZoomLevel(65535);
    //    base.setStrokeMinZoomLevel(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);

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
        setDy(double.parse(value) * MapsforgeSettingsMgr().getScaleFactor());
      } else if (Renderinstruction.SCALE == name) {
        setScaleFromValue(value);
        if (scale == Scale.NONE) {
          setBitmapMinZoomLevel(65535);
        }
      } else if (Renderinstruction.ID == name) {
        id = value;
      } else if (Renderinstruction.STROKE == name) {
        setStrokeColorFromNumber(XmlUtils.getColor(value));
      } else if (Renderinstruction.STROKE_DASHARRAY == name) {
        List<double> dashArray = parseFloatArray(name, value);
        if (MapsforgeSettingsMgr().getScaleFactor() != 1) {
          for (int f = 0; f < dashArray.length; ++f) {
            dashArray[f] = dashArray[f] * MapsforgeSettingsMgr().getScaleFactor();
          }
        }
        setStrokeDashArray(dashArray);
      } else if (Renderinstruction.STROKE_LINECAP == name) {
        setStrokeCap(Cap.values.firstWhere((e) => e.toString().toLowerCase().contains(value)));
      } else if (Renderinstruction.STROKE_LINEJOIN == name) {
        setStrokeJoin(Join.values.firstWhere((e) => e.toString().toLowerCase().contains(value)));
      } else if (Renderinstruction.STROKE_WIDTH == name) {
        setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) * MapsforgeSettingsMgr().getScaleFactor());
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

  static List<double> parseFloatArray(String name, String dashString) {
    List<String> dashEntries = dashString.split(",");
    List<double> dashIntervals = dashEntries.map((e) => XmlUtils.parseNonNegativeFloat(name, e)).toList();
    // List<double>(dashEntries.length);
    // for (int i = 0; i < dashEntries.length; ++i) {
    //   dashIntervals[i] = XmlUtils.parseNonNegativeFloat(name, dashEntries[i]);
    // }
    return dashIntervals;
  }

  @override
  MapRectangle? getBoundary() {
    // boundary depends on the area
    return null;
  }

  @override
  void matchNode(LayerContainer layerContainer, NodeProperties nodeProperties) {}

  @override
  void matchWay(LayerContainer layerContainer, WayProperties wayProperties) {
    if (bitmapSrc == null && isStrokeTransparent()) return;
    if (wayProperties.getCoordinatesAbsolute().isEmpty) return;

    layerContainer.add(RenderInfoWay<RenderinstructionPolyline>(wayProperties, this));
  }
}
