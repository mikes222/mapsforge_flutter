import 'package:execution_queue/execution_queue.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/layer/job/jobresult.dart';
import 'package:mapsforge_flutter/src/layer/job/jobset.dart';

import '../../cache/tilebitmapcache.dart';
import '../../graphics/tilebitmap.dart';
import '../../model/displaymodel.dart';
import 'job.dart';
import 'jobrenderer.dart';

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

  final ExecutionQueue _executionQueue = ExecutionQueue();

  JobQueue(this.displayModel, this.jobRenderer, this.tileBitmapCache)
      : tileBitmapCache1stLevel = MemoryTileBitmapCache() {}

  void dispose() {}

  ///
  /// Called whenever a new bitmap is created
  ///
  //Stream<JobSet> get observeJobResult => _injectJobResult.stream;

  ///
  /// Let the queue process this jobset
  void processJobset(JobSet jobSet) {
    // now add all new jobs to queue
    Map<Job, TileBitmap> toRemove = Map();
    jobSet.jobs.forEach((job) {
      TileBitmap? tileBitmap =
          tileBitmapCache1stLevel.getTileBitmapSync(job.tile);
      if (tileBitmap != null) {
        toRemove[job] = tileBitmap;
      }
    });

    toRemove.forEach((key, value) {
      jobSet.jobFinished(key, JobResult(value, JOBRESULT.NORMAL));
    });
    //_log.info("Starting jobSet $jobSet");
    _currentJobSet?.removeJobs();
    _currentJobSet = jobSet;
    _executionQueue.add(() => _startNextJob(jobSet));
  }

  void _startNextJob(JobSet jobSet) async {
    //_log.info("ListQueue has ${_listQueue.length} elements");
    if (jobSet.jobs.isEmpty) return;
    Job nextJob = jobSet.jobs.first;
    //_log.info("taken ${nextJob?.toString()} from queue");
    try {
      await _donowDirect(jobSet, nextJob);
    } catch (e, stacktrace) {
      _log.warning("$e\n$stacktrace");
    }
  }

  Future<void> _donowDirect(JobSet jobSet, Job job) async {
    TileBitmap? tileBitmap =
        await tileBitmapCache?.getTileBitmapAsync(job.tile);
    if (tileBitmap != null) {
      tileBitmapCache1stLevel.addTileBitmap(job.tile, tileBitmap);
      jobSet.jobFinished(job, JobResult(tileBitmap, JOBRESULT.NORMAL));
      _executionQueue.add(() => _startNextJob(jobSet));
      return;
    }
    JobResult jobResult = await renderDirect(IsolateParam(job, jobRenderer));
    if (jobResult.result == JOBRESULT.NORMAL) {
      tileBitmapCache1stLevel.addTileBitmap(job.tile, jobResult.bitmap!);
      tileBitmapCache?.addTileBitmap(job.tile, jobResult.bitmap!);
    }
    if (jobResult.result == JOBRESULT.ERROR ||
        jobResult.result == JOBRESULT.UNSUPPORTED) {
      tileBitmapCache1stLevel.addTileBitmap(job.tile, jobResult.bitmap!);
    }
    jobSet.jobFinished(job, jobResult);
    _executionQueue.add(() => _startNextJob(jobSet));
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
      int diff = DateTime.now().millisecondsSinceEpoch - time;
      if (diff >= 250)
        _log.info("Renderer needed $diff ms for job ${job.toString()}");
      //isolateParam.tileBitmapCache.addTileBitmap(job.tile, tileBitmap);
      jobResult.bitmap!.incrementRefCount();
      return jobResult;
    } else {
      // no datastore for that tile
      int diff = DateTime.now().millisecondsSinceEpoch - time;
      if (diff >= 250)
        _log.info(
            "Renderer needed $diff ms for non-existent job ${job.toString()}");
      TileBitmap bmp =
          await isolateParam.jobRenderer.createNoDataBitmap(job.tileSize);
      //isolateParam.tileBitmapCache.addTileBitmap(job.tile, bmp);
      bmp.incrementRefCount();
      return JobResult(bmp, JOBRESULT.UNSUPPORTED);
    }
  } catch (error, stackTrace) {
    _log.warning(error.toString());
    if (stackTrace.toString().length > 0) _log.warning(stackTrace.toString());
    TileBitmap bmp =
        await isolateParam.jobRenderer.createErrorBitmap(job.tileSize, error);
    bmp.incrementRefCount();
    return JobResult(bmp, JOBRESULT.ERROR);
  }
}
