import 'dart:math';

import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/projection/pixelprojection.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape.dart';

import '../../graphics/hillshadingbitmap.dart';
import '../../layer/hills/hillsrenderconfig.dart';
import '../../model/mappoint.dart';
import '../../model/maprectangle.dart';
import '../../model/tile.dart';
import '../shape/shape_hillshading.dart';
import '../rendercontext.dart';

/**
 * Represents hillshading on a painter algorithm layer/level in the parsed rendertheme
 * (but without a rule, we don't need to increase waymatching complexity here)
 */
class RenderinstructionHillshading {
  bool always;
  final int level;
  final int layer;
  final int minZoom;
  final int maxZoom;
  final double magnitude;

  RenderinstructionHillshading(this.minZoom, this.maxZoom, this.magnitude,
      this.layer, this.always, this.level);

  void render(
      final RenderContext renderContext, HillsRenderConfig hillsRenderConfig) {
    if (hillsRenderConfig == null) {
      if (always) {
        renderContext.setDrawingLayers(layer);
        Shape hillShape = new ShapeHillshading.base();
        //renderContext.addToCurrentDrawingLayer(level, new ShapePaintContainer(hillShape, null, 0));
      }
      return;
    }
    double effectiveMagnitude = min(
            max(0, this.magnitude * hillsRenderConfig.getMaginuteScaleFactor()),
            255) /
        255;
    Tile tile = renderContext.job.tile;
    int zoomLevel = tile.zoomLevel;
    PixelProjection projection = renderContext.projection;
    Mappoint origin = projection.getLeftUpper(tile);
    double maptileTopLat = projection.pixelYToLatitude(origin.y);
    double maptileLeftLng = projection.pixelXToLongitude(origin.x);

    double maptileBottomLat =
        projection.pixelYToLatitude(origin.y + renderContext.job.tileSize);
    double maptileRightLng =
        projection.pixelXToLongitude(origin.x + renderContext.job.tileSize);

    double mapTileLatDegrees = maptileTopLat - maptileBottomLat;
    double mapTileLngDegrees = maptileRightLng - maptileLeftLng;
    double pxPerLat = (renderContext.job.tileSize / mapTileLatDegrees);
    double pxPerLng = (renderContext.job.tileSize / mapTileLngDegrees);

    if (maptileRightLng < maptileLeftLng) maptileRightLng += projection.mapsize;

    int shadingLngStep = 1;
    int shadingLatStep = 1;
    for (int shadingLeftLng = maptileLeftLng.floor();
        shadingLeftLng <= maptileRightLng;
        shadingLeftLng += shadingLngStep) {
      for (int shadingBottomLat = maptileBottomLat.floor();
          shadingBottomLat <= maptileTopLat;
          shadingBottomLat += shadingLatStep) {
        int shadingRightLng = shadingLeftLng + 1;
        int shadingTopLat = shadingBottomLat + 1;

        HillshadingBitmap? shadingTile = null;
        shadingTile = hillsRenderConfig.getShadingTile(
            shadingBottomLat, shadingLeftLng, pxPerLat, pxPerLng);
        if (shadingTile == null) {
          if (!always) {
            continue;
          }
        }
        double shadingPixelOffset = 0;

        int padding;
        int shadingInnerWidth;
        int shadingInnerHeight;
        if (shadingTile != null) {
          padding = shadingTile.getPadding();
          shadingInnerWidth = shadingTile.getWidth() - 2 * padding;
          shadingInnerHeight = shadingTile.getHeight() - 2 * padding;
        } else {
          // dummy values to not confuse the maptile calculations
          padding = 0;
          shadingInnerWidth = 1;
          shadingInnerHeight = 1;
        }

        // shading tile subset if it fully fits inside map tile
        double shadingSubrectTop = padding.toDouble();
        double shadingSubrectLeft = padding.toDouble();

        double shadingSubrectRight = shadingSubrectLeft + shadingInnerWidth;
        double shadingSubrectBottom = shadingSubrectTop + shadingInnerHeight;

        // map tile subset if it fully fits inside shading tile
        double maptileSubrectLeft = 0;
        double maptileSubrectTop = 0;
        double maptileSubrectRight = renderContext.job.tileSize.toDouble();
        double maptileSubrectBottom = renderContext.job.tileSize.toDouble();

        // find the intersection between map tile and shading tile in earth coordinates and determine the pixel
        if (shadingTopLat > maptileTopLat) {
          // map tile ends in shading tile
          shadingSubrectTop = padding +
              shadingInnerHeight *
                  ((shadingTopLat - maptileTopLat) / shadingLatStep);
        } else if (maptileTopLat > shadingTopLat) {
          maptileSubrectTop = projection.latitudeToPixelY(
                  shadingTopLat + (shadingPixelOffset / shadingInnerHeight)) -
              origin.y;
        }
        if (shadingBottomLat < maptileBottomLat) {
          // map tile ends in shading tile
          shadingSubrectBottom = padding +
              shadingInnerHeight -
              shadingInnerHeight *
                  ((maptileBottomLat - shadingBottomLat) / shadingLatStep);
        } else if (maptileBottomLat < shadingBottomLat) {
          maptileSubrectBottom = projection.latitudeToPixelY(shadingBottomLat +
                  (shadingPixelOffset / shadingInnerHeight)) -
              origin.y;
        }
        if (shadingLeftLng < maptileLeftLng) {
          // map tile ends in shading tile
          shadingSubrectLeft = padding +
              shadingInnerWidth *
                  ((maptileLeftLng - shadingLeftLng) / shadingLngStep);
        } else if (maptileLeftLng < shadingLeftLng) {
          maptileSubrectLeft = projection.longitudeToPixelX(
                  shadingLeftLng + (shadingPixelOffset / shadingInnerWidth)) -
              origin.x;
        }
        if (shadingRightLng > maptileRightLng) {
          // map tile ends in shading tile
          shadingSubrectRight = padding +
              shadingInnerWidth -
              shadingInnerWidth *
                  ((shadingRightLng - maptileRightLng) / shadingLngStep);
        } else if (maptileRightLng > shadingRightLng) {
          maptileSubrectRight = projection.longitudeToPixelX(
                  shadingRightLng + (shadingPixelOffset / shadingInnerHeight)) -
              origin.x;
        }

        MapRectangle? hillsRect = (shadingTile == null)
            ? null
            : new MapRectangle(shadingSubrectLeft, shadingSubrectTop,
                shadingSubrectRight, shadingSubrectBottom);
        MapRectangle maptileRect = new MapRectangle(maptileSubrectLeft,
            maptileSubrectTop, maptileSubrectRight, maptileSubrectBottom);
        Shape hillShape = new ShapeHillshading.base();
        //shadingTile, effectiveMagnitude, hillsRect, maptileRect);

        renderContext.setDrawingLayers(layer);
        //renderContext.addToCurrentDrawingLayer(level, new ShapePaintContainer(hillShape, graphicFactory.createPaint(), 0));
      }
    }
  }
}
