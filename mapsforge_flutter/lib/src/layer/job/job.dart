import 'package:mapsforge_flutter/src/model/tile.dart';

///
/// A job is a job to produce or retrieve a bitmap for a tile
///
class Job {
  final bool hasAlpha;
  final double textScale;
  final Tile tile;
  final double tileSize;

  Job._(this.tile, this.hasAlpha, this.textScale, this.tileSize)
      : assert(tile != null),
        assert(hasAlpha != null),
        assert(tileSize != null && tileSize > 0);

  factory Job(Tile tile, bool alpha, double scaleFactor, double tileSize) {
    Job job = Job._(tile, alpha, scaleFactor, tileSize);
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
}
