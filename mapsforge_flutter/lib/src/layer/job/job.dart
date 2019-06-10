import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

class Job {
  final bool hasAlpha;
  final Tile tile;

  /// The resulting bitmap after this job has been processed.
  TileBitmap _tileBitmap;

  Job(this.tile, this.hasAlpha) : assert(tile != null);

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
}
