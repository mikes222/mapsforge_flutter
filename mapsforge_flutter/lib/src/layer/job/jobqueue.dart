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

  Subject<Set<Job>> _inject = PublishSubject();
  Subject<Job> _injectJob = PublishSubject();
  Observable<Job> _observe;

  static final List<Lock> _lock = List(4);

  static int _roundRobin = 0;

  JobQueue(this.displayModel, this.tileCache, this.jobRenderer)
      : assert(displayModel != null),
        assert(tileCache != null),
        assert(jobRenderer != null) {
    for (int i = 0; i < _lock.length; ++i) {
      _lock[i] = Lock();
    }
    _inject.listen((Set<Job> jobs) {
      process(jobs);
    });
    _observe = _injectJob.asBroadcastStream();
  }

  Observable<Job> get observe => _observe;

  void add(Job job) {
    Set<Job> jobs = Set();
    jobs.add(job);
    addJobs(jobs);
  }

  void addJobs(Set<Job> jobs) {
    if (jobs.length == 0) return;
    _inject.add(jobs);
  }

  process(Set<Job> jobs) async {
    for (Job job in jobs) {
      _lock[++_roundRobin % _lock.length].synchronized(() async {
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
