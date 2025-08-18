import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/src/model/cap.dart';
import 'package:dart_rendertheme/src/model/display.dart';
import 'package:dart_rendertheme/src/model/join.dart';
import 'package:dart_rendertheme/src/model/scale.dart';
import 'package:dart_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/bitmap_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_way.dart';
import 'package:dart_rendertheme/src/renderinstruction/stroke_color_src_mixin.dart';
import 'package:dart_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

/// Represents an open polyline on the map.
class RenderinstructionPolyline with BaseSrcMixin, BitmapSrcMixin, StrokeColorSrcMixin implements RenderInstructionWay {
  String? id;

  RenderinstructionPolyline(int level) {
    this.level = level;
  }

  void parse(XmlElement rootElement) {
    // do not scale bitmap in lines they look ugly
    setBitmapPercent(100 * MapsforgeSettingsMgr().getFontScaleFactor().round());
    //    base.setBitmapMinZoomLevel(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    setBitmapMinZoomLevel(65535);
    //    base.setStrokeMinZoomLevel(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.SRC == name) {
        bitmapSrc = value;
      } else if (RenderInstruction.DISPLAY == name) {
        display = Display.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.PRIORITY == name) {
        priority = int.parse(value);
      } else if (RenderInstruction.DY == name) {
        setDy(double.parse(value) * MapsforgeSettingsMgr().getScaleFactor());
      } else if (RenderInstruction.SCALE == name) {
        setScaleFromValue(value);
        if (scale == Scale.NONE) {
          setBitmapMinZoomLevel(65535);
        }
      } else if (RenderInstruction.ID == name) {
        id = value;
      } else if (RenderInstruction.STROKE == name) {
        setStrokeColorFromNumber(XmlUtils.getColor(value));
      } else if (RenderInstruction.STROKE_DASHARRAY == name) {
        List<double> dashArray = parseFloatArray(name, value);
        if (MapsforgeSettingsMgr().getScaleFactor() != 1) {
          for (int f = 0; f < dashArray.length; ++f) {
            dashArray[f] = dashArray[f] * MapsforgeSettingsMgr().getScaleFactor();
          }
        }
        setStrokeDashArray(dashArray);
      } else if (RenderInstruction.STROKE_LINECAP == name) {
        setStrokeCap(Cap.values.firstWhere((e) => e.toString().toLowerCase().contains(value)));
      } else if (RenderInstruction.STROKE_LINEJOIN == name) {
        setStrokeJoin(Join.values.firstWhere((e) => e.toString().toLowerCase().contains(value)));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) * MapsforgeSettingsMgr().getScaleFactor());
      } else if (RenderInstruction.SYMBOL_HEIGHT == name) {
        setBitmapHeight(XmlUtils.parseNonNegativeInteger(name, value));
      } else if (RenderInstruction.SYMBOL_PERCENT == name) {
        setBitmapPercent(XmlUtils.parseNonNegativeInteger(name, value) * MapsforgeSettingsMgr().getFontScaleFactor().round());
      } else if (RenderInstruction.SYMBOL_SCALING == name) {
        // no-op
      } else if (RenderInstruction.SYMBOL_WIDTH == name) {
        setBitmapWidth(XmlUtils.parseNonNegativeInteger(name, value));
      } else {
        throw new Exception("element hinich");
      }
    });
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
}
