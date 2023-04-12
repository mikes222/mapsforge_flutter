import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/cap.dart';
import 'package:mapsforge_flutter/src/graphics/join.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_polyline.dart';
import 'package:mapsforge_flutter/src/rendertheme/wayrenderinfo.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../../graphics/display.dart';
import '../nodeproperties.dart';
import '../rendercontext.dart';
import '../wayproperties.dart';

/// Represents an open polyline on the map.
class RenderinstructionLine extends RenderInstruction {
  //static final Pattern SPLIT_PATTERN = Pattern.compile(",");

  late final ShapePolyline base;

  RenderinstructionLine(int level, [ShapePolyline? base]) {
    this.base = base ?? ShapePolyline.base()
      ..level = level;
  }

  @override
  RenderinstructionLine? prepareScale(int zoomLevel) {
    ShapePolyline newShape = ShapePolyline.scale(base, zoomLevel);
    if (newShape.display == Display.NEVER) return null;
    return RenderinstructionLine(base.level, newShape);
  }

  void parse(DisplayModel displayModel, XmlElement rootElement) {
    // do not scale bitmap in lines they look ugly
    base.setBitmapPercent(100 * displayModel.getFontScaleFactor().round());
//    base.setBitmapMinZoomLevel(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    base.setBitmapMinZoomLevel(65535);
//    base.setStrokeMinZoomLevel(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);

    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.SRC == name) {
        base.bitmapSrc = value;
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.DY == name) {
        base.setDy(double.parse(value) * displayModel.getScaleFactor());
      } else if (RenderInstruction.SCALE == name) {
        base.scale = scaleFromValue(value);
        if (base.scale == Scale.NONE) {
          base.setBitmapMinZoomLevel(65535);
        }
      } else if (RenderInstruction.STROKE == name) {
        base.setStrokeColorFromNumber(XmlUtils.getColor(value, this));
      } else if (RenderInstruction.STROKE_DASHARRAY == name) {
        List<double> dashArray = parseFloatArray(name, value);
        if (displayModel.getScaleFactor() != 1)
          for (int f = 0; f < dashArray.length; ++f) {
            dashArray[f] = dashArray[f] * displayModel.getScaleFactor();
          }
        base.setStrokeDashArray(dashArray);
      } else if (RenderInstruction.STROKE_LINECAP == name) {
        base.setStrokeCap(Cap.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value)));
      } else if (RenderInstruction.STROKE_LINEJOIN == name) {
        base.setStrokeJoin(Join.values
            .firstWhere((e) => e.toString().toLowerCase().contains(value)));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        base.setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) *
            displayModel.getScaleFactor());
      } else if (RenderInstruction.SYMBOL_HEIGHT == name) {
        base.setBitmapHeight(XmlUtils.parseNonNegativeInteger(name, value));
      } else if (RenderInstruction.SYMBOL_PERCENT == name) {
        base.setBitmapPercent(XmlUtils.parseNonNegativeInteger(name, value) *
            displayModel.getFontScaleFactor().round());
      } else if (RenderInstruction.SYMBOL_SCALING == name) {
// no-op
      } else if (RenderInstruction.SYMBOL_WIDTH == name) {
        base.setBitmapWidth(XmlUtils.parseNonNegativeInteger(name, value));
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
  void renderNode(
      final RenderContext renderContext, NodeProperties nodeProperties) {
    // do nothing
    return;
  }

  @override
  void renderWay(
      final RenderContext renderContext, WayProperties wayProperties) {
    if (wayProperties.getCoordinatesAbsolute(renderContext.projection).length ==
        0) return;

    renderContext.addToCurrentDrawingLayer(
        base.level, WayRenderInfo<ShapePolyline>(wayProperties, base));
  }
}
