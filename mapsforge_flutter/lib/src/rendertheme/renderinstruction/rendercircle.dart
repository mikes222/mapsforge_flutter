import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/paintelements/shape/circlecontainer.dart';
import 'package:mapsforge_flutter/src/paintelements/shape_paint_circle_container.dart';
import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';
import 'package:mapsforge_flutter/src/paintelements/shape/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../rendercontext.dart';
import 'renderinstruction.dart';

/**
 * Represents a round area on the map.
 */
class RenderCircle extends RenderInstruction with PaintMixin {
  final int level;
  double? radius;
  final Map<int, double> renderRadiusScaled;
  bool scaleRadius = false;

  RenderCircle(this.level)
      : renderRadiusScaled = new Map(),
        super() {
    initPaintMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL);
    this.setFillColor(Colors.transparent);
    this.setStrokeColor(Colors.transparent);
  }

  @override
  void dispose() {
    disposePaintMixin();
  }

  void parse(DisplayModel displayModel, XmlElement rootElement) {
    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.RADIUS == name || RenderInstruction.R == name) {
        this.radius = XmlUtils.parseNonNegativeFloat(name, value) *
            displayModel.getScaleFactor();
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.FILL == name) {
        this.setFillColorFromNumber(XmlUtils.getColor(value, this));
      } else if (RenderInstruction.SCALE_RADIUS == name) {
        this.scaleRadius = value == "true";
      } else if (RenderInstruction.STROKE == name) {
        this.setStrokeColorFromNumber(XmlUtils.getColor(value, this));
      } else if (RenderInstruction.STROKE_WIDTH == name) {
        this.setStrokeWidth(XmlUtils.parseNonNegativeFloat(name, value) *
            displayModel.getScaleFactor());
      } else {
        throw Exception("circle probs");
      }
    });

    XmlUtils.checkMandatoryAttribute(
        rootElement.name.toString(), RenderInstruction.RADIUS, this.radius);
  }

  double getRenderRadius(int zoomLevel) {
    double? radius = renderRadiusScaled[zoomLevel];
    radius ??= this.radius;
    return radius!;
  }

  @override
  void renderNode(final RenderContext renderContext, PointOfInterest poi) {
    // if ((fill == null || fill.isTransparent()) &&
    //     (stroke == null || stroke.isTransparent())) return;
    Mappoint poiPosition = renderContext.projection
        .pixelRelativeToTile(poi.position, renderContext.job.tile);
    //_log.info("Adding circle $poiPosition with $radius");
    renderContext.addToCurrentDrawingLayer(
        level,
        ShapePaintCircleContainer(
            new CircleContainer(
                poiPosition, getRenderRadius(renderContext.job.tile.zoomLevel)),
            getFillPaint(renderContext.job.tile.zoomLevel),
            getStrokePaint(renderContext.job.tile.zoomLevel),
            getDy(renderContext.job.tile.zoomLevel)));
  }

  @override
  void renderWay(final RenderContext renderContext, PolylineContainer way) {
    // do nothing
  }

  @override
  void prepareScale(int zoomLevel) {
    if (this.scaleRadius) {
      double scaleFactor = 1;
      this.renderRadiusScaled[zoomLevel] = this.radius! * scaleFactor;
      prepareScalePaintMixin(zoomLevel);
    }
  }
}
