import 'dart:math';

import '../../graphics/graphicfactory.dart';
import '../../graphics/hillshadingbitmap.dart';
import '../../layer/hills/hillsrenderconfig.dart';
import '../../model/mappoint.dart';
import '../../model/rectangle.dart';
import '../../model/tile.dart';
import '../../renderer/hillshadingcontainer.dart';
import '../../renderer/shapecontainer.dart';
import '../../renderer/shapepaintcontainer.dart';
import '../../utils/mercatorprojection.dart';

import '../rendercontext.dart';

/**
 * Represents hillshading on a painter algorithm layer/level in the parsed rendertheme
 * (but without a rule, we don't need to increase waymatching complexity here)
 */
class Hillshading {
  bool always;
  final int level;
  final int layer;
  final int minZoom;
  final int maxZoom;
  final double magnitude;

  Hillshading(this.minZoom, this.maxZoom, this.magnitude, this.layer, this.always, this.level, GraphicFactory graphicFactory)
      : assert(always != null),
        assert(level != null),
        assert(layer != null),
        assert(minZoom != null),
        assert(maxZoom != null),
        assert(magnitude != null);

  void render(final RenderContext renderContext, HillsRenderConfig hillsRenderConfig) {
    if (hillsRenderConfig == null) {
      if (always) {
        renderContext.setDrawingLayers(layer);
        ShapeContainer hillShape = new HillshadingContainer(null, this.magnitude, null, null);
        renderContext.addToCurrentDrawingLayer(level, new ShapePaintContainer(hillShape, null, 0));
      }
      return;
    }
    double effectiveMagnitude = min(max(0, this.magnitude * hillsRenderConfig.getMaginuteScaleFactor()), 255) / 255;
    Tile tile = renderContext.job.tile;
    int zoomLevel = tile.zoomLevel;
    if (zoomLevel > maxZoom || zoomLevel < minZoom) return;

    Mappoint origin = tile.getOrigin();
    double maptileTopLat = MercatorProjection.pixelYToLatitude(origin.y, tile.mapSize);
    double maptileLeftLng = MercatorProjection.pixelXToLongitude(origin.x, tile.mapSize);

    double maptileBottomLat = MercatorProjection.pixelYToLatitude(origin.y + tile.tileSize, tile.mapSize);
    double maptileRightLng = MercatorProjection.pixelXToLongitude(origin.x + tile.tileSize, tile.mapSize);

    double mapTileLatDegrees = maptileTopLat - maptileBottomLat;
    double mapTileLngDegrees = maptileRightLng - maptileLeftLng;
    double pxPerLat = (tile.tileSize / mapTileLatDegrees);
    double pxPerLng = (tile.tileSize / mapTileLngDegrees);

    if (maptileRightLng < maptileLeftLng) maptileRightLng += tile.mapSize;

    int shadingLngStep = 1;
    int shadingLatStep = 1;
    for (int shadingLeftLng = maptileLeftLng.floor(); shadingLeftLng <= maptileRightLng; shadingLeftLng += shadingLngStep) {
      for (int shadingBottomLat = maptileBottomLat.floor(); shadingBottomLat <= maptileTopLat; shadingBottomLat += shadingLatStep) {
        int shadingRightLng = shadingLeftLng + 1;
        int shadingTopLat = shadingBottomLat + 1;

        HillshadingBitmap shadingTile = null;
        shadingTile = hillsRenderConfig.getShadingTile(shadingBottomLat, shadingLeftLng, pxPerLat, pxPerLng);
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
        double maptileSubrectRight = tile.tileSize.toDouble();
        double maptileSubrectBottom = tile.tileSize.toDouble();

        // find the intersection between map tile and shading tile in earth coordinates and determine the pixel
        if (shadingTopLat > maptileTopLat) {
          // map tile ends in shading tile
          shadingSubrectTop = padding + shadingInnerHeight * ((shadingTopLat - maptileTopLat) / shadingLatStep);
        } else if (maptileTopLat > shadingTopLat) {
          maptileSubrectTop =
              MercatorProjection.latitudeToPixelYWithMapSize(shadingTopLat + (shadingPixelOffset / shadingInnerHeight), tile.mapSize) -
                  origin.y;
        }
        if (shadingBottomLat < maptileBottomLat) {
          // map tile ends in shading tile
          shadingSubrectBottom =
              padding + shadingInnerHeight - shadingInnerHeight * ((maptileBottomLat - shadingBottomLat) / shadingLatStep);
        } else if (maptileBottomLat < shadingBottomLat) {
          maptileSubrectBottom =
              MercatorProjection.latitudeToPixelYWithMapSize(shadingBottomLat + (shadingPixelOffset / shadingInnerHeight), tile.mapSize) -
                  origin.y;
        }
        if (shadingLeftLng < maptileLeftLng) {
          // map tile ends in shading tile
          shadingSubrectLeft = padding + shadingInnerWidth * ((maptileLeftLng - shadingLeftLng) / shadingLngStep);
        } else if (maptileLeftLng < shadingLeftLng) {
          maptileSubrectLeft =
              MercatorProjection.longitudeToPixelXAtMapSize(shadingLeftLng + (shadingPixelOffset / shadingInnerWidth), tile.mapSize) -
                  origin.x;
        }
        if (shadingRightLng > maptileRightLng) {
          // map tile ends in shading tile
          shadingSubrectRight = padding + shadingInnerWidth - shadingInnerWidth * ((shadingRightLng - maptileRightLng) / shadingLngStep);
        } else if (maptileRightLng > shadingRightLng) {
          maptileSubrectRight =
              MercatorProjection.longitudeToPixelXAtMapSize(shadingRightLng + (shadingPixelOffset / shadingInnerHeight), tile.mapSize) -
                  origin.x;
        }

        Rectangle hillsRect =
            (shadingTile == null) ? null : new Rectangle(shadingSubrectLeft, shadingSubrectTop, shadingSubrectRight, shadingSubrectBottom);
        Rectangle maptileRect = new Rectangle(maptileSubrectLeft, maptileSubrectTop, maptileSubrectRight, maptileSubrectBottom);
        ShapeContainer hillShape = new HillshadingContainer(shadingTile, effectiveMagnitude, hillsRect, maptileRect);

        renderContext.setDrawingLayers(layer);
        renderContext.addToCurrentDrawingLayer(level, new ShapePaintContainer(hillShape, null, 0));
      }
    }
  }
}
