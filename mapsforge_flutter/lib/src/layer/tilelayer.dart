import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/cache/tilecache.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/graphics/matrix.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/model/mapviewdimension.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';
import 'package:mapsforge_flutter/src/utils/layerutil.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

import 'cache/MemoryTileCache.dart';
import 'cache/memorybitmapcache.dart';
import 'job/job.dart';
import 'job/jobqueue.dart';
import 'job/jobrenderer.dart';
import 'layer.dart';

class TileLayer extends Layer {
  static final _log = new Logger('TileLayer');

  final bool isTransparent;
  JobQueue jobQueue;
  final TileCache _tileCache = MemoryTileCache();
  final MemoryBitmapCache _bitmapCache = MemoryBitmapCache();
  final Matrix matrix;
  final JobRenderer jobRenderer;

  bool needsRepaint = false;

  TileLayer({
    this.matrix,
    this.isTransparent = false,
    @required displayModel,
    @required this.jobRenderer,
  })  : assert(isTransparent != null),
        assert(displayModel != null),
        assert(jobRenderer != null),
        jobQueue = JobQueue(displayModel, jobRenderer),
        super(displayModel) {}

  Observable<Job> get observeJob => jobQueue.observeJob;

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

  void jobResult(Job job) {
    _bitmapCache.addTileBitmap(job.tile, job.tileBitmap);
    needsRepaint = true;
  }

  @override
  void draw(MapViewDimension mapViewDimension, MapViewPosition mapViewPosition, MapCanvas canvas) {
    int time = DateTime.now().millisecondsSinceEpoch;
    needsRepaint = false;
    List<Tile> tiles = LayerUtil.getTiles(mapViewDimension, mapViewPosition, displayModel.tileSize, _tileCache);
    //_log.info("tiles: ${tiles.length}");

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

//    Set<Job> jobs = new Set();
//    for (Tile tile in tiles) {
//      jobs.add(createJob(tile));
//    }
//    this.tileCache.setWorkingSet(jobs);
    canvas.setClip(0, 0, mapViewDimension.getDimension().width.round(), mapViewDimension.getDimension().height.round());
    mapViewPosition.calculateBoundingBox(displayModel.tileSize, mapViewDimension.getDimension());
    Mappoint leftUpper = mapViewPosition.leftUpper;

    List<Job> jobs = List();
    tiles.forEach((tile) {
      Mappoint point = tile.leftUpperPoint;
      TileBitmap bitmap = this._bitmapCache.getTileBitmap(tile);

      if (bitmap == null) {
        Job job = createJob(tile);
        jobs.add(job);
//        if (Parameters.PARENT_TILES_RENDERING !=
//            Parameters.ParentTilesRendering.OFF) {
//          drawParentTileBitmap(canvas, point, tile);
//        }
        //_log.info("  tile: ${tile.toString()}");
      } else {
//        if (isTileStale(tile, bitmap) &&
//            this.hasJobQueue &&
//            !this.tileCache.containsKey(job)) {
//          this.jobQueue.add(job);
//        }
//        retrieveLabelsOnly(job);
        canvas.drawBitmap(
          bitmap: bitmap,
          left: point.x - leftUpper.x,
          top: point.y - leftUpper.y,
        ); //, (point.x), (point.y), this.displayModel.getFilter());
        //bitmap.decrementRefCount();
      }
    });
    this.jobQueue.addJobs(jobs);
    int diff = DateTime.now().millisecondsSinceEpoch - time;
    //_log.info("diff: $diff ms");
  }

  Job createJob(Tile tile) {
    return Job(tile, true);
  }

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
  bool isTileStale(Tile tile, TileBitmap bitmap) {}

  void retrieveLabelsOnly(Job job) {}

  void drawParentTileBitmap(MapCanvas canvas, Mappoint point, Tile tile) {
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
//    } else if (this.tileCache.containsKey(createJob(parentTile))) {
//      return parentTile;
    }

    return getCachedParentTile(parentTile, level - 1);
  }
}
