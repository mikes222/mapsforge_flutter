import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/src/datastore/datastorereadresult.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';
import 'package:mapsforge_flutter/src/utils/layerutil.dart';
import 'package:mapsforge_flutter/src/indoor/indoornotationmatcher.dart';
import 'package:ecache/ecache.dart';
import 'package:rxdart/rxdart.dart';

/**
 * Class that asynchronously retrieves all available indoor levels inside the tiles
 * currently rendered in the viewport with their mappings
 * These can be accessed via the levelMappings property
 * requires a ViewModel and MapDataStore
 * maximum zoom level of 17 can optionally be overwritten
 */
class LevelDetector {

  // sorts keys automatically from low to high
  final BehaviorSubject<SplayTreeMap<int, String>> levelMappings = new BehaviorSubject<SplayTreeMap<int, String>>.seeded(new SplayTreeMap<int, String>());

  // cache tile level mapping data
  Cache<SimpleTileKey, SplayTreeMap<int, String>> _tileLevelCache = new LruCache<SimpleTileKey, SplayTreeMap<int, String>>(
    storage: SimpleStorage(),
    capacity: 100,
  );

  final ViewModel _viewModel;

  final MapDataStore _mapDataStore;

  final int maxZoomLevel;

  LevelDetector(this._viewModel, this._mapDataStore, [this.maxZoomLevel = 17])  {
    // debounce position change events
    this._viewModel.observePosition.debounceTime(Duration(milliseconds: 150)).listen(_getTileCacheData);
    this._viewModel.observePosition.debounceTime(Duration(milliseconds: 150)).listen(_updateLevelMappings);
  }

  void dispose() {
    _tileLevelCache.clear();
  }

  void _getTileCacheData (MapViewPosition mapViewPosition) {
    if (_viewModel.viewDimension == null || mapViewPosition.zoomLevel < maxZoomLevel) return;

    List<Tile> tiles = LayerUtil.getTiles(_viewModel, mapViewPosition, DateTime.now().millisecondsSinceEpoch);

    // batch all missing tiles together so isolate only needs to be created once for each bundle
    List<Tile> missingTiles = [];

    for (Tile tile in tiles) {
      SimpleTileKey tileKey = SimpleTileKey(tile);
      // if tile cache entry currently does not exist
      if (!_tileLevelCache.containsKey(tileKey)) {
        // add empty cache entry
        _tileLevelCache.set(tileKey, null);
        missingTiles.add(tile);
      }
    }

    // read tile data and parse level mappings in isolate
    // update the empty level cache entry on response
    // trigger level update
    if (missingTiles.isNotEmpty) compute(readAndProcessTileData, new IsolateParam(_mapDataStore, missingTiles)).then((tileLevelMappingsBundle) {
      tileLevelMappingsBundle.forEach((tile, tileLevelMappings) {
        SimpleTileKey tileKey = SimpleTileKey(tile);
        _tileLevelCache.set(tileKey, SplayTreeMap.from(tileLevelMappings));
      });
      _updateLevelMappings();
    });
  }

  void _updateLevelMappings ([MapViewPosition mapViewPosition]) {
    if (_viewModel.viewDimension == null) return;

    List<Tile> tiles = LayerUtil.getTiles(_viewModel, _viewModel.mapViewPosition, DateTime.now().millisecondsSinceEpoch);

    SplayTreeMap<int, String> combinedLevelMappings = new SplayTreeMap<int, String>();

    // if out of min zoom level skip this and return empty map
    if (_viewModel.mapViewPosition.zoomLevel >= maxZoomLevel) {
      for (Tile tile in tiles) {
        SimpleTileKey tileKey = SimpleTileKey(tile);
        SplayTreeMap<int, String> tileLevelMappings = _tileLevelCache.get(tileKey);
        // if one tile cache entry currently does not exist exit this function
        if (tileLevelMappings == null) return;
        // merge mappings with others
        tileLevelMappings.forEach((key, value) {
          // overwrite if value is null or not set
          combinedLevelMappings[key] ??= value;
        });
      }
    }
    // only update if levels differ from previous level mappings
    if (!mapEquals(levelMappings.value, combinedLevelMappings)) {
      levelMappings.add(combinedLevelMappings);
    }
  }
}


/**
 * Use simplified version of Tile class, since the indoor value can be ignored
 **/
class SimpleTileKey {
  int tileX;
  int tileY;
  int zoomLevel;

  SimpleTileKey(Tile tile) {
    tileX = tile.tileX;
    tileY = tile.tileY;
    zoomLevel = tile.zoomLevel;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SimpleTileKey &&
              runtimeType == other.runtimeType &&
              tileX == other.tileX &&
              tileY == other.tileY &&
              zoomLevel == other.zoomLevel;

  @override
  int get hashCode => tileX.hashCode ^ tileY.hashCode ^ zoomLevel.hashCode;
}

/**
 * Structure to pass multiple arguments to an isolate at once
 **/
class IsolateParam {
  final MapDataStore mapDataStore;
  final List<Tile> tiles;

  IsolateParam(this.mapDataStore, this.tiles);
}


/**
 * This function is supposed to run in a separated isolate
 * It returns a normal map since a splaytreemap is not supported for isolate data exchange
 * returns a map containing the Tiles as the key and the level mappings as the value
 **/
Future<Map<Tile, Map <int, String>>> readAndProcessTileData (IsolateParam isolateParam) async {
  final Map<Tile, Map <int, String>> tileLevelMappingsBundle = new Map<Tile, Map <int, String>>();

  for (Tile tile in isolateParam.tiles) {
    final DatastoreReadResult mapReadResult = await isolateParam.mapDataStore.readMapDataSingle(tile);

    tileLevelMappingsBundle[tile] = new  Map <int, String>();

    void processTags (List tags) {
      String levelValue = IndoorNotationMatcher.getLevelValue(tags);
      if (levelValue != null) {
        // hardcoded filter to ignore level tags on buildings
        if (tags.any((tag) => tag.key == "building")) return;

        Iterable<int> levels = IndoorNotationMatcher.parseLevelNumbers(levelValue);
        if (levels != null) {
          // add all levels to the map with empty ref value
          levels.forEach((int level) => tileLevelMappingsBundle[tile][level] ??= null);
          // if only one level is given look for further level ref value
          if (levels.length == 1) {
            tileLevelMappingsBundle[tile][levels.single] ??= IndoorNotationMatcher.getLevelRefValue(tags);
          }
        }
      }
    }

    // get levels of all indoor elements and add them to the intersecting buildings
    mapReadResult.ways.forEach((way) => processTags(way.tags));
    mapReadResult.pointOfInterests.forEach((poi) => processTags(poi.tags));
  }

  return tileLevelMappingsBundle;
}