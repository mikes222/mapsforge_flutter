import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

///
/// A JobSet is a collection of one or more jobs which belongs together. When the map should be shown on screen,
/// the screen is split into Tiles and a job for each tile is created. All this jobs form a jobSet.
/// If the screen changes (move, zoom or changes its size) a totally different jobset may be needed and the old jobset does not
/// need to be finished.
///
class JobSet {
  final List<Job> jobs = List();

  /// The resulting bitmaps after the jobs has been processed.
  final Map<Tile, TileBitmap> _bitmaps = Map();

  void add(Job job) {
    jobs.add(job);
  }

  void removeJob(Job job, TileBitmap tileBitmap) {
    assert(tileBitmap != null);
    assert(job != null);
    jobs.remove(job);
    tileBitmap.incrementRefCount();
    TileBitmap old = _bitmaps[job.tile];
    if (old != null) {
      old.decrementRefCount();
    }
    _bitmaps[job.tile] = tileBitmap;
  }

  TileBitmap getTileBitmap(Tile tile) {
    return _bitmaps[tile];
  }

  @mustCallSuper
  void dispose() {
    _bitmaps.values.forEach((element) {
      element.decrementRefCount();
    });
  }

  Map<Tile, TileBitmap> get bitmaps => _bitmaps;
}
