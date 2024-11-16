import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/layer/job/jobresult.dart';
import 'package:mapsforge_flutter/src/layer/job/jobset.dart';
import 'package:mapsforge_flutter/src/utils/mapsforge_constants.dart';
import 'package:queue/queue.dart';
import 'package:rxdart/rxdart.dart';

import '../../../maps.dart';
import '../../graphics/tilepicture.dart';
import '../../model/relative_mappoint.dart';
import '../../rendertheme/renderinfo.dart';
import '../../rendertheme/shape/shape.dart';
import '../../utils/layerutil.dart';
import '../../utils/timing.dart';
import 'job.dart';

///
/// The jobqueue receives jobs and starts the renderer for missing bitmaps.
///
class JobQueue {
  static final _log = new Logger('JobQueue');

  final DisplayModel displayModel;
  final JobRenderer jobRenderer;

  JobSet? _currentJobSet;

  final TileBitmapCache? tileBitmapCache;

  final TileBitmapCache tileBitmapCache1stLevel;

  final Queue _executionQueue = Queue();

  final TileBasedLabelStore labelStore;

  static TileBoundary? _lastBoundary;

  static int _lastIndoorLevel = -1;

  static JobSet? _lastJobset;

  final Map<Job, _JobQueueInfo> _renderJobs = {};

  final Map<Job, _JobQueueInfo> _renderLabelJobs = {};

  Subject<JobSet> _injectJobset = BehaviorSubject();

  Stream<JobSet> get observeJobset => _injectJobset.stream;

  JobQueue(this.displayModel, this.jobRenderer, this.tileBitmapCache,
      this.tileBitmapCache1stLevel)
      : labelStore = TileBasedLabelStore(1000);

  void dispose() {
    _executionQueue.dispose();
    _currentJobSet?.dispose();
    _renderJobs.clear();
    _renderLabelJobs.clear();
    _currentJobSet = null;
    _injectJobset.close();
  }

  /// Let the queue process this jobset. A Jobset is a collection of jobs needed to render a whole view. It often consists of several tiles.
  void processJobset(JobSet jobSet) {
    _immedateProcessing(jobSet);
    // remove existing jobs
    _renderJobs.forEach((key, value) {
      value.jobSet = null;
    });
    _renderLabelJobs.forEach((key, value) {
      value.jobSet = null;
    });
    // add new jobs
    jobSet.jobs.forEach((job) {
      _JobQueueInfo? jobQueueInfo = _renderJobs[job];
      if (jobQueueInfo == null) {
        jobQueueInfo = _JobQueueInfo();
        _renderJobs[job] = jobQueueInfo;
      }
      jobQueueInfo.jobSet = jobSet;
    });
    jobSet.labelJobs.forEach((job) {
      _JobQueueInfo? jobQueueInfo = _renderLabelJobs[job];
      if (jobQueueInfo == null) {
        jobQueueInfo = _JobQueueInfo();
        _renderLabelJobs[job] = jobQueueInfo;
      }
      jobQueueInfo.jobSet = jobSet;
    });
    if (_executionQueue.isCancelled) return;
    _executionQueue.add(() async {
      await _startNextJob();
    });
  }

  // remove all jobs which can be fulfilled via the 1st level caches
  void _immedateProcessing(JobSet jobSet) {
    Map<Job, TilePicture> toRemove = {};
    jobSet.jobs.forEach((job) {
      TilePicture? tileBitmap =
          tileBitmapCache1stLevel.getTileBitmapSync(job.tile);
      if (tileBitmap != null) {
        toRemove[job] = tileBitmap;
      }
    });
    jobSet.jobsFinished(toRemove);

    Map<Job, List<RenderInfo<Shape>>> items =
        labelStore.getVisibleItems(jobSet.labelJobs);
    jobSet.renderingJobsFinished(items);
  }

  Future<void> _startNextJob() async {
    //_log.info("ListQueue has ${_listQueue.length} elements");
    if (_renderJobs.isEmpty) {
      unawaited(_startNextLabelJob());
      return;
    }
    MapEntry<Job, _JobQueueInfo> entry = _renderJobs.entries.first;
    Job job = entry.key;
    if (entry.value.jobSet != null) {
      if (!entry.value.processing) {
        entry.value.processing = true;
        //_log.info("taken ${nextJob?.toString()} from queue");
        try {
          await _donowDirect(job);
        } catch (e, stacktrace) {
          _log.warning("$e\n$stacktrace");
        }
      }
    }
    _renderJobs.remove(job);
    if (_executionQueue.isCancelled) return;
    unawaited(_executionQueue.add(() async {
      await _startNextJob();
    }));
  }

  Future<void> _startNextLabelJob() async {
    if (_renderLabelJobs.isEmpty) {
      return;
    }
    MapEntry<Job, _JobQueueInfo> entry = _renderLabelJobs.entries.first;
    Job job = entry.key;
    if (entry.value.jobSet != null) {
      if (!entry.value.processing) {
        entry.value.processing = true;
        JobResult jobResult = await jobRenderer.retrieveLabels(job);
        _JobQueueInfo? jobQueueInfo = _renderLabelJobs[job];
        if (jobResult.renderInfos != null) {
          labelStore.storeMapItems(job.tile, jobResult.renderInfos!);
          jobQueueInfo?.jobSet
              ?.renderingJobFinished(job, jobResult.renderInfos!);
        } else {
          // we have to remove this job even if we do not have labels
          jobQueueInfo?.jobSet?.labelJobs.remove(job);
        }
      }
    }
    _renderLabelJobs.remove(job);
    if (_executionQueue.isCancelled) return;
    unawaited(_executionQueue.add(() async {
      await _startNextLabelJob();
    }));
  }

  Future<void> _donowDirect(Job job) async {
    TilePicture? tileBitmap =
        await tileBitmapCache?.getTileBitmapAsync(job.tile);
    if (tileBitmap != null) {
      tileBitmapCache1stLevel.addTileBitmap(job.tile, tileBitmap);
      _JobQueueInfo? jobQueueInfo = _renderJobs[job];
      jobQueueInfo?.jobSet
          ?.jobFinished(job, JobResult(tileBitmap, JOBRESULT.NORMAL));
      _renderJobs.remove(job);
      return;
    }
    JobResult jobResult = await renderDirect(IsolateParam(job, jobRenderer));
    if (jobResult.result == JOBRESULT.NORMAL) {
      tileBitmapCache1stLevel.addTileBitmap(job.tile, jobResult.picture!);
      tileBitmapCache?.addTileBitmap(job.tile, jobResult.picture!);
    }
    if (/*jobResult.result == JOBRESULT.ERROR ||*/
        jobResult.result == JOBRESULT.UNSUPPORTED) {
      tileBitmapCache1stLevel.addTileBitmap(job.tile, jobResult.picture!);
    }
    _JobQueueInfo? jobQueueInfo = _renderJobs[job];
    jobQueueInfo?.jobSet?.jobFinished(job, jobResult);
    _renderJobs.remove(job);

    if (jobResult.renderInfos != null) {
      labelStore.storeMapItems(job.tile, jobResult.renderInfos!);
    }
  }

  JobSet? submitJobSet(ViewModel viewModel, MapViewPosition mapViewPosition) {
    //_log.info("viewModel ${viewModel.viewDimension}");
    Timing timing = Timing(log: _log, active: true);
    TileBoundary? _boundary = _lastBoundary;
    List<Tile> tiles = _getTiles(viewModel, mapViewPosition);
    if (_boundary == _lastBoundary &&
        (_lastJobset?.completed() ?? false) &&
        _lastIndoorLevel == tiles.first.indoorLevel &&
        _lastJobset?.mapViewPosition.zoomLevel == mapViewPosition.zoomLevel) {
      /// The last jobset is completed and represents still the desired data so use it.
      _lastJobset?.mapViewPosition = mapViewPosition;
      _injectJobset.add(_lastJobset!);
      return _lastJobset;
    }
    _lastJobset?.dispose();
    _lastJobset = null;
    JobSet jobSet = JobSet(mapViewPosition: mapViewPosition);

    tiles.forEach((Tile tile) {
      Job job = Job(tile, false);
      jobSet.add(job);
    });
    timing.lap(50, "${jobSet.jobs.length} missing tiles");
    //_log.info("JobSets created: ${jobSet.jobs.length}");
    if (jobSet.jobs.length > 0) {
      processJobset(jobSet);
      _lastJobset = jobSet;
      _lastIndoorLevel = tiles.first.indoorLevel;
      _injectJobset.add(jobSet);
      return jobSet;
    }
    return null;
  }

  ///
  /// Get all tiles needed for a given view. The tiles are in the order where it makes most sense for
  /// the user (tile in the middle should be created first
  ///
  List<Tile> _getTiles(ViewModel viewModel, MapViewPosition mapViewPosition) {
    Mappoint center = mapViewPosition.getCenter();
    int zoomLevel = mapViewPosition.zoomLevel;
    int indoorLevel = mapViewPosition.indoorLevel;
    double halfWidth = viewModel.mapDimension.width / 2;
    double halfHeight = viewModel.mapDimension.height / 2;
    if (mapViewPosition.rotation > 2) {
      // we rotate. Use the max side for both width and height
      halfWidth = max(halfWidth, halfHeight);
      halfHeight = max(halfWidth, halfHeight);
    }
    // rising from 0 to 45, then falling to 0 at 90°
    int degreeDiff = 45 - ((mapViewPosition.rotation) % 90 - 45).round().abs();
    int tileLeft =
        mapViewPosition.projection.pixelXToTileX(max(center.x - halfWidth, 0));
    int tileRight = mapViewPosition.projection.pixelXToTileX(min(
        center.x + halfWidth, mapViewPosition.projection.mapsize.toDouble()));
    int tileTop =
        mapViewPosition.projection.pixelYToTileY(max(center.y - halfHeight, 0));
    int tileBottom = mapViewPosition.projection.pixelYToTileY(min(
        center.y + halfHeight, mapViewPosition.projection.mapsize.toDouble()));
    if (degreeDiff > 5) {
      // the map is rotated. To avoid empty corners enhance each side by one tile
      tileLeft = max(tileLeft - 1, 0);
      tileRight =
          min(tileRight + 1, Tile.getMaxTileNumber(mapViewPosition.zoomLevel));
      tileTop = max(tileTop - 1, 0);
      tileBottom =
          min(tileBottom + 1, Tile.getMaxTileNumber(mapViewPosition.zoomLevel));
    }
    // shift the center to the left-upper corner of a tile since we will calculate the distance to the left-upper corners of each tile
    RelativeMappoint relative = center.offset(-MapsforgeConstants().tileSize / 2,
        -MapsforgeConstants().tileSize / 2);
    Map<Tile, double> tileMap = Map<Tile, double>();
    for (int tileY = tileTop; tileY <= tileBottom; ++tileY) {
      for (int tileX = tileLeft; tileX <= tileRight; ++tileX) {
        Tile tile = Tile(tileX, tileY, zoomLevel, indoorLevel);
        Mappoint leftUpper = mapViewPosition.projection.getLeftUpper(tile);
        tileMap[tile] =
            (pow(leftUpper.x - relative.x, 2) + pow(leftUpper.y - relative.y, 2))
                .toDouble();
      }
    }
    //_log.info("$tileTop, $tileBottom, sort ${tileMap.length} items");

    List<Tile> sortedKeys = tileMap.keys.toList(growable: false)
      ..sort((k1, k2) => tileMap[k1]!.compareTo(tileMap[k2]!));
    _lastBoundary = TileBoundary(
        tileLeft: tileLeft,
        tileRight: tileRight,
        tileTop: tileTop,
        tileBottom: tileBottom);
    return sortedKeys;
  }
}

/////////////////////////////////////////////////////////////////////////////

class _JobQueueInfo {
  JobSet? jobSet;

  bool processing = false;
}

/////////////////////////////////////////////////////////////////////////////

class IsolateParam {
  final Job job;
  final JobRenderer jobRenderer;

  IsolateParam(this.job, this.jobRenderer);
}

/////////////////////////////////////////////////////////////////////////////

///
/// Renders one job and produces the bitmap for the requested tile. In case of errors or no data a special bitmap will be produced.
/// Executes the callback function when finished.
///
Future<JobResult> renderDirect(IsolateParam isolateParam) async {
  final _log = new Logger('JobQueueRender');

  Job job = isolateParam.job;
  int time = DateTime.now().millisecondsSinceEpoch;
  try {
    JobResult jobResult = await isolateParam.jobRenderer.executeJob(job);
    if (jobResult.picture != null) {
      //jobResult.bitmap!.incrementRefCount();
    }
    int diff = DateTime.now().millisecondsSinceEpoch - time;
    if (diff >= 250)
      _log.info("Renderer needed $diff ms for job ${job.toString()}");
    return jobResult;
  } catch (error, stackTrace) {
    _log.warning(error.toString());
    if (stackTrace.toString().length > 0) _log.warning(stackTrace.toString());
    TilePicture bmp =
        await isolateParam.jobRenderer.createErrorBitmap(MapsforgeConstants().tileSize, error);
    //bmp.incrementRefCount();
    return JobResult(bmp, JOBRESULT.ERROR);
  }
}
