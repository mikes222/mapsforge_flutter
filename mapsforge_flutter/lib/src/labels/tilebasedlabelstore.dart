import 'dart:core';

import 'package:ecache/ecache.dart';
import 'package:logging/logging.dart';

import '../layer/job/job.dart';
import '../model/tile.dart';
import '../rendertheme/renderinfo.dart';
import '../rendertheme/shape/shape.dart';
import 'labelstore.dart';

/// A LabelStore where the data is stored per tile.
class TileBasedLabelStore implements LabelStore {
  static final _log = new Logger('TileBasedLabelStore');

  final Storage<Tile, List<RenderInfo>> storage =
      StatisticsStorage<Tile, List<RenderInfo>>();

  late LruCache<Tile, List<RenderInfo>> _cache;

  int version = 0;

  void debug() {
    _log.info("version: $version, items in Cache: ${_cache.length}");
    storage.keys.forEach((key) {
      _log.info("Storage: $key - ${storage.get(key)!.value!.length} items");
    });
  }

  TileBasedLabelStore(int capacity) {
    _cache = new LruCache<Tile, List<RenderInfo>>(
      storage: storage,
      capacity: capacity,
    );
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
  void storeMapItems(Tile tile, List<RenderInfo<Shape>> renderInfos) {
    _cache.set(tile, renderInfos);
    ++this.version;
  }

  @override
  int getVersion() {
    return this.version;
  }

  @override
  Map<Job, List<RenderInfo<Shape>>> getVisibleItems(Set<Job> jobs) {
    Map<Job, List<RenderInfo<Shape>>> visibleItems = {};
    for (Job job in jobs) {
      if (_cache.containsKey(job.tile)) {
        visibleItems[job] = _cache.get(job.tile)!;
      }
    }
    return visibleItems;
  }

  @override
  bool hasTile(Tile tile) {
    return _cache.containsKey(tile);
  }

  List<RenderInfo>? get(Tile tile) {
    return _cache.get(tile);
  }
}
