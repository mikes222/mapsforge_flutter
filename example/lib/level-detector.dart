import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/src/datastore/datastorereadresult.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';
import 'package:mapsforge_flutter/src/utils/layerutil.dart';
import 'package:mapsforge_flutter/src/indoor/indoornotationmatcher.dart';
import 'package:mapsforge_flutter/src/model/tag.dart';
import 'package:ecache/ecache.dart';
import 'package:rxdart/rxdart.dart';

/// A Class that asynchronously retrieves all available indoor levels inside the
/// tiles currently rendered in the viewport with their mappings.
///
/// These can be accessed via the [levelMappings] property.
///
/// Requires a [ViewModel] and [MapDataStore].
///
/// Minimum zoom level of 17 can optionally be overwritten to a higher value.
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

  /// The lowest value of the [zoomLevel] that triggers the [LevelDetector] to
  /// operate.
  ///
  /// By default indoor elements are not rendered below a [zoomLevel] of 17,
  /// thus the value should be (and will be set to) 17 or higher.
  late final int minZoomLevel;

  LevelDetector(this._viewModel, this._mapDataStore, [this.minZoomLevel = 17])  {
    if (minZoomLevel < 17) minZoomLevel = 17;
    // debounce position change events
    this._viewModel.observePosition.debounceTime(const Duration(milliseconds: 150)).listen(_getTileCacheData);
    this._viewModel.observePosition.debounceTime(const Duration(milliseconds: 150)).listen(_updateLevelMappings);
  }

  void dispose() {
    _tileLevelCache.clear();
  }

  /// Collects information about levels in cached tiles and triggers an
  /// [_updateLevelMapping] on data change.
  ///
  /// Operates only if the current [zoomLevel] is high enough.
  void _getTileCacheData (MapViewPosition mapViewPosition) {
    if (_viewModel.viewDimension == null || mapViewPosition.zoomLevel < minZoomLevel) return;

    List<Tile> tiles = LayerUtil.getTiles(_viewModel, mapViewPosition, DateTime.now().millisecondsSinceEpoch);

    // batch all missing tiles together so isolate only needs to be created once for each bundle
    List<Tile> missingTiles = [];

    for (Tile tile in tiles) {
      SimpleTileKey tileKey = SimpleTileKey(tile);
      // if tile cache entry currently not exists
      if (!_tileLevelCache.containsKey(tileKey)) {
        // add empty cache entry
        _tileLevelCache.set(tileKey, {} as SplayTreeMap<int, String>);
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

  /// Updates information about level mappings in currently cached tiles.
  void _updateLevelMappings ([MapViewPosition? mapViewPosition]) {
    if (_viewModel.viewDimension == null || _viewModel.mapViewPosition == null) return;

    List<Tile> tiles = LayerUtil.getTiles(_viewModel, _viewModel.mapViewPosition!, DateTime.now().millisecondsSinceEpoch);

    SplayTreeMap<int, String> combinedLevelMappings = new SplayTreeMap<int, String>();

    // if below min zoom level skip this and return empty map
    if (_viewModel.mapViewPosition!.zoomLevel >= minZoomLevel) {
      for (Tile tile in tiles) {
        SimpleTileKey tileKey = SimpleTileKey(tile);
        SplayTreeMap<int, String>? tileLevelMappings = _tileLevelCache.get(tileKey);
        // if one tile cache entry currently does not exist, exit this function
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


/// A simplified version of [Tile] class, since the indoor value can be ignored
class SimpleTileKey {
  late int tileX;
  late int tileY;
  late int zoomLevel;

  SimpleTileKey(Tile tile) {
    this.tileX = tile.tileX;
    this.tileY = tile.tileY;
    this.zoomLevel = tile.zoomLevel;
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

/// Structure to pass multiple arguments to an isolate at once
class IsolateParam {
  final MapDataStore mapDataStore;
  final List<Tile> tiles;

  IsolateParam(this.mapDataStore, this.tiles);
}


/// This function is supposed to run in a separated isolate.
/// It returns a normal [Map] since a [SplayTreeMap] is not supported for isolate data exchange.
///
/// Returns a [Map] containing the [Tile]s as the key and the level mappings as the value.
Future<Map<Tile, Map <int, String>>> readAndProcessTileData(IsolateParam isolateParam) async {
  final Map<Tile, Map <int, String>> tileLevelMappingsBundle = new Map<Tile, Map <int, String>>();

  for (Tile tile in isolateParam.tiles) {
    final DatastoreReadResult? mapReadResult = await isolateParam.mapDataStore.readMapDataSingle(tile);

    tileLevelMappingsBundle[tile] = new  Map <int, String>();

    void processTags (List<Tag> tags) {
      String? levelValue = IndoorNotationMatcher.getLevelValue(tags);
      if (levelValue != null) {
        // hardcoded filter to ignore level tags on buildings
        if (tags.any((tag) => tag.key == "building")) return;

        Iterable<int>? levels = IndoorNotationMatcher.parseLevelNumbers(levelValue);
        if (levels != null) {
          // add all levels to the map with empty ref value
          levels.forEach((int level) => tileLevelMappingsBundle[tile]![level] ??= "null");
          // if only one level is given look for further level ref value
          if (levels.length == 1) {
            tileLevelMappingsBundle[tile]![levels.single] ??= IndoorNotationMatcher.getLevelRefValue(tags)!;
          }
        }
      }
    }

    // get levels of all indoor elements and add them to the intersecting buildings
    if (mapReadResult != null) {
      mapReadResult.ways.forEach((way) => processTags(way.tags));
      mapReadResult.pointOfInterests.forEach((poi) => processTags(poi.tags));
    }
  }

  return tileLevelMappingsBundle;
}

/* The LevelDetector has been cut out because it was inefficient and didn't work properly with current sdk updates.
 *
 * If updated and optimized, use the LevelDetector like this in the map-view-page:
 * - declare a LevelDetector levelDetector at the beginning of the MapViewPageState
 * - in the _prepare() function, fill the two IndoorlevelZoomOverlay with (viewModel, indoorLevels: levelDetector.levelMappings.value)
 * - in the end of the _prepare() function, define the detector like this:
 *
 *     levelDetector = new LevelDetector(viewModel, mapDataStore);
 *     levelDetector.levelMappings.listen((levelMappings) {
 *       if (levelMappings.length > 1) {
 *         if (fadeAnimationController.isDismissed ||
 *             fadeAnimationController.status == AnimationStatus.reverse) {
 *           // fade in level bar
 *           fadeAnimationController.forward();
 *         }
 *         // update level mappings and show level bar
 *         setState(() {});
 *       } else {
 *         if (fadeAnimationController.isCompleted ||
 *             fadeAnimationController.status == AnimationStatus.forward) {
 *           // fade out and hide level bar
 *           fadeAnimationController.reverse().whenComplete(() => setState(() {}));
 *         }
 *       }
 *     });
 */
