import 'package:mapsforge_flutter/src/model/tile.dart';

class Job {
  final bool hasAlpha;
  final Tile tile;

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
}
