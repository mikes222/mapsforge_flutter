import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/layer/job/jobresult.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

///
/// A JobSet is a collection of one or more jobs which belongs together. When the map should be shown on screen,
/// the screen is split into Tiles and a job for each tile is created. All this jobs form a jobSet.
/// If the screen changes (move, zoom or changes its size) a totally different jobset may be needed and the old jobset does not
/// need to be finished.
///
class JobSet extends ChangeNotifier {
  final List<Job> jobs = [];

  /// The resulting bitmaps after the jobs has been processed.
  Map<Tile, JobResult>? _bitmaps = Map();

  void add(Job job) {
    assert(!jobs.contains(job));
    jobs.add(job);
  }

  void jobFinished(Job job, JobResult jobResult) {
    if (_bitmaps == null) return;
    jobs.remove(job);
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
    jobs.clear();
    _bitmaps!.values.forEach((element) {
      //element.bitmap?.decrementRefCount();
    });
    _bitmaps = null;
    super.dispose();
  }

  Map<Tile, JobResult> get results => _bitmaps!;

  void removeJobs() {
    jobs.clear();
    _bitmaps!.values.forEach((element) {
      //element.bitmap?.decrementRefCount();
    });
    _bitmaps!.clear();
  }

  @override
  String toString() {
    return 'JobSet{jobs: $jobs, _bitmaps: $_bitmaps}';
  }
}
