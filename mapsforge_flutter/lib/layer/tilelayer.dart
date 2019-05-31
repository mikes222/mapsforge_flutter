import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/cache/tilecache.dart';
import 'package:mapsforge_flutter/graphics/canvas.dart';
import 'package:mapsforge_flutter/graphics/matrix.dart';
import 'package:mapsforge_flutter/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/model/boundingbox.dart';
import 'package:mapsforge_flutter/model/mappoint.dart';
import 'package:mapsforge_flutter/model/mapviewposition.dart';
import 'package:mapsforge_flutter/model/tile.dart';
import 'package:mapsforge_flutter/tilestore/tileposition.dart';
import 'package:mapsforge_flutter/utils/layerutil.dart';

import 'job/job.dart';
import 'job/jobqueue.dart';
import 'layer.dart';

abstract class TileLayer<T extends Job> extends Layer {
  static final _log = new Logger('TileLayer');

  final bool hasJobQueue;
  final bool isTransparent;
  JobQueue<T> jobQueue;
  final TileCache tileCache;
  final Matrix matrix;

  TileLayer(this.tileCache, this.matrix, this.isTransparent, displayModel)
      : hasJobQueue = false,
        super(displayModel) {
    //this(tileCache, mapViewPosition, matrix, isTransparent, true);
  }

//  public TileLayer(TileCache tileCache, IMapViewPosition mapViewPosition, Matrix matrix, bool isTransparent, bool hasJobQueue) {
//    super();
//
//    if (tileCache == null) {
//      throw new IllegalArgumentException("tileCache must not be null");
//    } else if (mapViewPosition == null) {
//      throw new IllegalArgumentException("mapViewPosition must not be null");
//    }
//
//    this.hasJobQueue = hasJobQueue;
//    this.tileCache = tileCache;
//    this.mapViewPosition = mapViewPosition;
//    this.matrix = matrix;
//    this.isTransparent = isTransparent;
//  }

  @override
  void draw(MapViewPosition mapViewPosition, BoundingBox boundingBox,
      Canvas canvas, Mappoint topLeftPoint) {
    List<TilePosition> tilePositions = LayerUtil.getTilePositions(
        boundingBox,
        mapViewPosition.zoomLevel,
        topLeftPoint,
        this.displayModel.getTileSize());

    _log.info("tilePositions: ${tilePositions.length}");

    // In a rotation situation it is possible that drawParentTileBitmap sets the
    // clipping bounds to portrait, while the device is just being rotated into
    // landscape: the result is a partially painted screen that only goes away
    // after zooming (which has the effect of resetting the clip bounds if drawParentTileBitmap
    // is called again).
    // Always resetting the clip bounds here seems to avoid the problem,
    // I assume that this is a pretty cheap operation, otherwise it would be better
    // to hook this into the onConfigurationChanged call chain.
    canvas.resetClip();

    if (!isTransparent) {
      canvas.fillColorFromNumber(this.displayModel.getBackgroundColor());
    }

    Set<Job> jobs = new Set();
    for (TilePosition tilePosition in tilePositions) {
      jobs.add(createJob(tilePosition.tile));
    }
    this.tileCache.setWorkingSet(jobs);

    for (int i = tilePositions.length - 1; i >= 0; --i) {
      TilePosition tilePosition = tilePositions.elementAt(i);
      Mappoint point = tilePosition.point;
      Tile tile = tilePosition.tile;
      _log.info("  tilePosition: ${tilePosition.toString()}");
      T job = createJob(tile);
      TileBitmap bitmap = this.tileCache.getImmediately(job);

      if (bitmap == null) {
        if (this.hasJobQueue && !this.tileCache.containsKey(job)) {
          this.jobQueue.add(job);
        }
//        if (Parameters.PARENT_TILES_RENDERING !=
//            Parameters.ParentTilesRendering.OFF) {
//          drawParentTileBitmap(canvas, point, tile);
//        }
      } else {
        if (isTileStale(tile, bitmap) &&
            this.hasJobQueue &&
            !this.tileCache.containsKey(job)) {
          this.jobQueue.add(job);
        }
        retrieveLabelsOnly(job);
//        canvas.drawBitmap(bitmap, (point.
//            x), (point.y), this.displayModel.getFilter());
        bitmap.decrementRefCount();
      }
    }
    if (this.hasJobQueue) {
      this.jobQueue.notifyWorkers();
    }
  }

  T createJob(Tile tile);

  /**
   * Whether the tile is stale and should be refreshed.
   * <p/>
   * This method is called from {@link #draw(BoundingBox, byte, Canvas, Point)} to determine whether the tile needs to
   * be refreshed. Subclasses must override this method and implement appropriate checks to determine when a tile is
   * stale.
   * <p/>
   * Return {@code false} to use the cached copy without attempting to refresh it.
   * <p/>
   * Return {@code true} to cause the layer to attempt to obtain a fresh copy of the tile. The layer will first
   * display the tile referenced by {@code bitmap} and attempt to obtain a fresh copy in the background. When a fresh
   * copy becomes available, the layer will replace is and update the cache. If a fresh copy cannot be obtained (e.g.
   * because the tile is obtained from an online source which cannot be reached), the stale tile will continue to be
   * used until another {@code #draw(BoundingBox, byte, Canvas, Point)} operation requests it again.
   *
   * @param tile   A tile.
   * @param bitmap The bitmap for {@code tile} currently held in the layer's cache.
   */
  bool isTileStale(Tile tile, TileBitmap bitmap);

  void retrieveLabelsOnly(T job) {}

  void drawParentTileBitmap(Canvas canvas, Mappoint point, Tile tile) {
    Tile cachedParentTile = getCachedParentTile(tile, 4);
    if (cachedParentTile != null) {
//      Bitmap bitmap = this.tileCache.getImmediately(
//          createJob(cachedParentTile));
//      if (bitmap != null) {
//        int tileSize = this.displayModel.getTileSize();
//        long translateX = tile.getShiftX(cachedParentTile) * tileSize;
//        long translateY = tile.getShiftY(cachedParentTile) * tileSize;
//        byte zoomLevelDiff = (byte)(
//            tile.zoomLevel - cachedParentTile.zoomLevel);
//        float scaleFactor = (float) Math.pow(2, zoomLevelDiff);
//
//        int x = (int) Math.round(point.x);
//        int y = (int) Math.round(point.y);
//
//        if (Parameters.PARENT_TILES_RENDERING ==
//            Parameters.ParentTilesRendering.SPEED) {
//          bool antiAlias = canvas.isAntiAlias();
//          bool filterBitmap = canvas.isFilterBitmap();
//
//          canvas.setAntiAlias(false);
//          canvas.setFilterBitmap(false);
//
//          canvas.drawBitmap(
//              bitmap,
//              (int)(translateX / scaleFactor),
//              (int)(translateY / scaleFactor),
//              (int)((translateX + tileSize) / scaleFactor),
//              (int)((translateY + tileSize) / scaleFactor),
//              x,
//              y,
//              x + tileSize,
//              y + tileSize,
//              this.displayModel.getFilter());
//
//          canvas.setAntiAlias(antiAlias);
//          canvas.setFilterBitmap(filterBitmap);
//        } else {
//          this.matrix.reset();
//          this.matrix.translate(x - translateX, y - translateY);
//          this.matrix.scale(scaleFactor, scaleFactor);
//
//          canvas.setClip(x, y, this.displayModel.getTileSize(),
//              this.displayModel.getTileSize());
//          canvas.drawBitmap(bitmap, this.matrix, this.displayModel.getFilter());
//          canvas.resetClip();
//        }
//
//        bitmap.decrementRefCount();
//      }
    }
  }

  /**
   * @return the first parent object of the given object whose tileCacheBitmap is cached (may be null).
   */
  Tile getCachedParentTile(Tile tile, int level) {
    if (level == 0) {
      return null;
    }

    Tile parentTile = tile.getParent();
    if (parentTile == null) {
      return null;
    } else if (this.tileCache.containsKey(createJob(parentTile))) {
      return parentTile;
    }

    return getCachedParentTile(parentTile, level - 1);
  }

  TileCache getTileCache() {
    return this.tileCache;
  }
}
