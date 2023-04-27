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
  bool _disposed = false;

  final List<Job> _jobs = [];

  final Set<Job> _labelJobs = {};

  /// The resulting bitmaps after the jobs has been processed.
  Map<Tile, JobResult>? _bitmaps = {};

  List<RenderInfo<Shape>>? _renderInfos;

  List<Job> get jobs => _jobs;

  Set<Job> get labelJobs => _labelJobs;

  List<RenderInfo>? get renderInfos => _renderInfos;

  void add(Job job) {
    assert(!_jobs.contains(job));
    _jobs.add(job);
    _labelJobs.add(job);
  }

  void addLabels(Job job, List<RenderInfo> renderInfos) {
    _renderInfos ??= [];
    if (_labelJobs.contains(job)) {
      _renderInfos!.addAll(renderInfos);
      _labelJobs.remove(job);
      notifyListeners();
    }
  }

  void jobFinished(Job job, JobResult jobResult) {
    if (_bitmaps == null) return;
    _jobs.remove(job);
    //jobResult.bitmap?.incrementRefCount();
    TileBitmap? old = _bitmaps![job.tile]?.bitmap;
    if (old != null) {
      //old.decrementRefCount();
    }
    _bitmaps![job.tile] = jobResult;
    //print("jobSet job finished ${_bitmaps!.length}");
    if (_bitmaps == null) return;
    notifyListeners();
  }

  JobResult? getJobResult(Tile tile) {
    return _bitmaps![tile];
  }

  @mustCallSuper
  @override
  void dispose() {
    _disposed = true;
    _jobs.clear();
    _labelJobs.clear();
    _bitmaps?.values.forEach((element) {
      //element.bitmap?.decrementRefCount();
    });
    _bitmaps = null;
    super.dispose();
  }

  Map<Tile, JobResult> get results => _bitmaps!;

  void removeJobs() {
    _jobs.clear();
    _labelJobs.clear();
    _bitmaps!.values.forEach((element) {
      //element.bitmap?.decrementRefCount();
    });
    _bitmaps!.clear();
  }

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
