import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontfamily.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontstyle.dart';
import 'package:mapsforge_flutter/src/graphics/position.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/textkey.dart';
import 'package:mapsforge_flutter/src/rendertheme/wayrenderinfo.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/rulebuilder.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../nodeproperties.dart';
import '../noderenderinfo.dart';
import '../rendercontext.dart';
import '../shape/shape_caption.dart';
import '../wayproperties.dart';

/**
 * Represents a text label on the map.
 * <p/>
 * If a bitmap symbol is present the caption position is calculated relative to the bitmap, the
 * center of which is at the point of the POI. The bitmap itself is never rendered.
 */
class RenderinstructionCaption extends RenderInstruction {
  static final double DEFAULT_GAP = 2;

  final SymbolFinder symbolFinder;

  late final ShapeCaption base;

  RenderinstructionCaption(this.symbolFinder, int level, [ShapeCaption? base]) {
    this.base = base ?? ShapeCaption.base()
      ..level = level;
  }

  @override
  RenderinstructionCaption? prepareScale(int zoomLevel) {
    ShapeCaption newShape = ShapeCaption.scale(base, zoomLevel);
    if (newShape.display == Display.NEVER) return null;
    return RenderinstructionCaption(symbolFinder, base.level, newShape);
  }

  void parse(DisplayModel displayModel, XmlElement rootElement) {
    base.maxTextWidth = displayModel.getMaxTextWidth();
    base.gap = DEFAULT_GAP * displayModel.getFontScaleFactor();
    base.setStrokeMinZoomLevel(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.K == name) {
        base.textKey = TextKey(value);
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.DISPLAY == name) {
        base.display = Display.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.DY == name) {
        base.setDy(double.parse(value) * displayModel.getScaleFactor());
      } else if (RenderInstruction.FILL == name) {
        base.setFillColorFromNumber(XmlUtils.getColor(value, this));
      } else if (RenderInstruction.FONT_FAMILY == name) {
        base.setFontFamily(MapFontFamily.values
            .firstWhere((v) => v.toString().toLowerCase().contains(value)));
      } else if (RenderInstruction.FONT_SIZE == name) {
        base.setFontSize(XmlUtils.parseNonNegativeFloat(name, value) *
            displayModel.getFontScaleFactor());
      } else if (RenderInstruction.FONT_STYLE == name) {
        base.setFontStyle(MapFontStyle.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value)));
      } else if (RenderInstruction.POSITION == name) {
        base.position = Position.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.PRIORITY == name) {
        base.priority = int.parse(value);
      } else if (RenderInstruction.STROKE == name) {
        base.setStrokeColorFromNumber(XmlUtils.getColor(value, this));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        base.setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) *
            displayModel.getFontScaleFactor());
      } else if (RenderInstruction.SYMBOL_ID == name) {
        base.symbolId = value;
      } else {
        throw Exception("caption unknwon attribute");
      }
    });

    XmlUtils.checkMandatoryAttribute(
        rootElement.name.toString(), RenderInstruction.K, base.textKey);
  }

  @override
  void renderNode(final RenderContext renderContext, NodeProperties container) {
    String? caption = base.textKey!.getValue(container.tags);
    if (caption == null) {
      //_log.info("caption is null for $textKey");
      return;
    }

    if (base.symbolId != null) {
      // This caption belongs to a symbol. Try to find it and connect both
      SymbolHolder symbolHolder = symbolFinder.findSymbolHolder(
          base.symbolId!, renderContext.job.tile.zoomLevel);
      base.symbolHolder = symbolHolder;
    }

    renderContext.labels
        .add(NodeRenderInfo(container, base)..caption = caption);
    return;
  }

  @override
  void renderWay(final RenderContext renderContext, WayProperties container) {
    String? caption = base.textKey!.getValue(container.getTags());
    if (caption == null) {
      return;
    }

    if (container.getCoordinatesAbsolute(renderContext.projection).length == 0)
      return;

    if (base.symbolId != null) {
      // This caption belongs to a symbol. Try to find it and connect both
      SymbolHolder symbolHolder = symbolFinder.findSymbolHolder(
          base.symbolId!, renderContext.job.tile.zoomLevel);
      base.symbolHolder = symbolHolder;
    }

    renderContext.labels.add(WayRenderInfo(container, base)..caption = caption);
    return;
  }
}
