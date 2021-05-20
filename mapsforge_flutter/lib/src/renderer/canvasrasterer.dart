import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/projection/pixelprojection.dart';

import '../graphics/bitmap.dart';
import '../graphics/filter.dart';
import '../graphics/graphicfactory.dart';
import '../graphics/graphicutils.dart';
import '../graphics/mapcanvas.dart';
import '../graphics/mappath.dart';
import '../graphics/matrix.dart';
import '../mapelements/mapelementcontainer.dart';
import '../model/mappoint.dart';
import '../model/tile.dart';
import '../renderer/polylinecontainer.dart';
import '../renderer/rendererutils.dart';
import '../renderer/shapecontainer.dart';
import '../renderer/shapepaintcontainer.dart';
import '../renderer/shapetype.dart';
import '../rendertheme/rendercontext.dart';
import 'circlecontainer.dart';
import 'hillshadingcontainer.dart';

class CanvasRasterer {
  static final _log = new Logger('CanvasRasterer');
  final MapCanvas canvas;
  final MapPath path;
  final Matrix symbolMatrix;

  CanvasRasterer(GraphicFactory graphicFactory, double width, double height, [String? src])
      : canvas = graphicFactory.createCanvas(width, height, src),
        path = graphicFactory.createPath(),
        symbolMatrix = graphicFactory.createMatrix();

  void destroy() {
    this.canvas.destroy();
  }

  void drawWays(RenderContext renderContext) {
    for (List<List<ShapePaintContainer>> shapePaintContainers in renderContext.ways) {
      for (List<ShapePaintContainer> wayList in shapePaintContainers) {
        wayList.reversed.forEach((element) {
          _drawShapePaintContainer(element, renderContext.projection);
        });
        // for (int index = wayList.length - 1; index >= 0; --index) {
        //   _drawShapePaintContainer(wayList.elementAt(index), renderContext.projection);
        // }
      }
    }
  }

  void drawMapElements(Set<MapElementContainer> elements, PixelProjection projection, Tile tile) {
    // we have a set of all map elements (needed so we do not draw elements twice),
    // but we need to draw in priority order as we now allow overlaps. So we
    // convert into list, then sort, then draw.
    // draw elements in order of priority: lower priority first, so more important
    // elements will be drawn on top (in case of display=true) items.
    List<MapElementContainer> elementsAsList = elements.toList()..sort();

    for (MapElementContainer element in elementsAsList) {
      // The color filtering takes place in TileLayer
      //print("label to draw now: $element");
      element.draw(canvas, projection.getLeftUpper(tile), this.symbolMatrix, Filter.NONE);
    }
  }

  void fill(int color) {
    if (GraphicUtils.getAlpha(color) > 0) {
      this.canvas.fillColorFromNumber(color);
    }
  }

  /**
   * Fills the area outside the specificed rectangle with color. Use this method when
   * overpainting with a transparent color as it sets the PorterDuff mode.
   * This method is used to blank out areas that fall outside the map area.
   *
   * @param color      the fill color for the outside area
   * @param insideArea the inside area on which not to draw
   */
  // void fillOutsideAreas(Color color, Rectangle insideArea) {
  //   this
  //       .canvas
  //       .setClipDifference(insideArea.left.toInt(), insideArea.top.toInt(), insideArea.getWidth().toInt(), insideArea.getHeight().toInt());
  //   this.canvas.fillColor(color);
  //   this.canvas.resetClip();
  // }

  /**
   * Fills the area outside the specificed rectangle with color.
   * This method is used to blank out areas that fall outside the map area.
   *
   * @param color      the fill color for the outside area
   * @param insideArea the inside area on which not to draw
   */
  // void fillOutsideAreasFromNumber(int color, Rectangle insideArea) {
  //   this
  //       .canvas
  //       .setClipDifference(insideArea.left.toInt(), insideArea.top.toInt(), insideArea.getWidth().toInt(), insideArea.getHeight().toInt());
  //   this.canvas.fillColorFromNumber(color);
  //   this.canvas.resetClip();
  // }

  void startCanvasBitmap() {
    //this.canvas.setBitmap(bitmap);
  }

  Future<Bitmap> finalizeCanvasBitmap() async {
    return await canvas.finalizeBitmap();
  }

  void drawCircleContainer(ShapePaintContainer shapePaintContainer) {
    CircleContainer circleContainer = shapePaintContainer.shapeContainer as CircleContainer;
    Mappoint point = circleContainer.point;
    this.canvas.drawCircle(point.x.toInt(), point.y.toInt(), circleContainer.radius.toInt(), shapePaintContainer.paint);
  }

  // void drawHillshading(HillshadingContainer container) {
  //   canvas.shadeBitmap(container.bitmap, container.hillsRect, container.tileRect, container.magnitude);
  // }

  void _drawPath(ShapePaintContainer shapePaintContainer, List<List<Mappoint>> coordinates, double dy) {
    this.path.clear();

    for (List<Mappoint> innerList in coordinates) {
      List<Mappoint> points;
      if (dy != 0) {
        points = RendererUtils.parallelPath(innerList, dy);
      } else {
        points = innerList;
      }
      // bool below = true;
      // bool left = true;
      // bool right = true;
      // bool top = true;
      // points.forEach((element) {
      //   if (element.y >= 0) {
      //     below = false;
      //     return;
      //   }
      //   if (element.x >= 0) {
      //     left = false;
      //     return;
      //   }
      //   if (element.x <= 256) {
      //     right = false;
      //     return;
      //   }
      //   if (element.y <= 256) {
      //     top = false;
      //     return;
      //   }
      // });
      // if (!below || !left || !top || !right) {
      //_log.info("Path is ${points.join(",")}");
      Mappoint point = points[0];
      this.path.moveTo(point.x, point.y);
      for (int i = 1; i < points.length; i++) {
        point = points[i];
        this.path.lineTo(point.x, point.y);
      }
//      }
    }

    this.canvas.drawPath(this.path, shapePaintContainer.paint);
  }

  void _drawShapePaintContainer(ShapePaintContainer shapePaintContainer, PixelProjection projection) {
    ShapeContainer shapeContainer = shapePaintContainer.shapeContainer;
    ShapeType shapeType = shapeContainer.getShapeType();
    switch (shapeType) {
      case ShapeType.CIRCLE:
        drawCircleContainer(shapePaintContainer);
        break;
      case ShapeType.HILLSHADING:
        HillshadingContainer hillshadingContainer = shapeContainer as HillshadingContainer;
        //drawHillshading(hillshadingContainer);
        break;
      case ShapeType.POLYLINE:
        PolylineContainer polylineContainer = shapeContainer as PolylineContainer;
        //_log.info("drawing line " + polylineContainer.toString());
        _drawPath(shapePaintContainer, polylineContainer.getCoordinatesRelativeToOrigin(projection), shapePaintContainer.dy);
        break;
    }
  }
}
