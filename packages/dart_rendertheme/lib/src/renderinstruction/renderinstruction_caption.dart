import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/src/model/display.dart';
import 'package:dart_rendertheme/src/model/mapfontfamily.dart';
import 'package:dart_rendertheme/src/model/mapfontstyle.dart';
import 'package:dart_rendertheme/src/model/position.dart';
import 'package:dart_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/fill_color_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_node.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_way.dart';
import 'package:dart_rendertheme/src/renderinstruction/stroke_color_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/text_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/textkey.dart';
import 'package:dart_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

/**
 * Represents a text label on the map.
 * <p/>
 * If a bitmap symbol is present the caption position is calculated relative to the bitmap, the
 * center of which is at the point of the POI. The bitmap itself is never rendered.
 */
class RenderinstructionCaption with BaseSrcMixin, TextSrcMixin, FillColorSrcMixin, StrokeColorSrcMixin implements RenderInstructionNode, RenderInstructionWay {
  static final double DEFAULT_GAP = 1;

  String? symbolId;

  TextKey? textKey;

  Position position = Position.CENTER;

  double gap = DEFAULT_GAP;

  RenderinstructionCaption(int level) {
    this.level = level;
  }

  @override
  String getType() {
    return "caption";
  }

  void parse(XmlElement rootElement) {
    maxTextWidth = MapsforgeSettingsMgr().getMaxTextWidth();
    gap = DEFAULT_GAP * MapsforgeSettingsMgr().getFontScaleFactor();
    setStrokeMinZoomLevel(MapsforgeSettingsMgr().strokeMinZoomlevelText);
    setFontSize(10 * MapsforgeSettingsMgr().getFontScaleFactor());

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
        setFontStyle(MapFontStyle.values.firstWhere((e) => e.toString().toLowerCase().contains(value)));
      } else if (Renderinstruction.POSITION == name) {
        position = Position.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (Renderinstruction.STROKE == name) {
        setStrokeColorFromNumber(XmlUtils.getColor(value));
      } else if (Renderinstruction.STROKE_WIDTH == name) {
        setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) * MapsforgeSettingsMgr().getFontScaleFactor());
      } else if (Renderinstruction.SYMBOL_ID == name) {
        symbolId = value;
      } else {
        throw Exception("caption unknwon attribute");
      }
    });

    XmlUtils.checkMandatoryAttribute(rootElement.name.toString(), Renderinstruction.K, textKey);
  }

  @override
  RenderinstructionCaption forZoomlevel(int zoomlevel) {
    RenderinstructionCaption renderinstruction = RenderinstructionCaption(level)
      ..baseSrcMixinScale(this, zoomlevel)
      ..textSrcMixinScale(this, zoomlevel)
      ..fillColorSrcMixinScale(this, zoomlevel)
      ..strokeColorSrcMixinScale(this, zoomlevel);
    renderinstruction.symbolId = symbolId;
    renderinstruction.textKey = textKey;
    renderinstruction.position = position;
    renderinstruction.gap = gap;
    return renderinstruction;
  }
}
