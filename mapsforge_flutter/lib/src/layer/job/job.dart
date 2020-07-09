import 'package:dcache/dcache.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

///
/// A job is a job to produce or retrieve a bitmap for a tile
///
class Job {
  final bool hasAlpha;
  final double textScale;
  final Tile tile;

  /// The resulting bitmap after this job has been processed.
  TileBitmap _tileBitmap;

  static final Cache jobs = new SimpleCache<Tile, Job>(
      storage: new SimpleStorage<Tile, Job>(size: 1000),
      onEvict: (key, Job item) {
        item.getAndRemovetileBitmap();
      });

  Job._(this.tile, this.hasAlpha, this.textScale)
      : assert(tile != null),
        assert(hasAlpha != null);

  factory Job(Tile tile, bool alpha, double scaleFactor) {
    Job job = jobs[tile];
    if (job != null) {
      return job;
    }
    job = Job._(tile, alpha, scaleFactor);
    jobs[tile] = job;
    return job;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Job && runtimeType == other.runtimeType && hasAlpha == other.hasAlpha && tile == other.tile;

  @override
  int get hashCode => hasAlpha.hashCode ^ tile.hashCode;

  @override
  String toString() {
    return 'Job{hasAlpha: $hasAlpha, tile: $tile}';
  }

  set tileBitmap(TileBitmap tileBitmap) {
    if (tileBitmap != null) {
      tileBitmap.incrementRefCount();
    }
    if (_tileBitmap != null) {
      _tileBitmap.decrementRefCount();
    }
    _tileBitmap = tileBitmap;
  }

  TileBitmap getAndRemovetileBitmap() {
    if (_tileBitmap == null) return null;
    TileBitmap result = _tileBitmap;
    _tileBitmap = null;
    return result;
  }

  TileBitmap getTileBitmap() {
    return _tileBitmap;
  }

  bool hasTileBitmap() {
    return _tileBitmap != null;
  }
}
