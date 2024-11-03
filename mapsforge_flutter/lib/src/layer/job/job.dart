import 'package:mapsforge_flutter/src/model/tile.dart';

///
/// A job is a job to produce or retrieve a bitmap for a tile
///
class Job {

  /// not used anymore
  final bool hasAlpha;

  /// A tile.
  final Tile tile;

  const Job._(this.tile, this.hasAlpha);

  factory Job(Tile tile, bool alpha) {
    Job job = Job._(tile, alpha);
    return job;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Job &&
              runtimeType == other.runtimeType &&
              hasAlpha == other.hasAlpha &&
              tile == other.tile;

  @override
  int get hashCode => hasAlpha.hashCode ^ tile.hashCode;

  @override
  String toString() {
    return 'Job{hasAlpha: $hasAlpha, tile: $tile}';
  }
}
