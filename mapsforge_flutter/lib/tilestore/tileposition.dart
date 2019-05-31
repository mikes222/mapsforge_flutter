import '../model/mappoint.dart';
import '../model/tile.dart';

class TilePosition {
  final Mappoint point;
  final Tile tile;

  TilePosition(this.tile, this.point);

  @override
  String toString() {
    return 'TilePosition{point: $point, tile: $tile}';
  }
}
