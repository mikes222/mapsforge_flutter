import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/graphics/cap.dart';
import 'package:mapsforge_flutter/src/graphics/color.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/style.dart';
import 'package:mapsforge_flutter/src/renderer/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/bitmapmixin.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../rendercallback.dart';
import '../rendercontext.dart';
import 'renderinstruction.dart';

/**
 * Represents a closed polygon on the map.
 */
class Area extends RenderInstruction with BitmapMixin {
  late MapPaint fill;
  final int level;
  Scale scale = Scale.STROKE;
  late MapPaint stroke;
  late Map<int, MapPaint> strokes;
  late double strokeWidth;

  Area(GraphicFactory graphicFactory, SymbolCache symbolCache, displayModel, String elementName, this.level)
      : super(graphicFactory, displayModel) {
    this.symbolCache = symbolCache;
    this.fill = graphicFactory.createPaint();
    this.fill.setColor(Color.TRANSPARENT);
    this.fill.setStyle(Style.FILL);
    this.fill.setStrokeCap(Cap.ROUND);

    this.stroke = graphicFactory.createPaint();
    this.stroke.setColor(Color.TRANSPARENT);
    this.stroke.setStyle(Style.STROKE);
    this.stroke.setStrokeCap(Cap.ROUND);

    this.strokes = new Map();
    strokeWidth = 1;
  }

  void parse(XmlElement rootElement, List<RenderInstruction> initPendings) {
    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;
      //_log.info("checking $name=$value");
      if (RenderInstruction.SRC == name) {
        this.src = value;
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.FILL == name) {
        this.fill.setColorFromNumber(XmlUtils.getColor(graphicFactory, value, this));
      } else if (RenderInstruction.SCALE == name) {
        this.scale = scaleFromValue(value);
      } else if (RenderInstruction.STROKE == name) {
        this.stroke.setColorFromNumber(XmlUtils.getColor(graphicFactory, value, this));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        this.strokeWidth = XmlUtils.parseNonNegativeFloat(name, value) * displayModel.getScaleFactor();
      } else if (RenderInstruction.SYMBOL_HEIGHT == name) {
        this.height = XmlUtils.parseNonNegativeInteger(name, value) * displayModel.getScaleFactor();
      } else if (RenderInstruction.SYMBOL_PERCENT == name) {
        this.percent = XmlUtils.parseNonNegativeInteger(name, value);
      } else if (RenderInstruction.SYMBOL_SCALING == name) {
// no-op
      } else if (RenderInstruction.SYMBOL_WIDTH == name) {
        this.width = XmlUtils.parseNonNegativeInteger(name, value) * displayModel.getScaleFactor();
      } else {
        throw Exception(name + "=" + value);
      }
    });
    if (src != null) initPendings.add(this);
  }

  MapPaint getFillPaint() {
    return this.fill;
  }

  MapPaint getStrokePaint(int zoomLevel) {
    MapPaint? paint = strokes[zoomLevel];
    if (paint == null) {
      paint = this.stroke;
    }
    return paint;
  }

  @override
  void renderNode(RenderCallback renderCallback, final RenderContext renderContext, PointOfInterest poi) {
    // do nothing
  }

  @override
  void renderWay(RenderCallback renderCallback, final RenderContext renderContext, PolylineContainer way) {
//    synchronized(this) {
    // this needs to be synchronized as we potentially set a shift in the shader and
    // the shift is particular to the tile when rendered in multi-thread mode
    MapPaint fillPaint = getFillPaint();

    renderCallback.renderArea(renderContext, fillPaint, getStrokePaint(renderContext.job.tile.zoomLevel), this.level, way);
//}
  }

  @override
  void scaleStrokeWidth(double scaleFactor, int zoomLevel) {
    if (this.scale == Scale.NONE) {
      return;
    }
    if (this.strokes[zoomLevel] != null) return;
    MapPaint paint = graphicFactory.createPaintFrom(this.stroke);
    paint.setStrokeWidth(this.strokeWidth * scaleFactor);
    this.strokes[zoomLevel] = paint;
  }

  @override
  void scaleTextSize(double scaleFactor, int zoomLevel) {
    // do nothing
  }

  @override
  Future<Area> initResources(GraphicFactory graphicFactory) async {
    await initBitmap(graphicFactory);

    if (bitmap != null) {
      // make sure the color is not transparent
      if (fill.isTransparent()) fill.setColorFromNumber(0xff000000);
      fill.setBitmapShader(bitmap!);
      //bitmap.incrementRefCount();
    }

    //fillPaint.setBitmapShaderShift(way.getUpperLeft().getOrigin());
    return this;
  }

  @override
  void dispose() {
    fill.dispose();
    strokes.values.forEach((element) {
      element.dispose();
    });
    super.dispose();
  }
}
