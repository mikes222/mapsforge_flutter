import 'package:mapsforge_flutter/src/cache/tilecache.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/model/displaymodel.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';

import 'job.dart';
import 'jobrenderer.dart';

class JobQueue {
  final DisplayModel displayModel;
  final TileCache tileCache;
  final JobRenderer jobRenderer;

  Subject<JobQueueItem> _inject = PublishSubject();
  Subject<Job> _injectJob = PublishSubject();
  Observable<Job> _observe;

  static final List<Lock> _lock = List(4);

  static int _roundRobin = 0;

  JobQueueItem _lastItem;

  JobQueue(this.displayModel, this.tileCache, this.jobRenderer)
      : assert(displayModel != null),
        assert(tileCache != null),
        assert(jobRenderer != null) {
    for (int i = 0; i < _lock.length; ++i) {
      _lock[i] = Lock();
    }
    _inject.listen((JobQueueItem item) {
      process(item);
    });
    _observe = _injectJob.asBroadcastStream();
  }

  Observable<Job> get observe => _observe;

  void add(Job job) {
    Set<Job> jobs = Set();
    jobs.add(job);
    _inject.add(JobQueueItem(jobs));
  }

  void addJobs(Set<Job> jobs) {
    if (jobs.length == 0) return;
    if (_lastItem != null) {
      _lastItem.outdated = true;
    }
    _lastItem = JobQueueItem(jobs);
    _inject.add(_lastItem);
  }

  void process(JobQueueItem item) async {
    for (Job job in item.jobs) {
      _lock[++_roundRobin % _lock.length].synchronized(() async {
        if (item.outdated) return null;
        TileBitmap tileBitmap = tileCache.getTileBitmap(job.tile.tileX, job.tile.tileY, job.tile.zoomLevel);
        if (tileBitmap != null) {
          return job;
        }
        tileBitmap = await jobRenderer.executeJob(job);
        if (tileBitmap != null) {
          tileCache.addTileBitmap(job.tile, tileBitmap);
          _injectJob.add(job);
        }
        return job;
      });
    }
  }
}

/////////////////////////////////////////////////////////////////////////////

class JobQueueItem {
  final Set<Job> jobs;

  bool outdated = false;

  JobQueueItem(this.jobs);
}
