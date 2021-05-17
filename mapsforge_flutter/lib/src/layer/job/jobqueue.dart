import 'dart:collection';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttertilebitmap.dart';
import 'package:mapsforge_flutter/src/layer/job/jobset.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';

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

  Subject<JobSet> _injectJobResult = PublishSubject();
  ListQueue<Job> _listQueue = ListQueue();

  JobSet? _currentJobSet;

  late SendPort _sendPort;

  Isolate? _isolate;

  final TileBitmapCache? tileBitmapCache;

  final TileBitmapCache tileBitmapCache1stLevel;

  FlutterTileBitmap? _missingBitmap;

  // we have only one thread, so limit the number of concurrent renderings for now
  final List<Lock> _lock = [Lock()];

  int _roundRobin = 0;

  JobQueue(this.displayModel, this.jobRenderer, this.tileBitmapCache) : tileBitmapCache1stLevel = MemoryTileBitmapCache() {
    //_startIsolateJob();
    for (int i = 0; i < _lock.length; ++i) {
      _lock[i] = Lock();
    }
    // precreate the missing bitmap
    getMissingBitmap(displayModel.tileSize);
  }

  void dispose() {
    if (_isolate != null) {
      _isolate!.kill(priority: Isolate.immediate);
      _isolate = null;
    }
  }

  ///
  /// Called whenever a new bitmap is created
  ///
  Stream<JobSet> get observeJobResult => _injectJobResult.stream;

  TileBitmap? getMissingBitmap(int tileSize) {
    if (_missingBitmap != null) return _missingBitmap!;
    jobRenderer.createMissingBitmap(tileSize).then((TileBitmap value) {
      _missingBitmap = value as FlutterTileBitmap;
    });
    return _missingBitmap;
  }

  ///
  /// Let the queue process this jobset
  void processJobset(JobSet jobSet) {
    // remove all jobs from the queue which are not needed anymore because we want to show another view hence other tiles
    _listQueue.clear();
    //_listQueue.removeWhere((element) => !jobSet.jobs.contains(element));
    // now add all new jobs to queue
    Map<Job, TileBitmap> toRemove = Map();
    jobSet.jobs.where((job) => !_listQueue.contains(job)).forEach((job) {
      TileBitmap? tileBitmap = tileBitmapCache1stLevel.getTileBitmapSync(job.tile);
      if (tileBitmap != null) {
        toRemove[job] = tileBitmap;
      } else {
        _listQueue.add(job);
      }
    });

    toRemove.forEach((key, value) {
      jobSet.removeJob(key, value);
    });
    //_log.info("Starting jobSet $jobSet");
    _currentJobSet?.dispose();
    _currentJobSet = jobSet;
    _startNextJob(jobSet);

    // in the meantime return the found jobs
    if (toRemove.length > 0) {
      _injectJobResult.add(jobSet);
    }
  }

  void _startNextJob(JobSet jobSet) {
    //_log.info("ListQueue has ${_listQueue.length} elements");
    if (_listQueue.isEmpty) return;
    // let the job in the queue until it is finished, so we prevent adding the job to the queue again
    _lock[_roundRobin++ % _lock.length].synchronized(() async {
      // recheck, it may have changed in the meantime
      if (_listQueue.isEmpty) return;
      Job nextJob = _listQueue.first;
      //_log.info("taken ${nextJob?.toString()} from queue");
      try {
//     await _donow3(item);
//     await _donow(item);
        await _donowDirect(jobSet, nextJob);
      } catch (e, stacktrace) {
        _log.warning("$e\n$stacktrace");
      }
      _listQueue.remove(nextJob);
      //_log.info("taken ${nextJob?.toString()} from queue finished");
    });
  }

  Future<void> _donowViaIsolate(JobSet jobSet, Job job) async {
    TileBitmap? tileBitmap = await tileBitmapCache?.getTileBitmapAsync(job.tile);
    if (tileBitmap != null) {
      _currentJobSet!.removeJob(job, tileBitmap);
      _injectJobResult.add(_currentJobSet!);
      _startNextJob(jobSet);
      return;
    }
    _sendPort.send(IsolateParam(job, jobRenderer));
  }

  Future<void> _donowDirect(JobSet jobSet, Job job) async {
    TileBitmap? tileBitmap = await tileBitmapCache?.getTileBitmapAsync(job.tile);
    if (tileBitmap != null) {
      _currentJobSet!.removeJob(job, tileBitmap);
      tileBitmapCache1stLevel.addTileBitmap(job.tile, tileBitmap);
      _injectJobResult.add(_currentJobSet!);
      _startNextJob(jobSet);
      return;
    }
    tileBitmap = await renderDirect(IsolateParam(job, jobRenderer));
    tileBitmapCache1stLevel.addTileBitmap(job.tile, tileBitmap);
    tileBitmapCache?.addTileBitmap(job.tile, tileBitmap);
    _currentJobSet!.removeJob(job, tileBitmap);
    _injectJobResult.add(_currentJobSet!);
    //_log.info("Job executed with bitmap");
    _startNextJob(jobSet);
  }

  void _donowViaCompute(JobSet jobSet, Job job) async {
    TileBitmap? tileBitmap = await tileBitmapCache?.getTileBitmapAsync(job.tile);
    if (tileBitmap != null) {
      _currentJobSet!.removeJob(job, tileBitmap);
      _injectJobResult.add(_currentJobSet!);
      _startNextJob(jobSet);
      return;
    }
    // Job result = await compute(renderDirect, IsolateParam(job, jobRenderer));
    // if (result.hasTileBitmap()) {
    //   tileBitmapCache.addTileBitmap(job.tile, result.getTileBitmap());
    //   _injectJobResult.add(result);
    //   // _log.info("Job executed with bitmap");
    // } else {
    //   // _log.warning("Job executed without bitmap");
    // }
    _startNextJob(jobSet);
  }

  ///
  /// Isolates currently not suitable for our purpose. Most UI canvas calls are not accessible from isolates
  /// so we cannot produce the bitmap.
  void _startIsolateJob() async {
    var receivePort = new ReceivePort();
    _isolate = await Isolate.spawn(entryPoint, receivePort.sendPort);

    await for (var data in receivePort) {
      //tileCache.addTileBitmap(job.tile, tileBitmap);
      print("received from isolate: ${data.toString()}");
      if (data is SendPort) {
        // Receive the SendPort from the Isolate
        _sendPort = data;
      } else if (data is TileBitmap) {
        TileBitmap bmp = data;
        // tileBitmapCache.addTileBitmap(job.tile, bmp);
        // _injectJobResult.add(job);
        // _log.info("Job executed with bitmap");
        //_startNextJob();
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

  // Listen for messages (optional)
  await for (IsolateParam isolateParam in receivePort as Stream<IsolateParam>) {
    //print("hello, we received $isolateParam in the isolate");
    TileBitmap bmp = await renderDirect(isolateParam);
    sendPort.send(bmp);
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
Future<TileBitmap> renderDirect(IsolateParam isolateParam) async {
  // _lock[++_roundRobin % _lock.length].synchronized(() async {
  Job job = isolateParam.job;
//  if (job.hasTileBitmap()) {
//    return job;
//  }
  //_log.info("Processing tile ${job.tile.toString()}");
//  TileBitmap tileBitmap = await isolateParam.tileBitmapCache.getTileBitmapAsync(job.tile);
//  if (tileBitmap != null) {
//    job.tileBitmap = tileBitmap;
//    return job;
//  }
  int time = DateTime.now().millisecondsSinceEpoch;
  try {
    TileBitmap? tileBitmap = await isolateParam.jobRenderer.executeJob(job);
    if (tileBitmap != null) {
      int diff = DateTime.now().millisecondsSinceEpoch - time;
//      if (diff >= 100) _log.info("Renderer needed $diff ms for job ${job.toString()}");
      //isolateParam.tileBitmapCache.addTileBitmap(job.tile, tileBitmap);
      return tileBitmap;
    } else {
      // no datastore for that tile
      int diff = DateTime.now().millisecondsSinceEpoch - time;
//      if (diff >= 100) _log.info("Renderer needed $diff ms for non-existent job ${job.toString()}");
      TileBitmap bmp = await isolateParam.jobRenderer.createNoDataBitmap(job.tileSize);
      //isolateParam.tileBitmapCache.addTileBitmap(job.tile, bmp);
      //bmp.incrementRefCount();
      return bmp;
    }
  } catch (error, stackTrace) {
    print(error.toString());
    print(stackTrace.toString());
    TileBitmap bmp = await isolateParam.jobRenderer.createErrorBitmap(job.tileSize, error);
    bmp.incrementRefCount();
    return bmp;
  }
}
