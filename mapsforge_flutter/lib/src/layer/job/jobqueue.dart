import 'dart:isolate';

import 'package:dcache/dcache.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/layer/cache/bitmapcache.dart';
import 'package:mapsforge_flutter/src/model/displaymodel.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';
import 'package:mapsforge_flutter/src/renderer/dummyrenderer.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';

import 'job.dart';
import 'jobrenderer.dart';

class JobQueue {
  static final _log = new Logger('JobQueue');

  final DisplayModel displayModel;
  final JobRenderer jobRenderer;

  Subject<JobQueueItem> _inject = PublishSubject();
  Subject<Job> _injectJob = PublishSubject();
  Observable<Job> _observeJob;

  JobQueueItem _lastItem;

  SendPort _sendPort;

  Isolate _isolate;

  StaticRenderClass _renderClass;

  final Cache jobs = new SimpleCache<Tile, Job>(
      storage: new SimpleStorage<Tile, Job>(size: 1000),
      onEvict: (key, item) {
        item.getAndRemovetileBitmap();
      });

  JobQueue(this.displayModel, this.jobRenderer, BitmapCache bitmapCache)
      : assert(displayModel != null),
        assert(jobRenderer != null),
        _renderClass = StaticRenderClass(jobRenderer: jobRenderer, bitmapCache: bitmapCache) {
    _inject.listen((JobQueueItem item) {
      _process(item);
    });
    _observeJob = _injectJob.asBroadcastStream();
    //_startIsolate();
  }

  void dispose() {
    if (_isolate != null) {
      _isolate.kill(priority: Isolate.immediate);
      _isolate = null;
    }
  }

  Job createJob(Tile tile) {
    Job job = jobs[tile];
    if (job != null) {
      return job;
    }
    job = Job(tile, true);
    jobs[tile] = job;
    return job;
  }

  Observable<Job> get observeJob => _observeJob;

  void add(Job job) {
    List<Job> jobs = List();
    jobs.add(job);
    _inject.add(JobQueueItem(jobs));
  }

  void addJobs(List<Job> jobs) {
    if (jobs.length == 0) return;
    if (_lastItem != null) {
      _lastItem.outdated = true;
    }
    _lastItem = JobQueueItem(jobs);
    _inject.add(_lastItem);
  }

  void _process(JobQueueItem item) async {
    // _sendPort.send(item);
    _renderClass.render(item, (job) {
      _injectJob.add(job);
    });
  }

  void _startIsolate() async {
    var receivePort = new ReceivePort();
    _isolate = await Isolate.spawn(entryPoint, receivePort.sendPort);

    await for (var data in receivePort) {
      //tileCache.addTileBitmap(job.tile, tileBitmap);
      print("received from isolate: ${data.toString()}");
      if (data is SendPort) {
        // Receive the SendPort from the Isolate
        _sendPort = data;
      } else if (data is Job) {
        Job job = data;
        _injectJob.add(job);
      }
    }
  }
}

/////////////////////////////////////////////////////////////////////////////

/// see https://github.com/flutter/flutter/issues/13937
// Entry point for your Isolate
entryPoint(SendPort sendPort) async {
  // Open the ReceivePort to listen for incoming messages (optional)
  var receivePort = new ReceivePort();

  // Send messages to other Isolates
  sendPort.send(receivePort.sendPort);

  StaticRenderClass _renderClass = StaticRenderClass(jobRenderer: DummyRenderer());

  // Listen for messages (optional)
  await for (JobQueueItem item in receivePort) {
    print("hello, we received $item in the isolate");
    _renderClass.render(item, (job) {
      sendPort.send(job);
    });
  }
}

/////////////////////////////////////////////////////////////////////////////

typedef void Callback(Job job);

/////////////////////////////////////////////////////////////////////////////

class StaticRenderClass {
  static final _log = new Logger('StaticRenderClass');

  // we have only one thread, so limit the number of concurrent renderings for now
  final List<Lock> _lock = List(1);

  int _roundRobin = 0;

  final BitmapCache bitmapCache;

  final JobRenderer jobRenderer;

  StaticRenderClass({@required this.jobRenderer, @required this.bitmapCache})
      : assert(jobRenderer != null),
        assert(bitmapCache != null) {
    for (int i = 0; i < _lock.length; ++i) {
      _lock[i] = Lock();
    }
  }

  void render(JobQueueItem item, Callback callback) async {
    for (Job job in item.jobs) {
      // _lock[++_roundRobin % _lock.length].synchronized(() async {
      if (item.outdated) return;
      if (job.hasTileBitmap()) {
        callback(job);
        return;
      }
      if (job.inWork) {
        return;
      }
      TileBitmap tileBitmap = await bitmapCache.getTileBitmapAsync(job.tile);
      if (tileBitmap != null) {
        job.tileBitmap = tileBitmap;
        callback(job);
        return;
      }
      int time = DateTime.now().millisecondsSinceEpoch;
      job.inWork = true;
      tileBitmap = await jobRenderer.executeJob(job);
      if (tileBitmap != null) {
        int diff = DateTime.now().millisecondsSinceEpoch - time;
        _log.info("Renderer needed $diff ms for job ${job.toString()}");
        bitmapCache.addTileBitmap(job.tile, tileBitmap);
        job.tileBitmap = tileBitmap;
        job.inWork = false;
        callback(job);
      } else {
        // no datastore for that tile
        TileBitmap bmp = await jobRenderer.getNoDataBitmap(job.tile);
        bmp.incrementRefCount();
        job.tileBitmap = bmp;
        job.inWork = false;
        callback(job);
      }
      //return job;
      //  });
    }
  }
}

/////////////////////////////////////////////////////////////////////////////

class JobQueueItem {
  final List<Job> jobs;

  bool outdated = false;

  JobQueueItem(this.jobs);
}
