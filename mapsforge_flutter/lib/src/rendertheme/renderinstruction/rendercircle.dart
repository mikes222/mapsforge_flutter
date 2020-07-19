import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/graphics/color.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/style.dart';
import 'package:mapsforge_flutter/src/model/displaymodel.dart';
import 'package:mapsforge_flutter/src/renderer/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../rendercallback.dart';
import '../rendercontext.dart';
import 'renderinstruction.dart';

/**
 * Represents a round area on the map.
 */
class RenderCircle extends RenderInstruction {
  MapPaint fill;
  final Map<int, MapPaint> fills;
  final int level;
  double radius;
  double renderRadius;
  final Map<int, double> renderRadiusScaled;
  bool scaleRadius = false;
  MapPaint stroke;
  final Map<int, MapPaint> strokes;
  double strokeWidth = 1;

  RenderCircle(GraphicFactory graphicFactory, DisplayModel displayModel, symbolCache, this.level)
      : fills = new Map(),
        strokes = new Map(),
        renderRadiusScaled = new Map(),
        super(graphicFactory, displayModel) {
    this.fill = graphicFactory.createPaint();
    this.fill.setColor(Color.TRANSPARENT);
    this.fill.setStyle(Style.FILL);

    this.stroke = graphicFactory.createPaint();
    this.stroke.setColor(Color.TRANSPARENT);
    this.stroke.setStyle(Style.STROKE);
  }

  @override
  void destroy() {
    // no-op
  }

  void parse(XmlElement rootElement, List<RenderInstruction> initPendings) {
    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.RADIUS == name || RenderInstruction.R == name) {
        this.radius = XmlUtils.parseNonNegativeFloat(name, value) * displayModel.getScaleFactor();
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.FILL == name) {
        this.fill.setColorFromNumber(XmlUtils.getColor(graphicFactory, value, null, this));
      } else if (RenderInstruction.SCALE_RADIUS == name) {
        this.scaleRadius = value == "true";
      } else if (RenderInstruction.STROKE == name) {
        this.stroke.setColorFromNumber(XmlUtils.getColor(graphicFactory, value, null, this));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        this.strokeWidth = XmlUtils.parseNonNegativeFloat(name, value) * displayModel.getScaleFactor();
      } else {
        throw Exception("circle probs");
      }
    });

    XmlUtils.checkMandatoryAttribute(rootElement.name.toString(), RenderInstruction.RADIUS, this.radius);

    if (!this.scaleRadius) {
      this.renderRadius = this.radius;
      this.stroke.setStrokeWidth(this.strokeWidth);
    } else {
      this.renderRadius = this.radius;
    }
    initPendings.add(this);
  }

  MapPaint getFillPaint(int zoomLevel) {
    MapPaint paint = fills[zoomLevel];
    if (paint == null) {
      paint = this.fill;
    }
    return paint;
  }

  double getRenderRadius(int zoomLevel) {
    double radius = renderRadiusScaled[zoomLevel];
    if (radius == null) {
      radius = this.renderRadius;
    }
    return radius;
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
    renderCallback.renderPointOfInterestCircle(renderContext, getRenderRadius(renderContext.job.tile.zoomLevel),
        getFillPaint(renderContext.job.tile.zoomLevel), getStrokePaint(renderContext.job.tile.zoomLevel), this.level, poi);
  }

  @override
  void renderWay(RenderCallback renderCallback, final RenderContext renderContext, PolylineContainer way) {
    // do nothing
  }

  @override
  void scaleStrokeWidth(double scaleFactor, int zoomLevel) {
    if (this.scaleRadius) {
      this.renderRadiusScaled[zoomLevel] = this.radius * scaleFactor;
      if (this.stroke != null) {
        MapPaint paint = graphicFactory.createPaintFrom(stroke);
        paint.setStrokeWidth(this.strokeWidth * scaleFactor);
        strokes[zoomLevel] = paint;
      }
    }
  }

  @override
  void scaleTextSize(double scaleFactor, int zoomLevel) {
    // do nothing
  }

  @override
  Future<void> initResources(GraphicFactory graphicFactory) {
    return null;
  }
}
