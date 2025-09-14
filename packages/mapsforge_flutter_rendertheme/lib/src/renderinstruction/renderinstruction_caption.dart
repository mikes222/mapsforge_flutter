import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';
import 'package:mapsforge_flutter_rendertheme/src/model/map_display.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/base_src_mixin.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/fill_src_mixin.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/stroke_src_mixin.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/text_src_mixin.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/textkey.dart';
import 'package:mapsforge_flutter_rendertheme/src/xml/xmlutils.dart';
import 'package:xml/xml.dart';

/// Rendering instruction for text labels and captions on the map.
///
/// This class handles the rendering of text labels for POIs, area names, and other
/// textual information. It supports positioning relative to symbols, font styling,
/// stroke outlines, and collision detection for optimal label placement.
///
/// Key features:
/// - Text positioning relative to symbols or standalone
/// - Font family, size, and style customization
/// - Text stroke outlines for better readability
/// - Collision detection and label placement optimization
/// - Support for both node (POI) and way (area) labeling
class RenderinstructionCaption extends Renderinstruction
    with BaseSrcMixin, TextSrcMixin, FillSrcMixin, StrokeSrcMixin
    implements RenderinstructionNode, RenderinstructionWay {
  /// Default gap between text and associated symbols in pixels.
  static final double DEFAULT_GAP = 1;

  /// Identifier of the symbol this caption is associated with.
  String? symbolId;

  /// Text key defining which map feature attribute to display.
  TextKey? textKey;

  /// Positioning of the caption relative to its anchor point or symbol.
  MapPositioning position = MapPositioning.CENTER;

  /// Gap distance between caption and associated symbol in pixels.
  double gap = DEFAULT_GAP;

  /// Boundary rectangle of the associated symbol for relative positioning.
  ///
  /// Determined in the second pass of theme processing to enable
  /// accurate caption alignment relative to symbol boundaries.
  MapRectangle? symbolBoundary;

  /// Creates a new caption rendering instruction for the specified drawing level.
  ///
  /// Initializes default text properties including font size, stroke settings,
  /// and gap scaling based on global font scale factor.
  ///
  /// [level] The drawing level (layer) for this caption instruction
  RenderinstructionCaption(int level) {
    this.level = level;
    gap = DEFAULT_GAP * MapsforgeSettingsMgr().getFontScaleFactor();
    setStrokeMinZoomLevel(MapsforgeSettingsMgr().strokeMinZoomlevelText);
    setFontSize(10);
  }

  @override
  RenderinstructionCaption forZoomlevel(int zoomlevel, int level) {
    RenderinstructionCaption renderinstruction = RenderinstructionCaption(level)
      ..renderinstructionScale(this, zoomlevel)
      ..baseSrcMixinScale(this, zoomlevel)
      ..textSrcMixinScale(this, zoomlevel)
      ..fillSrcMixinScale(this, zoomlevel)
      ..strokeSrcMixinScale(this, zoomlevel);
    renderinstruction.symbolId = symbolId;
    renderinstruction.textKey = textKey;
    renderinstruction.position = position;
    if (zoomlevel >= strokeMinZoomLevel) {
      double scaleFactor = MapsforgeSettingsMgr().calculateScaleFactor(zoomlevel, strokeMinZoomLevel);
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
      symbolBoundary = symbolSearcher.searchForSymbolBoundary(symbolId!);
    }
  }

  void parse(XmlElement rootElement) {
    for (var element in rootElement.attributes) {
      String name = element.name.toString();
      String value = element.value;

      if (Renderinstruction.K == name) {
        textKey = TextKey(value);
      } else if (Renderinstruction.DISPLAY == name) {
        display = MapDisplay.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
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
        position = MapPositioning.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
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
  MapRectangle getBoundary(RenderInfo renderInfo) {
    MapSize textSize = getEstimatedTextBoundary(renderInfo.caption ?? "", strokeWidth);
    return calculateBoundaryWithSymbol(position, textSize.width, textSize.height);
  }

  MapRectangle calculateBoundaryWithSymbol(MapPositioning pos, double fontWidth, double fontHeight) {
    assert(fontWidth > 0, "fontWidth must be positive ($fontWidth)");
    assert(fontWidth < 10000, "fontWidth must be less than 10000 ($fontWidth)");
    assert(fontHeight > 0, "fontHeight must be positive ($fontHeight)");
    assert(fontHeight < 10000, "fontHeight must be less than 10000 ($fontHeight)");
    //    print("captoin: $pos $fontWidth $fontHeight $symbolBoundary for caption $textKey");
    MapRectangle? symBoundary = symbolBoundary;
    if (pos == MapPositioning.CENTER && symBoundary != null) {
      // sensible defaults: below if symbolContainer is present, center if not
      pos = MapPositioning.BELOW;
    }

    if (symBoundary == null) {
      // symbol not available, draw the text at the center
      pos = MapPositioning.CENTER;
      symBoundary = const MapRectangle.zero();
    }

    double halfWidth = fontWidth / 2;
    double halfHeight = fontHeight / 2;

    switch (pos) {
      case MapPositioning.AUTO:
      case MapPositioning.CENTER:
        boundary = MapRectangle(-halfWidth, -halfHeight + dy, halfWidth, halfHeight + dy);
        break;
      case MapPositioning.BELOW:
        boundary = MapRectangle(-halfWidth, symBoundary.bottom + 0 + gap + dy, halfWidth, symBoundary.bottom + fontHeight + gap + dy);
        break;
      case MapPositioning.BELOW_LEFT:
        boundary = MapRectangle(
          symBoundary.left - fontWidth - gap,
          symBoundary.bottom + 0 + gap + dy,
          symBoundary.left - 0 - gap,
          symBoundary.bottom + fontHeight + gap + dy,
        );
        break;
      case MapPositioning.BELOW_RIGHT:
        boundary = MapRectangle(
          symBoundary.right + 0 + gap,
          symBoundary.bottom + 0 + gap + dy,
          symBoundary.right + fontWidth + gap,
          symBoundary.bottom + fontHeight + gap + dy,
        );
        break;
      case MapPositioning.ABOVE:
        boundary = MapRectangle(-halfWidth, symBoundary.top - fontHeight - gap + dy, halfWidth, symBoundary.top - 0 - gap + dy);
        break;
      case MapPositioning.ABOVE_LEFT:
        boundary = MapRectangle(
          symBoundary.left - fontWidth - gap,
          symBoundary.top - fontHeight - gap + dy,
          symBoundary.left - 0 - gap,
          symBoundary.top + 0 - gap + dy,
        );
        break;
      case MapPositioning.ABOVE_RIGHT:
        boundary = MapRectangle(
          symBoundary.right + 0 + gap,
          symBoundary.top - fontHeight - gap + dy,
          symBoundary.right + fontWidth + gap,
          symBoundary.top + 0 - gap + dy,
        );
        break;
      case MapPositioning.LEFT:
        boundary = MapRectangle(symBoundary.left - fontWidth - gap, -halfHeight + dy, symBoundary.left - 0 - gap, halfHeight + dy);
        break;
      case MapPositioning.RIGHT:
        boundary = MapRectangle(symBoundary.right + 0 + gap, -halfHeight + dy, symBoundary.right + fontHeight + gap, halfHeight + dy);
        break;
    }
    return boundary!;
  }

  @override
  void matchNode(LayerContainer layerContainer, NodeProperties nodeProperties) {
    String? caption = textKey!.getValue(nodeProperties.tags);
    if (caption == null || caption.trim().isEmpty) {
      return;
    }

    layerContainer.addLabel(RenderInfoNode(nodeProperties, this, caption: caption.trim()));
  }

  @override
  void matchWay(LayerContainer layerContainer, WayProperties wayProperties) {
    String? caption = textKey!.getValue(wayProperties.getTags());
    if (caption == null || caption.trim().isEmpty) {
      return;
    }

    layerContainer.addLabel(RenderInfoWay(wayProperties, this, caption: caption.trim()));
  }
}
