import '../graphics/bitmap.dart';
import '../graphics/canvas.dart';
import '../graphics/color.dart';
import '../graphics/filter.dart';
import '../graphics/graphicfactory.dart';
import '../graphics/graphicutils.dart';
import '../graphics/matrix.dart';
import '../graphics/path.dart';
import '../mapelements/mapelementcontainer.dart';
import '../model/mappoint.dart';
import '../model/rectangle.dart';
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
  final Canvas canvas;
  final Path path;
  final Matrix symbolMatrix;

  CanvasRasterer(GraphicFactory graphicFactory)
      : canvas = graphicFactory.createCanvas(),
        path = graphicFactory.createPath(),
        symbolMatrix = graphicFactory.createMatrix();

  void destroy() {
    this.canvas.destroy();
  }

  void drawWays(RenderContext renderContext) {
    int levelsPerLayer = renderContext.ways.elementAt(0).length;

    for (int layer = 0, layers = renderContext.ways.length;
        layer < layers;
        ++layer) {
      List<List<ShapePaintContainer>> shapePaintContainers =
          renderContext.ways.elementAt(layer);

      for (int level = 0; level < levelsPerLayer; ++level) {
        List<ShapePaintContainer> wayList =
            shapePaintContainers.elementAt(level);

        for (int index = wayList.length - 1; index >= 0; --index) {
          drawShapePaintContainer(wayList.elementAt(index));
        }
      }
    }
  }

  void drawMapElements(Set<MapElementContainer> elements, Tile tile) {
    // we have a set of all map elements (needed so we do not draw elements twice),
    // but we need to draw in priority order as we now allow overlaps. So we
    // convert into list, then sort, then draw.
    List<MapElementContainer> elementsAsList = new List();
    elementsAsList.addAll(elements);
    // draw elements in order of priority: lower priority first, so more important
    // elements will be drawn on top (in case of display=true) items.
    elementsAsList.sort();

    for (MapElementContainer element in elementsAsList) {
      // The color filtering takes place in TileLayer
      element.draw(canvas, tile.getOrigin(), this.symbolMatrix, Filter.NONE);
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
  void fillOutsideAreas(Color color, Rectangle insideArea) {
    this.canvas.setClipDifference(
        insideArea.left.toInt(),
        insideArea.top.toInt(),
        insideArea.getWidth().toInt(),
        insideArea.getHeight().toInt());
    this.canvas.fillColor(color);
    this.canvas.resetClip();
  }

  /**
   * Fills the area outside the specificed rectangle with color.
   * This method is used to blank out areas that fall outside the map area.
   *
   * @param color      the fill color for the outside area
   * @param insideArea the inside area on which not to draw
   */
  void fillOutsideAreasFromNumber(int color, Rectangle insideArea) {
    this.canvas.setClipDifference(
        insideArea.left.toInt(),
        insideArea.top.toInt(),
        insideArea.getWidth().toInt(),
        insideArea.getHeight().toInt());
    this.canvas.fillColorFromNumber(color);
    this.canvas.resetClip();
  }

  void setCanvasBitmap(Bitmap bitmap) {
    this.canvas.setBitmap(bitmap);
  }

  void drawCircleContainer(ShapePaintContainer shapePaintContainer) {
    CircleContainer circleContainer = shapePaintContainer.shapeContainer;
    Mappoint point = circleContainer.point;
    this.canvas.drawCircle(point.x.toInt(), point.y.toInt(),
        circleContainer.radius.toInt(), shapePaintContainer.paint);
  }

  void drawHillshading(HillshadingContainer container) {
    canvas.shadeBitmap(container.bitmap, container.hillsRect,
        container.tileRect, container.magnitude);
  }

  void drawPath(ShapePaintContainer shapePaintContainer,
      List<List<Mappoint>> coordinates, double dy) {
    this.path.clear();

    for (List<Mappoint> innerList in coordinates) {
      List<Mappoint> points;
      if (dy != 0) {
        points = RendererUtils.parallelPath(innerList, dy);
      } else {
        points = innerList;
      }
      if (points.length >= 2) {
        Mappoint point = points[0];
        this.path.moveTo(point.x, point.y);
        for (int i = 1; i < points.length; ++i) {
          point = points[i];
          this.path.lineTo(point.x, point.y);
        }
      }
    }

    this.canvas.drawPath(this.path, shapePaintContainer.paint);
  }

  void drawShapePaintContainer(ShapePaintContainer shapePaintContainer) {
    ShapeContainer shapeContainer = shapePaintContainer.shapeContainer;
    ShapeType shapeType = shapeContainer.getShapeType();
    switch (shapeType) {
      case ShapeType.CIRCLE:
        drawCircleContainer(shapePaintContainer);
        break;
      case ShapeType.HILLSHADING:
        HillshadingContainer hillshadingContainer = shapeContainer;
        drawHillshading(hillshadingContainer);
        break;
      case ShapeType.POLYLINE:
        PolylineContainer polylineContainer = shapeContainer;
        drawPath(
            shapePaintContainer,
            polylineContainer.getCoordinatesRelativeToOrigin(),
            shapePaintContainer.dy);
        break;
    }
  }
}
