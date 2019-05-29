import '../cache/tilecache.dart';
import '../datastore/mapdatastore.dart';
import '../datastore/mapreadresult.dart';
import '../graphics/color.dart';
import '../graphics/graphicfactory.dart';
import '../graphics/tilebitmap.dart';
import '../labels/tilebasedlabelstore.dart';
import '../layer/hills/hillsrenderconfig.dart';
import '../mapelements/mapelementcontainer.dart';
import '../model/rectangle.dart';
import '../model/tile.dart';
import '../renderer/rendererjob.dart';
import '../renderer/tiledependencies.dart';
import '../rendertheme/rendercontext.dart';
import '../utils/layerutil.dart';
import 'package:logging/logging.dart';

import 'canvasrasterer.dart';
import 'standardrenderer.dart';

/**
 * The DatabaseRenderer renders map tiles by reading from a {@link org.mapsforge.map.datastore.MapDataStore}.
 */
class DatabaseRenderer extends StandardRenderer {
  static final _log = new Logger('DatabaseRenderer');

  final TileBasedLabelStore labelStore;
  final bool renderLabels;
  final TileCache tileCache;
  TileDependencies tileDependencies;

  /**
   * Constructs a new DatabaseRenderer.
   * There are three possible configurations:
   * 1) render labels directly onto tiles: renderLabels == true && tileCache != null
   * 2) do not render labels but cache them: renderLabels == false && labelStore != null
   * 3) do not render or cache labels: renderLabels == false && labelStore == null
   *
   * @param mapDataStore      the data source.
   * @param graphicFactory    the graphic factory.
   * @param tileCache         where tiles are cached (needed if labels are drawn directly onto tiles, otherwise null)
   * @param labelStore        where labels are cached.
   * @param renderLabels      if labels should be rendered.
   * @param cacheLabels       if labels should be cached.
   * @param hillsRenderConfig the hillshading setup to be used (can be null).
   */
  DatabaseRenderer(
      MapDataStore mapDataStore,
      GraphicFactory graphicFactory,
      this.tileCache,
      this.labelStore,
      this.renderLabels,
      bool cacheLabels,
      HillsRenderConfig hillsRenderConfig)
      : super(mapDataStore, graphicFactory, renderLabels || cacheLabels,
            hillsRenderConfig) {
    if (!renderLabels) {
      this.tileDependencies = null;
    } else {
      this.tileDependencies = new TileDependencies();
    }
  }

  /**
   * Called when a job needs to be executed.
   *
   * @param rendererJob the job that should be executed.
   */
  Future<TileBitmap> executeJob(RendererJob rendererJob) async {
    RenderContext renderContext = null;
    try {
      renderContext =
          new RenderContext(rendererJob, new CanvasRasterer(graphicFactory));

      if (renderBitmap(renderContext)) {
        TileBitmap bitmap = null;

        if (this.mapDataStore != null) {
          MapReadResult mapReadResult =
              await this.mapDataStore.readMapDataSingle(rendererJob.tile);
          processReadMapData(renderContext, mapReadResult);
        }

        if (!rendererJob.labelsOnly) {
          renderContext.renderTheme.matchHillShadings(this, renderContext);
          bitmap = this.graphicFactory.createTileBitmap(
              rendererJob.tile.tileSize, rendererJob.hasAlpha);
          bitmap.setTimestamp(
              rendererJob.mapDataStore.getDataTimestamp(rendererJob.tile));
          renderContext.canvasRasterer.setCanvasBitmap(bitmap);
          if (!rendererJob.hasAlpha &&
              rendererJob.displayModel.getBackgroundColor() !=
                  renderContext.renderTheme.getMapBackground()) {
            renderContext.canvasRasterer
                .fill(renderContext.renderTheme.getMapBackground());
          }
          renderContext.canvasRasterer.drawWays(renderContext);
        }

        if (this.renderLabels) {
          Set<MapElementContainer> labelsToDraw = processLabels(renderContext);
          // now draw the ways and the labels
          renderContext.canvasRasterer
              .drawMapElements(labelsToDraw, rendererJob.tile);
        }
        if (this.labelStore != null) {
          // store elements for this tile in the label cache
          this.labelStore.storeMapItems(rendererJob.tile, renderContext.labels);
        }

        if (!rendererJob.labelsOnly &&
            renderContext.renderTheme.hasMapBackgroundOutside()) {
          // blank out all areas outside of map
          Rectangle insideArea = this
              .mapDataStore
              .boundingBox()
              .getPositionRelativeToTile(rendererJob.tile);
          if (!rendererJob.hasAlpha) {
            renderContext.canvasRasterer.fillOutsideAreasFromNumber(
                renderContext.renderTheme.getMapBackgroundOutside(),
                insideArea);
          } else {
            renderContext.canvasRasterer
                .fillOutsideAreas(Color.TRANSPARENT, insideArea);
          }
        }
        return bitmap;
      }
      // outside of map area with background defined:
      return createBackgroundBitmap(renderContext);
    } catch (e) {
      // #1049: message can be null?
      _log.warning("Exception: " + e.getMessage());
      return null;
    } finally {
      if (renderContext != null) {
        renderContext.destroy();
      }
    }
  }

  MapDataStore getMapDatabase() {
    return this.mapDataStore;
  }

  void removeTileInProgress(Tile tile) {
    if (this.tileDependencies != null) {
      this.tileDependencies.removeTileInProgress(tile);
    }
  }

  /**
   * Draws a bitmap just with outside colour, used for bitmaps outside of map area.
   *
   * @param renderContext the RenderContext
   * @return bitmap drawn in single colour.
   */
  TileBitmap createBackgroundBitmap(RenderContext renderContext) {
    TileBitmap bitmap = this.graphicFactory.createTileBitmap(
        renderContext.rendererJob.tile.tileSize,
        renderContext.rendererJob.hasAlpha);
    renderContext.canvasRasterer.setCanvasBitmap(bitmap);
    if (!renderContext.rendererJob.hasAlpha) {
      renderContext.canvasRasterer
          .fill(renderContext.renderTheme.getMapBackgroundOutside());
    }
    return bitmap;
  }

  Set<MapElementContainer> processLabels(RenderContext renderContext) {
    // if we are drawing the labels per tile, we need to establish which tile-overlapping
    // elements need to be drawn.
    Set<MapElementContainer> labelsToDraw = new Set();

    //synchronized(tileDependencies)
    {
      // first we need to get the labels from the adjacent tiles if they have already been drawn
      // as those overlapping items must also be drawn on the current tile. They must be drawn regardless
      // of priority clashes as a part of them has alread been drawn.
      Set<Tile> neighbours = renderContext.rendererJob.tile.getNeighbours();
      Set<MapElementContainer> undrawableElements = new Set();

      tileDependencies.addTileInProgress(renderContext.rendererJob.tile);
      neighbours.forEach((Tile neighbour) {
        if (tileDependencies.isTileInProgress(neighbour) ||
            tileCache
                .containsKey(renderContext.rendererJob.otherTile(neighbour))) {
          // if a tile has already been drawn, the elements drawn that overlap onto the
          // current tile should be in the tile dependencies, we add them to the labels that
          // need to be drawn onto this tile. For the multi-threaded renderer we also need to take
          // those tiles into account that are not yet in the TileCache: this is taken care of by the
          // set of tilesInProgress inside the TileDependencies.
          labelsToDraw.addAll(tileDependencies.getOverlappingElements(
              neighbour, renderContext.rendererJob.tile));

          // but we need to remove the labels for this tile that overlap onto a tile that has been drawn
          for (MapElementContainer current in renderContext.labels) {
            if (current.intersects(neighbour.getBoundaryAbsolute())) {
              undrawableElements.add(current);
            }
          }
          // since we already have the data from that tile, we do not need to get the data for
          // it, so remove it from the neighbours list.
          neighbours.remove(neighbour);
        } else {
          tileDependencies.removeTileData(neighbour);
        }
      });

      // now we remove the elements that overlap onto a drawn tile from the list of labels
      // for this tile
      renderContext.labels
          .removeWhere((toTest) => undrawableElements.contains(toTest));

      // at this point we have two lists: one is the list of labels that must be drawn because
      // they already overlap from other tiles. The second one is currentLabels that contains
      // the elements on this tile that do not overlap onto a drawn tile. Now we sort this list and
      // remove those elements that clash in this list already.
      List<MapElementContainer> currentElementsOrdered =
          LayerUtil.collisionFreeOrdered(renderContext.labels);

      // now we go through this list, ordered by priority, to see which can be drawn without clashing.
      currentElementsOrdered.forEach((MapElementContainer current) {
        for (MapElementContainer label in labelsToDraw) {
          if (label.clashesWith(current)) {
            currentElementsOrdered.remove(current);
            break;
          }
        }
      });

      labelsToDraw.addAll(currentElementsOrdered);

      // update dependencies, add to the dependencies list all the elements that overlap to the
      // neighbouring tiles, first clearing out the cache for this relation.
      for (Tile tile in neighbours) {
        tileDependencies.removeTileData(renderContext.rendererJob.tile,
            to: tile);
        for (MapElementContainer element in labelsToDraw) {
          if (element.intersects(tile.getBoundaryAbsolute())) {
            tileDependencies.addOverlappingElement(
                renderContext.rendererJob.tile, tile, element);
          }
        }
      }
    }
    return labelsToDraw;
  }
}
