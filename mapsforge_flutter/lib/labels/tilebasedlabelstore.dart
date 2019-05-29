import 'dart:core';
import 'dart:core';

import '../mapelements/mapelementcontainer.dart';
import '../model/tile.dart';
import '../utils/layerutil.dart';
import '../utils/workingsetcache.dart';

import 'labelstore.dart';

/**
 * A LabelStore where the data is stored per tile.
 */

class TileBasedLabelStore
    extends WorkingSetCache<Tile, List<MapElementContainer>>
    implements LabelStore {
  Set<Tile> lastVisibleTileSet;
  int version;

  TileBasedLabelStore(int capacity) : super(capacity) {
    lastVisibleTileSet = new Set<Tile>();
  }

  void destroy() {
    this.clear();
  }

  /**
   * Stores a list of MapElements against a tile.
   *
   * @param tile     tile on which the mapItems reside.
   * @param mapItems the map elements.
   */
  void storeMapItems(Tile tile, List<MapElementContainer> mapItems) {
    this.put(tile, LayerUtil.collisionFreeOrdered(mapItems));
    this.version += 1;
  }

  @override
  int getVersion() {
    return this.version;
  }

  @override
  List<MapElementContainer> getVisibleItems(Tile upperLeft, Tile lowerRight) {
    return getVisibleItemsInternal(
        LayerUtil.getTilesByTile(upperLeft, lowerRight));
  }

  List<MapElementContainer> getVisibleItemsInternal(Set<Tile> tiles) {
    lastVisibleTileSet = tiles;

    List<MapElementContainer> visibleItems = new List<MapElementContainer>();
    for (Tile tile in lastVisibleTileSet) {
      if (containsKey(tile)) {
        visibleItems.addAll(get(tile));
      }
    }
    return visibleItems;
  }

  /**
   * Returns if a tile is in the current tile set and no data is stored for this tile.
   *
   * @param tile the tile
   * @return true if the tile is in the current tile set, but no data is stored for it.
   */
  bool requiresTile(Tile tile) {
    return this.lastVisibleTileSet.contains(tile) && !this.containsKey(tile);
  }

//  @override
//  bool removeEldestEntry(Map.Entry<Tile, List<MapElementContainer>> eldest) {
//    if (size() > this.capacity) {
//      return true;
//    }
//    return false;
//  }
}
