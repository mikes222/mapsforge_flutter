import 'dart:core';

import 'package:ecache/ecache.dart';
import 'package:logging/logging.dart';

import '../../maps.dart';
import '../model/tile.dart';
import '../rendertheme/renderinfo.dart';
import '../utils/layerutil.dart';
import 'labelstore.dart';

/// A LabelStore where the data is stored per tile.
class TileBasedLabelStore implements LabelStore {
  static final _log = new Logger('TileBasedLabelStore');
  final Storage<Tile, List<RenderInfo>> storage =
      StatisticsStorage<Tile, List<RenderInfo>>();
  late LruCache<Tile, List<RenderInfo>> _cache;

  late Set<Tile> lastVisibleTileSet;
  int version = 0;

  void debug() {
    _log.info("version: $version, items in Cache: ${_cache.length}");
    lastVisibleTileSet.forEach((element) {
      _log.info("LastVisibleTile: $element");
    });
    storage.keys.forEach((key) {
      _log.info("Storage: $key - ${storage.get(key)!.value!.length} items");
    });
  }

  TileBasedLabelStore(int capacity) {
    _cache = new LruCache<Tile, List<RenderInfo>>(
      storage: storage,
      capacity: capacity,
    );
    lastVisibleTileSet = new Set<Tile>();
  }

  void destroy() {
    print("Statistics for TileBasedLabelStore: ${_cache.storage.toString()}");
    _cache.clear();
  }

  @override
  void clear() {
    print("Statistics for TileBasedLabelStore: ${_cache.storage.toString()}");
    _cache.clear();
  }

  /**
   * Stores a list of MapElements against a tile.
   *
   * @param tile     tile on which the mapItems reside.
   * @param mapItems the map elements.
   */
  void storeMapItems(
      Tile tile, List<RenderInfo> mapItems, PixelProjection projection) {
    _cache.set(tile, LayerUtil.collisionFreeOrdered(mapItems, projection));
    ++this.version;
  }

  @override
  int getVersion() {
    return this.version;
  }

  @override
  List<RenderInfo> getVisibleItems(Tile upperLeft, Tile lowerRight) {
    return getVisibleItemsInternal(
        LayerUtil.getTilesByTile(upperLeft, lowerRight));
  }

  List<RenderInfo> getVisibleItemsInternal(Set<Tile> tiles) {
    lastVisibleTileSet = tiles;

    List<RenderInfo> visibleItems = [];
    for (Tile tile in lastVisibleTileSet) {
      if (_cache.containsKey(tile)) {
        visibleItems.addAll(_cache.get(tile)!);
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
    return this.lastVisibleTileSet.contains(tile) && !_cache.containsKey(tile);
  }
}
