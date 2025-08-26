import 'package:dart_common/model.dart';
import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:dart_rendertheme/src/model/display.dart';
import 'package:dart_rendertheme/src/model/layer_container.dart';
import 'package:dart_rendertheme/src/model/mapfontfamily.dart';
import 'package:dart_rendertheme/src/model/mapfontstyle.dart';
import 'package:dart_rendertheme/src/model/nodeproperties.dart';
import 'package:dart_rendertheme/src/model/position.dart';
import 'package:dart_rendertheme/src/model/render_info_node.dart';
import 'package:dart_rendertheme/src/model/render_info_way.dart';
import 'package:dart_rendertheme/src/model/wayproperties.dart';
import 'package:dart_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/fill_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/stroke_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/text_src_mixin.dart';
import 'package:dart_rendertheme/src/renderinstruction/textkey.dart';
import 'package:dart_rendertheme/src/rule/symbol_searcher.dart';
import 'package:dart_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

/// Represents a text label on the map.
/// <p/>
/// If a bitmap symbol is present the caption position is calculated relative to the bitmap, the
/// center of which is at the point of the POI. The bitmap itself is never rendered by this class.
class RenderinstructionCaption extends Renderinstruction
    with BaseSrcMixin, TextSrcMixin, FillSrcMixin, StrokeSrcMixin
    implements RenderinstructionNode, RenderinstructionWay {
  static final double DEFAULT_GAP = 1;

  String? symbolId;

  TextKey? textKey;

  Position position = Position.CENTER;

  double gap = DEFAULT_GAP;

  /// In the second pass we try to find the corresponding symbol so that we can align the caption relative to this symbol.
  RenderinstructionSymbol? renderinstructionSymbol;

  RenderinstructionCaption(int level) {
    this.level = level;
    maxTextWidth = MapsforgeSettingsMgr().getMaxTextWidth();
    gap = DEFAULT_GAP * MapsforgeSettingsMgr().getFontScaleFactor();
    setStrokeMinZoomLevel(MapsforgeSettingsMgr().strokeMinZoomlevelText);
    setFontSize(10);
  }

  @override
  RenderinstructionCaption forZoomlevel(int zoomlevel) {
    RenderinstructionCaption renderinstruction = RenderinstructionCaption(level)
      ..renderinstructionScale(this, zoomlevel)
      ..baseSrcMixinScale(this, zoomlevel)
      ..textSrcMixinScale(this, zoomlevel)
      ..fillSrcMixinScale(this, zoomlevel)
      ..strokeSrcMixinScale(this, zoomlevel);
    renderinstruction.symbolId = symbolId;
    renderinstruction.textKey = textKey;
    renderinstruction.position = position;
    if (zoomlevel >= MapsforgeSettingsMgr().strokeMinZoomlevel) {
      double scaleFactor = MapsforgeSettingsMgr().calculateScaleFactor(zoomlevel, MapsforgeSettingsMgr().strokeMinZoomlevel);
      renderinstruction.gap = gap * scaleFactor;
    }
    return renderinstruction;
  }

  @override
  String getType() {
    return "caption";
  }

  @override
  void secondPass(SymbolSearcher symbolSearcher) {
    super.secondPass(symbolSearcher);
    if (symbolId != null) {
      renderinstructionSymbol = symbolSearcher.searchForSymbol(symbolId!);
    }
  }

  void parse(XmlElement rootElement) {
    for (var element in rootElement.attributes) {
      String name = element.name.toString();
      String value = element.value;

      if (Renderinstruction.K == name) {
        textKey = TextKey(value);
      } else if (Renderinstruction.DISPLAY == name) {
        display = Display.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (Renderinstruction.PRIORITY == name) {
        priority = int.parse(value);
      } else if (Renderinstruction.DY == name) {
        setDy(double.parse(value));
      } else if (Renderinstruction.SCALE == name) {
        setScaleFromValue(value);
      } else if (Renderinstruction.FILL == name) {
        setFillColorFromNumber(XmlUtils.getColor(value));
      } else if (Renderinstruction.FONT_FAMILY == name) {
        setFontFamily(MapFontFamily.values.firstWhere((v) => v.toString().toLowerCase().contains(value)));
      } else if (Renderinstruction.FONT_SIZE == name) {
        setFontSize(XmlUtils.parseNonNegativeFloat(name, value));
      } else if (Renderinstruction.FONT_STYLE == name) {
        setFontStyle(MapFontStyle.values.firstWhere((e) => e.toString().toLowerCase().contains(value)));
      } else if (Renderinstruction.POSITION == name) {
        position = Position.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (Renderinstruction.STROKE == name) {
        setStrokeColorFromNumber(XmlUtils.getColor(value));
      } else if (Renderinstruction.STROKE_WIDTH == name) {
        setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value));
      } else if (Renderinstruction.SYMBOL_ID == name) {
        symbolId = value;
      } else {
        throw Exception("Parsing problems $name=$value");
      }
    }

    XmlUtils.checkMandatoryAttribute(rootElement.name.toString(), Renderinstruction.K, textKey);
  }

  @override
  MapRectangle getBoundary() {
    // boundary depends on the text, so fake it
    double widthEstimated = MapsforgeSettingsMgr().maxTextWidth;
    double heightEstimated = fontSize;
    return calculateBoundaryWithSymbol(position, widthEstimated, heightEstimated);
  }

  MapRectangle calculateBoundaryWithSymbol(Position pos, double fontWidth, double fontHeight) {
    MapRectangle? symbolBoundary = renderinstructionSymbol?.getBoundary();
    //    print("captoin: $pos $fontWidth $fontHeight $symbolBoundary for caption $textKey");
    if (pos == Position.CENTER && symbolBoundary != null) {
      // sensible defaults: below if symbolContainer is present, center if not
      pos = Position.BELOW;
    }

    if (symbolBoundary == null) {
      // symbol not available, draw the text at the center
      pos = Position.CENTER;
      symbolBoundary = const MapRectangle.zero();
    }

    double halfWidth = fontWidth / 2;
    double halfHeight = fontHeight / 2;

    switch (pos) {
      case Position.AUTO:
      case Position.CENTER:
        boundary = MapRectangle(-halfWidth, -halfHeight, halfWidth, halfHeight);
        break;
      case Position.BELOW:
        boundary = MapRectangle(-halfWidth, symbolBoundary.bottom + 0 + gap + dy, halfWidth, symbolBoundary.bottom + fontHeight + gap + dy);
        break;
      case Position.BELOW_LEFT:
        boundary = MapRectangle(
          symbolBoundary.left - fontWidth - gap,
          symbolBoundary.bottom + 0 + gap + dy,
          symbolBoundary.left - 0 - gap,
          symbolBoundary.bottom + fontHeight + gap + dy,
        );
        break;
      case Position.BELOW_RIGHT:
        boundary = MapRectangle(
          symbolBoundary.right + 0 + gap,
          symbolBoundary.bottom + 0 + gap + dy,
          symbolBoundary.right + fontWidth + gap,
          symbolBoundary.bottom + fontHeight + gap + dy,
        );
        break;
      case Position.ABOVE:
        boundary = MapRectangle(-halfWidth, symbolBoundary.top - fontHeight - gap + dy, halfWidth, symbolBoundary.top - 0 - gap + dy);
        break;
      case Position.ABOVE_LEFT:
        boundary = MapRectangle(
          symbolBoundary.left - fontWidth - gap,
          symbolBoundary.top - fontHeight - gap + dy,
          symbolBoundary.left - 0 - gap,
          symbolBoundary.top + 0 - gap + dy,
        );
        break;
      case Position.ABOVE_RIGHT:
        boundary = MapRectangle(
          symbolBoundary.right + 0 + gap,
          symbolBoundary.top - fontHeight - gap + dy,
          symbolBoundary.right + fontWidth + gap,
          symbolBoundary.top + 0 - gap + dy,
        );
        break;
      case Position.LEFT:
        boundary = MapRectangle(symbolBoundary.left - fontWidth - gap, -halfHeight, symbolBoundary.left - 0 - gap, halfHeight);
        break;
      case Position.RIGHT:
        boundary = MapRectangle(symbolBoundary.right + 0 + gap, -halfHeight, symbolBoundary.right + fontHeight + gap, halfHeight);
        break;
    }
    return boundary!;
  }

  @override
  void matchNode(LayerContainer layerContainer, NodeProperties nodeProperties) {
    String? caption = textKey!.getValue(nodeProperties.tags);
    if (caption == null) {
      return;
    }

    layerContainer.addLabel(RenderInfoNode(nodeProperties, this, caption: caption));
  }

  @override
  void matchWay(LayerContainer layerContainer, WayProperties wayProperties) {
    String? caption = textKey!.getValue(wayProperties.getTags());
    if (caption == null) {
      return;
    }

    layerContainer.addLabel(RenderInfoWay(wayProperties, this, caption: caption));
  }
}
