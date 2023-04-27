import 'dart:async';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/layer/job/jobresult.dart';
import 'package:mapsforge_flutter/src/layer/job/jobset.dart';
import 'package:queue/queue.dart';

import '../../../maps.dart';
import '../../graphics/tilebitmap.dart';
import '../../rendertheme/renderinfo.dart';
import '../../rendertheme/shape/shape.dart';
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

  JobQueue(this.displayModel, this.jobRenderer, this.tileBitmapCache,
      this.tileBitmapCache1stLevel)
      : labelStore = TileBasedLabelStore(1000);

  void dispose() {
    _executionQueue.dispose();
    _currentJobSet?.dispose();
    _currentJobSet = null;
  }

  /// Let the queue process this jobset. A Jobset is a collection of jobs needed to render a whole view. It often consists of several tiles.
  void processJobset(JobSet jobSet) {
    // stop processing the former jobSet
    _currentJobSet?.removeJobs();

    // remove all jobs which can be fulfilled via the 1st level cache
    Map<Job, TileBitmap> toRemove = {};
    jobSet.jobs.forEach((job) {
      TileBitmap? tileBitmap =
          tileBitmapCache1stLevel.getTileBitmapSync(job.tile);
      if (tileBitmap != null) {
        toRemove[job] = tileBitmap;
      }
    });
    toRemove.forEach((Job key, TileBitmap tileBitmap) {
      // we have this already in our 1st level cache
      jobSet.jobFinished(key, JobResult(tileBitmap, JOBRESULT.NORMAL));
    });
    Map<Job, List<RenderInfo<Shape>>> items =
        labelStore.getVisibleItems(jobSet.labelJobs);
    items.forEach((tile, value) {
      jobSet.addLabels(tile, value);
    });
    _currentJobSet = jobSet;
    _executionQueue.add(() async {
      await _startNextJob(jobSet);
    });
  }

  Future<void> _startNextJob(JobSet jobSet) async {
    //_log.info("ListQueue has ${_listQueue.length} elements");
    if (jobSet.jobs.isEmpty) {
      unawaited(_startNextLabelJob(jobSet));
      return;
    }
    Job nextJob = jobSet.jobs.first;
    //_log.info("taken ${nextJob?.toString()} from queue");
    try {
      await _donowDirect(jobSet, nextJob);
    } catch (e, stacktrace) {
      _log.warning("$e\n$stacktrace");
    }
  }

  Future<void> _startNextLabelJob(JobSet jobSet) async {
    if (jobSet.labelJobs.isEmpty) return;
    Job job = jobSet.labelJobs.first;
    JobResult jobResult = await jobRenderer.retrieveLabels(job);
    if (jobResult.renderInfos != null) {
      labelStore.storeMapItems(job.tile, jobResult.renderInfos!);
      jobSet.addLabels(job, jobResult.renderInfos!);
    } else {
      // we have to remove this job even if we do not have labels
      jobSet.labelJobs.remove(job);
    }
    unawaited(_startNextLabelJob(jobSet));
  }

  Future<void> _donowDirect(JobSet jobSet, Job job) async {
    TileBitmap? tileBitmap =
        await tileBitmapCache?.getTileBitmapAsync(job.tile);
    if (tileBitmap != null) {
      tileBitmapCache1stLevel.addTileBitmap(job.tile, tileBitmap);
      jobSet.jobFinished(job, JobResult(tileBitmap, JOBRESULT.NORMAL));
      unawaited(_executionQueue.add(() async {
        await _startNextJob(jobSet);
      }));
      return;
    }
    JobResult jobResult = await renderDirect(IsolateParam(job, jobRenderer));
    if (jobResult.result == JOBRESULT.NORMAL) {
      tileBitmapCache1stLevel.addTileBitmap(job.tile, jobResult.bitmap!);
      tileBitmapCache?.addTileBitmap(job.tile, jobResult.bitmap!);
    }
    if (/*jobResult.result == JOBRESULT.ERROR ||*/
        jobResult.result == JOBRESULT.UNSUPPORTED) {
      tileBitmapCache1stLevel.addTileBitmap(job.tile, jobResult.bitmap!);
    }
    jobSet.jobFinished(job, jobResult);
    if (jobResult.renderInfos != null) {
      labelStore.storeMapItems(job.tile, jobResult.renderInfos!);
      jobSet.addLabels(job, jobResult.renderInfos!);
    }
    unawaited(_executionQueue.add(() async {
      await _startNextJob(jobSet);
    }));
  }
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
    if (jobResult.bitmap != null) {
      //jobResult.bitmap!.incrementRefCount();
    }
    int diff = DateTime.now().millisecondsSinceEpoch - time;
    if (diff >= 250)
      _log.info("Renderer needed $diff ms for job ${job.toString()}");
    return jobResult;
  } catch (error, stackTrace) {
    _log.warning(error.toString());
    if (stackTrace.toString().length > 0) _log.warning(stackTrace.toString());
    TileBitmap bmp =
        await isolateParam.jobRenderer.createErrorBitmap(job.tileSize, error);
    //bmp.incrementRefCount();
    return JobResult(bmp, JOBRESULT.ERROR);
  }
}
