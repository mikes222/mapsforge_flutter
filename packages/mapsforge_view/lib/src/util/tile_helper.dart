import 'dart:math';

import 'package:dart_common/model.dart';
import 'package:dart_common/utils.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/tile/tile_dimension.dart';

class TileHelper {
  /// Calculates all tiles needed to display the map on the available view area
  static TileDimension calculateTiles({required MapPosition mapViewPosition, required MapSize screensize}) {
    Mappoint center = mapViewPosition.getCenter();
    double halfWidth = screensize.width / 2;
    double halfHeight = screensize.height / 2;
    if (mapViewPosition.rotation > 2) {
      // we rotate. Use the max side for both width and height
      halfWidth = max(halfWidth, halfHeight);
      halfHeight = halfWidth;
    }
    int tileLeft = mapViewPosition.projection.pixelXToTileX(max(center.x - halfWidth, 0));
    int tileRight = mapViewPosition.projection.pixelXToTileX(min(center.x + halfWidth, mapViewPosition.projection.mapsize.toDouble()));
    int tileTop = mapViewPosition.projection.pixelYToTileY(max(center.y - halfHeight, 0));
    int tileBottom = mapViewPosition.projection.pixelYToTileY(min(center.y + halfHeight, mapViewPosition.projection.mapsize.toDouble()));
    // rising from 0 to 45, then falling to 0 at 90°
    int degreeDiff = 45 - ((mapViewPosition.rotation) % 90 - 45).round().abs();
    if (degreeDiff > 5) {
      // the map is rotated. To avoid empty corners enhance each side by one tile
      int diff = (MapsforgeSettingsMgr().getDeviceScaleFactor().ceil());
      tileLeft = max(tileLeft - diff, 0);
      tileRight = min(tileRight + diff, Tile.getMaxTileNumber(mapViewPosition.zoomLevel));
      tileTop = max(tileTop - diff, 0);
      tileBottom = min(tileBottom + diff, Tile.getMaxTileNumber(mapViewPosition.zoomLevel));
    }
    return TileDimension(left: tileLeft, right: tileRight, top: tileTop, bottom: tileBottom);
  }
}
