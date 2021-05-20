import 'dart:core';

import 'package:ecache/ecache.dart';
import 'package:logging/logging.dart';

import '../mapelements/mapelementcontainer.dart';
import '../model/tile.dart';
import '../utils/layerutil.dart';
import 'labelstore.dart';

/// A LabelStore where the data is stored per tile.
class TileBasedLabelStore implements LabelStore {
  static final _log = new Logger('TileBasedLabelStore');
  final SimpleStorage<Tile, List<MapElementContainer>> storage = SimpleStorage<Tile, List<MapElementContainer>>();
  late Cache<Tile, List<MapElementContainer>> _items;

  late Set<Tile> lastVisibleTileSet;
  int version = 0;

  void debug() {
    _log.info("version: $version, items in Cache: ${_items.length}");
    lastVisibleTileSet.forEach((element) {
      _log.info("LastVisibleTile: $element");
    });
    storage.keys.forEach((key) {
      _log.info("Storage: $key - ${storage.get(key)!.value!.length} items");
    });
  }

  TileBasedLabelStore(int capacity) {
    _items = new LruCache<Tile, List<MapElementContainer>>(
      storage: storage,
      capacity: capacity,
    );
    lastVisibleTileSet = new Set<Tile>();
  }

  void destroy() {
    _items.clear();
  }

  @override
  void clear() {
    _items.clear();
  }

  /**
   * Stores a list of MapElements against a tile.
   *
   * @param tile     tile on which the mapItems reside.
   * @param mapItems the map elements.
   */
  void storeMapItems(Tile tile, List<MapElementContainer> mapItems) {
    _items.set(tile, LayerUtil.collisionFreeOrdered(mapItems));
    ++this.version;
  }

  @override
  int getVersion() {
    return this.version;
  }

  @override
  List<MapElementContainer> getVisibleItems(Tile upperLeft, Tile lowerRight) {
    return getVisibleItemsInternal(LayerUtil.getTilesByTile(upperLeft, lowerRight));
  }

  List<MapElementContainer> getVisibleItemsInternal(Set<Tile> tiles) {
    lastVisibleTileSet = tiles;

    List<MapElementContainer> visibleItems = [];
    for (Tile tile in lastVisibleTileSet) {
      if (_items.containsKey(tile)) {
        visibleItems.addAll(_items.get(tile)!);
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
    return this.lastVisibleTileSet.contains(tile) && !_items.containsKey(tile);
  }
}
