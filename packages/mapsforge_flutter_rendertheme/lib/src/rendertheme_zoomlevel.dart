import 'package:ecache/ecache.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';
import 'package:mapsforge_flutter_rendertheme/src/model/matching_cache_key.dart';

/// Zoom level specific rendering theme containing optimized rule matching.
///
/// This class represents a pre-processed rendering theme for a specific zoom level,
/// providing cached rule matching for improved performance. It maintains separate
/// caches for nodes, open ways, and closed ways to optimize rendering operations.
///
/// Key features:
/// - LRU caches for rule matching results
/// - Separate handling for nodes, open ways, and closed ways
/// - Indoor level support for 3D mapping
/// - Optimized matching algorithms with caching
class RenderthemeZoomlevel {
  /// Hierarchical list of rendering rules for this zoom level.
  ///
  /// Contains the complete rule tree structure as defined in the theme XML,
  /// organized for efficient matching against map features.
  final List<Rule> rulesList;

  /// LRU cache for node (POI) rendering instruction matches.
  late final Cache<MatchingCacheKey, List<Renderinstruction>> nodeMatchingCache;

  /// LRU cache for open way (linear) rendering instruction matches.
  late final Cache<MatchingCacheKey, List<Renderinstruction>> openWayMatchingCache;

  /// LRU cache for closed way (area) rendering instruction matches.
  late final Cache<MatchingCacheKey, List<Renderinstruction>> closedWayMatchingCache;

  int maxLevels;

  /// Creates a new zoom level specific rendering theme.
  ///
  /// [rulesList] Hierarchical list of rendering rules for this zoom level
  RenderthemeZoomlevel({required this.rulesList, required this.maxLevels, int zoomlevel = -1}) {
    nodeMatchingCache = LruCache(capacity: 1000, name: "Node-MatchingCache$zoomlevel");
    openWayMatchingCache = LruCache(capacity: 1000, name: "OpenWay-MatchingCache$zoomlevel");
    closedWayMatchingCache = LruCache(capacity: 1000, name: "ClosedWay-MatchingCache$zoomlevel");
  }

  void dispose() {
    for (var element in rulesList) {
      element.dispose();
    }
    nodeMatchingCache.dispose();
    openWayMatchingCache.dispose();
    closedWayMatchingCache.dispose();
  }

  /// Matches a node (POI) against the rendering rules for this zoom level.
  ///
  /// Uses cached results when available to improve performance. The matching
  /// process considers both the POI's tags and the indoor level for 3D mapping.
  ///
  /// [indoorLevel] Indoor level for 3D mapping support
  /// [pointOfInterest] Point of interest to match against rules
  /// Returns list of applicable rendering instructions
  List<Renderinstruction> matchNode(final int indoorLevel, PointOfInterest pointOfInterest) {
    MatchingCacheKey matchingCacheKey = MatchingCacheKey(pointOfInterest.tags, indoorLevel);

    List<Renderinstruction>? matchingList = nodeMatchingCache[matchingCacheKey];
    if (matchingList == null) {
      // build cache
      matchingList = [];

      for (var element in rulesList) {
        element.matchNode(indoorLevel, matchingList, pointOfInterest);
      }
      nodeMatchingCache[matchingCacheKey] = matchingList;
    }
    return matchingList;
  }

  /// Matches a closed way (area) against the rendering rules for this zoom level.
  ///
  /// Uses cached results when available to improve performance. Closed ways
  /// represent areas such as buildings, parks, or water bodies.
  ///
  /// [tile] Tile context containing indoor level information
  /// [way] Closed way to match against rules
  /// Returns list of applicable rendering instructions
  List<Renderinstruction> matchClosedWay(final Tile tile, Way way) {
    MatchingCacheKey matchingCacheKey = MatchingCacheKey(way.tags, tile.indoorLevel);

    List<Renderinstruction>? matchingList = closedWayMatchingCache[matchingCacheKey];
    if (matchingList == null) {
      // build cache
      matchingList = [];
      for (var rule in rulesList) {
        rule.matchClosedWay(way, tile, matchingList);
      }

      closedWayMatchingCache[matchingCacheKey] = matchingList;
    }
    return matchingList;
  }

  /// Matches a linear way (open path) against the rendering rules for this zoom level.
  ///
  /// Uses cached results when available to improve performance. Linear ways
  /// represent paths such as roads, rivers, or boundaries.
  ///
  /// [tile] Tile context containing indoor level information
  /// [way] Linear way to match against rules
  /// Returns list of applicable rendering instructions
  List<Renderinstruction> matchLinearWay(final Tile tile, Way way) {
    MatchingCacheKey matchingCacheKey = MatchingCacheKey(way.tags, tile.indoorLevel);

    List<Renderinstruction>? matchingList = openWayMatchingCache[matchingCacheKey];
    if (matchingList == null) {
      // build cache
      matchingList = [];
      for (var rule in rulesList) {
        rule.matchOpenWay(way, tile, matchingList);
      }

      openWayMatchingCache[matchingCacheKey] = matchingList;
    }
    return matchingList;
  }
}
