import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/graphics/color.dart';
import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';
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
class Area extends RenderInstruction with BitmapMixin, PaintMixin {
  final int level;
  Scale scale = Scale.STROKE;

  Area(
      String elementName, this.level)
      : super() {

    initPaintMixin();
    this.fill.setColor(Color.TRANSPARENT);
    this.stroke.setColor(Color.TRANSPARENT);
  }

  void parse(DisplayModel displayModel, XmlElement rootElement, List<RenderInstruction> initPendings) {
    this.bitmapPercent = (100 * displayModel.getFontScaleFactor()).round();

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;
      if (RenderInstruction.SRC == name) {
        this.bitmapSrc = value;
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.FILL == name) {
        this
            .fill
            .setColorFromNumber(XmlUtils.getColor( value, this));
      } else if (RenderInstruction.SCALE == name) {
        this.scale = scaleFromValue(value);
      } else if (RenderInstruction.STROKE == name) {
        this
            .stroke
            .setColorFromNumber(XmlUtils.getColor( value, this));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        this.stroke.setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) *
            displayModel.getScaleFactor());
      } else if (RenderInstruction.SYMBOL_HEIGHT == name) {
        this.bitmapHeight =
            XmlUtils.parseNonNegativeInteger(name, value).toDouble();
      } else if (RenderInstruction.SYMBOL_PERCENT == name) {
        this.bitmapPercent = (XmlUtils.parseNonNegativeInteger(name, value) *
                displayModel.getFontScaleFactor())
            .round();
      } else if (RenderInstruction.SYMBOL_SCALING == name) {
// no-op
      } else if (RenderInstruction.SYMBOL_WIDTH == name) {
        this.bitmapWidth =
            XmlUtils.parseNonNegativeInteger(name, value).toDouble();
      } else {
        throw Exception(name + "=" + value);
      }
    });
    if (bitmapSrc != null) initPendings.add(this);
  }

  @override
  void renderNode(RenderCallback renderCallback,
      final RenderContext renderContext, PointOfInterest poi) {
    // do nothing
  }

  @override
  void renderWay(RenderCallback renderCallback,
      final RenderContext renderContext, PolylineContainer way) {
//    synchronized(this) {
    // this needs to be synchronized as we potentially set a shift in the shader and
    // the shift is particular to the tile when rendered in multi-thread mode

    if (way.getCoordinatesAbsolute(renderContext.projection).length == 0)
      return;

    renderCallback.renderArea(renderContext, fill,
        getStrokePaint(renderContext.job.tile.zoomLevel), this.level, way);
//}
  }

  @override
  void scaleStrokeWidth(double scaleFactor, int zoomLevel) {
    if (this.scale == Scale.NONE) {
      return;
    }
    scaleMixinStrokeWidth( scaleFactor, zoomLevel);
  }

  @override
  void scaleTextSize(double scaleFactor, int zoomLevel) {
    // do nothing
  }

  @override
  Future<Area> initResources(SymbolCache? symbolCache) async {
    await initBitmap( symbolCache);

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
    mixinDispose();
    super.dispose();
  }

  @override
  String toString() {
    return 'Area{fill: $fill, level: $level, scale: $scale, stroke: $stroke, strokes: $strokes}';
  }
}
