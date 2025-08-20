import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/src/model/display.dart';
import 'package:dart_rendertheme/src/model/position.dart';
import 'package:dart_rendertheme/src/model/scale.dart';
import 'package:dart_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/bitmap_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/renderinstruction_way.dart';
import 'package:dart_rendertheme/src/renderinstruction/repeat_src_mixin.dart';
import 'package:dart_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import 'renderinstruction.dart';

/// Represents an icon along a polyline on the map.
class RenderinstructionLinesymbol with BaseSrcMixin, BitmapSrcMixin, RepeatSrcMixin implements RenderInstructionWay {
  static final double REPEAT_GAP_DEFAULT = 200;
  static final double REPEAT_START_DEFAULT = 30;

  Position position = Position.CENTER;

  bool alignCenter = true;

  RenderinstructionLinesymbol(int level) {
    this.level = level;
  }

  @override
  String getType() {
    return "linesymbol";
  }

  void parse(XmlElement rootElement) {
    //initBitmapSrcMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    setRepeatGap(REPEAT_GAP_DEFAULT * MapsforgeSettingsMgr().getFontScaleFactor());
    repeatStart = REPEAT_START_DEFAULT * MapsforgeSettingsMgr().getFontScaleFactor();
    setBitmapPercent(100 * MapsforgeSettingsMgr().getFontScaleFactor().round());
    setBitmapMinZoomLevel(MapsforgeSettingsMgr().strokeMinZoomlevelText);

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (Renderinstruction.SRC == name) {
        bitmapSrc = value;
      } else if (Renderinstruction.ALIGN_CENTER == name) {
        alignCenter = "true" == (value);
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
      } else if (Renderinstruction.POSITION == name) {
        position = Position.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (Renderinstruction.PRIORITY == name) {
        priority = int.parse(value);
      } else if (Renderinstruction.REPEAT == name) {
        repeat = "true" == (value);
      } else if (Renderinstruction.REPEAT_GAP == name) {
        setRepeatGap(double.parse(value) * MapsforgeSettingsMgr().getFontScaleFactor());
      } else if (Renderinstruction.REPEAT_START == name) {
        repeatStart = double.parse(value) * MapsforgeSettingsMgr().getFontScaleFactor();
      } else if (Renderinstruction.ROTATE == name) {
        rotate = "true" == (value);
      } else if (Renderinstruction.SYMBOL_HEIGHT == name) {
        setBitmapHeight(XmlUtils.parseNonNegativeInteger(name, value));
      } else if (Renderinstruction.SYMBOL_PERCENT == name) {
        setBitmapPercent(XmlUtils.parseNonNegativeInteger(name, value) * MapsforgeSettingsMgr().getFontScaleFactor().round());
      } else if (Renderinstruction.SYMBOL_SCALING == name) {
        // no-op
      } else if (Renderinstruction.SYMBOL_WIDTH == name) {
        setBitmapWidth(XmlUtils.parseNonNegativeInteger(name, value));
      } else {
        throw Exception("LineSymbol probs: unknown '$name'");
      }
    });
  }

  @override
  RenderinstructionLinesymbol forZoomlevel(int zoomlevel) {
    RenderinstructionLinesymbol renderinstruction = RenderinstructionLinesymbol(level)
      ..baseSrcMixinScale(this, zoomlevel)
      ..bitmapSrcMixinScale(this, zoomlevel)
      ..repeatSrcMixinScale(this, zoomlevel);
    renderinstruction.position = position;
    renderinstruction.alignCenter = alignCenter;
    return renderinstruction;
  }
}
