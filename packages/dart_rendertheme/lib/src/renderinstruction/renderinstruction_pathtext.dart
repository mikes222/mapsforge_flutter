import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/src/model/display.dart';
import 'package:dart_rendertheme/src/model/mapfontfamily.dart';
import 'package:dart_rendertheme/src/model/mapfontstyle.dart';
import 'package:dart_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/fill_color_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_way.dart';
import 'package:dart_rendertheme/src/renderinstruction/repeat_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/stroke_color_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/text_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/textkey.dart';
import 'package:dart_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import 'renderinstruction.dart';

/**
 * Represents a text along a polyline on the map.
 */
class RenderinstructionPathtext with BaseSrcMixin, TextSrcMixin, StrokeColorSrcMixin, FillColorSrcMixin, RepeatSrcMixin implements RenderInstructionWay {
  static final double REPEAT_GAP_DEFAULT = 100;
  static final double REPEAT_START_DEFAULT = 10;

  TextKey? textKey;

  RenderinstructionPathtext(int level) {
    this.level = level;
    //initTextMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    //initPaintMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
  }

  void parse(XmlElement rootElement) {
    maxTextWidth = MapsforgeSettingsMgr().getMaxTextWidth();
    repeatGap = REPEAT_GAP_DEFAULT * MapsforgeSettingsMgr().getFontScaleFactor();
    repeatStart = REPEAT_START_DEFAULT * MapsforgeSettingsMgr().getFontScaleFactor();
    setStrokeMinZoomLevel(MapsforgeSettingsMgr().strokeMinZoomlevelText);

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.K == name) {
        textKey = TextKey(value);
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
      } else if (RenderInstruction.FONT_FAMILY == name) {
        setFontFamily(MapFontFamily.values.firstWhere((v) => v.toString().toLowerCase().contains(value)));
      } else if (RenderInstruction.FONT_SIZE == name) {
        setFontSize(XmlUtils.parseNonNegativeFloat(name, value) * MapsforgeSettingsMgr().getFontScaleFactor());
      } else if (RenderInstruction.FONT_STYLE == name) {
        setFontStyle(MapFontStyle.values.firstWhere((v) => v.toString().toLowerCase().contains(value)));
      } else if (RenderInstruction.REPEAT == name) {
        repeat = value == "true";
      } else if (RenderInstruction.REPEAT_GAP == name) {
        repeatGap = double.parse(value) * MapsforgeSettingsMgr().getFontScaleFactor();
      } else if (RenderInstruction.REPEAT_START == name) {
        repeatStart = double.parse(value) * MapsforgeSettingsMgr().getFontScaleFactor();
      } else if (RenderInstruction.ROTATE == name) {
        rotate = value == "true";
      } else if (RenderInstruction.STROKE == name) {
        setStrokeColorFromNumber(XmlUtils.getColor(value));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) * MapsforgeSettingsMgr().getFontScaleFactor());
      } else {
        throw Exception("PathText probs");
      }
    });

    XmlUtils.checkMandatoryAttribute(rootElement.name.toString(), RenderInstruction.K, textKey);
  }
}
