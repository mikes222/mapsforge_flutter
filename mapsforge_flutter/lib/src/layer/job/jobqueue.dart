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

  Subject<Job> _inject = PublishSubject();
  Observable<Job> _observe;

  static final Lock _lock = Lock();

  JobQueue(this.displayModel, this.tileCache, this.jobRenderer)
      : assert(displayModel != null),
        assert(tileCache != null),
        assert(jobRenderer != null) {
    _observe = _inject.asyncMap(process).asBroadcastStream();
  }

  Observable<Job> get observe => _observe;

  void add(Job job) {
    _inject.add(job);
  }

  Future<Job> process(Job job) async {
    Job result = await _lock.synchronized(() async {
      TileBitmap tileBitmap = tileCache.getTileBitmap(job.tile.tileX, job.tile.tileY, job.tile.zoomLevel);
      if (tileBitmap != null) {
        return job;
      }
      tileBitmap = await jobRenderer.executeJob(job);
      if (tileBitmap != null) tileCache.addTileBitmap(job.tile, tileBitmap);
      return job;
    });
    return result;
  }
}
