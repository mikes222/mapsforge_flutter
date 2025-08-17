import 'dart:async';
import 'dart:math';

import 'package:isolate_task_queue/isolate_task_queue.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/layer/job/jobresult.dart';
import 'package:mapsforge_flutter/src/layer/job/jobset.dart';
import 'package:mapsforge_flutter/src/utils/mapsforge_constants.dart';

import '../../../maps.dart';
import '../../graphics/tilepicture.dart';
import '../../model/relative_mappoint.dart';
import '../../model/tile_dimension.dart';
import '../../rendertheme/renderinfo.dart';
import '../../utils/timing.dart';
import 'job.dart';

///
/// The jobqueue receives jobs and starts the renderer for missing bitmaps.
///
class JobQueue {
  static final _log = new Logger('JobQueue');

  final JobRenderer jobRenderer;

  JobSet? _currentJobSet;

  final TileBitmapCache? tileBitmapCache;

  final TileBitmapCache tileBitmapCache1stLevel;

  final TileBasedLabelStore labelStore;

  final TaskQueue _executionQueue;

  JobQueue(this.jobRenderer, this.tileBitmapCache, this.tileBitmapCache1stLevel, [int parallelJobs = 4])
      : labelStore = TileBasedLabelStore(1000),
        _executionQueue = ParallelTaskQueue(parallelJobs);

  //@override
  void dispose() {
    //super.dispose();
    _executionQueue.cancel();
    _currentJobSet?.dispose();
    _currentJobSet = null;
  }

  /// Let the queue process this jobset. A Jobset is a collection of jobs needed to render a whole view. It often consists of several tiles.
  void processJobset(JobSet jobSet) {
    jobSet.renderJobs.forEach((job) {
      if (_executionQueue.isCancelled) return;
      _executionQueue.add(() async {
        if (_currentJobSet != jobSet) return;
        TilePicture? tilePicture = tileBitmapCache1stLevel.getTileBitmapSync(job.tile);
        if (tilePicture != null) {
          jobSet.renderJobFinishedPicture(job, tilePicture);
          unawaited(_addLabelJob(jobSet, job));
        } else {
          tilePicture = await tileBitmapCache?.getTileBitmapAsync(job.tile);
          if (tilePicture != null) {
            tileBitmapCache1stLevel.addTileBitmap(job.tile, tilePicture);
            jobSet.renderJobFinishedPicture(job, tilePicture);
            unawaited(_addLabelJob(jobSet, job));
          } else {
            try {
              JobResult jobResult = await _createTilePicture(job, jobSet);
              jobSet.renderJobFinished(job, jobResult);
              jobSet.labelJobFinished(job, jobResult.renderInfos ?? []);
            } catch (error, stackTrace) {
              _log.warning(error.toString());
              if (stackTrace.toString().length > 0) _log.warning(stackTrace.toString());
              TilePicture bmp = await jobRenderer.createErrorBitmap(MapsforgeConstants().tileSize, error);
              jobSet.renderJobFinishedPicture(job, bmp);
              jobSet.labelJobFinished(job, []);
            }
          }
        }
      });
    });
  }

  Future<void> _addLabelJob(JobSet jobSet, Job job) async {
    if (_executionQueue.isCancelled) return;
    if (!jobSet.labelJobs.contains(job)) return;
    await _executionQueue.add(() async {
      if (_currentJobSet != jobSet) return;
      List<RenderInfo<Shape>>? renderInfos = labelStore.get(job.tile);
      if (renderInfos != null) {
        jobSet.labelJobFinished(job, renderInfos);
      } else {
        JobResult jobResult = await jobRenderer.retrieveLabels(job);
        labelStore.storeMapItems(job.tile, jobResult.renderInfos ?? []);
        jobSet.labelJobFinished(job, jobResult.renderInfos ?? []);
      }
    });
  }

  Future<JobResult> _createTilePicture(Job job, JobSet jobSet) async {
    JobResult jobResult = await jobRenderer.executeJob(job);
    if (jobResult.result == JOBRESULT.NORMAL) {
      tileBitmapCache1stLevel.addTileBitmap(job.tile, jobResult.picture!);
      tileBitmapCache?.addTileBitmap(job.tile, jobResult.picture!);
      labelStore.storeMapItems(job.tile, jobResult.renderInfos ?? []);
    }
    if (/*jobResult.result == JOBRESULT.ERROR ||*/
        jobResult.result == JOBRESULT.UNSUPPORTED) {
      tileBitmapCache1stLevel.addTileBitmap(job.tile, jobResult.picture!);
      labelStore.storeMapItems(job.tile, jobResult.renderInfos ?? []);
    }
    return jobResult;
  }

  // remove all jobs which can be fulfilled via the 1st level caches
  void _immedateProcessing(JobSet jobSet) {
    Map<Job, TilePicture> toRemove = {};
    jobSet.renderJobs.forEach((job) {
      TilePicture? tileBitmap = tileBitmapCache1stLevel.getTileBitmapSync(job.tile);
      if (tileBitmap != null) {
        toRemove[job] = tileBitmap;
      }
    });
    jobSet.renderJobsFinishedPicture(toRemove);

    Map<Job, List<RenderInfo<Shape>>> items = labelStore.getVisibleItems(jobSet.labelJobs);
    jobSet.labelJobsFinished(items);
  }

  JobSet? createJobSet(ViewModel viewModel, MapViewPosition mapViewPosition, MapSize screensize) {
    Timing timing = Timing(log: _log, active: true);
    TileDimension tileDimension = _calculateTiles(mapViewPosition: mapViewPosition, screensize: screensize);
    //print("Dimension: $tileDimension");
    if (tileDimension == _currentJobSet?.tileDimension && mapViewPosition.indoorLevel == _currentJobSet?.indoorLevel) {
      return _currentJobSet;
    }

    final tiles = _createTiles(mapViewPosition: mapViewPosition, tileDimension: tileDimension);

    _executionQueue.clear();
    JobSet jobSet = JobSet(
        boundingBox: mapViewPosition.projection.boundingBoxOfTileNumbers(tileDimension.top, tileDimension.left, tileDimension.bottom, tileDimension.right),
        tileDimension: tileDimension,
        jobs: tiles.map((tile) => Job(tile, false)).toList(),
        center: mapViewPosition.getCenter());
    _immedateProcessing(jobSet);
    _currentJobSet?.dispose();
    _currentJobSet = jobSet;
    processJobset(jobSet);
    timing.done(50, "${jobSet.renderJobs.length} missing tiles");
    return jobSet;
  }

  TileDimension _calculateTiles({required MapViewPosition mapViewPosition, required MapSize screensize}) {
    Mappoint center = mapViewPosition.getCenter();
    double halfWidth = screensize.width / 2;
    double halfHeight = screensize.height / 2;
    if (mapViewPosition.rotation > 2) {
      // we rotate. Use the max side for both width and height
      halfWidth = max(halfWidth, halfHeight);
      halfHeight = max(halfWidth, halfHeight);
    }
    int tileLeft = mapViewPosition.projection.pixelXToTileX(max(center.x - halfWidth, 0));
    int tileRight = mapViewPosition.projection.pixelXToTileX(min(center.x + halfWidth, mapViewPosition.projection.mapsize.toDouble()));
    int tileTop = mapViewPosition.projection.pixelYToTileY(max(center.y - halfHeight, 0));
    int tileBottom = mapViewPosition.projection.pixelYToTileY(min(center.y + halfHeight, mapViewPosition.projection.mapsize.toDouble()));
    // rising from 0 to 45, then falling to 0 at 90°
    int degreeDiff = 45 - ((mapViewPosition.rotation) % 90 - 45).round().abs();
    if (degreeDiff > 5) {
      // the map is rotated. To avoid empty corners enhance each side by one tile
      tileLeft = max(tileLeft - 1, 0);
      tileRight = min(tileRight + 1, Tile.getMaxTileNumber(mapViewPosition.zoomLevel));
      tileTop = max(tileTop - 1, 0);
      tileBottom = min(tileBottom + 1, Tile.getMaxTileNumber(mapViewPosition.zoomLevel));
    }
    return TileDimension(left: tileLeft, right: tileRight, top: tileTop, bottom: tileBottom);
  }

  ///
  /// Get all tiles needed for a given view. The tiles are in the order where it makes most sense for
  /// the user (tile in the middle should be created first
  ///
  List<Tile> _createTiles({required MapViewPosition mapViewPosition, required TileDimension tileDimension}) {
    int zoomLevel = mapViewPosition.zoomLevel;
    int indoorLevel = mapViewPosition.indoorLevel;
    Mappoint center = mapViewPosition.getCenter();
    // shift the center to the left-upper corner of a tile since we will calculate the distance to the left-upper corners of each tile
    RelativeMappoint relative = center.offset(-MapsforgeConstants().tileSize / 2, -MapsforgeConstants().tileSize / 2);
    Map<Tile, double> tileMap = Map<Tile, double>();
    for (int tileY = tileDimension.top; tileY <= tileDimension.bottom; ++tileY) {
      for (int tileX = tileDimension.left; tileX <= tileDimension.right; ++tileX) {
        Tile tile = Tile(tileX, tileY, zoomLevel, indoorLevel);
        Mappoint leftUpper = mapViewPosition.projection.getLeftUpper(tile);
        tileMap[tile] = (pow(leftUpper.x - relative.x, 2) + pow(leftUpper.y - relative.y, 2)).toDouble();
      }
    }
    //_log.info("$tileTop, $tileBottom, sort ${tileMap.length} items");

    List<Tile> sortedKeys = tileMap.keys.toList(growable: false)..sort((k1, k2) => tileMap[k1]!.compareTo(tileMap[k2]!));

    return sortedKeys;
  }
}
