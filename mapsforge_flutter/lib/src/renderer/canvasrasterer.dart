import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/paintelements/point/mapelementcontainer.dart';
import 'package:mapsforge_flutter/src/paintelements/shape_paint_container.dart';
import 'package:mapsforge_flutter/src/projection/pixelprojection.dart';

import '../graphics/bitmap.dart';
import '../graphics/graphicutils.dart';
import '../graphics/mapcanvas.dart';
import '../rendertheme/rendercontext.dart';

class CanvasRasterer {
  final MapCanvas canvas;

  CanvasRasterer(double width, double height, [String? src])
      : canvas = GraphicFactory().createCanvas(width, height, src);

  void destroy() {
    this.canvas.destroy();
  }

  int drawWays(RenderContext renderContext) {
    int count = 0;
    //print("drawing now ${renderContext.layerWays.length} layers");
    for (LayerPaintContainer layerPaintContainer in renderContext.layerWays) {
      //print("   drawing now ${layerPaintContainer.ways.length} levels");
      for (List<ShapePaintContainer> wayList in layerPaintContainer.ways) {
        //if (wayList.length > 0) print("      drawing now ${wayList.length} ShapePaintContainers");
        for (ShapePaintContainer element in wayList) {
          //print("         drawing now ${element}");
          element.draw(this.canvas);
          ++count;
        }
      }
    }
    return count;
  }

  void drawMapElements(Set<MapElementContainer> elements,
      PixelProjection projection, Tile tile) {
    // we have a set of all map elements (needed so we do not draw elements twice),
    // but we need to draw in priority order as we now allow overlaps. So we
    // convert into list, then sort, then draw.
    // draw elements in order of priority: lower priority first, so more important
    // elements will be drawn on top (in case of display=true) items.
    List<MapElementContainer> elementsAsList = elements.toList()..sort();
    for (MapElementContainer element in elementsAsList) {
      // The color filtering takes place in TileLayer
      //print("label to draw now: $element");
      element.draw(canvas, projection.getLeftUpper(tile));
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

// void drawHillshading(HillshadingContainer container) {
//   canvas.shadeBitmap(container.bitmap, container.hillsRect, container.tileRect, container.magnitude);
// }

}
