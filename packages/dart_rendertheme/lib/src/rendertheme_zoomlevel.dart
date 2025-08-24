import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/rendertheme.dart';
import 'package:dart_rendertheme/src/model/matching_cache_key.dart';
import 'package:ecache/ecache.dart';

/// The rendertheme for one specific zoomlevel
class RenderthemeZoomlevel {
  /// A list of rules which contains a list of rules which ...
  /// see defaultrender.xml how this is constructed.
  final List<Rule> rulesList;

  final Cache<MatchingCacheKey, List<Renderinstruction>> nodeMatchingCache = LruCache(capacity: 100);
  final Cache<MatchingCacheKey, List<Renderinstruction>> openWayMatchingCache = LruCache(capacity: 100);
  final Cache<MatchingCacheKey, List<Renderinstruction>> closedWayMatchingCache = LruCache(capacity: 100);

  RenderthemeZoomlevel({required this.rulesList});

  /// Matches a node with the given parameters against this RenderTheme.
  ///
  /// @param renderCallback the callback implementation which will be executed on each match.
  /// @param renderContext
  /// @param poi            the point of interest.
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

  /// Matches a closed way with the given parameters against this RenderTheme.
  ///
  /// @param renderCallback the callback implementation which will be executed on each match.
  /// @param renderContext
  /// @param way
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

  /// Matches a linear way with the given parameters against this RenderTheme.
  ///
  /// @param renderCallback the callback implementation which will be executed on each match.
  /// @param renderContext
  /// @param way
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
