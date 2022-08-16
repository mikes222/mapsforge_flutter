import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';
import 'package:mapsforge_flutter/src/paintelements/shape_paint_area_container.dart';
import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';
import 'package:mapsforge_flutter/src/paintelements/shape/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/bitmapsrcmixin.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../rendercontext.dart';
import 'renderinstruction.dart';

/**
 * Represents a closed polygon on the map.
 */
class Area extends RenderInstruction with BitmapSrcMixin, PaintMixin {
  final int level;
  Scale scale = Scale.STROKE;

  Area(String elementName, this.level) : super() {
    initPaintMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL);
    // do not scale bitmaps in areas. They look ugly
    initBitmapSrcMixin(65535);
    setFillColor(Colors.transparent);
    setStrokeColor(Colors.transparent);
  }

  void parse(DisplayModel displayModel, XmlElement rootElement) {
    this.setBitmapPercent(100 * displayModel.getFontScaleFactor().round());

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;
      if (RenderInstruction.SRC == name) {
        this.bitmapSrc = value;
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.FILL == name) {
        this.setFillColorFromNumber(XmlUtils.getColor(value, this));
      } else if (RenderInstruction.SCALE == name) {
        this.scale = scaleFromValue(value);
      } else if (RenderInstruction.STROKE == name) {
        this.setStrokeColorFromNumber(XmlUtils.getColor(value, this));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        this.setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) *
            displayModel.getScaleFactor());
      } else if (RenderInstruction.SYMBOL_WIDTH == name) {
        this.setBitmapWidth(XmlUtils.parseNonNegativeInteger(name, value));
      } else if (RenderInstruction.SYMBOL_HEIGHT == name) {
        this.setBitmapHeight(XmlUtils.parseNonNegativeInteger(name, value));
      } else if (RenderInstruction.SYMBOL_PERCENT == name) {
        this.setBitmapPercent(XmlUtils.parseNonNegativeInteger(name, value) *
            displayModel.getFontScaleFactor().round());
      } else if (RenderInstruction.SYMBOL_SCALING == name) {
// no-op
      } else if (RenderInstruction.SYMBOL_WIDTH == name) {
        this.setBitmapWidth(XmlUtils.parseNonNegativeInteger(name, value));
      } else {
        throw Exception(name + "=" + value);
      }
    });
  }

  @override
  Future<void> renderNode(final RenderContext renderContext,
      PointOfInterest poi, SymbolCache symbolCache) async {
    // do nothing
  }

  @override
  Future<void> renderWay(final RenderContext renderContext,
      PolylineContainer way, SymbolCache symbolCache) async {
//    synchronized(this) {
    // this needs to be synchronized as we potentially set a shift in the shader and
    // the shift is particular to the tile when rendered in multi-thread mode

    if (way.getCoordinatesAbsolute(renderContext.projection).length == 0)
      return;

    ResourceBitmap? bitmap =
        await loadBitmap(renderContext.job.tile.zoomLevel, symbolCache);
    if (bitmap != null &&
        getFillPaint(renderContext.job.tile.zoomLevel).getBitmapShader() ==
            null) {
      if (getFillPaint(renderContext.job.tile.zoomLevel).isTransparent())
        getFillPaint(renderContext.job.tile.zoomLevel).setColor(Colors.black);
      getFillPaint(renderContext.job.tile.zoomLevel).setBitmapShader(bitmap);
    }

    renderContext.addToCurrentDrawingLayer(
        level,
        ShapePaintAreaContainer(
            way,
            getFillPaint(renderContext.job.tile.zoomLevel),
            getStrokePaint(renderContext.job.tile.zoomLevel),
            getDy(renderContext.job.tile.zoomLevel),
            renderContext.projection));
  }

  @override
  void prepareScale(int zoomLevel) {
    if (this.scale == Scale.NONE) {
      return;
    }
    prepareScalePaintMixin(zoomLevel);
    prepareScaleBitmapSrcMixin(zoomLevel);
  }
}
