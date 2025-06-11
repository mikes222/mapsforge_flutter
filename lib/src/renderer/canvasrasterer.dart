import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/graphics/tilepicture.dart';
import 'package:mapsforge_flutter/src/projection/pixelprojection.dart';

import '../graphics/graphicutils.dart';
import '../rendertheme/rendercontext.dart';
import '../rendertheme/renderinfo.dart';
import '../utils/layerutil.dart';

class CanvasRasterer {
  final MapCanvas canvas;

  int renderInfoCount = 0;

  CanvasRasterer(double width, double height, [String? src]) : canvas = GraphicFactory().createCanvas(width, height, src);

  void destroy() {
    this.canvas.destroy();
  }

  void drawWays(RenderContext renderContext, Mappoint center) {
    //print("drawing now ${renderContext.layerWays.length} layers");
    for (LayerPaintContainer layerPaintContainer in renderContext.drawingLayers) {
      //print("   drawing now ${layerPaintContainer.ways.length} levels");
      for (List<RenderInfo> wayList in layerPaintContainer.ways) {
        //if (wayList.length > 0) print("      drawing now ${wayList.length} ShapePaintContainers");
        for (RenderInfo element in wayList) {
          //print("         drawing now ${element}");
          element.render(this.canvas, renderContext.projection, center);
          ++renderInfoCount;
        }
      }
    }
    for (List<RenderInfo> wayList in renderContext.clashDrawingLayer.ways) {
      List<RenderInfo> renderInfos = LayerUtil.collisionFreeOrdered(wayList, renderContext.projection);
      //if (wayList.length > 0) print("      drawing now ${wayList.length} ShapePaintContainers");
      for (RenderInfo element in renderInfos) {
        //print("         drawing now ${element}");
        element.render(this.canvas, renderContext.projection, center);
        ++renderInfoCount;
      }
    }
  }

  void drawMapElements(Set<RenderInfo> elements, PixelProjection projection, Mappoint center, Tile tile) {
    // we have a set of all map elements (needed so we do not draw elements twice),
    // but we need to draw in priority order as we now allow overlaps. So we
    // convert into list, then sort, then draw.
    // draw elements in order of priority: lower priority first, so more important
    // elements will be drawn on top (in case of display=true) items.
    List<RenderInfo> elementsAsList = elements.toList()..sort();
    for (RenderInfo element in elementsAsList) {
      // The color filtering takes place in TileLayer
      //print("label to draw now: $element");
      element.render(this.canvas, projection, center);
      ++renderInfoCount;
    }
  }

  void fill(int color) {
    if (GraphicUtils.getAlpha(color) > 0) {
      this.canvas.fillColorFromNumber(color);
    }
  }

  void startCanvasBitmap() {
    //this.canvas.setBitmap(bitmap);
  }

  Future<TilePicture> finalizeCanvasBitmap() async {
    return await canvas.finalizeBitmap();
  }

  @override
  String toString() {
    return 'CanvasRasterer{renderInfoCount: $renderInfoCount}, canvas: $canvas';
  }
}
