import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/layer/job/jobresult.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

import '../../rendertheme/renderinfo.dart';
import '../../rendertheme/shape/shape.dart';

///
/// A JobSet is a collection of one or more jobs which belongs together. When the map should be shown on screen,
/// the screen is split into Tiles and a job for each tile is created. All this jobs form a jobSet.
/// If the screen changes (move, zoom or changes its size) a totally different jobset may be needed and the old jobset does not
/// need to be finished.
///
class JobSet extends ChangeNotifier {
  /// true if we do not need this jobset anymore. Happens if we move the position before the jobset is completed.
  bool _disposed = false;

  /// The jobs to perform where we need images
  final List<Job> _jobs = [];

  /// The jobs where we need labels
  final Set<Job> _labelJobs = {};

  /// The resulting bitmaps after the jobs has been processed.
  Map<Tile, JobResult> _bitmaps = {};

  /// All labels and rendering infos
  List<RenderInfo<Shape>> _renderInfos = [];

  List<Job> get jobs => _jobs;

  Set<Job> get labelJobs => _labelJobs;

  List<RenderInfo>? get renderInfos => _renderInfos;

  void add(Job job) {
    assert(!_jobs.contains(job));
    _jobs.add(job);
    _labelJobs.add(job);
  }

  void renderingJobFinished(Job job, List<RenderInfo> renderInfos) {
    if (_disposed) return;
    if (_labelJobs.contains(job)) {
      _renderInfos.addAll(renderInfos);
      _labelJobs.remove(job);
      notifyListeners();
    }
  }

  void renderingJobsFinished(Map<Job, List<RenderInfo<Shape>>> items) {
    items.forEach((job, renderInfos) {
      if (_labelJobs.contains(job)) {
        _renderInfos.addAll(renderInfos);
        _labelJobs.remove(job);
      }
    });
    notifyListeners();
  }

  void jobFinished(Job job, JobResult jobResult) {
    if (_disposed) return;
    _jobs.remove(job);
    //jobResult.bitmap?.incrementRefCount();
    TileBitmap? old = _bitmaps[job.tile]?.bitmap;
    if (old != null) {
      //old.decrementRefCount();
    }
    _bitmaps[job.tile] = jobResult;
    //print("jobSet job finished ${_bitmaps!.length}");
    notifyListeners();
  }

  void jobsFinished(Map<Job, TileBitmap> jobResults) {
    jobResults.forEach((Job job, TileBitmap tileBitmap) {
      _jobs.remove(job);
      TileBitmap? old = _bitmaps[job.tile]?.bitmap;
      if (old != null) {
        //old.decrementRefCount();
      }
      _bitmaps[job.tile] = JobResult(tileBitmap, JOBRESULT.NORMAL);
    });
    notifyListeners();
  }

  // JobResult? getJobResult(Tile tile) {
  //   return _bitmaps[tile];
  // }

  bool completed() {
    if (_disposed) return false;
    if (_jobs.isNotEmpty) return false;
    if (_labelJobs.isNotEmpty) return false;
    return true;
  }

  @mustCallSuper
  @override
  void dispose() {
    _disposed = true;
    _jobs.clear();
    _labelJobs.clear();
    _bitmaps.values.forEach((element) {
      //element.bitmap?.decrementRefCount();
    });
    _bitmaps.clear();
    super.dispose();
  }

  Map<Tile, JobResult> get bitmaps => _bitmaps;

  // void removeJobs() {
  //   _jobs.clear();
  //   _labelJobs.clear();
  //   _bitmaps.values.forEach((element) {
  //     //element.bitmap?.decrementRefCount();
  //   });
  //   _bitmaps.clear();
  // }

  @override
  String toString() {
    return 'JobSet{jobs: $_jobs, _bitmaps: $_bitmaps}';
  }

  /// https://stackoverflow.com/questions/63884633/unhandled-exception-a-changenotifier-was-used-after-being-disposed
  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}
