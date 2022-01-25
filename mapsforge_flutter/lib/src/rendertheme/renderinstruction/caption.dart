import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontfamily.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontstyle.dart';
import 'package:mapsforge_flutter/src/graphics/position.dart';
import 'package:mapsforge_flutter/src/model/displaymodel.dart';
import 'package:mapsforge_flutter/src/renderer/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/renderer/textmixin.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/rendersymbol.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/textkey.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/rulebuilder.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../rendercallback.dart';
import '../rendercontext.dart';

/**
 * Represents a text label on the map.
 * <p/>
 * If a bitmap symbol is present the caption position is calculated relative to the bitmap, the
 * center of which is at the point of the POI. The bitmap itself is never rendered.
 */
class Caption extends RenderInstruction with TextMixin {
  static final _log = new Logger('Caption');
  static final double DEFAULT_GAP = 5;

  Display display = Display.IFSPACE;
  double dy = 0;
  final Map<int, double> dyScaled = {};
  double _horizontalOffset = 0;
  double _verticalOffset = 0;
  late double gap;
  final int maxTextWidth;
  Position position = Position.CENTER;
  int priority = 0;
  String? symbolId;
  final SymbolFinder symbolFinder;
  TextKey? textKey;

  Caption(GraphicFactory graphicFactory, DisplayModel displayModel,
      this.symbolFinder)
      : maxTextWidth = displayModel.getMaxTextWidth(),
        super(graphicFactory, displayModel) {
    this.gap = DEFAULT_GAP * displayModel.getFontScaleFactor();

    initTextMixin(graphicFactory);
  }

  void parse(XmlElement rootElement, List<RenderInstruction> initPendings) {
    MapFontFamily fontFamily = MapFontFamily.DEFAULT;
    MapFontStyle fontStyle = MapFontStyle.NORMAL;

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.K == name) {
        this.textKey = TextKey.getInstance(value);
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.DISPLAY == name) {
        this.display = Display.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.DY == name) {
        this.dy = double.parse(value) * displayModel.getScaleFactor();
      } else if (RenderInstruction.FILL == name) {
        this
            .fill
            .setColorFromNumber(XmlUtils.getColor(graphicFactory, value, this));
      } else if (RenderInstruction.FONT_FAMILY == name) {
        fontFamily = MapFontFamily.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.FONT_SIZE == name) {
        this.fontSize = XmlUtils.parseNonNegativeFloat(name, value) *
            displayModel.getFontScaleFactor();
      } else if (RenderInstruction.FONT_STYLE == name) {
        fontStyle = MapFontStyle.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.POSITION == name) {
        this.position = Position.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.PRIORITY == name) {
        this.priority = int.parse(value);
      } else if (RenderInstruction.STROKE == name) {
        this
            .stroke
            .setColorFromNumber(XmlUtils.getColor(graphicFactory, value, this));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        this.stroke.setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) *
            displayModel.fontScaleFactor);
      } else if (RenderInstruction.SYMBOL_ID == name) {
        this.symbolId = value;
      } else {
        throw Exception("caption unknwon attribute");
      }
    });

    XmlUtils.checkMandatoryAttribute(
        rootElement.name.toString(), RenderInstruction.K, this.textKey);

    initMixinAfterParse(fontFamily, fontStyle);

    initPendings.add(this);
  }

  @override
  void renderNode(RenderCallback renderCallback,
      final RenderContext renderContext, PointOfInterest poi) {
    if (Display.NEVER == this.display) {
      //_log.info("display is never for $textKey");
      return;
    }

    String? caption = this.textKey!.getValue(poi.tags);
    if (caption == null) {
      //_log.info("caption is null for $textKey");
      return;
    }

    renderCallback.renderPointOfInterestCaption(
        renderContext,
        this.display,
        this.priority,
        caption,
        _horizontalOffset,
        _verticalOffset + dyScaled[renderContext.job.tile.zoomLevel]!,
        getFillPaint(renderContext.job.tile.zoomLevel),
        getStrokePaint(renderContext.job.tile.zoomLevel),
        position,
        this.maxTextWidth,
        poi);
  }

  @override
  void renderWay(RenderCallback renderCallback,
      final RenderContext renderContext, PolylineContainer way) {
    if (Display.NEVER == this.display) {
      return;
    }

    String? caption = this.textKey!.getValue(way.getTags());
    if (caption == null) {
      return;
    }

    if (way.getCoordinatesAbsolute(renderContext.projection).length == 0)
      return;

    renderCallback.renderAreaCaption(
        renderContext,
        this.display,
        this.priority,
        caption,
        _horizontalOffset,
        _verticalOffset + dyScaled[renderContext.job.tile.zoomLevel]!,
        getFillPaint(renderContext.job.tile.zoomLevel),
        getStrokePaint(renderContext.job.tile.zoomLevel),
        this.position,
        this.maxTextWidth,
        way);
  }

  @override
  void scaleStrokeWidth(double scaleFactor, int zoomLevel) {
    // do nothing
  }

  @override
  void scaleTextSize(double scaleFactor, int zoomLevel) {
    scaleMixinTextSize(graphicFactory, scaleFactor, zoomLevel);

    this.dyScaled[zoomLevel] = this.dy * scaleFactor;
  }

  @override
  void dispose() {
    mixinDispose();
  }

  @override
  Future<Caption> initResources(GraphicFactory graphicFactory) async {
    _verticalOffset = 0;

    RenderSymbol? renderSymbol;
    if (this.symbolId != null) {
      renderSymbol = await symbolFinder.find(this.symbolId!);
      if (renderSymbol == null) {
        _log.warning(
            "Symbol $symbolId referenced in caption in render.xml, but not defined as symbol");
      }
    }

    if (this.position == Position.CENTER && renderSymbol?.bitmap != null) {
      // sensible defaults: below if symbolContainer is present, center if not
      this.position = Position.BELOW;
    }
    switch (this.position) {
      case Position.CENTER:
      case Position.BELOW:
        if (renderSymbol?.bitmap?.getHeight() != null)
          _verticalOffset += renderSymbol!.bitmap!.getHeight() / 2 + this.gap;
        break;
      case Position.ABOVE:
        if (renderSymbol?.bitmap?.getHeight() != null)
          _verticalOffset -= renderSymbol!.bitmap!.getHeight() / 2 + this.gap;
        break;
      case Position.BELOW_LEFT:
        if (renderSymbol?.bitmap?.getWidth() != null)
          _horizontalOffset -= renderSymbol!.bitmap!.getWidth() / 2 + this.gap;
        if (renderSymbol?.bitmap?.getHeight() != null)
          _verticalOffset += renderSymbol!.bitmap!.getHeight() / 2 + this.gap;
        break;
      case Position.ABOVE_LEFT:
        if (renderSymbol?.bitmap?.getWidth() != null)
          _horizontalOffset -= renderSymbol!.bitmap!.getWidth() / 2 + this.gap;
        if (renderSymbol?.bitmap?.getHeight() != null)
          _verticalOffset -= renderSymbol!.bitmap!.getHeight() / 2 + this.gap;
        break;
      case Position.LEFT:
        if (renderSymbol?.bitmap?.getWidth() != null)
          _horizontalOffset -= renderSymbol!.bitmap!.getWidth() / 2 + this.gap;
        break;
      case Position.BELOW_RIGHT:
        if (renderSymbol?.bitmap?.getWidth() != null)
          _horizontalOffset +=
              (renderSymbol!.bitmap!.getWidth() / 2 + this.gap);
        if (renderSymbol?.bitmap?.getHeight() != null)
          _verticalOffset += renderSymbol!.bitmap!.getHeight() / 2 + this.gap;
        break;
      case Position.ABOVE_RIGHT:
        if (renderSymbol?.bitmap?.getWidth() != null)
          _horizontalOffset +=
              (renderSymbol!.bitmap!.getWidth() / 2 + this.gap);
        if (renderSymbol?.bitmap?.getHeight() != null)
          _verticalOffset -= renderSymbol!.bitmap!.getHeight() / 2 + this.gap;
        break;
      case Position.RIGHT:
        if (renderSymbol?.bitmap?.getWidth() != null)
          _horizontalOffset +=
              (renderSymbol!.bitmap!.getWidth() / 2 + this.gap);
        break;
      default:
        throw new Exception("Position invalid");
    }

    return this;
  }
}
