import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/graphics/cap.dart';
import 'package:mapsforge_flutter/src/graphics/join.dart';
import 'package:mapsforge_flutter/src/paintelements/shape/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/paintelements/shape_paint_polyline_container.dart';
import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/bitmapsrcmixin.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../rendercontext.dart';

/// Represents a polyline on the map.
class Line extends RenderInstruction with BitmapSrcMixin, PaintMixin {
  //static final Pattern SPLIT_PATTERN = Pattern.compile(",");

  final int level;
  final String? relativePathPrefix;
  Scale scale = Scale.STROKE;

  Line(String elementName, this.level, this.relativePathPrefix);

  void parse(DisplayModel displayModel, XmlElement rootElement) {
    initPaintMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL);
    // do not scale bitmap in lines they look ugly
    initBitmapSrcMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    this.setBitmapPercent(100 * displayModel.getFontScaleFactor().round());

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.SRC == name) {
        this.bitmapSrc = value;
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.DY == name) {
        this.setDy(double.parse(value) * displayModel.getScaleFactor());
      } else if (RenderInstruction.SCALE == name) {
        this.scale = scaleFromValue(value);
      } else if (RenderInstruction.STROKE == name) {
        this.setStrokeColorFromNumber(XmlUtils.getColor(value, this));
      } else if (RenderInstruction.STROKE_DASHARRAY == name) {
        List<double> dashArray = parseFloatArray(name, value);
        if (displayModel.getScaleFactor() != 1)
          for (int f = 0; f < dashArray.length; ++f) {
            dashArray[f] = dashArray[f] * displayModel.getScaleFactor();
          }
        this.setStrokeDashArray(dashArray);
      } else if (RenderInstruction.STROKE_LINECAP == name) {
        this.setStrokeCap(Cap.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value)));
      } else if (RenderInstruction.STROKE_LINEJOIN == name) {
        this.setStrokeJoin(Join.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value)));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        this.setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) *
            displayModel.getScaleFactor());
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
        throw new Exception("element hinich");
      }
    });
  }

  static List<double> parseFloatArray(String name, String dashString) {
    List<String> dashEntries = dashString.split(",");
    List<double> dashIntervals = dashEntries
        .map((e) => XmlUtils.parseNonNegativeFloat(name, e))
        .toList();
    // List<double>(dashEntries.length);
    // for (int i = 0; i < dashEntries.length; ++i) {
    //   dashIntervals[i] = XmlUtils.parseNonNegativeFloat(name, dashEntries[i]);
    // }
    return dashIntervals;
  }

  @override
  void renderNode(final RenderContext renderContext, PointOfInterest poi) {
    // do nothing
  }

  @override
  void renderWay(final RenderContext renderContext, PolylineContainer way) {
    if (way.getCoordinatesAbsolute(renderContext.projection).length == 0)
      return;

    renderContext.addToCurrentDrawingLayer(
        level,
        ShapePaintPolylineContainer(
            way,
            getStrokePaint(renderContext.job.tile.zoomLevel),
            bitmapSrc,
            getBitmapWidth(renderContext.job.tile.zoomLevel),
            getBitmapHeight(renderContext.job.tile.zoomLevel),
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
