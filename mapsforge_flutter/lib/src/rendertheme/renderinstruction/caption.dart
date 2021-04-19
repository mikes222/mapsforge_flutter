import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/graphics/color.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontfamily.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontstyle.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/position.dart';
import 'package:mapsforge_flutter/src/graphics/style.dart';
import 'package:mapsforge_flutter/src/model/displaymodel.dart';
import 'package:mapsforge_flutter/src/renderer/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/rendersymbol.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/textkey.dart';
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
class Caption extends RenderInstruction {
  static final _log = new Logger('Caption');
  static final double DEFAULT_GAP = 5;

  Display display;
  double dy = 0;
  final Map<int, double> dyScaled;
  MapPaint fill;
  final Map<int, MapPaint> fills;
  double fontSize = 10;
  double gap;
  final int maxTextWidth;
  Position position;
  int priority = 0;
  MapPaint stroke;
  final Map<int, MapPaint> strokes;
  String symbolId;
  final Map<String, RenderSymbol> symbols;
  TextKey textKey;
  RenderSymbol renderSymbol;

  Caption(GraphicFactory graphicFactory, DisplayModel displayModel, this.symbols)
      : fills = new Map(),
        strokes = new Map(),
        dyScaled = new Map(),
        maxTextWidth = displayModel.getMaxTextWidth(),
        super(graphicFactory, displayModel) {
    this.fill = graphicFactory.createPaint();
    this.fill.setColor(Color.BLACK);
    this.fill.setStyle(Style.FILL);

    this.stroke = graphicFactory.createPaint();
    this.stroke.setColor(Color.BLACK);
    this.stroke.setStyle(Style.STROKE);

    this.display = Display.IFSPACE;

    this.gap = DEFAULT_GAP * displayModel.getScaleFactor();
  }

  double computeHorizontalOffset() {
    // compute only the offset required by the bitmap, not the text size,
    // because at this point we do not know the text boxing
    if (Position.RIGHT == this.position ||
        Position.LEFT == this.position ||
        Position.BELOW_RIGHT == this.position ||
        Position.BELOW_LEFT == this.position ||
        Position.ABOVE_RIGHT == this.position ||
        Position.ABOVE_LEFT == this.position) {
      double horizontalOffset = this.renderSymbol.bitmap.getWidth() / 2 + this.gap;
      if (Position.LEFT == this.position || Position.BELOW_LEFT == this.position || Position.ABOVE_LEFT == this.position) {
        horizontalOffset *= -1;
      }
      return horizontalOffset;
    }
    return 0;
  }

  double computeVerticalOffset(int zoomLevel) {
    double verticalOffset = this.dyScaled[zoomLevel];
    if (verticalOffset == null) {
      verticalOffset = this.dy;
    }

    if (Position.ABOVE == this.position || Position.ABOVE_LEFT == this.position || Position.ABOVE_RIGHT == this.position) {
      verticalOffset -= this.renderSymbol.bitmap.getHeight() / 2 + this.gap;
    } else if (Position.BELOW == this.position || Position.BELOW_LEFT == this.position || Position.BELOW_RIGHT == this.position) {
      verticalOffset += this.renderSymbol.bitmap.getHeight() / 2 + this.gap;
    }
    return verticalOffset;
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
        this.display = Display.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.DY == name) {
        this.dy = double.parse(value) * displayModel.getScaleFactor();
      } else if (RenderInstruction.FILL == name) {
        this.fill.setColorFromNumber(XmlUtils.getColor(graphicFactory, value, this));
      } else if (RenderInstruction.FONT_FAMILY == name) {
        fontFamily = MapFontFamily.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.FONT_SIZE == name) {
        this.fontSize = XmlUtils.parseNonNegativeFloat(name, value) * displayModel.getScaleFactor();
      } else if (RenderInstruction.FONT_STYLE == name) {
        fontStyle = MapFontStyle.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.POSITION == name) {
        this.position = Position.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.PRIORITY == name) {
        this.priority = int.parse(value);
      } else if (RenderInstruction.STROKE == name) {
        this.stroke.setColorFromNumber(XmlUtils.getColor(graphicFactory, value, this));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        this.stroke.setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) * displayModel.getScaleFactor());
      } else if (RenderInstruction.SYMBOL_ID == name) {
        this.symbolId = value;
      } else {
        throw Exception("caption unknwon attribute");
      }
    });

    this.fill.setTypeface(fontFamily, fontStyle);
    this.stroke.setTypeface(fontFamily, fontStyle);

    XmlUtils.checkMandatoryAttribute(rootElement.name.toString(), RenderInstruction.K, this.textKey);

    if (this.symbolId != null) {
      renderSymbol = symbols[this.symbolId];
      if (renderSymbol == null) {
        _log.warning("Symbol $symbolId referenced in caption in render.xml, but not defined as symbol before");
      }
    }

    if (this.position == null) {
      // sensible defaults: below if symbolContainer is present, center if not
      if (this.renderSymbol == null) {
        this.position = Position.CENTER;
      } else {
        this.position = Position.BELOW;
      }
    }
    switch (this.position) {
      case Position.CENTER:
      case Position.BELOW:
      case Position.ABOVE:
        //this.stroke.setTextAlign(Align.CENTER);
        //this.fill.setTextAlign(Align.CENTER);
        break;
      case Position.BELOW_LEFT:
      case Position.ABOVE_LEFT:
      case Position.LEFT:
        //this.stroke.setTextAlign(Align.RIGHT);
        //this.fill.setTextAlign(Align.RIGHT);
        break;
      case Position.BELOW_RIGHT:
      case Position.ABOVE_RIGHT:
      case Position.RIGHT:
        //this.stroke.setTextAlign(Align.LEFT);
        //this.fill.setTextAlign(Align.LEFT);
        break;
      default:
        throw new Exception("Position invalid");
    }
  }

  MapPaint getFillPaint(int zoomLevel) {
    MapPaint paint = fills[zoomLevel];
    if (paint == null) {
      paint = this.fill;
    }
    return paint;
  }

  MapPaint getStrokePaint(int zoomLevel) {
    MapPaint paint = strokes[zoomLevel];
    if (paint == null) {
      paint = this.stroke;
    }
    return paint;
  }

  @override
  void renderNode(RenderCallback renderCallback, final RenderContext renderContext, PointOfInterest poi) {
    if (Display.NEVER == this.display) {
      //_log.info("display is never for $textKey");
      return;
    }

    String caption = this.textKey.getValue(poi.tags);
    if (caption == null) {
      //_log.info("caption is null for $textKey");
      return;
    }

    double horizontalOffset = 0;

    double verticalOffset = this.dyScaled[renderContext.job.tile.zoomLevel];
    if (verticalOffset == null) {
      verticalOffset = this.dy;
    }

    if (renderSymbol != null && renderSymbol.bitmap != null) {
      horizontalOffset = computeHorizontalOffset();
      verticalOffset = computeVerticalOffset(renderContext.job.tile.zoomLevel);
    }

    renderCallback.renderPointOfInterestCaption(
        renderContext,
        this.display,
        this.priority,
        caption,
        horizontalOffset,
        verticalOffset,
        getFillPaint(renderContext.job.tile.zoomLevel),
        getStrokePaint(renderContext.job.tile.zoomLevel),
        this.position,
        this.maxTextWidth,
        poi);
  }

  @override
  void renderWay(RenderCallback renderCallback, final RenderContext renderContext, PolylineContainer way) {
    if (Display.NEVER == this.display) {
      return;
    }

    String caption = this.textKey.getValue(way.getTags());
    if (caption == null) {
      return;
    }

    double horizontalOffset = 0;
    double verticalOffset = this.dyScaled[renderContext.job.tile.zoomLevel];
    if (verticalOffset == null) {
      verticalOffset = this.dy;
    }

    if (renderSymbol != null && renderSymbol.bitmap != null) {
      horizontalOffset = computeHorizontalOffset();
      verticalOffset = computeVerticalOffset(renderContext.job.tile.zoomLevel);
    }

    renderCallback.renderAreaCaption(
        renderContext,
        this.display,
        this.priority,
        caption,
        horizontalOffset,
        verticalOffset,
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
    MapPaint f = graphicFactory.createPaintFrom(this.fill);
    f.setTextSize(this.fontSize * scaleFactor);
    this.fills[zoomLevel] = f;

    MapPaint s = graphicFactory.createPaintFrom(this.stroke);
    s.setTextSize(this.fontSize * scaleFactor);
    this.strokes[zoomLevel] = s;

    this.dyScaled[zoomLevel] = this.dy * scaleFactor;
  }

  @override
  void dispose() {}

  @override
  Future<void> initResources(GraphicFactory graphicFactory) {
    return null;
  }
}
