import 'dart:isolate';

import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/layer/cache/memorybitmapcache.dart';
import 'package:mapsforge_flutter/src/model/displaymodel.dart';
import 'package:mapsforge_flutter/src/renderer/dummyrenderer.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';

import 'job.dart';
import 'jobrenderer.dart';

class JobQueue {
  final DisplayModel displayModel;
  final JobRenderer jobRenderer;

  Subject<JobQueueItem> _inject = PublishSubject();
  Subject<Job> _injectJob = PublishSubject();
  Observable<Job> _observe;

  JobQueueItem _lastItem;

  SendPort _sendPort;

  Isolate _isolate;

  StaticRenderClass _renderClass;

  JobQueue(this.displayModel, this.jobRenderer)
      : assert(displayModel != null),
        assert(jobRenderer != null),
        _renderClass = StaticRenderClass(jobRenderer: jobRenderer) {
    _inject.listen((JobQueueItem item) {
      process(item);
    });
    _observe = _injectJob.asBroadcastStream();
    //_startIsolate();
  }

  void dispose() {
    if (_isolate != null) {
      _isolate.kill(priority: Isolate.immediate);
      _isolate = null;
    }
  }

  Observable<Job> get observeJob => _observe;

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

  void process(JobQueueItem item) async {
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
  final List<Lock> _lock = List(4);

  int _roundRobin = 0;

  MemoryBitmapCache bitmapCache = MemoryBitmapCache();

  final JobRenderer jobRenderer;

  StaticRenderClass({@required this.jobRenderer}) : assert(jobRenderer != null) {
    for (int i = 0; i < _lock.length; ++i) {
      _lock[i] = Lock();
    }
  }

  void render(JobQueueItem item, Callback callback) {
    for (Job job in item.jobs) {
      _lock[++_roundRobin % _lock.length].synchronized(() async {
        if (item.outdated) return null;
        TileBitmap tileBitmap = bitmapCache.getTileBitmap(job.tile);
        if (tileBitmap != null) {
          job.tileBitmap = tileBitmap;
          callback(job);
          return job;
        }
        tileBitmap = await jobRenderer.executeJob(job);
        if (tileBitmap != null) {
          bitmapCache.addTileBitmap(job.tile, tileBitmap);
          job.tileBitmap = tileBitmap;
          callback(job);
        }
        return job;
      });
    }
  }
}

/////////////////////////////////////////////////////////////////////////////

class JobQueueItem {
  final List<Job> jobs;

  bool outdated = false;

  JobQueueItem(this.jobs);
}
