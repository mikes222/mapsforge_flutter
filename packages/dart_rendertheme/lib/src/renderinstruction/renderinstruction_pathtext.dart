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

  @override
  String getType() {
    return "pathtext";
  }

  void parse(XmlElement rootElement) {
    maxTextWidth = MapsforgeSettingsMgr().getMaxTextWidth();
    repeatGap = REPEAT_GAP_DEFAULT * MapsforgeSettingsMgr().getFontScaleFactor();
    repeatStart = REPEAT_START_DEFAULT * MapsforgeSettingsMgr().getFontScaleFactor();
    setStrokeMinZoomLevel(MapsforgeSettingsMgr().strokeMinZoomlevelText);

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (Renderinstruction.K == name) {
        textKey = TextKey(value);
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
      } else if (Renderinstruction.FONT_FAMILY == name) {
        setFontFamily(MapFontFamily.values.firstWhere((v) => v.toString().toLowerCase().contains(value)));
      } else if (Renderinstruction.FONT_SIZE == name) {
        setFontSize(XmlUtils.parseNonNegativeFloat(name, value) * MapsforgeSettingsMgr().getFontScaleFactor());
      } else if (Renderinstruction.FONT_STYLE == name) {
        setFontStyle(MapFontStyle.values.firstWhere((v) => v.toString().toLowerCase().contains(value)));
      } else if (Renderinstruction.REPEAT == name) {
        repeat = value == "true";
      } else if (Renderinstruction.REPEAT_GAP == name) {
        repeatGap = double.parse(value) * MapsforgeSettingsMgr().getFontScaleFactor();
      } else if (Renderinstruction.REPEAT_START == name) {
        repeatStart = double.parse(value) * MapsforgeSettingsMgr().getFontScaleFactor();
      } else if (Renderinstruction.ROTATE == name) {
        rotate = value == "true";
      } else if (Renderinstruction.STROKE == name) {
        setStrokeColorFromNumber(XmlUtils.getColor(value));
      } else if (Renderinstruction.STROKE_WIDTH == name) {
        setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) * MapsforgeSettingsMgr().getFontScaleFactor());
      } else {
        throw Exception("PathText probs");
      }
    });

    XmlUtils.checkMandatoryAttribute(rootElement.name.toString(), Renderinstruction.K, textKey);
  }

  @override
  RenderinstructionPathtext forZoomlevel(int zoomlevel) {
    RenderinstructionPathtext renderinstruction = RenderinstructionPathtext(level)
      ..baseSrcMixinScale(this, zoomlevel)
      ..textSrcMixinScale(this, zoomlevel)
      ..strokeColorSrcMixinScale(this, zoomlevel)
      ..fillColorSrcMixinScale(this, zoomlevel)
      ..repeatSrcMixinScale(this, zoomlevel);
    renderinstruction.textKey = textKey;
    return renderinstruction;
  }
}
