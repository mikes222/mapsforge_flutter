import 'package:mapsforge_flutter/src/rendertheme/rule/rule.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape.dart';

import '../../../core.dart';
import '../../../datastore.dart';
import '../nodeproperties.dart';
import 'matchingcachekey.dart';

class RenderthemeLevel {
  /// A list of rules which contains a list of rules which ...
  /// see defaultrender.xml how this is constructed.
  final List<Rule> rulesList;

  Map<MatchingCacheKey, List<Shape>> poiMatchingCache = {};
  Map<MatchingCacheKey, List<Shape>> openWayMatchingCache = {};
  Map<MatchingCacheKey, List<Shape>> closedWayMatchingCache = {};

  RenderthemeLevel({required this.rulesList});

  void dispose() {
    this.poiMatchingCache.clear();
    this.openWayMatchingCache.clear();
    this.closedWayMatchingCache.clear();
  }

  /**
   * Matches a closed way with the given parameters against this RenderTheme.
   *
   * @param renderCallback the callback implementation which will be executed on each match.
   * @param renderContext
   * @param way
   */
  List<Shape> matchClosedWay(final Tile tile, Way way) {
    MatchingCacheKey matchingCacheKey =
        MatchingCacheKey(way.tags, tile.zoomLevel, tile.indoorLevel);

    List<Shape>? matchingList = this.closedWayMatchingCache[matchingCacheKey];
    if (matchingList == null) {
      // build cache
      matchingList = [];
      rulesList.forEach((rule) {
        rule.matchClosedWay(way, tile, matchingList!);
      });

      this.closedWayMatchingCache[matchingCacheKey] = matchingList;
    }
    return matchingList;
  }

  /**
   * Matches a linear way with the given parameters against this RenderTheme.
   *
   * @param renderCallback the callback implementation which will be executed on each match.
   * @param renderContext
   * @param way
   */
  List<Shape> matchLinearWay(final Tile tile, Way way) {
    MatchingCacheKey matchingCacheKey =
        MatchingCacheKey(way.tags, tile.zoomLevel, tile.indoorLevel);

    List<Shape>? matchingList = this.openWayMatchingCache[matchingCacheKey];
    if (matchingList == null) {
      // build cache
      matchingList = [];
      rulesList.forEach((rule) {
        rule.matchOpenWay(way, tile, matchingList!);
      });

      this.openWayMatchingCache[matchingCacheKey] = matchingList;
    }
    return matchingList;
  }

  /**
   * Matches a node with the given parameters against this RenderTheme.
   *
   * @param renderCallback the callback implementation which will be executed on each match.
   * @param renderContext
   * @param poi            the point of interest.
   */
  List<Shape> matchNode(final Tile tile, NodeProperties nodeProperties) {
    MatchingCacheKey matchingCacheKey =
        MatchingCacheKey(nodeProperties.tags, tile.zoomLevel, tile.indoorLevel);

    List<Shape>? matchingList = this.poiMatchingCache[matchingCacheKey];
    if (matchingList == null) {
      // build cache
      matchingList = [];

      rulesList.forEach((element) {
        element.matchNode(tile, matchingList!, nodeProperties);
      });
      this.poiMatchingCache[matchingCacheKey] = matchingList;
    }
    return matchingList;
  }
}
