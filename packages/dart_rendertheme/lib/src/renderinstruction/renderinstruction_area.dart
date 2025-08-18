import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/src/model/display.dart';
import 'package:dart_rendertheme/src/model/scale.dart';
import 'package:dart_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/bitmap_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/fill_color_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_way.dart';
import 'package:dart_rendertheme/src/renderinstruction/stroke_color_src_mixin.dart';
import 'package:dart_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import 'renderinstruction.dart';

/**
 * Represents a closed polygon on the map.
 */
class RenderinstructionArea with BaseSrcMixin, BitmapSrcMixin, FillColorSrcMixin, StrokeColorSrcMixin implements RenderInstructionWay {
  RenderinstructionArea(int level) : super() {
    // do not scale bitmaps in areas. They look ugly
    setBitmapMinZoomLevel(65535);
    setBitmapPercent(100 * MapsforgeSettingsMgr().getFontScaleFactor().round());
  }

  void parse(XmlElement rootElement) {
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
        if (scale == Scale.NONE) setStrokeMinZoomLevel(665535);
      } else if (RenderInstruction.FILL == name) {
        setFillColorFromNumber(XmlUtils.getColor(value));
      } else if (RenderInstruction.STROKE == name) {
        setStrokeColorFromNumber(XmlUtils.getColor(value));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) * MapsforgeSettingsMgr().getScaleFactor());
      } else if (RenderInstruction.SYMBOL_WIDTH == name) {
        setBitmapWidth(XmlUtils.parseNonNegativeInteger(name, value));
      } else if (RenderInstruction.SYMBOL_HEIGHT == name) {
        setBitmapHeight(XmlUtils.parseNonNegativeInteger(name, value));
      } else if (RenderInstruction.SYMBOL_PERCENT == name) {
        setBitmapPercent(XmlUtils.parseNonNegativeInteger(name, value) * MapsforgeSettingsMgr().getFontScaleFactor().round());
      } else if (RenderInstruction.SYMBOL_SCALING == name) {
        // no-op
      } else if (RenderInstruction.SYMBOL_WIDTH == name) {
        setBitmapWidth(XmlUtils.parseNonNegativeInteger(name, value));
      } else {
        throw Exception(name + "=" + value);
      }
    });
  }
}
